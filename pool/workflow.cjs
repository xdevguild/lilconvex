const { execFile } = require("child_process");
const cron = require("node-cron");

cron.schedule("* * * * *", () =>
  execFile(__dirname + "/workflow.sh", (error, stdout, stderr) => {
    if (error) {
      console.error(`error: ${error.message}`);
      return;
    }

    if (stderr) {
      console.error(`stderr: ${stderr}`);
      return;
    }

    console.log(`stdout:\n${stdout}`);
  })
);
