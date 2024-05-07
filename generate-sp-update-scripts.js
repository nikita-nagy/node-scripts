const {
  saveTextToFile,
  replaceTemplate,
  walkthroughTableData,
} = require("./utils");
const { outputFolder } = require("./templates/variables");

const tables = require("./data/tables.json");
const outputPath = `${outputFolder}/sp/update-stored-procedures.sql`;

// Stored procedure template.
const Template = require("./templates/sp-update");

const getStoredProcedureContent = (tableName, tableData) => {
  const definitionParameters = [];
  const definitionSetCommands = [];
  // Prepare the parameters and columns.
  tableData.columns.forEach((column) => {
    let columnName = column.name;
    let defaultValue = "";
    let dataType = column.dataTypeSqlWithLength.toUpperCase();
    switch (column.name) {
      case "ID":
      case "UID":
      case "Modified_By":
      case "Modified_Date":
      case "Created_By":
      case "Created_Date":
        return;
      default:
        if (column.defaultValue && column.defaultValue != null)
          defaultValue = ` = ${column.defaultValue}`;

        if (column.isNullable && defaultValue == "") defaultValue = " = NULL";
        break;
    }

    const replacements = {
      columnName,
      dataType,
      defaultValue,
    };

    const definitionParameterContent = replaceTemplate(
      Template.definitions.Parameter,
      replacements
    );

    const definitionSetCommandContent = replaceTemplate(
      Template.definitions.SetCommand,
      replacements
    );

    definitionParameters.push(definitionParameterContent);
    definitionSetCommands.push(definitionSetCommandContent);
  });

  Template.replacements.Parameters = definitionParameters.join("\n");
  Template.replacements.SetCommands = definitionSetCommands.join("\n");
  Template.replacements.entityName = tableName;

  return replaceTemplate(Template.template, Template.replacements);
};

let scripts = [];
let fileContent = "";

walkthroughTableData(tables, (tableName) => {
  const scriptContent = getStoredProcedureContent(tableName, tables[tableName]);
  scripts.push(scriptContent);
});

fileContent = scripts.join("\n\n");

saveTextToFile(outputPath, fileContent);
