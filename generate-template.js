const {
  saveTextToFile,
  replaceTemplate,
  getUsingTemplate,
  walkthroughTableData,
} = require("./utils");

const { outputPaths } = require("./templates/variables");
const tables = require("./data/tables.json");
const { tableDictionaryPath } = require("./config");
const { spConfig, spChildTables } = require("./config-sp-custom");
const Templates = require("./templates/entity-class-templates");
const TemplateImplement = require("./templates/entity-class-implement");

const memoryClasses = require("./data/memory-classes.json");
const memoryClassTemplate = require("./templates/memory-class-templates");

const generateTemplate = (tableName) => {
  for (const template of Templates.templates) {
    const prefixPath = tableDictionaryPath[tableName] || "";
    const outputPath = `${outputPaths.jfwCore.entityClasses}/${prefixPath}/${tableName}${template.outputSuffix}.cs`;
    const templateText = template.template;

    // Replace EntityName
    let entityName = tableName;

    saveTextToFile(outputPath, replaceTemplate(templateText, { entityName }));
  }
};

const generateImplementTemplate = (tableName, tableData) => {
  // console.log(`Generating Entity Interface for ${tableName}...`);
  if (spChildTables[tableName] !== undefined) {
    return;
  }

  const prefixPath = tableDictionaryPath[tableName] || "";
  const outputPath = `${outputPaths.jfwCore.entityClasses}/${prefixPath}/${tableName}.Properties.cs`;
  const template = TemplateImplement.template;
  const definitions = TemplateImplement.definitions;

  const ignoredChildColumns = ["ID"];
  const hasChildTables =
    spConfig[tableName] && spConfig[tableName].childTables.length > 0;

  const definitionPartialClass = replaceTemplate(definitions.PartialClass, {
    EntityName: tableName,
  });

  let propertyDefinitions = [];
  let methodDefinitions = [];

  const processColumn = (column, tblName = tableName, isChildTable = false) => {
    if (column.name == "ID" && !hasChildTables) return;

    if (isChildTable && ignoredChildColumns.includes(column.name)) return;

    columnType = column.dataTypeDotNet;

    switch (column.name) {
      case "Is_System":
      case "Modified_Date":
      case "Created_Date":
        break;
      default:
        if (!columnType.includes("?") && column.dataTypeDotNet !== "string") {
          columnType += "?";
        }
        break;
    }

    const replacement = {
      entityName: tableName,
      childTable: isChildTable ? tblName : "",
      columnNamePascal: column.namePascal,
      columnType,
    };

    let definitionProperty;
    let definitionGetMethod;
    let definitionSetMethod;

    if (hasChildTables && !isChildTable) {
      let extraSetters = [];

      switch (column.name) {
        case "ID":
          extraSetters = getExtraSetters(
            tableName,
            column,
            spConfig[tableName].childTables
          );

          const extraReplacement = {
            ExtraSetters: extraSetters.join("\n"),
          };

          propertyDefinitions.push(
            replaceTemplate(definitions.PropertyExtendedId, extraReplacement)
          );
          return;
        case "Modified_By":
        case "Created_By":
          extraSetters = getExtraSetters(
            "",
            column,
            spConfig[tableName].childTables
          );

          definitionProperty = replaceTemplate(
            definitions.PropertyExtendedFullAccessor,
            {
              ExtraSetters: extraSetters.join("\n"),
            }
          );
          break;
        default:
          break;
      }
    }

    if (column.isEncrypted) {
      definitionProperty = definitionProperty ?? definitions.PropertyEncrypted;
      definitionGetMethod = definitions.MethodGetEncrypted;
    } else {
      if (column.isProtected) {
        definitionProperty =
          definitionProperty ?? definitions.PropertyProtected;
        definitionGetMethod = definitions.MethodGetProtected;
      } else if (column.isReadOnly) {
        definitionProperty = definitionProperty ?? definitions.PropertyReadOnly;
        definitionGetMethod = definitions.MethodGet;
      } else {
        definitionProperty =
          definitionProperty ?? definitions.PropertyFullAccessor;
        definitionGetMethod = definitions.MethodGet;
        definitionSetMethod = definitions.MethodSet;
      }
    }

    if (definitionProperty) {
      const propertyContent = replaceTemplate(definitionProperty, replacement);
      propertyDefinitions.push(propertyContent);
    }

    if (definitionGetMethod) {
      const getMethodContent = replaceTemplate(
        definitionGetMethod,
        replacement
      );
      methodDefinitions.push(getMethodContent);
    }

    if (definitionSetMethod) {
      const setMethodContent = replaceTemplate(
        definitionSetMethod,
        replacement
      );
      methodDefinitions.push(setMethodContent);
    }

    function getExtraSetters(tbl, col, childTables) {
      let extraSetters = [];
      childTables.forEach((childTable) => {
        const extraReplacement = {
          entityName: tbl,
          childTable: childTable,
          columnNamePascal: col.namePascal,
        };

        const extraContent = replaceTemplate(
          definitions.PropertyExtend,
          extraReplacement
        );

        extraSetters.push(extraContent);
      });

      return extraSetters;
    }
  };

  tableData.columns.forEach((column) => processColumn(column));

  const replacements = {
    EntityName: tableName,
    PartialClass: definitionPartialClass,
    Usings: getUsingTemplate(TemplateImplement.defaultUsings),
    PropertyDefinitions: propertyDefinitions.join("\n\n"),
    MethodDefinitions: methodDefinitions.join("\n\n"),
  };

  const entityInterface = replaceTemplate(template, replacements);
  saveTextToFile(outputPath, entityInterface);

  // If has child tables, process child tables
  if (hasChildTables !== true) return;

  let usings = [];
  usings.push(...TemplateImplement.defaultUsings);

  removeItem(usings, "Jfw.Core.EntityClasses.Interfaces");
  removeItem(usings, "Jfw.Repositories.Interfaces");

  propertyDefinitions = [];
  const childTables = spConfig[tableName]?.childTables;

  for (const childTable of childTables) {
    const childTableData = tables[childTable];
    const childData = spChildTables[childTable];
    const childTableOutputPath = `${outputPaths.jfwCore.entityClasses}/${prefixPath}/${tableName}.Properties.${childData.suffix}.cs`;
    const childPartialClass = replaceTemplate(definitions.PartialClassChild, {
      EntityName: childTable,
      ParentEntityName: tableName,
    });

    if (spChildTables[childTable].ignoredColumns) {
      ignoredChildColumns.push(...spChildTables[childTable].ignoredColumns);
    }

    propertyDefinitions = [];
    methodDefinitions = [];

    childTableData.columns.forEach((column) =>
      processColumn(column, childTable, true)
    );

    const childReplacements = {
      EntityName: childTable,
      PartialClass: childPartialClass,
      Usings: getUsingTemplate(usings),
      PropertyDefinitions: propertyDefinitions.join("\n\n"),
      MethodDefinitions: methodDefinitions.join("\n\n"),
    };

    const childEntityInterface = replaceTemplate(template, childReplacements);
    saveTextToFile(childTableOutputPath, childEntityInterface);
  }
};

function removeItem(arr, item) {
  const index = arr.indexOf(item);
  if (index > -1) {
    arr.splice(index, 1);
  }
}

const generateMemoryClassTemplate = (className) => {
  for (const template of memoryClassTemplate.templates) {
    const outputPath = `${outputPaths.jfwCore.memoryClasses}/${className}${template.outputSuffix}.cs`;
    const templateText = template.template;

    saveTextToFile(outputPath, replaceTemplate(templateText, { className }));
  }
};

walkthroughTableData(tables, (tableName) => {
  generateTemplate(tableName);
  generateImplementTemplate(tableName, tables[tableName]);
});

// For Memory Classes
for (const className of memoryClasses) {
  // generateMemoryClassTemplate(className);
}
