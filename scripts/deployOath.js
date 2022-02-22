const reaper = require("../src/ReaperSDK.js");
const elastic = require("../src/Elastic.js");

async function main() {

/*  let lge = await elastic.createProductionEnvironment(
    "0x8B4441E79151e3fC5264733A3C5da4fF8EAc16c1",
    259200
  );
  reaper.sleep(30000);
*/
  await elastic.addLicenses("0x96662f375a9734654cB57BbFeb31Db9dD7784A7F");


  //let Oath = await oath.createContractFactory()
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
