const {
  saveTextToFile,
  replaceTemplate,
  getUsingTemplate,
  getInheritanceTemplate,
  walkthroughTableData,
} = require("./utils");

const { outputPaths, suffixFileName } = require("./templates/variables");
const tables = require("./data/tables.json");

const TemplateInterface = require("./templates/entity-interface");
const TemplatePartial = require("./templates/entity-partital");
const TemplateImplement = require("./templates/entity-implement");

const toogles = {
  generateEntityInterface: true,
  generateEntityPartial: true,
  generateEntityImplements: true,
};

const generateEntities = (tableName, tableData) => {
  const entityInterface = {
    outputPath: `${outputPaths.jfwModels.interfaces}/I${tableName}Entity${suffixFileName}.cs`,
    template: TemplateInterface.template,
    usings: TemplateInterface.defaultUsings.slice(),
    inheritedInterfaces: TemplateInterface.defaultInterfaces.slice(),
    definitions: TemplateInterface.definitions,
    columns: [],
  };

  const entityPartial = {
    outputPath: `${outputPaths.jfwModels.implements}/${tableName}Entity${suffixFileName}.cs`,
    template: TemplatePartial.template,
    usings: TemplatePartial.defaultUsings.slice(),
    definitions: TemplatePartial.definitions,
    columns: [],
    parsings: [],
    insertParameters: [],
    updateParameters: [],
  };

  const entityImplement = {
    outputPath: `${outputPaths.jfwModels.implements}/${tableName}Entity.cs`,
    template: TemplateImplement.template,
    usings: TemplateImplement.defaultUsings.slice(),
    definitions: TemplateImplement.definitions,
    columns: [],
    fields: [],
  };

  function CreateFile(outputPath, template, replacements) {
    const content = replaceTemplate(template, replacements);
    saveTextToFile(outputPath, content);
  }

  function SetInterfaceReplacements() {
    entityInterface.replacements = {
      EntityName: tableName,
      Usings: getUsingTemplate(entityInterface.usings),
      InheritedInterfaces: getInheritanceTemplate(
        entityInterface.inheritedInterfaces
      ),
      ColumnDefinitions: entityInterface.columns.join("\n\n"),
    };
  }

  function SetPartialReplacements() {
    entityPartial.replacements = {
      EntityName: tableName,
      Usings: getUsingTemplate(entityPartial.usings),
      ColumnDefinitions: entityPartial.columns.join("\n\n"),
      ColumnParseDefinitions: entityPartial.parsings.join("\n"),
      InsertParameters: entityPartial.insertParameters.join(",\n"),
      UpdateParameters: entityPartial.updateParameters.join(",\n"),
    };
  }

  function SetImplementReplacements() {
    entityImplement.replacements = {
      EntityName: tableName,
      Usings: getUsingTemplate(entityImplement.usings),
      ColumnDefinitions: entityImplement.columns.join("\n\n"),
      EncryptedFields: entityImplement.fields.join("\n"),
    };
  }

  const handleColumnForInterface = (column) => {
    // If the column is an inherited column, add inherited interfaces
    switch (column.name) {
      case "ID":
      case "Modified_By":
      case "Modified_Date":
      case "Created_By":
      case "Created_Date":
        return;
      case "Is_System":
        entityInterface.inheritedInterfaces.push("IHasIsSystem");
        return;
      default:
        break;
    }

    // If the usings does not contain the column's data type, add it
    if (!entityInterface.usings.includes("System")) {
      switch (column.dataTypeDotNet) {
        case "DateTime":
        case "DateTime?":
          entityInterface.usings.push("System");
          break;
        default:
          break;
      }
    }

    if (column.isEncrypted) {
      columnDefinition = entityInterface.definitions.EncryptedColumn;
    } else {
      columnDefinition = entityInterface.definitions.Column;
    }

    let columnType = column.dataTypeDotNet;
    if (!columnType.includes("?") && column.dataTypeDotNet !== "string") {
      columnType += "?";
    }

    const replacements = {
      entityName: tableName,
      columnName: column.name,
      columnNamePascal: column.namePascal,
      columnType,
    };

    entityInterface.columns.push(
      replaceTemplate(columnDefinition, replacements)
    );
  };

  const handleColumnForPartial = (column) => {
    function handleColumns() {
      // Skips ID column because it is already defined in BaseEntity
      if (column.name === "ID") return;

      const replacement = {
        columnName: column.name,
        columnNamePascal: column.namePascal,
      };

      const content = replaceTemplate(
        entityPartial.definitions.ColumnConstant,
        replacement
      );

      entityPartial.columns.push(content);
    }

    function handleParsings() {
      const replacement = {
        columnNamePascal: column.namePascal,
        columnType: column.dataTypeDotNet,
      };

      let definition;

      if (column.isEncrypted) {
        definition = entityPartial.definitions.EncryptedColumnParse;
      } else {
        definition = entityPartial.definitions.ColumnParse;
      }

      const content = replaceTemplate(definition, replacement);

      entityPartial.parsings.push(content);
    }

    handleColumns();

    handleParsings();
  };

  const handleParametersForPartial = (tableData) => {
    const processParameter = (parameter) => {
      const column = tableData.columns.find(
        (column) => column.namePascal === parameter.namePascal
      );

      if (!column) {
        console.log(`Column ${parameter.namePascal} not found in ${tableName}`);
        return;
      }

      let defaultValue = "";
      if (column.name !== "Is_System") {
        if (!column?.isNullable && column?.defaultValue === null) {
          defaultValue = "";
        } else {
          defaultValue = " ?? ";
          if (column?.defaultValue !== null) {
            defaultValue += column.defaultValue;
          } else {
            defaultValue += "(object)DBNull.Value";
          }
        }
      }

      const replacement = {
        columnNamePascal: parameter.namePascal,
        defaultValue,
      };

      let definition;

      if (column?.isEncrypted) {
        definition = entityPartial.definitions.EncryptedParameter;
      } else {
        definition = entityPartial.definitions.Parameter;
      }

      return replaceTemplate(definition, replacement);
    };

    if (tableData?.procedures) {
      const insertProcedure = tableData?.procedures["Insert"];
      const updateProcedure = tableData?.procedures["Update"];
      if (insertProcedure) {
        entityPartial.insertParameters =
          insertProcedure.parameters.map(processParameter);
      } else {
        console.log(`Insert procedure for ${tableName} is not defined`);
      }

      if (updateProcedure) {
        entityPartial.updateParameters =
          updateProcedure.parameters.map(processParameter);
      } else {
        console.log(`Update procedure for ${tableName} is not defined`);
      }
    }
  };

  const handleColumnForImplement = (column) => {
    let columnType = column.dataTypeDotNet;
    let toLower = "";

    switch (column.name) {
      case "ID":
      case "Is_System":
      case "Modified_Date":
      case "Created_Date":
        break;
      case "Username":
      case "Email_Address":
        toLower = ".ToLower()";
        break;
      default:
        if (!columnType.includes("?") && column.dataTypeDotNet !== "string") {
          columnType += "?";
          break;
        }
    }

    const replacement = {
      columnType,
      columnNamePascal: column.namePascal,
      columnNameCamel: column.nameCamel,
      toLower,
    };

    const usings = entityImplement.usings;

    if (!usings.includes("Jfw.Helpers")) {
      if (column.isEncrypted) usings.unshift("Jfw.Helpers");
    }

    // If the usings does not contain the column's data type, add it
    if (!usings.includes("System")) {
      switch (column.dataTypeDotNet) {
        case "DateTime":
        case "DateTime?":
          usings.unshift("System");
          break;
        default:
          break;
      }
    }

    let definition;
    let definitionField;
    let content;

    if (column.isEncrypted) {
      definition = entityImplement.definitions.EncryptedColumn;
      definitionField = entityImplement.definitions.EncryptedField;
      content = replaceTemplate(definitionField, replacement);
      entityImplement.fields.push(content);
    } else {
      definition = entityImplement.definitions.Column;
    }

    content = replaceTemplate(definition, replacement);
    entityImplement.columns.push(content);
  };

  // Adds the base entity interface to the inherited interfaces.
  if (!entityInterface.inheritedInterfaces.includes("IBaseEntity")) {
    entityInterface.inheritedInterfaces.push(
      `IBaseEntity<I${tableName}Entity>`
    );
  }

  entityImplement.fields.push("");

  tableData.columns.forEach((column) => {
    handleColumnForInterface(column);
    handleColumnForPartial(column);
    handleColumnForImplement(column);
  });

  handleParametersForPartial(tableData);

  if (entityImplement.fields.length > 1) {
    entityImplement.fields.push("");
  }

  SetInterfaceReplacements();
  SetPartialReplacements();
  SetImplementReplacements();

  CreateFile(
    entityInterface.outputPath,
    entityInterface.template,
    entityInterface.replacements
  );

  CreateFile(
    entityPartial.outputPath,
    entityPartial.template,
    entityPartial.replacements
  );

  CreateFile(
    entityImplement.outputPath,
    entityImplement.template,
    entityImplement.replacements
  );
};

walkthroughTableData(tables, (tableName) => {
  generateEntities(tableName, tables[tableName]);
});
