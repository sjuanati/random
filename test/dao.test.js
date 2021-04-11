const { expectRevert, expectEvent, time, ether } = require('@openzeppelin/test-helpers');
const assert = require('assert');

const DAO = artifacts.require("DAO");
const DAI = artifacts.require("FakeDAI");

contract("DAO", (accounts) => {
    let dao;
    let dai;
    const [admin, participant1, participant2, participant3] = accounts;
    const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
    const STATUS = {
        Open: 0,
        Approved: 1,
        Rejected: 2,
    };
    const ANSWER = {
        Yes: 0,
        No: 1,
    };


    beforeEach(async () => {
        // Contract instances
        dai = await DAI.new({ from: admin });
        dao = await DAO.new(dai.address, { from: admin });

        // Transfer governance tokens to participants
        await dai.mint(participant1, ether('1000'), { from: admin });
        await dai.mint(participant2, ether('500'), { from: admin });

        // Create proposal
        await dai.approve(dao.address, ether('200'), { from: participant2 });
        await dao.deposit(ether('200'), { from: participant2 });
        await dao.createProposal('Add AAVE', { from: participant2 });
    });

    it("deposit(): should not deposit - amount must be greater than 0", async () => {
        await expectRevert(
            dao.deposit(0, { from: participant1 }),
            'amount must be greater than 0'
        );
    });

    it("deposit(): should not deposit - transfer not approved", async () => {
        await expectRevert(
            dao.deposit(50, { from: participant1 }),
            'ERC20: transfer amount exceeds allowance'
        );
    });

    it("deposit(): should deposit", async () => {
        await dai.approve(dao.address, ether('1000'), { from: participant1 });
        await dao.deposit(ether('1000'), { from: participant1 });

        const balanceDAO = await dai.balanceOf(dao.address);
        assert(balanceDAO.eq(ether('1200')), 'DAO balance in DAI should be 1200');
    });

    it("withdraw(): should not withdraw - not enough shares", async () => {
        await dai.approve(dao.address, ether('1000'), { from: participant1 });
        await dao.deposit(ether('1000'), { from: participant1 });
        await expectRevert(
            dao.withdraw(ether('5000'), { from: participant1 }),
            'not enough shares'
        );
    });

    it("withdraw(): should withdraw", async () => {
        await dai.approve(dao.address, ether('1000'), { from: participant1 });
        await dao.deposit(ether('1000'), { from: participant1 });
        await dao.withdraw(ether('700'), { from: participant1 });

        const balanceDAO = await dai.balanceOf(dao.address);
        assert(balanceDAO.eq(ether('500')), 'DAO balance in DAI should be 500');
    });

    it("createProposal(): should not create proposal - not enough shares", async () => {
        await dai.approve(dao.address, ether('90'), { from: participant1 });
        await dao.deposit(ether('90'), { from: participant1 });
        await expectRevert(
            dao.createProposal('Add Compound', { from: participant1 }),
            'not enough shares to create proposal'
        );
    });

    it("createProposal(): should create proposal", async () => {
        await dai.approve(dao.address, ether('200'), { from: participant1 });
        await dao.deposit(ether('200'), { from: participant1 });
        await dao.createProposal('Add Compound', { from: participant1 });

        const { title, author, proposalId, status } = await dao.proposals.call(1);
        assert(title === 'Add Compound', 'name should be Add Compound');
        assert(author === participant1, 'author should be participant1');
        assert(proposalId.toString() === '1', 'proposalId should be 1');
        assert(status.toNumber() === STATUS.Open, 'status should be open');
        assert((await dao.nextProposalId()).toNumber() === 2, 'nextProposalId should be 2');
    });

    it("vote(): should not vote - not enough shares", async () => {
        await expectRevert(
            dao.vote(0, ANSWER.Yes, {from: participant3}),
            'not enough shares to vote'
        );
    });

    it("vote(): should not vote - proposal does not exist", async () => {
        await expectRevert(
            dao.vote(5, ANSWER.Yes, {from: participant2}),
            'proposal does not exist'
        );
    });

    it("vote(): should not vote - proposal is closed", async () => {
        await dao.vote(0, ANSWER.Yes, {from: participant2})
        await expectRevert(
            dao.vote(0, ANSWER.Yes, {from: participant2}),
            'proposal is closed'
        );
    });

    it("vote(): should not vote - already voted", async () => {
        await dai.approve(dao.address, ether('20'), { from: participant1 });
        await dao.deposit(ether('20'), { from: participant1 });
        await dao.vote(0, ANSWER.Yes, {from: participant1})
        await expectRevert(
            dao.vote(0, ANSWER.Yes, {from: participant1}),
            'already voted'
        );
    });

    it("vote(): should not vote - voting period has ended", async () => {
        time.increase(time.duration.days(8));
        await expectRevert(
            dao.vote(0, ANSWER.Yes, {from: participant2}),
            'voting period has ended'
        );
    });

    it.only("vote(): should vote", async () => {
        await dai.approve(dao.address, ether('300'), { from: participant1 });
        await dao.deposit(ether('300'), { from: participant1 });
        
        await dao.vote(0, ANSWER.No, {from: participant2}); // shares: 200
        await dao.vote(0, ANSWER.Yes, {from: participant1}); // shares: 300

        const { votesYes, votesNo, status } = await dao.proposals.call(0);

        assert(votesYes.toString() === ether('300').toString(), 'Yes should be 300 ETH')
        assert(votesNo.toString() === ether('200').toString(), 'No should be 200 ETH')
        assert(status.toNumber() === STATUS.Approved, 'status should be Approved')
    });

});
