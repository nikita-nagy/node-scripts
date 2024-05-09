const config = require("./config");

if (!config.configToggles.enableRepositoryGeneration) {
  return;
}

const {
  saveTextToFile,
  replaceTemplate,
  walkthroughTableData,
} = require("./utils");

const { outputPaths, suffixFileName } = require("./templates/variables");
const tables = require("./data/tables.json");
const InterfaceTemplate = require("./templates/repository-interface");
const ImplementTemplate = require("./templates/repository-implement");

const generateInterfaces = (tableName) => {
  // console.log(`Generating Entity Interface for ${tableName}...`);
  const outputPath = `${outputPaths.jfwRepositories.interfaces}/I${tableName}Repository.cs`;
  const template = InterfaceTemplate.template;

  // Replace EntityName
  let entityName = tableName;

  saveTextToFile(outputPath, replaceTemplate(template, { entityName }));
};

const generateAutoImplement = (tableName) => {
  // console.log(`Generating Entity Interface for ${tableName}...`);
  const outputPath = `${outputPaths.jfwRepositories.implements}/${tableName}Repository${suffixFileName}.cs`;
  const template = ImplementTemplate.template;

  // Replace EntityName
  let entityName = tableName;

  saveTextToFile(outputPath, replaceTemplate(template, { entityName }));
};

const generateImplementTemplate = (tableName) => {
  // console.log(`Generating Entity Interface for ${tableName}...`);
  const outputPath = `${outputPaths.jfwRepositories.implements}/${tableName}Repository.cs`;
  const template = ImplementTemplate.implementTemplate;

  // Replace EntityName
  let entityName = tableName;

  saveTextToFile(outputPath, replaceTemplate(template, { entityName }));
};

walkthroughTableData(tables, (tableName) => {
  generateInterfaces(tableName);
  generateAutoImplement(tableName);
  generateImplementTemplate(tableName);
});
