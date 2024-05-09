const {
  saveTextToFile,
  replaceTemplate,
  walkthroughTableData,
} = require("./utils");
const { outputFolder } = require("./templates/variables");

const tables = require("./data/tables.json");
const outputPath = `${outputFolder}/sp/get-stored-procedures.sql`;

// Insert stored procedure template.
const Template = require("./templates/sp-get");

const getStoredProcedureContent = (tableName) => {
  Template.replacements.entityName = tableName;

  return replaceTemplate(Template.template, Template.replacements);
};

let scripts = [];
let fileContent = "";

walkthroughTableData(tables, (tableName) => {
  const scriptContent = getStoredProcedureContent(tableName);
  scripts.push(scriptContent);
});

fileContent = scripts.join("\n\n");

saveTextToFile(outputPath, fileContent);
