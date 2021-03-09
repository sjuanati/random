// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/* 
- Deploy contract B first, then A
- Call function A.setVars() with address of contract B and a value
- Updates are only performed in A. If a variable in B is not in A (test), it won't be updated
*/

contract B {
    // NOTE: storage layout must be the same as contract A
    uint256 public num;
    address public sender;
    uint256 public value;
    uint256 public test;

    function setVars(uint256 _num, uint256 _test) public payable {
        num = _num;
        sender = msg.sender;
        value = msg.value;
        test = _test;
    }
}

contract A {
    uint256 public num;
    address public sender;
    uint256 public value;

    function setVars(address _contract, uint256 _num, uint256 _test) public payable {
        // A's storage is set, B is not modified.
        (bool success, bytes memory data) =
            _contract.delegatecall(
                abi.encodeWithSignature("setVars(uint256,uint256)", _num, _test)
            );
    }
}
