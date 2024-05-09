// Delete the contents of the output folder

const fs = require("fs");
const { outputFolder } = require("./templates/variables");

console.log(`Cleaning output folder...`);
fs.rm(outputFolder, { recursive: true }, () => {
  console.log(`Output folder cleaned!`);
  fs.mkdir(outputFolder, () => {
    console.log(`Output folder created!`);
  });
});
