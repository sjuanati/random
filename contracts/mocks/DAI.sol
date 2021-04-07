// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FakeDAI is ERC20 {

  constructor() ERC20("FakeDAI", "fDAI") {}

  function mint(address user, uint256 amount) external {
    _mint(user, amount);
  }
}
