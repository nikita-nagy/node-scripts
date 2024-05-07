const {
  saveTextToFile,
  replaceTemplate,
  walkthroughTableData,
} = require("./utils");
const { outputFolder } = require("./templates/variables");

const { spConfig } = require("./config-sp-custom");
const tables = require("./data/tables.json");
const outputPath = `${outputFolder}/sp/view-stored-procedures.sql`;

// Stored procedure template.
const Template = require("./templates/sp-view");
const allowList = ["Brand", "Device", "User"];

const getStoredProcedureContent = (tableName, tableData) => {
  if (!allowList.includes(tableName)) return;

  const spCustom = spConfig[tableName];
  const definitionParameters = [];
  const definitionFilterCriterias = [];
  const definitionKeywordFilterCriterias = [];
  const definitionChildFroms = [];
  const definitionChildSelects = [];

  const processColumn = (column, tblName = tableName, isChildTable = false) => {
    let columnName = column.name;
    let dataType = column.dataTypeSqlWithLength.toUpperCase();

    const addParameterContent = (name, type) => {
      const definitionParameterContent = replaceTemplate(
        Template.definitions.Parameter,
        { columnName: name, dataType: type }
      );

      definitionParameters.push(definitionParameterContent);
    };

    const addFilterCriteriaContent = (name, template) => {
      const definitionFilterCriteriaContent = replaceTemplate(template, {
        columnName: name,
        entityAlias: spCustom.alias[tblName],
      });

      definitionFilterCriterias.push(definitionFilterCriteriaContent);
    };

    switch (column.name) {
      case "Modified_By":
      case "Modified_Date":
      case "Created_By":
      case "Created_Date":
        return;
      default:
        break;
    }

    if (column.name.includes("_ID") || column.name === "ID" || column.name === "UID") {
      if (
        isChildTable &&
        (column.name === tableName + "_ID" || column.name === "ID" || column.name === "UID")
      )
        return;
      addParameterContent(columnName, "VARCHAR(MAX)");
      addFilterCriteriaContent(
        columnName,
        Template.definitions.FilterCriteriaList
      );
    } else {
      switch (column.dataTypeDotNet) {
        case "DateTime":
        case "DateTime?":
          addParameterContent(`${columnName}_From`, dataType);
          addParameterContent(`${columnName}_To`, dataType);
          addFilterCriteriaContent(
            columnName,
            Template.definitions.FilterCriteriaDateRange
          );
          break;
        default:
          addParameterContent(columnName, dataType);
          addFilterCriteriaContent(
            columnName,
            Template.definitions.FilterCriteria
          );
          break;
      }
    }
  };

  if (spCustom?.customParameters) {
    for (const customParameterName in spCustom.customParameters) {
      const customParameter = spCustom.customParameters[customParameterName];
      const customParameterContent = replaceTemplate(
        Template.definitions.Parameter,
        {
          columnName: customParameter.name,
          dataType: customParameter.type,
        }
      );

      definitionParameters.push(customParameterContent);

      // Push to the first of the filter criteria list.
      definitionFilterCriterias.unshift(
        customParameter.filterCriteriaContent.replace(/\t/g, "    ")
      );
    }
  }

  // Prepare the parameters and columns.
  tableData.columns.forEach((column) => processColumn(column));

  // Prepare the child tables.
  spCustom.childTables.forEach((childTable) => {
    const childEntityName = childTable;
    const childEntityAlias = spCustom.alias[childTable];
    const replacements = {
      childEntityName,
      childEntityAlias,
      entityName: tableName,
      entityAlias: spCustom.alias[tableName],
    };

    definitionChildFroms.push(
      replaceTemplate(Template.definitions.ChildFromClause, replacements)
    );

    definitionChildSelects.push(
      replaceTemplate(Template.definitions.ChildSelectClause, replacements)
    );

    definitionKeywordFilterCriterias.push(
      replaceTemplate(Template.definitions.KeywordFilterCriteria, replacements)
    );

    tables[childTable].columns.forEach((column) =>
      processColumn(column, childTable, true)
    );
  });

  Template.replacements.PreExecutionStatements = spCustom?.precondition ?? "";
  Template.replacements.Parameters = definitionParameters.join("\n");
  Template.replacements.FilterCriterias = definitionFilterCriterias.join("\n");
  Template.replacements.KeywordFilterCriterias =
    definitionKeywordFilterCriterias.join("\n");
  Template.replacements.ChildEntitySelectClause =
    definitionChildSelects.join("\n");
  Template.replacements.ChildEntityFromClause = definitionChildFroms.join("\n");
  Template.replacements.entityName = tableName;
  Template.replacements.entityAlias = spCustom.alias[tableName];

  return replaceTemplate(Template.template, Template.replacements);
};

let scripts = [];
let fileContent = "";

walkthroughTableData(tables, (tableName) => {
  const scriptContent = getStoredProcedureContent(tableName, tables[tableName]);

  if (!scriptContent) return;

  scripts.push(scriptContent);
});

fileContent = scripts.join("\n\n");

saveTextToFile(outputPath, fileContent);
