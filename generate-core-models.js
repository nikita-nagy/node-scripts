const {
  saveTextToFile,
  replaceTemplate,
  getUsingTemplate,
  walkthroughTableData,
  getInheritanceTemplate,
} = require("./utils");

const { outputPaths, suffixFileName } = require("./templates/variables");
const tables = require("./data/tables.json");
const ModelInterfaceTemplate = require("./templates/entity-class-model-interface");
const InterfaceTemplate = require("./templates/entity-class-interface");
const { spConfig, spChildTables } = require("./config-sp-custom");

const generateInterfaces = () => {
  const outputPath = `${outputPaths.jfwCore.entityClassesInterfaces}/IEntityClassInterfaces.Generated.cs`;
  const interfaceContents = [];

  // For each table, append the interface to the file content.
  for (const tableName in tables) {
    // Append the interface to the file content.
    interfaceContents.push(
      replaceTemplate(InterfaceTemplate.definitions.Interface, {
        entityName: tableName,
      })
    );
  }

  const replacements = {
    InterfaceDefinitions: interfaceContents.join("\n\n"),
  };

  const fileContent = replaceTemplate(InterfaceTemplate.template, replacements);

  saveTextToFile(outputPath, fileContent);
};

const generateModelInterface = (tableName, tableData) => {
  // console.log(`Generating Entity Interface for ${tableName}...`);
  const outputPath = `${outputPaths.jfwCore.entityClassesModelInterfaces}/I${tableName}Model${suffixFileName}.cs`;
  const template = ModelInterfaceTemplate.template;
  const definitions = ModelInterfaceTemplate.definitions;

  const usings = [];
  const inheritedInterfaces = [];
  const columnDefinitions = [];
  const ignoredColumns = ["ID"];

  if (spConfig[tableName]) {
    const childTables = spConfig[tableName].childTables;
    childTables.forEach((childTable) => {
      inheritedInterfaces.push(`I${childTable}Model`);
    });
  }

  if (spChildTables[tableName] && spChildTables[tableName].ignoredColumns) {
    ignoredColumns.push(...spChildTables[tableName].ignoredColumns);
  }

  // Replace ColumnDefinitions.
  tableData.columns.forEach((column) => {
    if (ignoredColumns.includes(column.name)) return;

    let setter = column.isReadOnly ? "" : "set; ";
    let columnType = column.dataTypeDotNet;

    switch (column.name) {
      case "Is_System":
      case "Modified_Date":
      case "Created_Date":
        break;
      default:
        if (!column.isNullable && columnType !== "string") {
          columnType += "?";
        }
    }

    // If the usings does not contain the column's data type, add it.
    if (!usings.includes("System")) {
      switch (column.dataTypeDotNet) {
        case "DateTime":
        case "DateTime?":
          usings.push("System");
          break;
        default:
          break;
      }
    }

    const replacements = {
      entityName: tableName,
      columnName: column.name,
      columnNamePascal: column.namePascal,
      columnType,
      setter,
    };

    let columnDefinition = column.isEncrypted
      ? definitions.EncryptedColumn
      : definitions.Column;

    const content = replaceTemplate(columnDefinition, replacements);

    columnDefinitions.push(content);
  });

  const replacement = {
    EntityName: tableName,
    Usings: getUsingTemplate(usings),
    ColumnDefinitions: columnDefinitions.join("\n\n"),
    InheritedInterfaces: getInheritanceTemplate(inheritedInterfaces),
  };

  const entityInterface = replaceTemplate(template, replacement);
  saveTextToFile(outputPath, entityInterface);
};

generateInterfaces();

walkthroughTableData(tables, (tableName) => {
  generateModelInterface(tableName, tables[tableName]);
});
