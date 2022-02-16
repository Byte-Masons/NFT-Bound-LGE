const reaper = require("../src/ReaperSDK.js");
const elastic = require("../src/Elastic.js");

async function main() {

  let self = //ENTER TEST ACCOUNT ADDRESS :3

  let env = await elastic.assembleEnvironment(self);
  let lge = await elastic.deployLGE(
    env.oath,
    env.ftm,
    await reaper.getTimestamp(),
    await reaper.getTimestamp() + 1000
  );


}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
