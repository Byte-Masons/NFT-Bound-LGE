const reaper = require("../src/ReaperSDK.js");
const elastic = require("../src/Elastic.js");
const allocations = require("./allocations.json");

async function main() {

  let arr = [
    allocations.friendsAndFamilyLong,
    allocations.friendsAndFamilyShort,
    allocations.iLoveYou,
    allocations.oldFantie,
    allocations.reaperPartnerLong,
    allocations.reaperPartnerShort,
    allocations.researcher,
    allocations.sigmaReaper,
    allocations.testMonke,
    allocations.vCardVictims,
    allocations.tarot
  ]

  let NFT = await ethers.getContractFactory("OathERC721");
  for (let i=0; i<arr.length; i++) {
    let nft = await NFT.attach(
      arr[i].address
    );
    console.log(arr[i].name + ": " +nft.address);
    let tx = await nft.setURI(arr[i].uri);
    await tx.wait();

    reaper.sleep(10000);
  }

/*
Oathseekers: 0x62404613100cfaC01f1bff0824d826dc0e4e1236
Blood Oath - Long Terms: 0x577DEA56D4fBBad1185A36E2bed30B4A0EA5792D
Blood Oath - Short Terms: 0x08ec059DBd2438Ea7FAf0106F14F679396422A34
Crab Nation ID Card: 0x016B0F99827724D0947A2418D0Cb1Ae5439Eb25E
Ancient Oathkeepers: 0x65cf313138595D3190bC10e59f18459264936adF
Oath Takers - Long Terms: 0x0EAA652ac0503602923De4190FF8a97D658575Fd
Oath Takers - Short Terms: 0x9c5E136AB845e683793Ae28824877c955324a3E1
Gift for the Wise: 0xC27f1a9c32D74da141E090b1eCe90F5f3E915116
Allies of the Oath: 0xa412Ec87870ACF3086CD83631F0E7e25c109b9f5
Oath Fanatics: 0x0c66020474f712E1a2040D94a36263336C7f543E */

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
