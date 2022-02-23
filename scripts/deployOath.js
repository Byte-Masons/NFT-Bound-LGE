const reaper = require("../src/ReaperSDK.js");
const elastic = require("../src/Elastic.js");

async function main() {

/*  let lge = await elastic.createProductionEnvironment(
    "0x8B4441E79151e3fC5264733A3C5da4fF8EAc16c1",
    259200
  );
  reaper.sleep(30000);
*/
 let oath = await elastic.deployOath("0x111731A388743a75CF60CCA7b140C58e41D83635");
 console.log(oath.address);


  //let Oath = await oath.createContractFactory()
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
