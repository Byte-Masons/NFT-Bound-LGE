//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OZ/token/ERC20/ERC20.sol";

contract TestERC20 is IERC20, ERC20 {

  constructor(string memory name, string memory symbol) ERC20(name, symbol) { }

  function mint(address to, uint amount) external returns (bool) {
    _mint(to, amount);
    return true;
  }

}
