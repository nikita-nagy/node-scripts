const {
  saveTextToFile,
  replaceTemplate,
  walkthroughTableData,
} = require("./utils");
const { outputFolder } = require("./templates/variables");

const tables = require("./data/tables.json");
const outputPath = `${outputFolder}/sp/insert-stored-procedures.sql`;

// Insert stored procedure template.
const Template = require("./templates/sp-insert");

const getStoredProcedureContent = (tableName, tableData) => {
  const parameters = [];
  const columns = [];
  const values = [];
  // Prepare the parameters and columns.
  tableData.columns.forEach((column) => {
    let columnName = column.name;
    let defaultValue = "";
    // Upper case the data type.
    let dataType = column.dataTypeSqlWithLength.toUpperCase();
    switch (column.name) {
      case "ID":
      case "UID":
      case "Modified_By":
      case "Modified_Date":
      case "Created_By":
      case "Created_Date":
        return;
      case "Is_Default":
      case "Is_System":
        defaultValue = " = 0";
        break;
      default:
        if (column.defaultValue && column.defaultValue != null) {
          if (column.dataType == "bit") {
            defaultValue = ` = ${column.defaultValue ? 1 : 0}`;
          } else {
            defaultValue = ` = '${column.defaultValue}'`;
          }
        }
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

    const definitionColumnContent = replaceTemplate(
      Template.definitions.Column,
      replacements
    );

    const definitionValueContent = replaceTemplate(
      Template.definitions.Value,
      replacements
    );

    parameters.push(definitionParameterContent);
    columns.push(definitionColumnContent);
    values.push(definitionValueContent);
  });

  Template.replacements.Parameters = parameters.join("\n");
  Template.replacements.Columns = columns.join("\n");
  Template.replacements.Values = values.join("\n");
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
