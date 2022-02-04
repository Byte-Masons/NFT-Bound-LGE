//SPDX license identifier: MIT

pragma solidity ^0.8.0;

import "./Math.sol";
import "./OZ/token/ERC20/IERC20.sol";
import "./OZ/access/Ownable.sol";
import "./OZ/token/ERC721/IERC721.sol";

contract IntegralFundraising is Ownable {
  using Math for uint;

  uint public sold;
  uint public targetRaise;
  uint public startPercent;
  uint public targetPrice;

  uint public BASIS_POINTS = 10000;
  uint public slope;

  uint public divisor;

  IERC20 public asset;
  IERC20 public counterAsset;
  uint public startingAmount;

  struct License {
    uint threshold;
    uint limit;
  }

  struct Allocation {
    uint remaining;
    bool activated;
  }

  //TODO: finish function
  function addLicense(address addr, uint threshold, uint limit) public onlyOwner returns (bool) {
    licenses[addr] = License(threshold, limit);
    return true;
  }

  mapping(address => License) public licenses;
  mapping(address => mapping(uint => Allocation)) public allocations;

  mapping(address => uint) public tokensPurchased;

  IERC721[] public supportedTokens;

  /*
   + lower number = tighter slope
  */

  constructor(
    address _asset,
    address _counterAsset,
    uint _startPercent,
    uint _targetRaise,
    uint _tPrice,
    uint _slope
  ) {
    require(_slope <= 5, "no point");
    asset = IERC20(_asset);
    counterAsset = IERC20(_counterAsset);
    startPercent = _startPercent;
    targetRaise = _targetRaise;
    targetPrice = _tPrice;
    slope = _slope;
  }

  function buy(uint amount, address NFT, uint index) external returns (bool) {
    require(licenses[NFT].limit > 0, "buy: this NFT is not eligible for whitelist");
    require(getPrice() >= licenses[NFT].threshold, "buy: you cannot buy yet");
    _buy(amount, NFT, index);
    return true;
  }

  function _buy(uint amount, address NFT, uint index) internal returns (bool) {
    Allocation storage alloc = allocations[NFT][index];
    if (!alloc.activated) {
      activate(NFT, index, amount);
    } else {
      require(alloc.remaining >= amount);
      alloc.remaining -= amount;
    }

    uint cost = getPrice() * amount / BASIS_POINTS;
    counterAsset.transferFrom(msg.sender, address(this), cost);
    tokensPurchased[msg.sender] += amount;
    asset.transfer(msg.sender, amount);
    return true;
  }

  function activate(address addr, uint index, uint amount) internal returns (bool) {
    require(amount <= licenses[addr].limit, "activate: amount too high");
    Allocation storage alloc = allocations[addr][index];
    alloc.remaining = licenses[addr].limit - amount;
    alloc.activated = true;
    return true;
  }

  function getPrice() internal view returns (uint) {
    return (_targetPrice() * (baseCurve(percentSold()) / findDivisor(startPercent)));
  }

  function percentRaised() internal view returns (uint) {
    return raised() * BASIS_POINTS / targetRaise;
  }

  function percentSold() internal view returns (uint) {
    return _sold() * BASIS_POINTS / startingAmount;
  }

  function baseCurve(uint n) internal view returns (uint) {
    uint curve = n ** 2;
    if (slope > 0) {
      for (uint i = 0; i <= slope; i++) {
        curve = curve * Math.sqrt(n);
      }
    }
    return curve;
  }

  function _sold() internal view returns (uint) {
    return startingAmount - asset.balanceOf(address(this));
  }

  function raised() internal view returns (uint) {
    return counterAsset.balanceOf(address(this));
  }

  function findDivisor(uint n) internal view returns (uint) {
    return (baseCurve(BASIS_POINTS)) / (BASIS_POINTS + n);
  }

  function _targetPrice() internal view returns (uint) {
    return modify(targetPrice);
  }

  function modify(uint n) internal pure returns (uint) { }

}
