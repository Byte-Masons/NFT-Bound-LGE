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

// @title NFT-Bound Elastic LGE
// @author Justin Bebis
// @dev a way to make fair launch more fun and flexible

contract ElasticLGE is Ownable {
  using Math for uint;

  // defaultTerm:: vesting term for normal mode
  // ventureTerm:: vesting term for venture mode
  // defaultPrice:: base price - 1 unit ($FTM) per share
  // venturePrice:: price for venture terms

  uint public constant BASIS_POINTS = 10000;
  uint public constant defaultTerm = 90 days;
  uint public constant ventureTerm = 1460 days;
  uint public constant defaultPrice = 1e18;
  uint public constant venturePrice = 5e17;

  // oath:: token for sale
  // counterAsset:: currency accepted
  IOath public oath;
  IERC20 public counterAsset;

  // raised:: amount of counterAsset raised
  // shareSupply:: total amount of shares in existence
  // totalOath:: amount of Oath available
  uint public raised;
  uint public shareSupply;
  uint public totalOath;

  // beginning:: start time of event
  // end:: end time of event - when vesting begins
  uint public beginning;
  uint public end;

  // price:: 9000 = 90.00% of full value
  // limit:: the maximum amount that can be purchased from the NFT
  // term:: the vesting term for the particular NFT
  struct License {
    uint price;
    uint limit;
    uint term;
  }

  // shares:: the amount of shares purchased by the user
  // term:: the user's weighted average term
  struct Terms {
    uint shares;
    uint term;
  }

  // remaining:: amount of shares remaining for this NFT
  // activated:: true if the NFT has been used at all
  struct Allocation {
    uint remaining;
    bool activated;
  }

  // licenses:: mapped to ERC721 address, shows base allocation info
  // allocations:: mapped to NFT IDs, nested within the NFT address, shows current allocation info
  // terms:: mapped to user address, stores user's terms
  // claimed:: mapped to user address, stores the amount of oath claimed so far
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

  // @dev routing function to protect internals and simplify front end integration
  // amount:: the amount of shares the user would like to buy
  // NFT:: the address of the NFT terms a user would like to use - 0 to use default terms
  // index:: ID paired with the NFT contract
  // venture:: type of default term user would like to use

  function buy(uint amount, address NFT, uint index, bool venture) public returns (bool) {
    require (amount > 0, "buy: please input amount");
    require(block.timestamp >= beginning, "lge has not begun!");
    if(NFT == address(0)) {
      _buyDefault(amount, venture);
    } else {
      require(licenses[NFT].limit > 0, "buy: this NFT is not eligible for whitelist");
      require(IERC721(NFT).ownerOf(index) == msg.sender, "buyer is not the owner");
      _buyDiscounted(amount, NFT, index);
    }
    return true;
  }

  // @dev function that applies NFT terms to the user's purchase
  // @note considering transferring funds directly to multisig to keep contract empty
  // amount:: amount of shares user wants to buy
  // NFT:: address of the NFT terms user is using
  // index:: id paired with the NFT address
  function _buyDiscounted(uint amount, address NFT, uint index) internal returns (bool) {
    Allocation storage alloc = allocations[NFT][index];
    // managing per-NFT state
    if (!alloc.activated) {
      activate(NFT, index, amount);
    } else {
      require(alloc.remaining >= amount, "_buyDiscounted: insufficient remaining");
      alloc.remaining -= amount;
    }
    uint cost = (amount * 1e18) * licenses[NFT].price / BASIS_POINTS;
    counterAsset.transferFrom(msg.sender, address(this), cost);
    _updateTerms(amount, licenses[NFT].term);
    shareSupply += amount;
    raised += cost;
    return true;
  }

  // @dev function that allows user to use default vesting terms
  // @amount:: amount of shares user wants to buy
  // @_venture:: true if user would like to use venture terms
  function _buyDefault(uint amount, bool _venture) internal returns (bool) {
    uint price = _venture ? venturePrice : defaultPrice;
    uint term = _venture ? ventureTerm : defaultTerm;
    uint cost = amount * price;
    counterAsset.transferFrom(msg.sender, address(this), cost);
    _updateTerms(amount, term);
    shareSupply += amount;
    raised += cost;
    return true;
  }

  // @dev front end helper function - settles large amount of purchases with multiple...
  // ...NFTs and sinks remaining desired into a default purchase
  // totalAmount:: the total amount of shares user wants to purchase
  // NFTs:: array of NFTs user would like to cash out
  // indicies:: paired with the NFT addresses
  // _venture:: if true, settles remaining share purcahses with venture terms
  function batchPurchase(uint totalAmount, address[] calldata NFTs, uint[] calldata indicies, bool _venture) external returns (bool) {
    require(NFTs.length == indicies.length, "array lengths do not match");
    uint remaining = totalAmount;
    for (uint i = 0; i < NFTs.length; i++) {
      (uint available,,) = getPricingData(NFTs[i], indicies[i]);
      uint amount = Math.min(available, remaining);
      if (amount > 0) {
        buy(amount, NFTs[i], indicies[i], _venture);
        remaining -= amount;
      }
      if (remaining == 0) { return true; }
    }
    if (remaining > 0) {
      buy(remaining, address(0), 0, _venture);
      return true;
    }
    return true;
  }

  // @dev used to issue Oath to users after the LGE, claims all unclaimed Oath from last claim to current
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

  // @dev save some operations
  function _totalOwed() internal view returns (uint) {
    return (totalOath * terms[msg.sender].shares / shareSupply);
  }

  // @dev helper function for the front end
  // @returns weighted average price per share, total cost, and total shares available for all NFTs passed in
  function getBatchPricing(
    address[] calldata NFTs,
    uint[] calldata indicies
  ) public view returns (
    uint perShare,
    uint totalCost,
    uint totalShares
  ) {
    for (uint i = 0; i < NFTs.length; i++) {
      (uint amount, uint _perShare,) = getPricingData(NFTs[i], indicies[i]);
      perShare = findWeightedAverage(amount, totalShares, _perShare, perShare);
      totalShares += amount;
    }
    totalCost = perShare * totalShares;
  }

  // @dev helper function for the front end
  // @returns the weighted average terms for all NFTs passed in
  function getBatchTerms(address[] calldata NFTs, uint[] calldata indicies) public view returns (uint term) {
    uint totalShares;
    for (uint i = 0; i < NFTs.length; i++) {
      (uint amount,,) = getPricingData(NFTs[i], indicies[i]);
      uint _term = licenses[NFTs[i]].term;
      term = findWeightedAverage(amount, totalShares, _term, term);
      totalShares += amount;
    }
  }

  // @dev useful function to return commonly used pricing data
  // @returns available shares in the NFT, the price per share, and the total cost
  // ensures uninstantiated allocations are accounted for properly
  function getPricingData(address NFT, uint index) public view returns (uint available, uint perShare, uint totalCost) {
    Allocation memory alloc = allocations[NFT][index];
    if (alloc.activated) {
      available = allocations[NFT][index].remaining;
    } else {
      available = licenses[NFT].limit;
    }
    perShare = 1e18 * licenses[NFT].price / BASIS_POINTS;
    totalCost = available * perShare;
  }

  // @dev admin function to add a license to a given NFT project. Could use some guardrails.
  function addLicense(address addr, uint threshold, uint limit, uint term) public onlyOwner returns (bool) {
    licenses[addr] = License(threshold, limit, term);
    return true;
  }

  // @dev updates the user's terms
  // @_shares:: amount of shares being added to total - used to determine weight
  // @_term:: new term for shares being added - weighted against existing shares/term
  function _updateTerms(uint _shares, uint _term) internal returns (bool) {
    Terms storage userTerms = terms[msg.sender];
    userTerms.term = findWeightedAverage(_shares, userTerms.shares, _term, userTerms.term);
    userTerms.shares += _shares;
    return true;
  }

  // @dev utility function to find weighted averages without any underflows or zero division problems.
  // use x to determine weights, with y being the values you're weighting
  // addedValue:: new amount of x being added
  // oldValue:: current amount of x
  // weightedNew:: new amount of y being added to weighted average
  // weightedOld:: current weighted average of y
  function findWeightedAverage(
    uint addedValue,
    uint oldValue,
    uint weightedNew,
    uint weightedOld
  ) internal pure returns (
    uint weightedAverage
  ) {
    if (oldValue == 0) {
      weightedAverage = weightedNew;
    } else {
      uint total = addedValue + oldValue;
      uint sum = weightNew + weightOld;
      weightedAverage = total / sum / BASIS_POINTS;
      /*
      uint weightNew = (addedValue * 1e18 / oldValue);
      uint weightOld = (oldValue * 1e18 / addedValue);
      uint combined = weightNew + weightOld;
      uint sumEach = (weightedNew * weightNew) + (weightedOld * weightOld);
      weightedAverage = sumEach / combined;
      */
    }
  }

  // @dev pulls license state into allocation state and updates the amountTwo
  // ensures double spends aren't possible
  // addr:: address of the NFT whose license you're using
  // index:: id of the NFT you're activating
  // amount:: amount being spent out of that NFT

  function activate(address addr, uint index, uint amount) internal returns (bool) {
    require(amount <= licenses[addr].limit, "activate: amount too high");
    Allocation storage alloc = allocations[addr][index];
    alloc.remaining = licenses[addr].limit - amount;
    alloc.activated = true;
    return true;
  }
}
