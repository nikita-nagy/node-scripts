const {
  saveTextToFile,
  replaceTemplate,
  getUsingTemplate,
  getInheritanceTemplate,
  walkthroughTableData,
} = require("./utils");

const { outputPaths, suffixFileName } = require("./templates/variables");
const tables = require("./data/tables.json");
const FilterTemplate = require("./templates/filter-template");
const { spConfig } = require("./config-sp-custom");

const template = FilterTemplate.template;
const templateReplacements = FilterTemplate.templateReplacements;
const definitions = FilterTemplate.definitions;

const generateFilters = (tableName, tableData) => {
  const spCustom = spConfig[tableName];
  const outputPath = `${outputPaths.jfwModels.filters}/${tableName}Filter${suffixFileName}.cs`;
  const usings = [];
  const inheritedInterfaces = ["IFilter"];
  const shorColumnDefinitions = [];
  const parameterNames = [];
  const columnDefinitions = [];
  const conditionDefinitions = [];
  const listSetters = [];
  const setterDefinitions = [];

  const processColumn = (column, isChildTable = false) => {
    let shouldInsertIntoInterface = true;
    switch (column.name) {
      case "ID":
      case "Created_By":
      case "Created_Date":
      case "Modified_By":
      case "Modified_Date":
        return;
      case "Is_Default":
        if (!inheritedInterfaces.includes("IHasDefaultFilter"))
          inheritedInterfaces.push("IHasDefaultFilter");
        shouldInsertIntoInterface = false;
        break;
      case "Is_System":
        if (!inheritedInterfaces.includes("IHasSystemFilter"))
          inheritedInterfaces.push("IHasSystemFilter");
        shouldInsertIntoInterface = false;
        break;
      case "UID":
        column.dataTypeDotNet = "string";
        const uidListSetterContent = replaceTemplate(definitions.ListSetterGuid, {
          columnNamePascal: column.namePascal,
        });
        const uidSetterContent = replaceTemplate(definitions.SetterGuidInterface, {
          columnNamePascal: column.namePascal,
        });

        listSetters.push(uidListSetterContent);
        setterDefinitions.push(uidSetterContent);
        
        break;
      default:
        if (column.name.includes("_ID")) {
          if (isChildTable && column.name === tableName + "_ID") return;
          column.dataTypeDotNet = "string";
          const listSetterContent = replaceTemplate(definitions.ListSetter, {
            columnNamePascal: column.namePascal,
          });
          const setterContent = replaceTemplate(definitions.SetterInterface, {
            columnNamePascal: column.namePascal,
          });

          listSetters.push(listSetterContent);
          setterDefinitions.push(setterContent);
        }
        break;
    }

    // If the usings does not contain the column's data type, add it
    if (!usings.includes("System")) {
      switch (column.dataTypeDotNet) {
        case "DateTime":
        case "DateTime?":
          usings.push("System");
          usings.push("System.Data.SqlTypes");
          break;
        default:
          break;
      }
    }

    // If the column type does not contain a question mark, it is not nullable, so adds a question mark to the end.
    let nullable = "";

    if (column.dataTypeDotNet !== "string" && !column.isNullable) {
      nullable = "?";
    }

    const replacement = {
      columnName: column.name,
      columnNamePascal: column.namePascal,
      columnType: `${column.dataTypeDotNet}${nullable}`,
    };

    const columnDefinitionContent = replaceTemplate(
      definitions.Column,
      replacement
    );

    if (shouldInsertIntoInterface)
      columnDefinitions.push(columnDefinitionContent);

    const parameterNameContent = replaceTemplate(
      definitions.Parameter,
      replacement
    );

    parameterNames.push(parameterNameContent);

    const shortColumnDefinitionContent = replaceTemplate(
      definitions.ShortColumn,
      replacement
    );

    shorColumnDefinitions.push(shortColumnDefinitionContent);

    let conditionTemplate = "";

    if (column.isEncrypted) {
      if (!usings.includes("Jfw.Helpers")) {
        usings.push("Jfw.Helpers");
      }
      conditionTemplate = definitions.ConditionEncrypted;
    } else {
      switch (column.dataTypeDotNet) {
        case "string":
          conditionTemplate = definitions.ConditionString;
          break;
        case "DateTime":
        case "DateTime?":
          conditionTemplate = definitions.ConditionDateTime;
          break;
        default:
          conditionTemplate = definitions.ConditionOther;
          break;
      }
    }

    const conditionDefinitionContent = replaceTemplate(
      conditionTemplate,
      replacement
    );

    conditionDefinitions.push(conditionDefinitionContent);
  };

  // Replace EntityName
  templateReplacements.EntityName = tableName;

  if (spCustom?.customParameters) {
    for (const customParameterName in spCustom.customParameters) {
      const customParameter = spCustom.customParameters[customParameterName];

      const replacement = {
        columnName: customParameter.name,
        columnNamePascal: customParameter.propertyName,
        columnType: customParameter.propertyType,
      };

      const columnDefinitionContent = replaceTemplate(
        definitions.Column,
        replacement
      );

      columnDefinitions.push(columnDefinitionContent);

      const parameterNameContent = replaceTemplate(
        definitions.Parameter,
        replacement
      );

      parameterNames.push(parameterNameContent);

      const shortColumnDefinitionContent = replaceTemplate(
        definitions.ShortColumn,
        replacement
      );

      shorColumnDefinitions.push(shortColumnDefinitionContent);

      let conditionTemplate = "";

      switch (customParameter.propertyType) {
        case "string":
          conditionTemplate = definitions.ConditionString;
          break;
        case "DateTime":
        case "DateTime?":
          conditionTemplate = definitions.ConditionDateTime;
          break;
        default:
          conditionTemplate = definitions.ConditionOther;
          break;
      }

      const conditionDefinitionContent = replaceTemplate(
        conditionTemplate,
        replacement
      );

      conditionDefinitions.push(conditionDefinitionContent);
    }
  }

  // Prepare the columns.
  tableData.columns.forEach((column) => processColumn(column));

  // Prepare the child tables.
  spCustom?.childTables.forEach((childTable) => {
    tables[childTable].columns.forEach((column) => processColumn(column, true));
  });

  templateReplacements.ColumnDefinitions = columnDefinitions.join("\n\n");
  templateReplacements.SetterDefinitions = setterDefinitions.join("\n\n");
  templateReplacements.ShortColumnDefinitions =
    shorColumnDefinitions.join("\n");
  templateReplacements.ParameterNameDefinitions = parameterNames.join("\n");
  templateReplacements.ConditionDefinitions = conditionDefinitions.join("\n\n");
  templateReplacements.ListSetters = listSetters.join("\n");

  // Replace Usings
  templateReplacements.Usings = getUsingTemplate([
    ...usings,
    ...FilterTemplate.defaultUsings,
  ]);

  // Replace InheritedInterfaces
  templateReplacements.InheritedInterfaces =
    getInheritanceTemplate(inheritedInterfaces);

  const content = replaceTemplate(template, templateReplacements);

  saveTextToFile(outputPath, content);
};

walkthroughTableData(tables, (tableName) => {
  generateFilters(tableName, tables[tableName]);
});
