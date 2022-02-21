const reaper = require("../src/ReaperSDK.js");
const elastic = require("../src/Elastic.js");

async function main() {

  async function loadWallets(pkeyArray) {
    let wallets = [];
    for (let i=0; i<pkeyArray.length; i++) {
      let wallet = new ethers.Wallet(pkeyArray[i]);
      wallets.push(wallet);
    }
    return wallets;
  }

  async function license() {
    await elastic.addLicense(lge, enft, 9000, 500, 10000);
    await elastic.addLicense(lge, lnft, 11000, 700, 100000);
    let license = await elastic.viewLicense(lge, enft);
    console.log(">>>EPIC NFT<<<");
    console.log(license);
    license = await elastic.viewLicense(lge, lnft);
    console.log(">>>LAME NFT<<<");
    console.log(license);
  }

  async function logState() {
    let state = await elastic.viewState(lge);
    console.log(state);
  }

  async function createEnvironment() {
    let wallets = await loadWallets(pkeys);
    let env = await elastic.assembleEnvironment(wallets);
    console.log("let oath = " +env.oath.address + ";");
    console.log("let ftm = " +env.ftm.address + ";");
    console.log("let enft = " +env.enft.address + ";");
    console.log("let lnft = " +env.lnft.address + ";");
    console.log("let lge = " +env.lge.address + ";");
    await reaper.approveMax(env.lge.address, env.ftm.address);
  }

  async function mintNFTs(amount) {
    for(let i=0; i<amount; i++) {
      await elastic.mintTestNFT(enft, self);
      await elastic.mintTestNFT(lnft, self);
    }
  }

  async function logBalance() {
    let balance = await reaper.getUserBalance(self, ftm);
    console.log("user ftm balance: " +balance.toString());
  }

  async function logTerms() {
    let terms = await elastic.viewTerms(lge, self);
    console.log(terms);
  }

  async function logAllocations() {
    let eAllocation = await elastic.viewAllocation(lge, enft, 1);
    let lAllocation = await elastic.viewAllocation(lge, lnft, 1);
    console.log(">>>Epic NFT Allocation<<<");
    console.log(eAllocation);
    console.log(">>>Lame NFT Allocation<<<");
    console.log(lAllocation);
  }

  let pkeys = [
    "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
  ];

  let self = "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266";
  let zero = "0x0000000000000000000000000000000000000000";

  let oath = "0xBA6BfBa894B5cAF04c3462A5C8556fFBa4de6782";
  let ftm = "0xA199e7ab96BF9DF52C52eb7BAb5572789a726d33";
  let enft = "0xF978b011bcf604b201996FEb3E53eD3D52F0A90F";
  let lnft = "0x8233369E29653b70E50E93d1276a50B8f2122a01";
  let lge = "0xca9507C5F707103e86B45DF4b35C37FE2700BB5B";

  //await createEnvironment();

  await mintNFTs(5);
  await license();
  await logState();
  await logBalance();
  await logTerms();
  await logAllocations();

  let batchPricing = await elastic.getBatchPricing(
    lge,
    10000,
    [enft, enft, enft, enft, enft, lnft, lnft, lnft, lnft, lnft],
    [1, 2, 3, 4, 5, 1, 2, 3, 4, 5],
    true
  );
  console.log(batchPricing);

  terms = await elastic.getBatchTerms(
    lge,
    10000,
    [enft, enft, enft, enft, enft, lnft, lnft, lnft, lnft, lnft],
    [1, 2, 3, 4, 5, 1, 2, 3, 4, 5],
    true
  );
  console.log(terms);


/*  await elastic.batchPurchase(
    lge,
    10000,
    [enft, enft, enft, enft, enft, lnft, lnft, lnft, lnft, lnft],
    [1, 2, 3, 4, 5, 1, 2, 3, 4, 5],
    true
  );
*/
  await logTerms();
  await logState();

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
