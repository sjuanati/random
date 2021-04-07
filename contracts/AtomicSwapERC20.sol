// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.1;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AtomicSwapERC20 {
    struct Swap {
        uint256 timelock;
        uint256 value;
        address trader;
        address contractAddress;
        address withdrawTrader;
        bytes32 secretLock;
        string secretKey;
    }

    enum States {INVALID, OPEN, CLOSED, EXPIRED}

    mapping(bytes32 => Swap) private swaps;
    mapping(bytes32 => States) private swapStates;

    event OpenProposal(
        bytes32 _swapID,
        address _withdrawTrader,
        bytes32 _secretLock
    );
    event ExpireProposal(bytes32 _swapID);
    event CloseProposal(bytes32 _swapID, string _secretKey);

    modifier onlyInvalidSwaps(bytes32 _swapID) {
        require(
            swapStates[_swapID] == States.INVALID,
            "AtomicSwapERC20: Swap is valid"
        );
        _;
    }

    modifier onlyOpenSwaps(bytes32 _swapID) {
        require(
            swapStates[_swapID] == States.OPEN,
            "AtomicSwapERC20: Swap is not opened"
        );
        _;
    }

    modifier onlyClosedSwaps(bytes32 _swapID) {
        require(
            swapStates[_swapID] == States.CLOSED,
            "AtomicSwapERC20: Swap is not closed"
        );
        _;
    }

    modifier onlyExpirableSwaps(bytes32 _swapID) {
        require(
            swaps[_swapID].timelock <= _getNow(),
            "AtomicSwapERC20: Swap is not expired"
        );
        _;
    }

    modifier onlyWithSecretKey(bytes32 _swapID, string memory _secretKey) {
        // TODO: Require _secretKey length to conform to the spec
        require(
            swaps[_swapID].secretLock == sha256(abi.encodePacked(_secretKey)),
            "AtomicSwapERC20: Invalid secret key"
        );
        _;
    }

    function createProposal(
        bytes32 _swapID,
        uint256 _value,
        address _contractAddress,
        address _withdrawTrader,
        bytes32 _secretLock,
        uint256 _timelock
    ) public onlyInvalidSwaps(_swapID) {
        // Transfer value from the token trader to this contract.
        IERC20 contractInstance = IERC20(_contractAddress);
        require(
            _value <= contractInstance.allowance(msg.sender, address(this)),
            "AtomicSwapERC20.createProposal: Caller has not enough balance"
        );
        require(
            contractInstance.transferFrom(msg.sender, address(this), _value),
            "AtomicSwapERC20.createProposal: Transaction failed"
        );

        // Store the details of the swap.
        Swap memory swap =
        Swap({
            timelock: _timelock,
            value: _value,
            trader: msg.sender,
            contractAddress: _contractAddress,
            withdrawTrader: _withdrawTrader,
            secretLock: _secretLock,
            secretKey: ''
        });
        swaps[_swapID] = swap;
        swapStates[_swapID] = States.OPEN;
        emit OpenProposal(_swapID, _withdrawTrader, _secretLock);
    }

    function claimFunds(bytes32 _swapID, string memory _secretKey)
        public
        onlyOpenSwaps(_swapID)
        onlyWithSecretKey(_swapID, _secretKey)
    {
        // Close the swap.
        Swap memory swap = swaps[_swapID];
        swaps[_swapID].secretKey = _secretKey;
        swapStates[_swapID] = States.CLOSED;

        // Transfer the funds from this contract to the withdrawing trader.
        IERC20 contractInstance = IERC20(swap.contractAddress);
        require(
            contractInstance.transfer(swap.withdrawTrader, swap.value),
            "AtomicSwapERC20.claimFunds: Transaction failed"
        );

        emit CloseProposal(_swapID, _secretKey);
    }

    function refundFunds(bytes32 _swapID)
        public
        onlyOpenSwaps(_swapID)
        onlyExpirableSwaps(_swapID)
    {
        // Expire the swap.
        Swap memory swap = swaps[_swapID];
        swapStates[_swapID] = States.EXPIRED;

        // Transfer the token from this contract back to the trader.
        IERC20 contractInstance = IERC20(swap.contractAddress);
        require(
            contractInstance.transfer(swap.trader, swap.value),
            "AtomicSwapERC20.refundFunds: Transaction failed"
        );

        emit ExpireProposal(_swapID);
    }

    function getSwapInfo(bytes32 _swapID)
        public
        view
        returns (
        uint256 timelock,
        uint256 value,
        address contractAddress,
        address withdrawTrader,
        bytes32 secretLock
        )
    {
        Swap memory swap = swaps[_swapID];
        return (
        swap.timelock,
        swap.value,
        swap.contractAddress,
        swap.withdrawTrader,
        swap.secretLock
        );
    }

    function getSecretKey(bytes32 _swapID)
        public
        view
        onlyClosedSwaps(_swapID)
        returns (string memory secretKey)
    {
        Swap memory swap = swaps[_swapID];
        return swap.secretKey;
    }

    function _getNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}