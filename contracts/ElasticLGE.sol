//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./OZ/utils/math/Math.sol";
import "./OZ/token/ERC20/IERC20.sol";
import "./OZ/access/Ownable.sol";
import "./OZ/token/ERC721/IERC721.sol";
import "./TestERC20.sol";
import "hardhat/console.sol";

interface IOath {
  function mint(address to, uint amount) external returns (bool);
}

contract ElasticLGE is Ownable {
  using Math for uint;

  uint public BASIS_POINTS = 10000;

  IOath public oath;
  IERC20 public counterAsset;

  uint public raised;
  uint public shareSupply;
  uint public totalOath;
  uint public defaultTerm = 90 days;
  uint public defaultPrice = 1e18;

  uint public beginning;
  uint public end;

  // price:: 9000 = 90.00% of full value
  // limit:: the maximum amount that can be purchased from the NFT
  struct License {
    uint price;
    uint limit;
    uint term;
  }

  struct Terms {
    uint shares;
    uint term;
  }

  struct Allocation {
    uint remaining;
    bool activated;
  }

  mapping(address => License) public licenses;
  mapping(address => mapping(uint => Allocation)) public allocations;
  mapping(address => Terms) public terms;
  mapping(address => uint) public claimed;

  constructor(
    address _oath,
    address _counterAsset,
    uint _totalOath,
    uint _beginning,
    uint _end
  ) {
    oath = IOath(_oath);
    counterAsset = IERC20(_counterAsset);
    totalOath = _totalOath;
    beginning = _beginning;
    end = _end;
  }

  //shares out
  function buy(uint amount, address NFT, uint index) public returns (bool) {
    require (amount > 0, "buy: please input amount");
    require(block.timestamp >= beginning, "lge has not begun!");
    if(NFT == address(0)) {
      _buyDefault(amount);
    } else {
      require(licenses[NFT].limit > 0, "buy: this NFT is not eligible for whitelist");
      require(IERC721(NFT).ownerOf(index) == msg.sender);
      _buyDiscounted(amount, NFT, index);
    }
    return true;
  }

  //consider transferring funds to multisig to keep contract empty
  function _buyDiscounted(uint amount, address NFT, uint index) internal returns (bool) {
    Allocation storage alloc = allocations[NFT][index];
    if (!alloc.activated) {
      activate(NFT, index, amount);
    } else {
      require(alloc.remaining >= amount, "_buyDiscounted: insufficient remaining");
      alloc.remaining -= amount;
    }
    uint cost = amount * licenses[NFT].price / BASIS_POINTS;
    counterAsset.transferFrom(msg.sender, address(this), cost);
    _updateTerms(amount, licenses[NFT].term);
    shareSupply += amount;
    raised += cost;
    return true;
  }

  function _buyDefault(uint amount) internal returns (bool) {
    uint cost = amount * defaultPrice;
    counterAsset.transferFrom(msg.sender, address(this), cost);
    _updateTerms(amount, defaultTerm);
    shareSupply += amount;
    raised += cost;
    return true;
  }

  function batchPurchase(uint totalAmount, address[] calldata NFTs, uint[] calldata indicies) external returns (bool) {
    require(NFTs.length == indicies.length, "array lengths do not match");
    uint remaining = totalAmount;
    for (uint i = 0; i < NFTs.length; i++) {
      (uint available,,) = getPricingData(NFTs[i], indicies[i]);
      uint amount = available > remaining ? available : remaining;
      buy(amount, NFTs[i], indicies[i]);
      remaining -= amount;
      if (remaining == 0) { return true; }
    }
    if (remaining > 0) {
      buy(remaining, address(0), 0);
      return true;
    }
    return true;
  }

  function claim() external returns (bool) {
    require(claimed[msg.sender] < _totalOwed(), "you have no more tokens to claim");
    require(block.timestamp >= end, "lge has not ended");
    uint perSecond = _totalOwed() / terms[msg.sender].term;
    uint secondsClaimed = claimed[msg.sender] / perSecond;
    uint lastClaim = end + secondsClaimed;
    uint owed = block.timestamp - lastClaim * perSecond;
    claimed[msg.sender] += owed;
    oath.mint(msg.sender, owed);
    return true;
  }

  function _totalOwed() internal view returns (uint) {
    return (totalOath * terms[msg.sender].shares / shareSupply);
  }

  //per share and total
  function getBatchPricing(uint totalAmount, address[] calldata NFTs, uint[] calldata indicies) public view returns (uint perShare, uint totalCost, uint totalShares) {
    uint remaining = totalAmount;
    for (uint i = 0; i < NFTs.length; i++) {
      (uint available, uint _perShare,) = getPricingData(NFTs[i], indicies[i]);
      uint amount = Math.min(remaining, available);
      remaining -= amount;
      if (perShare == 0) {
        perShare += _perShare;
      } else {
        uint weight = _perShare * 1e18 / perShare;
        perShare = (_perShare * weight) * (perShare * (1e18 - weight)) / 1e18;
      }
    }
    if (remaining > 0) {
      uint weight = 1e18 * 1e18 / perShare;
      perShare = (1e18 * weight) * (perShare * (1e18 - weight)) / 1e18;
    }
    totalCost = perShare * totalAmount;
    totalShares = totalAmount / perShare;
  }

  function getBatchTerms(address user, uint totalShares, address[] calldata NFTs, uint[] calldata indicies) public view returns (uint term) {
    uint remaining = totalShares;
    uint currentShares = terms[user].shares;
    for (uint i = 0; i < NFTs.length; i++) {
      (uint available,,) = getPricingData(NFTs[i], indicies[i]);
      uint amount = Math.min(remaining, available);
      uint _term = licenses[NFTs[i]].term;
      term = getUpdatedTerms(currentShares, term, amount, _term);
      remaining -= amount;
      currentShares += amount;
      totalShares += amount;
    }
    if (remaining > 0) {
      term = getUpdatedTerms(currentShares, term, remaining, defaultTerm);
    }
  }

  //per share and total
  function getPricingData(address NFT, uint index) public view returns (uint available, uint perShare, uint total) {
    Allocation memory alloc = allocations[NFT][index];
    if (alloc.activated) {
      available = allocations[NFT][index].remaining;
    } else {
      available = licenses[NFT].limit;
    }
    perShare = 1e18 * licenses[NFT].price / BASIS_POINTS;
    total = available * perShare;
  }

  function getUpdatedTerms(uint oldShares, uint oldTerm, uint newShares, uint newTerm) public pure returns (uint term) {
    if (oldShares == 0) {
      term = newTerm;
    } else {
      uint weight = (newShares * 1e18 / oldShares);
      term = ((newTerm * weight) + (oldTerm * (1e18 - weight))) / 1e18;
    }
  }

  function addLicense(address addr, uint threshold, uint limit, uint term) public onlyOwner returns (bool) {
    licenses[addr] = License(threshold, limit, term);
    return true;
  }

  function activate(address addr, uint index, uint amount) internal returns (bool) {
    require(amount <= licenses[addr].limit, "activate: amount too high");
    Allocation storage alloc = allocations[addr][index];
    alloc.remaining = licenses[addr].limit - amount;
    alloc.activated = true;
    return true;
  }

  function _updateTerms(uint _shares, uint _term) internal returns (bool) {
    Terms storage userTerms = terms[msg.sender];
    if (userTerms.shares == 0) {
      userTerms.shares += _shares;
      userTerms.term += _term;
      return true;
    } else {
      uint weight = (_shares * 1e18 / userTerms.shares);
      uint weightedAverage = ((_term * weight) + (userTerms.term * (1e18 - weight))) / 1e18;
      userTerms.term = weightedAverage;
      userTerms.shares += _shares;
      return true;
    }
  }
}
