// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract AuctionManager {
    address owner;
    
    struct Auction {
        uint256 price;
        uint256 deadline;
        address bidder;
    }
    
    Auction[] public auctions;
    
    constructor() {
        owner = msg.sender;
    }
    
    function start(uint256 _price, uint256 _deadline) external onlyOwner() {
        auctions.push(Auction(_price, _deadline, address(0)));
    }
    
    function bid(uint256 _auction, uint256 _price) external {
        Auction storage Auct = auctions[_auction];
        require(Auct.deadline > block.timestamp, 'auction is closed');
        require(Auct.bidder != msg.sender, 'already voted');
        require(Auct.price < _price, 'bidding price must be higher than current one');
        Auct.price = _price;
        Auct.bidder = msg.sender;
    }
    
    function showTimestamp() view external returns(uint256){
        return block.timestamp;
    }
    
    function getAuctions() view external returns(Auction[] memory) {
        return auctions;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, 'only owner');
        _;
    }
}