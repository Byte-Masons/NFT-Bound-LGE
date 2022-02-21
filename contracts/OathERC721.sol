pragma solidity ^0.8.11;

/***
 *     ▒█████   ▄▄▄      ▄▄▄█████▓ ██░ ██
 *    ▒██▒  ██▒▒████▄    ▓  ██▒ ▓▒▓██░ ██▒
 *    ▒██░  ██▒▒██  ▀█▄  ▒ ▓██░ ▒░▒██▀▀██░
 *    ▒██   ██░░██▄▄▄▄██ ░ ▓██▓ ░ ░▓█ ░██
 *    ░ ████▓▒░ ▓█   ▓██▒  ▒██▒ ░ ░▓█▒░██▓
 *    ░ ▒░▒░▒░  ▒▒   ▓▒█░  ▒ ░░    ▒ ░░▒░▒
 *      ░ ▒ ▒░   ▒   ▒▒ ░    ░     ▒ ░▒░ ░
 *    ░ ░ ░ ▒    ░   ▒     ░       ░  ░░ ░
 *        ░ ░        ░  ░          ░  ░  ░
 *
 */

import "./OZ/token/ERC721/extensions/ERC721Enumerable.sol";

contract OathERC721 is ERC721Enumerable {

    address admin;
    string uri;

    constructor(string memory _uri, string memory name, string memory symbol) ERC721(name, symbol) {
        admin = msg.sender;
        uri = _uri;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return uri;
    }

    function mint(address to) public {
        require(msg.sender == admin, "!admin");
        _mint(to, totalSupply());
    }

    function mintMany(address[] calldata addrs) external {
        for (uint i; i < addrs.length; i++) {
            mint(addrs[i]);
        }
    }

    function setAdmin(address _admin) external {
        require(msg.sender == admin, "!admin");
        admin = _admin;
    }

    function setURI(string calldata _uri) external {
        require(msg.sender == admin, "!admin");
        uri = _uri;
    }
}
