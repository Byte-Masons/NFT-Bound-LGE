const reaper = require("../src/ReaperSDK.js");
const addresses = require("../Addresses.json");
const { tokens, testnet, mainnet } = require("../Addresses.json");

async function main() {

  let Love = await ethers.getContractFactory("Loveletter");
  let love = await Love.deploy("0x04068DA6C83AFCFA0e13ba15A6696662335D5B75");
  console.log(love.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
