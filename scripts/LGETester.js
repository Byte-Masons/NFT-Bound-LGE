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
    await elastic.addLicense(lge, enft, 5000, 100, 100000);
    await elastic.addLicense(lge, lnft, 7500, 200, 50000);
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
    /*"0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d",
    "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"
    "0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6",
    "0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a",
    "0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba",
    "0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e",
    "0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356",
    "0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97",
    "0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6",
    "0xf214f2b2cd398c806f84e317254e0f0b801d0643303237d97a22a48e01628897",
    "0x701b615bbdfb9de65240bc28bd21bbc0d996645a3dd57e7b12bc2bdf6f192c82",
    "0xa267530f49f8280200edf313ee7af6b827f2a8bce2897751d06a843f644967b1",
    "0x47c99abed3324a2707c28affff1267e45918ec8c3f20b8aa892e8b065d2942dd",
    "0xc526ee95bf44d8fc405a158bb884d9d1238d99f0612e9f33d006bb0789009aaa",
    "0x8166f546bab6da521a8369cab06c5d2b9e46670292d85c875ee9ec20e84ffb61",
    "0xea6c44ac03bff858b476bba40716402b03e41b8e97e276d1baec7c37d42484a0",
    "0x689af8efa8c651a91ad287602527f3af2fe9f6501a7ac4b061667b5a93e037fd",
    "0xde9be858da4a475276426320d5e9262ecfc3ba460bfac56360bfa6c4c28b4ee0",
    "0xdf57089febbacf7ba0bc227dafbffa9fc08a93fdc68e1e42411a14efcf23656e"*/
  ];

  let self = "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266";
  let zero = "0x0000000000000000000000000000000000000000";

  let oath = "0xf524930660f75CF602e909C15528d58459AB2A56";
  let ftm = "0x26Df0Ea798971A97Ae121514B32999DfDb220e1f";
  let enft = "0xA3b48c7b901fede641B596A4C10a4630052449A6";
  let lnft = "0xa138575a030a2F4977D19Cc900781E7BE3fD2bc0";
  let lge = "0x6c383Ef7C9Bf496b5c847530eb9c49a3ED6E4C56";

  //await createEnvironment();
  await license();
  await logState();
  await logBalance();
  await logTerms();
  await logAllocations();

  await mintNFTs(5);

  let batchPricing = await elastic.getBatchPricing(
    lge,
    [enft, enft, enft, enft, enft, lnft, lnft, lnft, lnft, lnft],
    [1, 2, 3, 4, 5, 1, 2, 3, 4, 5]
  );
  console.log(batchPricing);

  let terms = await elastic.getBatchTerms(
    lge,
    [enft, enft, enft, enft, enft, lnft, lnft, lnft, lnft, lnft],
    [1, 2, 3, 4, 5, 1, 2, 3, 4, 5]
  );
  console.log(terms);

/*
  await elastic.batchPurchase(
    lge,
    1500,
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
