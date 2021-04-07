const PRIVIPodERC20Token = artifacts.require("PRIVI");
const AtomicSwapERC20 = artifacts.require("AtomicSwapERC20Mock");

const { BN } = require("web3-utils");
const sha256 = require('js-sha256');

function getUnixEpochTimeStamp(value) {
    return Math.floor(value.getTime() / 1000);
}

contract("AtomicSwapERC20", (accounts) => {
    let PRIVIPodERC20Token_contract;
    let AtomicSwapERC20_contract;
    let podAdress1;

    before(async () => {
        await AtomicSwapERC20.new({ from: accounts[0] }).then(function (instance) {
            AtomicSwapERC20_contract = instance;
        });

        await PRIVIPodERC20Token.new({ from: accounts[0] }).then(function (instance) {
            PRIVIPodERC20Token_contract = instance;
        });
        podAdress1 = PRIVIPodERC20Token_contract.address;

        await PRIVIPodERC20Token_contract.mint(accounts[1], 1000);
    });

    describe("swap", () => {
        it("everything is working fine with normal flow", async () => {

            assert.equal(new BN(await PRIVIPodERC20Token_contract.balanceOf(accounts[2]), { from: accounts[0] }).toString(), 0);

            let date = new Date(); // e.g.: 2021-04-07T12:13:38.337Z
            date.setDate(date.getDate() + 1); // adds one day, e.g.: 2021-04-08T12:13:38.337Z

            await PRIVIPodERC20Token_contract.approve(
                AtomicSwapERC20_contract.address,
                1000,
                { from: accounts[1] }
            );

            await AtomicSwapERC20_contract.createProposal(
                "0x341f85f5eca6304166fcfb6f591d49f6019f23fa39be0615e6417da06bf747ce",
                "100",
                podAdress1,
                accounts[2],
                '0x' + sha256('PRIVI_Secret_Key'),
                getUnixEpochTimeStamp(date),
                { from: accounts[1] }
            );

            await AtomicSwapERC20_contract.claimFunds(
                "0x341f85f5eca6304166fcfb6f591d49f6019f23fa39be0615e6417da06bf747ce",
                'PRIVI_Secret_Key',
                { from: accounts[2] }
            );

            assert.equal(new BN(await PRIVIPodERC20Token_contract.balanceOf(accounts[2]), { from: accounts[0] }).toString(), 100);
        });

        it("refund", async () => {
            let date = new Date();
            date.setDate(date.getDate() + 1);

            await PRIVIPodERC20Token_contract.approve(AtomicSwapERC20_contract.address, 1000, { from: accounts[1] })

            await AtomicSwapERC20_contract.createProposal(
                "0x341f85f5eca6304166fcfb6f591d49f6019f23fa39be0615e6417da06bf747cf",
                "100",
                podAdress1,
                accounts[2],
                '0x' + sha256('PRIVI_Secret_Key'),
                getUnixEpochTimeStamp(date),
                { from: accounts[1] }
            );

            date.setDate(date.getDate() + 2);
            await AtomicSwapERC20_contract.setBlockTimeStamp(getUnixEpochTimeStamp(date));


            await AtomicSwapERC20_contract.refundFunds(
                "0x341f85f5eca6304166fcfb6f591d49f6019f23fa39be0615e6417da06bf747cf",
                { from: accounts[1] }
            );

            // await AtomicSwapERC20_contract.refundFunds(
            //     "0x341f85f5eca6304166fcfb6f591d49f6019f23fa39be0615e6417da06bf747cf",
            //     { from: accounts[2] }
            // );

            assert.equal(new BN(await PRIVIPodERC20Token_contract.balanceOf(accounts[1]), { from: accounts[0] }).toString(), 900);
        });
    });
});