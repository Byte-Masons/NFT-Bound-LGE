const tokens = require("../tokens.json");
const reaper = require("./ReaperSDK.js");
const nft = require("./supportedNFTs.json");
const { upgrades }  = require("hardhat");

async function deployLGE(oath, counterAsset, totalOath, beginning, end) {
  let LGE = await ethers.getContractFactory("ElasticLGE");
  let lge = await LGE.deploy(oath, counterAsset, totalOath, beginning, end);
  return lge;
}

async function viewState(lgeAddress) {
  let LGE = await ethers.getContractFactory("ElasticLGE");
  let lge = await LGE.attach(lgeAddress);
  let oath = await lge.oath();
  let raised = await lge.raised();
  let shareSupply = await lge.shareSupply();
  let defaultTerm = await lge.defaultTerm();
  let defaultPrice = await lge.defaultPrice();
  return {
    "oathAddress": oath,
    "raised": raised.toString(),
    "shareSupply": shareSupply.toString(),
    "defaultTerm": defaultTerm.toString(),
    "defaultPrice": defaultPrice.toString()
  }
}

async function viewLicense(lgeAddress, nftAddress) {
  let LGE = await ethers.getContractFactory("ElasticLGE");
  let lge = await LGE.attach(lgeAddress);
  let license = await lge.licenses(nftAddress);
  return {
    "price": license[0].toString(),
    "limit": license[1].toString(),
    "term": license[2].toString()
  }
}

async function viewTerms(lgeAddress, userAddress) {
  let LGE = await ethers.getContractFactory("ElasticLGE");
  let lge = await LGE.attach(lgeAddress);
  let terms = await lge.terms(userAddress);
  return {
    "shares": terms[0].toString(),
    "term": terms[1].toString()
  }
}

async function viewAllocation(lgeAddress, nftAddress, nftIndex) {
  let LGE = await ethers.getContractFactory("ElasticLGE");
  let lge = await LGE.attach(lgeAddress);
  let allocation = await lge.allocations(nftAddress, nftIndex);
  return {
    "remaining": allocation[0].toString(),
    "activated": allocation[1]
  }
}

async function buy(lgeAddress, amount, nft, index, venture) {
  let LGE = await ethers.getContractFactory("ElasticLGE");
  let lge = await LGE.attach(lgeAddress);
  let tx = await lge.buy(amount, nft, index, venture);
  let receipt = await tx.wait();
  return receipt;
}

async function batchPurchase(lgeAddress, totalAmount, nftArray, indexArray, venture) {
  let LGE = await ethers.getContractFactory("ElasticLGE");
  let lge = await LGE.attach(lgeAddress);
  let tx = await lge.batchPurchase(totalAmount, nftArray, indexArray, venture);
  let receipt = await tx.wait();
  return receipt;
}

async function getBatchPricing(lgeAddress, totalAmount, nftArray, indexArray, venture) {
  let LGE = await ethers.getContractFactory("ElasticLGE");
  let lge = await LGE.attach(lgeAddress);
  let prices = await lge.getBatchPricing(totalAmount, nftArray, indexArray, venture);
  return {
    "nftPricePerShare": prices[0].toString(),
    "nftTotalCost": prices[1].toString(),
    "nftTotalShares": prices[2].toString(),
    "perShare": prices[3].toString(),
    "totalAvailable": prices[4].toString(),
    "totalCost": prices[5].toString()
  }
}

async function getBatchTerms(lgeAddress, totalAmount, nftArray, indexArray, venture) {
  let LGE = await ethers.getContractFactory("ElasticLGE");
  let lge = await LGE.attach(lgeAddress);
  let term = await lge.getBatchTerms(totalAmount, nftArray, indexArray, venture);
  return {
    "nftTerm": term[0].toString(),
    "term": term[1].toString()
  }
}

async function getPricingData(lgeAddress, nftAddress, index) {
  let LGE = await ethers.getContractFactory("ElasticLGE");
  let lge = await LGE.attach(lgeAddress);
  let tx = await lge.getPricingData(nftAddress, index);
  let receipt = await tx.wait();
  return receipt;
}

async function getUpdatedTerms(lgeAddress, oldShares, oldTerm, newShares, newTerm) {
  let LGE = await ethers.getContractFactory("ElasticLGE");
  let lge = await LGE.attach(lgeAddress);
  let tx = await lge.getUpdatedTerms(oldShares, oldTerm, newShares, newTerm);
  let receipt = await tx.wait();
  return receipt;
}

