// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract newERC20 is ERC20 {
    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {}

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}

contract ICO {
    enum Status {ACTIVE, FROZEN, CLOSED}

    struct Investor {
        uint256 amount;
        bool isWithdrawn;
    }

    struct Ico {
        address founder;
        uint256 totalTokens;
        Status status;
        newERC20 token;
        mapping(address => Investor) investors;
    }

    uint256 numIco;
    mapping(uint256 => Ico) public icos;

    function startICO(
        string memory name,
        string memory symbol,
        uint256 totalTokens
    ) external {
        Ico storage ico = icos[numIco];
        ico.founder = msg.sender;
        ico.totalTokens = totalTokens;
        ico.status = Status.ACTIVE;
        ico.token = new newERC20(name, symbol);
        ico.token.mint(address(this), totalTokens);
        numIco += 1;
        //todo: create an ERC20 token and store its reference
    }

    function contribute(uint256 _numIco) external payable {
        Ico storage ico = icos[_numIco];
        require(ico.status == Status.ACTIVE, "ICO is not active");
        //ico.investors[msg.sender] += msg.value;
        ico.investors[msg.sender].amount += msg.value;
    }

    function closeICO(uint256 _numIco) external {
        Ico storage ico = icos[_numIco];
        require(ico.founder == msg.sender, "only founder can close ICO");
        ico.status = Status.CLOSED;
    }

    function claimTokens(uint256 _numIco) external {
        Ico storage ico = icos[_numIco];
        require(ico.status == Status.CLOSED, "ico not yet close");
        require(
            ico.investors[msg.sender].isWithdrawn == false,
            "tokens already claimed"
        );
        require(
            ico.investors[msg.sender].amount > 0,
            "no amount to be claimed"
        );
        ico.token.transfer(msg.sender, ico.investors[msg.sender].amount * 2);
        ico.investors[msg.sender].isWithdrawn = true;
    }

    function checkContribution(uint256 _numIco)
        external
        view
        returns (uint256)
    {
        return icos[_numIco].investors[msg.sender].amount;
    }

    function checkTokens(uint256 _numIco) external view returns (uint256) {
        return icos[_numIco].token.balanceOf(msg.sender);
    }
}
