const {
  saveTextToFile,
  replaceTemplate,
  walkthroughTableData,
} = require("./utils");
const { outputFolder } = require("./templates/variables");
const { spConfig } = require("./config-sp-custom");

const tables = require("./data/tables.json");
const Template = require("./templates/sp-list");
const definitions = Template.definitions;

const outputPath = `${outputFolder}/sp/list-stored-procedures.sql`;

const getStoredProcedureContent = (tableName, tableData) => {
  const definitionParameters = [];
  const definitionFilterCriterias = [];
  const spCustom = spConfig[tableName];

  const addParameterContent = (columnName, dataType) => {
    const definitionParameterContent = replaceTemplate(definitions.Parameter, {
      columnName,
      dataType,
    });

    if (!definitionParameters.includes(definitionParameterContent)) {
      definitionParameters.push(definitionParameterContent);
    }
  };

  const addFilterCriteriaContent = (columnName, template) => {
    const filterCriteriaContent = replaceTemplate(template, {
      columnName,
    });

    definitionFilterCriterias.push(filterCriteriaContent);
  };

  if (spCustom?.customParameters) {
    for (const customParameterName in spCustom.customParameters) {
      const customParameter = spCustom.customParameters[customParameterName];
      const customParameterContent = replaceTemplate(definitions.Parameter, {
        columnName: customParameter.name,
        dataType: customParameter.type,
      });

      definitionParameters.push(customParameterContent);

      // Push to the first of the filter criteria list.
      definitionFilterCriterias.unshift(
        customParameter.filterCriteriaContent.replace(/\t/g, "    ")
      );
    }
  }
  // Prepare the parameters and columns.
  tableData.columns.forEach((column) => {
    let dataType = column.dataTypeSqlWithLength.toUpperCase();
    switch (column.name) {
      case "Modified_By":
      case "Modified_Date":
      case "Created_By":
      case "Created_Date":
        return;
      default:
        break;
    }

    if (column.name.includes("_ID") || column.name === "ID") {
      addParameterContent(column.name, "VARCHAR(MAX)");
      addFilterCriteriaContent(column.name, definitions.FilterCriteriaList);
    } else {
      switch (column.dataTypeDotNet) {
        case "DateTime":
        case "DateTime?":
          addParameterContent(`${column.name}_From`, dataType);
          addParameterContent(`${column.name}_To`, dataType);
          addFilterCriteriaContent(
            column.name,
            definitions.FilterCriteriaDateRange
          );
          break;
        default:
          addParameterContent(column.name, dataType);
          addFilterCriteriaContent(column.name, definitions.FilterCriteria);
          break;
      }
    }
  });

  Template.replacements.Parameters = definitionParameters.join("\n");
  Template.replacements.FilterCriterias = definitionFilterCriterias.join("\n");
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
