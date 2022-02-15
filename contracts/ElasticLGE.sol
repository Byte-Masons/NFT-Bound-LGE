//SPDX license identifier: MIT

pragma solidity 0.8.10;

import "./OZ/utils/math/Math.sol";
import "./OZ/token/ERC20/IERC20.sol";
import "./OZ/access/Ownable.sol";
import "./OZ/token/ERC721/IERC721.sol";

contract ElasticFundraising is Ownable {
  using Math for uint;

  uint public BASIS_POINTS = 10000;

  IERC20 public oath;
  IERC20 public counterAsset;

  uint public raised;
  uint public totalShares;
  uint public defaultTerm = 90 days;
  uint public defaultPrice = 1e18;

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

  IERC721[] public supportedTokens;

  constructor(
    address _oath,
    address _counterAsset
  ) {
    oath = IERC20(_oath);
    counterAsset = IERC20(_counterAsset);
  }

  //shares out
  function buy(uint amount, address NFT, uint index) public returns (bool) {
    require (amount > 0, "buy: please input amount");
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
    totalShares += amount;
    raised += cost;
    return true;
  }

  function _buyDefault(uint amount) internal returns (bool) {
    uint cost = amount * defaultPrice;
    counterAsset.transferFrom(msg.sender, address(this), cost);
    _updateTerms(amount, defaultTerm);
    totalShares += amount;
    raised += cost;
    return true;
  }

  function batchPurchase(uint totalAmount, address[] calldata NFTs, uint[] calldata indicies) external returns (bool) {
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
  }

  //per share and total
  function getBatchPricing(uint totalAmount, address[] calldata NFTs, uint[] calldata indicies) public view returns (uint perShare, uint totalCost, uint totalShares) {
    uint remaining = totalAmount;
    uint perShare;
    for (uint i = 0; i < NFTs.length; i++) {
      (uint available, uint _perShare, uint _total) = getPricingData(NFTs[i], indicies[i]);
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
    uint term;
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

  function getUpdatedTerms(uint oldShares, uint oldTerm, uint newShares, uint newTerm) public view returns (uint term) {
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