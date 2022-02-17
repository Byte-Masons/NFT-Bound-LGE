//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OZ/token/ERC721/ERC721.sol";

contract TestERC721 is IERC721, ERC721 {

  constructor(string memory name, string memory symbol) ERC721(name, symbol) { }

  uint nonce = 1;

  function mint(address to) external returns (bool) {
    _safeMint(to, nonce);
    nonce++;
    return true;
  }

}
