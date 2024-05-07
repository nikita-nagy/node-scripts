const {
  saveTextToFile,
  replaceTemplate,
  walkthroughTableData,
} = require("./utils");
const { outputFolder } = require("./templates/variables");
const softDeleteTables = ["Brand", "Device", "User", "Payment"];
const childTables = require("./config-sp-custom").spChildTables;

const tables = require("./data/tables.json");
const outputPath = `${outputFolder}/sp/delete-stored-procedures.sql`;

// Insert stored procedure template.
const Template = require("./templates/sp-delete");

const getStoredProcedureContent = (tableName) => {
  Template.replacements.entityName = tableName;

  // Check if the table is a soft delete table.
  if (softDeleteTables.includes(tableName)) {
    return replaceTemplate(Template.template.byStatus, Template.replacements);
  }

  // Check if the table is a child table.
  if (childTables[tableName]) {
    return replaceTemplate(Template.template.commented, Template.replacements);
  }

  return replaceTemplate(Template.template.default, Template.replacements);
};

let scripts = [];
let fileContent = "";

walkthroughTableData(tables, (tableName) => {
  const scriptContent = getStoredProcedureContent(tableName);
  scripts.push(scriptContent);
});

fileContent = scripts.join("\n\n");

saveTextToFile(outputPath, fileContent);
