// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "../AtomicSwapERC20.sol";

contract AtomicSwapERC20Mock is AtomicSwapERC20{
    uint256 public fakeBlockTimeStamp;

    function setBlockTimeStamp(uint256 _now) external {
        fakeBlockTimeStamp = _now;
    }

    function _getNow() internal override view returns (uint256) {
        return fakeBlockTimeStamp;
    }
}