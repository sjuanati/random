// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

// ICO (crowdsale): collect funds from investors
// ERC20: token given to the investors

// TODO: do the tests

import "./mocks/DAI.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// contract must be deployed before the start of the ICO (to avoid any potential technical problem during deployment)

contract ICO2 {
    struct Sale {
        address investor;
        uint256 quantity;
    }
    Sale[] public sales;

    mapping(address => bool) public investors; // KYC investors

    address public token;
    address public admin;

    uint256 public end; // end of the ICO
    uint256 public price; // number of tokens per ETH (token per ether)
    uint256 public availableTokens; // to allocate some tokens for founders, core team, early investors
    uint256 public minPurchase; // min : KYC has a cost, so each investment should cover at least this cost
    uint256 public maxPurchase; // max : to avoid whales, have diversification of investors, avoid too much power

    bool public released;

    constructor() {
        token = address(new FakeDAI());
        FakeDAI(token).mint(address(this), 10000);
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    modifier icoNotActive() {
        require(end == 0, "ICO should not be active");
        _;
    }

    modifier onlyInvestors() {
        require(investors[msg.sender] == true, "only investors");
        _;
    }

    modifier icoActive() {
        require(
            end > 0 && block.timestamp < end && availableTokens > 0,
            "ICO must be active"
        );
        _;
    }

    modifier icoEnded() {
        // whe called the start && (period is over || no tokens available)
        require(end > 0 && (block.timestamp >= end || availableTokens == 0));
        _;
    }

    modifier tokensNotReleased() {
        require(released == false, "tokens must NOT have been released");
        _;
    }

    modifier tokensReleased() {
        require(released == true, "tokens must have been released");
        _;
    }

    function start(
        uint256 duration,
        uint256 _price,
        uint256 _availableTokens,
        uint256 _minPurchase,
        uint256 _maxPurchase
    ) external onlyAdmin() icoNotActive() {
        require(duration > 0, "duration should be > 0");
        uint256 totalSupply = ERC20(token).totalSupply();
        require(
            _availableTokens > 0 && _availableTokens <= totalSupply,
            "totalSupply should be > 0 and <= totalSupply"
        );
        require(_minPurchase > 0, "minPruchase should be > 0");
        require(
            _maxPurchase > 0 && _maxPurchase <= availableTokens,
            "maxPurchase should be >0 and <= availableTokens"
        );

        end = duration + block.timestamp;
        price = _price;
        availableTokens = _availableTokens;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
    }

    // Only KYC investors
    function whiteList(address investor) external onlyAdmin() {
        investors[investor] = true;
    }

    function buy() external payable onlyInvestors() icoActive() {
        // check if eth sent is multiple of the price (to avoid leftover ether)
        require(msg.value % price == 0, "have to send a multiple of price");
        require(
            msg.value >= minPurchase && msg.value <= maxPurchase,
            "have to send between min and max purchase"
        );

        uint256 quantity = price * msg.value;
        // not redundant with previous check!
        require(quantity <= availableTokens, "not enough token left for sell");

        sales.push(Sale(msg.sender, quantity));
    }

    // to avoid users start transferring tokens during the ICO (primary market). They
    // can only be sold in the secondary market once the ICO is finished
    function release() external onlyAdmin() icoEnded() tokensNotReleased() {
        FakeDAI tokenInstance = FakeDAI(token);
        for (uint256 i = 0; i < sales.length; i++) {
            Sale storage sale = sales[i];
            tokenInstance.transfer(sale.investor, sale.quantity);
        }
    }

    // withdraw all ether once the ICO has ended
    function withdraw(address payable to, uint256 amount)
        external
        onlyAdmin()
        icoEnded()
        tokensReleased()
    {
        to.transfer(amount);
    }
}
