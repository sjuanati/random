// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

// Contract owner can create and finish a lottery
// Each ticket is 1 ETH

contract LotteryManager {
    address owner;

    struct Lottery {
        uint256 maxTickets;
        address winner;
        bool isActive;
    }

    struct Ticket {
        uint256 id;
        address player;
    }

    Lottery[] public lotteries;

    mapping(uint256 => Ticket[]) public tickets;

    constructor() {
        owner = msg.sender;
    }

    function create(uint256 _maxTickets) external onlyOwner() {
        lotteries.push(Lottery(_maxTickets, address(0), true));
    }

    function buy(uint256 _lottery) external payable {
        Lottery storage lottery = lotteries[_lottery];
        require(lotteries.length > _lottery, "lottery does not exist");
        require(lottery.isActive == true, "lottery has finished");
        require(msg.value == 1 ether, "must send 1 ETH");
        require(lottery.maxTickets > tickets[_lottery].length, "sold out");

        tickets[_lottery].push(
            Ticket(_assignAvailableRandomTicket(_lottery), msg.sender)
        );
    }

    function close(uint256 _lottery) external onlyOwner() {
        require(lotteries.length > _lottery, "lottery does not exist");

        uint256 max = lotteries[_lottery].maxTickets;
        uint256 random =
            (uint256(keccak256(abi.encode(block.difficulty, block.timestamp))) %
                max) + 1;

        for (uint256 i = 0; i < tickets[_lottery].length; i++) {
            if (tickets[_lottery][i].id == random) {
                lotteries[_lottery].winner = tickets[_lottery][i].player;
                payable(tickets[_lottery][i].player).transfer(
                    address(this).balance
                );
            }
        }
        //todo: emit with winner or no winner
    }

    function balance() external view returns (uint256) {
        return address(this).balance;
    }

    function _assignAvailableRandomTicket(uint256 _lottery)
        private
        view
        returns (uint256 result)
    {
        bool isFound = false;
        while (isFound == false) {
            uint256 max = lotteries[_lottery].maxTickets;
            // modulo returns a number between 0 and max-1, therefore, adding 1 to the result
            uint256 random =
                (uint256(
                    keccak256(abi.encode(block.difficulty, block.timestamp))
                ) % max) + 1;
            if (_isTicketAvailable(_lottery, random)) {
                result = random;
                isFound = true;
            }
        }
    }

    function _isTicketAvailable(uint256 _lottery, uint256 _ticket)
        private
        view
        returns (bool)
    {
        require(lotteries.length > _lottery, "lottery does not exist");
        for (uint256 i = 0; i < tickets[_lottery].length; i++) {
            if (tickets[_lottery][i].id == _ticket) {
                return false;
            }
        }
        return true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }
}
