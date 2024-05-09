const config = require("./config");

if (!config.configToggles.enableDataAccessGeneration) {
  return;
}

const {
  saveTextToFile,
  replaceTemplate,
  walkthroughTableData,
} = require("./utils");

const { outputPaths, suffixFileName } = require("./templates/variables");
const tables = require("./data/tables.json");
const TemplateInterface = require("./templates/data-access-interface");
const TemplateImplement = require("./templates/data-access-implement");

const generateInterfaces = (tableName) => {
  const outputPath = `${outputPaths.jfwDataAccess.interfaces}/I${tableName}Dao.cs`;
  const template = TemplateInterface.template;

  // Replace EntityName
  let entityName = tableName;

  saveTextToFile(outputPath, replaceTemplate(template, { entityName }));
};

const generateImplements = (tableName) => {
  const outputPath = `${outputPaths.jfwDataAccess.implements}/${tableName}Dao.cs`;
  const fixedOutputPath = `${outputPaths.jfwDataAccess.implements}/${tableName}Dao${suffixFileName}.cs`;

  // Replace EntityName
  let entityName = tableName;

  saveTextToFile(
    outputPath,
    replaceTemplate(TemplateImplement.template, { entityName })
  );

  saveTextToFile(
    fixedOutputPath,
    replaceTemplate(TemplateImplement.templateAuto, { entityName })
  );
};

walkthroughTableData(tables, (tableName) => {
  generateInterfaces(tableName);
  generateImplements(tableName);
});
