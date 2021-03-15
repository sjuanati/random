// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract carERC721 is ERC721 {
    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}

contract CarDealer {
    enum Status {OFFER, SOLD, DELIVERED}

    struct Car {
        address seller;
        address buyer;
        string model;
        uint256 price;
        Status status;
    }

    carERC721 asset;

    uint256 idCar = 1;
    mapping(uint256 => Car) public cars; // idCar -> Car

    constructor(string memory name, string memory symbol) {
        asset = new carERC721(name, symbol);
    }

    function offerCar(string memory model, uint256 price) external {
        Car storage car = cars[idCar];
        car.seller = msg.sender;
        car.price = price;
        car.model = model;
        car.status = Status.OFFER;
        asset.mint(address(this), idCar);
        idCar += 1;
    }

    function buyCar(uint256 _idCar) external payable {
        Car storage car = cars[_idCar];
        require(car.status == Status.OFFER, "car is not in offer");
        require(
            car.price == msg.value,
            "car price does not match with amount sent"
        );
        car.status = Status.SOLD;
        car.buyer = msg.sender;
    }

    function deliverCar(uint256 _idCar) external {
        Car storage car = cars[_idCar];
        require(car.seller == msg.sender, "only owner can sell the car");
        car.status = Status.DELIVERED;
        asset.transferFrom(address(this), car.buyer, _idCar);
        payable(msg.sender).transfer(car.price);
    }

    function getCarOwner(uint256 _idCar) external view returns (address) {
        return asset.ownerOf(_idCar);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
