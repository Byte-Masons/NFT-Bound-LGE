//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./OZ/utils/math/Math.sol";
import "./OZ/token/ERC20/IERC20.sol";
import "./OZ/access/Ownable.sol";
import "./OZ/token/ERC721/IERC721.sol";
import "./OZ/token/ERC20/utils/SafeERC20.sol";
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
  using SafeERC20 for IERC20;

  // defaultTerm:: vesting term for normal mode
  // ventureTerm:: vesting term for venture mode
  // defaultPrice:: base price - 1 unit ($FTM) per share
  // venturePrice:: price for venture terms

  uint public constant BASIS_POINTS = 10_000;
  uint public constant defaultTerm = 90 days;
  uint public constant ventureTerm = 1460 days;
  uint public constant defaultPrice = 1e18;
  uint public constant venturePrice = 5e17;

  // oath:: token for sale
  // counterAsset:: currency accepted
  // multisig:: address where funds raised are sent
  IOath public oath;
  IERC20 public immutable counterAsset;
  address public constant multisig = 0x111731A388743a75CF60CCA7b140C58e41D83635;

  // raised:: amount of counterAsset raised
  // shareSupply:: total amount of shares in existence
  // totalOath:: amount of Oath available
  uint public raised;
  uint public shareSupply;
  uint public immutable totalOath;

  // beginning:: start time of event
  // end:: end time of event - when vesting begins
  uint public immutable beginning;
  uint public immutable end;

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
    require((_end - _beginning) <= 5 days, "LGE too long");
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
    require(block.timestamp >= beginning, "lge has not begun!");
    require(block.timestamp <= end, "lge has ended.");
    require (amount != 0, "buy: please input amount");
    if(NFT == address(0)) {
      _buyDefault(amount, venture);
    } else {
      require(licenses[NFT].limit != 0, "buy: this NFT is not eligible for whitelist");
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
    counterAsset.safeTransferFrom(msg.sender, multisig, cost);
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
    counterAsset.safeTransferFrom(msg.sender, multisig, cost);
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
    require(block.timestamp >= end, "lge has not ended");
    uint _totalOwed = totalOath * terms[msg.sender].shares / shareSupply;
    uint perSecond = _totalOwed / terms[msg.sender].term;
    uint secondsClaimed = claimed[msg.sender] / perSecond;
    uint lastClaim = end + secondsClaimed;
    uint owed = (block.timestamp - lastClaim) * perSecond;
    if (claimed[msg.sender] + owed > _totalOwed) {
      owed = _totalOwed - claimed[msg.sender];
    }
    claimed[msg.sender] += owed;
    oath.mint(msg.sender, owed);
    return true;
  }

  struct BatchPricingData{
    uint nftPerShare;
    uint nftTotalCost;
    uint nftTotalShares;
    uint perShare;
    uint totalAvailable;
    uint totalCost;
  }

  // @dev helper function for the front end
  // @returns weighted average price per share, total cost, and total shares available for all NFTs passed in
  function getBatchPricing(
    uint totalAmount,
    address[] calldata NFTs,
    uint[] calldata indicies,
    bool venture
  ) public view returns (
    BatchPricingData memory data
  ) {
    uint remaining = totalAmount;
    uint totalShares;
    for (uint i = 0; i < NFTs.length; i++) {
      (uint available, uint _perShare,) = getPricingData(NFTs[i], indicies[i]);
      uint amount = Math.min(available, remaining);
      data.perShare = findWeightedAverage(amount, totalShares, _perShare, data.perShare);
      totalShares += amount;
      remaining -= amount;
      data.totalAvailable += available;
    }
    data.nftPerShare = data.perShare;
    data.nftTotalShares = totalShares;
    data.nftTotalCost = data.perShare * totalShares;
    if (remaining > 0) {
      data.perShare = findWeightedAverage(remaining, totalShares, (venture ? venturePrice : defaultPrice), data.perShare);
    }
    data.totalCost = data.perShare * totalAmount;
  }

  // @dev helper function for the front end
  // @returns the weighted average terms for all NFTs passed in
  function getBatchTerms(
    uint totalAmount,
    address[] calldata NFTs,
    uint[] calldata indicies,
    bool venture
  ) public view returns (
    uint nftTerm,
    uint term
  ) {
    uint remaining = totalAmount;
    uint totalShares;
    for (uint i = 0; i < NFTs.length; i++) {
      (uint available,,) = getPricingData(NFTs[i], indicies[i]);
      uint amount = Math.min(available, remaining);
      uint _term = licenses[NFTs[i]].term;
      term = findWeightedAverage(amount, totalShares, _term, term);
      totalShares += amount;
      remaining -= amount;
    }
    nftTerm = term;
    if (remaining > 0) {
      term = findWeightedAverage(remaining, totalShares, (venture ? ventureTerm : defaultTerm), term);
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

  //NOTE: this function was all kind of fucked and i got it working pretty late. will make it prettier tomorrow. docs are inaccurate.
  function findWeightedAverage(
    uint addedValue,
    uint oldValue,
    uint weightedNew,
    uint weightedOld
  ) public pure returns (
    uint
  ) {
    if (oldValue == 0) {
      return weightedNew;
    } else {
      uint weightNew;
      uint weightOld;
      if (addedValue < oldValue) {
        weightNew = addedValue * 1e27 / (addedValue + oldValue);
        weightOld = 1e27 - weightNew;
      } else if (oldValue < addedValue) {
        weightOld = oldValue * 1e27 / (addedValue + oldValue);
        weightNew = 1e27 - weightOld;
      } else {
        weightNew = 1e27 / 2;
        weightOld = 1e27 / 2;
      }
      uint a = weightedNew * weightNew / 1e27;
      uint b = weightedOld * weightOld / 1e27;
      return (a + b);
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

  function upgradeOath(address newOath) public onlyOwner {
    require(block.timestamp <= end, "LGE has ended");
    oath = IOath(newOath);
  }

  // @dev admin function to add a license to a given NFT project. Could use some guardrails.
  function addLicense(address addr, uint threshold, uint limit, uint term) public onlyOwner returns (bool) {
    licenses[addr] = License(threshold, limit, term);
    return true;
  }
}
