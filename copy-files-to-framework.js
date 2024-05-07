// Copy all files from the output folder to the framework folder

const fs = require("fs");
const path = require("path");
const { outputFolder, frameworkFolder } = require("./templates/variables");

function copyDirRecursiveSync(sourceDir, targetDir) {
  // Create the target directory if it doesn't exist
  if (!fs.existsSync(targetDir)) {
    fs.mkdirSync(targetDir);
  }

  // Read the source directory
  const files = fs.readdirSync(sourceDir);

  // Copy each file/directory recursively
  files.forEach((file) => {
    const sourcePath = path.join(sourceDir, file);
    const targetPath = path.join(targetDir, file);
    const isDirectory = fs.statSync(sourcePath).isDirectory();

    if (isDirectory) {
      // Recursively copy subdirectory
      copyDirRecursiveSync(sourcePath, targetPath);
    } else {
      console.log(`Copying file:\n\tFrom: ${sourcePath}\n\tTo: ${targetPath}`);
      // Copy file
      fs.copyFileSync(sourcePath, targetPath);
    }
  });
}

console.log(`Copying files from ${outputFolder} to ${frameworkFolder}`);

// Copy all files from the output folder to the framework folder
copyDirRecursiveSync(outputFolder, frameworkFolder);