async function addLicense(lgeAddress, nftAddress, price, limit, term) {
  let LGE = await ethers.getContractFactory("ElasticLGE");
  let lge = await LGE.attach(lgeAddress);
  let tx = await lge.addLicense(nftAddress, price, limit, term);
  let receipt = await tx.wait();
  return receipt;
}

async function assembleEnvironment(accounts, duration) {
  let mockFTM = await reaper.deployTestToken("Fantom", "WFTM");
  let enft = await deployTestNFT("Epic NFT", "eNFT");
  let lnft = await deployTestNFT("Lame NFT", "lNFT");
  reaper.sleep(10000);
  for (let i=0; i<accounts.length; i++) {
    await reaper.mintTestToken(mockFTM.address, accounts[i].address, ethers.utils.parseEther("1000000"));
    reaper.sleep(10000);
  }
  let oath = await deployOath(accounts[0].address);
  console.log("Oath proxy address: " +oath.address);
  reaper.sleep(10000);
  let lge = await deployLGE(
    oath.address,
    mockFTM.address,
    ethers.utils.parseEther("80000000"),
    await reaper.getTimestamp(),
    await reaper.getTimestamp() + duration
  );
  reaper.sleep(10000);
  let minter = await oath.MINTER_ROLE();
  let tx = await oath.grantRole(minter, lge.address);
  //await tx.wait();
  reaper.sleep(10000);
  console.log("lge address: " +lge.address);

  return {
    "oath": oath,
    "ftm": mockFTM,
    "enft": enft,
    "lnft": lnft,
    "lge": lge
  }
}

async function deployTestNFT(name, symbol) {
  let NFT = await ethers.getContractFactory("TestERC721");
  let nft = await NFT.deploy(name, symbol);
  return nft;
}

async function mintTestNFT(nftAddress, userAddress) {
  let NFT = await ethers.getContractFactory("TestERC721");
  let nft = await NFT.attach(nftAddress);
  let tx = await nft.mint(userAddress);
  let receipt = await tx.wait();
  return receipt;
}

async function findOwner(nftAddress, id) {
  let NFT = await ethers.getContractFactory("TestERC721");
  let nft = await NFT.attach(nftAddress);
  let owner = await nft.ownerOf(id);
  return owner;
}

async function claim(lgeAddress) {
  let LGE = await ethers.getContractFactory("ElasticLGE");
  let lge = await LGE.attach(lgeAddress);
  let tx = await lge.claim();
  let receipt = await tx.wait();
  return receipt;
}

async function deployWrappedFtm() {
  let Wftm = await ethers.getContractFactory("WrappedFtm");
  let wftm = await Wftm.deploy();
  return wftm;
}

async function deployOath(admin) {
  let Oath = await ethers.getContractFactory("Oath");
  let proxy = await upgrades.deployProxy(
    Oath,
    [admin],
    { kind: 'uups' }
  );
  await proxy.deployed();
  return proxy;
}

async function createProductionEnvironment(admin, duration) {
  let oath = await deployOath(admin);
  console.log("Oath proxy address: " +oath.address);
  reaper.sleep(30000);
  let wftm = await deployWrappedFtm();
  console.log("test wftm address: " +wftm.address);
  reaper.sleep(30000);
  let lge = await deployLGE(
    oath.address,
    wftm.address,
    ethers.utils.parseEther("80000000"),
    await reaper.getTimestamp(),
    await reaper.getTimestamp() + duration
  );
  reaper.sleep(30000);
  let minter = await oath.MINTER_ROLE();
  let tx = await oath.grantRole(minter, lge.address);
  await tx.wait();
  reaper.sleep(30000);
  console.log("lge address: " +lge.address);
}

async function addLicenses(lgeAddress) {
  for (let i=0; i<nft.supported.length; i++) {
    await addLicense(lgeAddress, nft.supported[i].address, nft.supported[i].price, nft.supported[i].limit, nft.supported[i].vest * 86400);
    console.log(`license added for ${nft.supported[i].name}`)
    reaper.sleep(10000);
  }
}

module.exports = {
  deployLGE,
  viewState,
  viewLicense,
  viewTerms,
  viewAllocation,
  buy,
  batchPurchase,
  getBatchPricing,
  getBatchTerms,
  getPricingData,
  getUpdatedTerms,
  addLicense,
  assembleEnvironment,
  deployTestNFT,
  mintTestNFT,
  findOwner,
  createProductionEnvironment,
  addLicenses,
  claim
}
