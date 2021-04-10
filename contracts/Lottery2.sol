// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/**
 * @title Lottery v2
 * @author SJS
 * @dev Lottery system that assigns numbers to users sequentially
 * and assigns a winner randomly
 **/
contract LotteryManager2 {
    address owner;

    struct Lottery {
        uint256 maxTickets;
        address winner;
        bool isActive;
        uint256 lastTicket;
    }

    Lottery[] public lotteries;

    // lotteryId => ticketId => player
    mapping(uint256 => mapping(uint256 => address)) public tickets;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    /**
     * @dev creates a new lottery
     * @param _maxTickets The maximum number of tickets to be sold
     */
    function create(uint256 _maxTickets) external onlyOwner() {
        lotteries.push(Lottery(_maxTickets, address(0), true, 0));
    }

    /**
     * @dev buys a lottery ticket by sending 1 ETH
     * @param _lotteryId The lottery identifier
     */
    function buy(uint256 _lotteryId) external payable {
        require(lotteries.length > _lotteryId, "lottery id does not exist");
        
        Lottery memory lottery = lotteries[_lotteryId];

        require(lottery.maxTickets > lottery.lastTicket, "sold out");
        require(lottery.isActive == true, "lottery has finished");
        require(msg.value == 1 ether, "must pay 1 ETH");

        _assign(_lotteryId, lottery.lastTicket);
    }

    /**
     * @dev closes a lottery and assigns a winner randomly
     * The modulo returns a number between 0 and max-1
     * @param _lotteryId The lottery identifier
     */
    function close(uint256 _lotteryId) external onlyOwner() {
        require(lotteries.length > _lotteryId, "lottery id does not exist");

        Lottery storage lottery = lotteries[_lotteryId];

        require(lottery.isActive == true, "lottery already closed");

        if (lottery.lastTicket > 0) {
            uint256 currentMaxTickets = lottery.lastTicket;
            uint256 random =
                (uint256(
                    keccak256(
                        abi.encode(
                            block.difficulty,
                            block.timestamp,
                            block.number
                        )
                    )
                ) % currentMaxTickets);
            lottery.winner = tickets[_lotteryId][random];
        }
        lottery.isActive = false;
    }

    /**
     * @dev Get the lottery data
     * @param _lotteryId The lottery identifier
     * @return The lottery data (maxTickets, winner, isActive, lastTicket)
     */
    function getLottery(uint256 _lotteryId)
        external
        view
        returns (Lottery memory)
    {
        return lotteries[_lotteryId];
    }

    /**
     * @dev Assign a lottery ticket to the current player
     * @param _lotteryId The lottery identifier
     * @param _ticketNumber The ticket number
     */
    function _assign(uint256 _lotteryId, uint256 _ticketNumber) private {
        tickets[_lotteryId][_ticketNumber] = msg.sender;
        lotteries[_lotteryId].lastTicket += 1;
    }
}
