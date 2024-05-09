const fs = require("fs");
const path = require("path");
const { frameworkFolder } = require("./templates/variables");
const Template = require("./templates/header-template");
const { replaceTemplate } = require("./utils");

// Gets the full path of the framework folder
const folderPath = path.resolve(__dirname, frameworkFolder);

// Loops the folder and subfolders, then prints the cs files with missing headers
const walkSync = (dir, filelist = []) => {
  fs.readdirSync(dir).forEach((file) => {
    const dirFile = path.join(dir, file);
    const fileStats = fs.statSync(dirFile);
    const isDirectory = fileStats.isDirectory();

    if (isDirectory) {
      walkSync(dirFile, filelist);
    } else {
      const isCsFile = dirFile.endsWith(".cs");
      if (isCsFile) {
        filelist.push(dirFile.replace(/\\/g, `/`));
      }
    }
  });
  return filelist;
};

const files = walkSync(folderPath);

files.forEach((file) => {
  const fileStats = fs.statSync(file);
  const fileContent = fs.readFileSync(file, "utf8");
  if (!fileContent.includes("/*")) {
    // Adds the file header.
    const replacements = {
      CreatedDate: fileStats.birthtime.toISOString().split("T")[0],
    };
    const fileHeader = replaceTemplate(Template.template, replacements);

    // Adds the file header to the beginning of the file.
    const fileContentWithHeader = fileHeader + fileContent.replace(/^\uFEFF/, '');

    console.log(`Writing file header to ${file}`);
    // Writes the file.
    fs.writeFileSync(file, fileContentWithHeader, "utf8");
  }
});
