const tokens = require("../tokens.json");
const reaper = require("./ReaperSDK.js");

async function deployLGE(oath, counterAsset, beginning, end) {
  let LGE = await ethers.getContractFactory("ElasticLGE");
  let lge = await LGE.deploy(oath, counterAsset, beginning, end);
  return lge;
}

async function viewState(lgeAddress) {
  let LGE = await ethers.getContractFactory("ElasticLGE");
  let lge = await LGE.attach(lgeAddress);
  let oath = await lge.oath();
  let raised = await lge.raised();
  let totalShares = await lge.totalShares();
  let defaultTerm = await lge.defaultTerm();
  let defaultPrice = await lge.defaultPrice();
  return {
    "oathAddress": oath,
    "raised": raised,
    "totalShares": totalShares,
    "defaultTerm": defaultTerm,
    "defaultPrice": defaultPrice
  }
}

async function viewLicense(lgeAddress, nftAddress) {
  let LGE = await ethers.getContractFactory("ElasticLGE");
  let lge = await LGE.attach(lgeAddress);
  let license = await lge.licenses(nftAddress);
  return {
    "price": license[0],
    "limit": license[1],
    "term": license[2]
  }
}

async function viewTerms(lgeAddress, userAddress) {
  let LGE = await ethers.getContractFactory("ElasticLGE");
  let lge = await LGE.attach(lgeAddress);
  let terms = await lge.terms(userAddress);
  return {
    "shares": terms[0],
    "term": terms[1]
  }
}

async function viewAllocation(lgeAddress, nftAddress, nftIndex) {
  let LGE = await ethers.getContractFactory("ElasticLGE");
  let lge = await LGE.attach(lgeAddress);
  let allocation = await lge.allocations(nftAddress, nftIndex);
  return {
    "remaining": allocation[0],
    "activated": allocation[1]
  }
}

async function buy(lgeAddress, amount, nft, index) {
  let LGE = await ethers.getContractFactory("ElasticLGE");
  let lge = await LGE.attach(lgeAddress);
  let tx = await lge.buy(amount, nft, index);
  let receipt = await tx.wait();
  return receipt;
}

async function batchPurchase(lgeAddress, totalAmount, nftArray, indexArray) {
  let LGE = await ethers.getContractFactory("ElasticLGE");
  let lge = await LGE.attach(lgeAddress);
  let tx = await lge.batchPurchase(totalAmmount, nftArray, indexArray);
  let receipt = await tx.wait();
  return receipt;
}

async function getBatchPricing(lgeAddress, totalAmount, nftArray, indexArray) {
  let LGE = await ethers.getContractFactory("ElasticLGE");
  let lge = await LGE.attach(lgeAddress);
  let tx = await lge.getBatchPricing(totalAmmount, nftArray, indexArray);
  let receipt = await tx.wait();
  return receipt;
}

async function getBatchTerms(lgeAddress, userAddress, totalShares, nftArray, indexArray) {
  let LGE = await ethers.getContractFactory("ElasticLGE");
  let lge = await LGE.attach(lgeAddress);
  let tx = await lge.getBatchTerms(userAddress, totalShares, nftArray, indexArray);
  let receipt = await tx.wait();
  return receipt;
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

async function addLicense(lgeAddress, threshold, limit, term) {
  let LGE = await ethers.getContractFactory("ElasticLGE");
  let lge = await LGE.attach(lgeAddress);
  let tx = await lge.addLicense(lgeAddress, threshold, limit, term);
  let receipt = await tx.wait();
  return receipt;
}

async function assembleEnvironment(accounts) {
  let mockFTM = await reaper.deployTestToken("Fantom", "WFTM");
  reaper.sleep(10000);
  for (let i=0; i<accounts.length; i++) {
    await reaper.mintTestToken(mockFTM.address, accounts[i], ethers.utils.parseEther("1000000"));
    reaper.sleep(10000);
  }
  let mockOath = await reaper.deployTestToken("Oath", "OATH");
  reaper.sleep(10000);
  let wallets = createNewWallets(100);

}

module.exports {
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
  assembleEnvironment
}
