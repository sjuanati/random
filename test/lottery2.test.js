const { expectRevert, expectEvent, balance, ether } = require('@openzeppelin/test-helpers');
const assert = require('assert');

const Lottery = artifacts.require("LotteryManager2");

contract("Lottery", (accounts) => {
    let lottery;
    const [admin, player1, player2] = accounts;
    const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

    beforeEach(async () => {
        lottery = await Lottery.new({ from: admin });
        await lottery.create(100, { from: admin });
    });

    it("create(): should create a lottery", async () => {
        const [maxTickets, winner, isActive, lastTicket] = await lottery.getLottery(0);

        assert(maxTickets.toString() === '100', 'should be 100 tickets max');
        assert(winner.toString() === ZERO_ADDRESS, 'should be 0x address');
        assert(isActive === true, 'should be active');
        assert(lastTicket.toString() === '0', 'should be currently 0 tickets');
    });

    it("buy(): should not buy - lottery id does not exist", async () => {
        await expectRevert(
            lottery.buy(3, { from: player1 }),
            'lottery id does not exist'
        );
    });

    it("buy(): should not buy - sold out", async () => {
        await lottery.create(1, { from: admin });
        await lottery.buy(1, { from: player1, value: ether('1') });
        await expectRevert(
            lottery.buy(1, { from: player2, value: ether('1') }),
            'sold out'
        );
    });

    it("buy(): should not buy - lottery id does not exist", async () => {
        await lottery.close(0, { from: admin });
        await expectRevert(
            lottery.buy(0, { from: player2, value: ether('1') }),
            'lottery has finished'
        );
    });

    it("buy(): should not buy - lottery id does not exist", async () => {
        await expectRevert(
            lottery.buy(0, { from: player2 }),
            'must pay 1 ETH'
        );
    });

    it("buy(): should buy", async () => {
        await lottery.buy(0, { from: player1, value: ether('1') });

        assert(await lottery.tickets.call(0, 0) === player1, 'should be player1');
    });

    it("close(): should not close - lottery id does not exist", async () => {
        await expectRevert(
            lottery.close(3, { from: admin }),
            'lottery id does not exist'
        );
    });

    it("close(): should not close - lottery already closed", async () => {
        await lottery.close(0, { from: admin })
        await expectRevert(
            lottery.close(0, { from: admin }),
            'lottery already closed'
        );
    });

    it("close(): should not assign a winner", async () => {
        await lottery.close(0, { from: admin })
        const [_, winner] = await lottery.getLottery(0);

        assert(winner.toString() === ZERO_ADDRESS, 'should be 0x address');
    });

    it("close(): should assign a winner", async () => {
        await lottery.buy(0, { from: player1, value: ether('1') });
        await lottery.buy(0, { from: player2, value: ether('1') });
        console.log(await lottery.tickets.call(0, 0))
        console.log(await lottery.tickets.call(0, 1))
        await lottery.close(0, { from: admin });
        const result = await lottery.getLottery(0);
        console.log('winner:', result[1]);
    });
});

