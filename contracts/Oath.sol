// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Oath is
  Initializable,
  ERC20Upgradeable,
  ERC20CappedUpgradeable,
  AccessControlUpgradeable,
  PausableUpgradeable,
  ERC20PermitUpgradeable,
  UUPSUpgradeable {

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant RESCUER_ROLE = keccak256("RESCUER_ROLE");
    uint256 public constant MAX_SUPPLY = 400_000_000 ether;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // @param lge: granting minting rights to the Liquidity Generation Event contract for initial distribution
    function initialize(address admin) initializer public {
        __ERC20_init("Oath Token", "OATH");
        __ERC20Capped_init(MAX_SUPPLY);
        __AccessControl_init();
        __Pausable_init();
        __ERC20Permit_init("Oath Token");
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);
        _grantRole(RESCUER_ROLE, admin);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20CappedUpgradeable) {
        require(totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override(ERC20Upgradeable)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function rescueLostTokens(address token, address to, uint256 amount) public onlyRole(RESCUER_ROLE){
    	IERC20Upgradeable(token).transfer(to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}
}
