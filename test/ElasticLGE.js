const { expect } = require("chai");
const { waffle } = require("hardhat");
const pools = require("../pools.json");
const tokens = require("../tokens.json");
const elastic = require("../src/Elastic.js");
const reaper = require("../src/reaperSDK.js");
const hre = require("hardhat");

describe("LGE", function () {

  beforeEach(async function () {

  });

  describe("Testing the LGE", function () {
    it("does the needful", async function () {

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

      async function license() {
        await elastic.addLicense(lge, enft, 6500, 210, 30);
        await elastic.addLicense(lge, lnft, 8000, 250, 60);
        let license = await elastic.viewLicense(lge, enft);
        console.log(">>>EPIC NFT<<<");
        console.log(license);
        license = await elastic.viewLicense(lge, lnft);
        console.log(">>>LAME NFT<<<");
        console.log(license);
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

      async function logBalances() {
        let balanceFTM = await reaper.getUserBalance(self, ftm);
        let balanceOath = await reaper.getUserBalance(self, oath);
        console.log("ftm balance: " +balanceFTM.toString());
        console.log("oath balance: " +balanceOath.toString());
      }

      let selfSigner;
      let user1;
      let user2;
      let user3;
      let user4;

      [selfSigner, user1, user2, user3, user4, ...users] = await ethers.getSigners();

      let self = await selfSigner.getAddress();

      console.log(self);
      let env = await elastic.assembleEnvironment([selfSigner], 30, self);
      await reaper.approveMax(env.lge.address, env.ftm.address);

      let zero = "0x0000000000000000000000000000000000000000";

      let oath = env.oath.address;
      let ftm = env.ftm.address;
      let enft = env.enft.address;
      let lnft = env.lnft.address;
      let lge = env.lge.address;
      console.log(lge);
      console.log(oath);

      await env.lge.upgradeOath("0x0000000000000000000000000000000000000000");

      oath = await env.lge.oath();

      console.log(oath);

      await mintNFTs(5);
      await license();
      await logState();
      await logBalance();
      await logTerms();
      await logAllocations();

      let batchPricing = await elastic.getBatchPricing(
        lge,
        3500,
        [enft, enft, enft, lnft, lnft, lnft],
        [1, 2, 3, 1, 2, 3],
        true
      );
      console.log(batchPricing);

      terms = await elastic.getBatchTerms(
        lge,
        3500,
        [enft, enft, enft, lnft, lnft, lnft],
        [1, 2, 3, 1, 2, 3],
        true
      );
      console.log(terms);

      await elastic.batchPurchase(
          lge,
          3500,
          [enft, lnft],
          [3, 4],
          true
      );

      await logTerms();
      await logState();
      await logBalances();

      reaper.sleep(30000);

      await elastic.claim(lge);

      await logBalances();

      reaper.sleep(30000);

      await elastic.claim(lge);

      await logBalances();

      reaper.sleep(30000);

      await elastic.claim(lge);

      await logBalances();

    });
  });
});
