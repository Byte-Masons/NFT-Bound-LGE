const reaper = require("../src/ReaperSDK.js");
const elastic = require("../src/Elastic.js");

async function main() {

  /*await elastic.createProductionEnvironment(
    "0x8B4441E79151e3fC5264733A3C5da4fF8EAc16c1",
    3000
  );*/
  //reaper.sleep(10000);

  await elastic.addLicenses("0xdEFea7ccD50D7E87e45D7dbD07c31F44EF7F73fd");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
