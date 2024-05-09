const _ = require("lodash");
const { fs, saveTextToFile, jsonStringifyOrder } = require("./utils");
const { databaseConfig, sqlDataTypeMapping, tableSchema } = require("./config");

const mssql = require("mssql");

let tableInfo = [];
let procedureInfo = [];

const tableInfoScript = fs.readFileSync(
  "./sql/get_all_column_info.sql",
  "utf8"
);

const procedureInfoScript = fs.readFileSync(
  "./sql/get_all_sp_parameters.sql",
  "utf8"
);

// Process the table info data.
const processTableInfo = (tableInfo) => {
  console.log("Table column info retrieved.");
  console.log("Writing table column info to file...");
  saveTextToFile(
    "./data/table-column-info.json",
    JSON.stringify(tableInfo, null, 2)
  );
  console.log("Table column info written to file.");
};

// Process the procedure info data.
const processProcedureInfo = (procedureInfo) => {
  console.log("Procedure parameter info retrieved.");
  console.log("Writing procedure parameter info to file...");
  saveTextToFile(
    "./data/procedure-parameter-info.json",
    JSON.stringify(procedureInfo, null, 2)
  );

  console.log("Procedure parameter info written to file.");
};

const toDataTypeSqlWithLength = (dataType, maxLength) => {
  switch (dataType) {
    case "nvarchar":
    case "varchar":
    case "char":
    case "nchar":
      return `${dataType}(${maxLength < 0 ? "MAX" : maxLength})`;
    default:
      return dataType;
  }
};

// Process the result data.
const processResultData = (tableInfo, procedureInfo) => {
  console.log("Processing result data...");

  // Create a new object that will hold the table data
  const tables = tableInfo.reduce(
    (
      acc,
      { TableName, ColumnName, DataType, IsNullable, MaxLength, DefaultValue }
    ) => {
      let dotNetType = sqlDataTypeMapping[DataType];
      // We need to convert the column name to camel case from snake case
      let columnNameCamelCase = _.camelCase(ColumnName.replace("_iOS", "iO_s"));
      let columnNamePascalCase = _.upperFirst(columnNameCamelCase);
      let dataTypeSqlWithLength = toDataTypeSqlWithLength(DataType, MaxLength);
      let defaultValue = DefaultValue?.replace(/[()]/g, "") ?? DefaultValue;

      if (dotNetType == "bool") {
        if (defaultValue == "0") {
          defaultValue = "false";
        }
        if (defaultValue == "1") {
          defaultValue = "true";
        }
      }

      // If the IsNullable column is true, then the data type is nullable
      if (IsNullable) {
        // If the data type is not a string, then add a question mark to the end of the data type
        if (dotNetType !== "string") {
          dotNetType += "?";
        }
      }

      let isEncrypted = false;
      let isReadOnly = false;
      let isProtected = false;
      switch (TableName) {
        case "User":
          switch (ColumnName) {
            case "Username":
            case "Password":
              isEncrypted = true;
              break;
            case "Brand_ID":
            case "User_Code":
              isReadOnly = true;
              isProtected = true;
              break;
            default:
              break;
          }
          break;
        case "UserProfile":
          switch (ColumnName) {
            case "Email_Address":
              isEncrypted = true;
              break;
            default:
              break;
          }
          break;
        case "UserSetting":
          switch (ColumnName) {
            case "Referral_Code":
              isReadOnly = true;
              isProtected = true;
              break;
            default:
              break;
          }
          break;
        case "BlackList": {
          switch (ColumnName) {
            case "Blocked_Date":
              isReadOnly = true;
              break;
            default:
              break;
          }
        }
        default:
          break;
      }

      switch (ColumnName) {
        case "ID":
          isReadOnly = true;
          break;
        case "Is_System":
          isReadOnly = true;
          break;
        case "Modified_Date":
          isReadOnly = true;
          break;
        case "Created_Date":
          isReadOnly = true;
          break;
      }

      let currentObject = {
        name: ColumnName,
        nameCamel: columnNameCamelCase,
        namePascal: columnNamePascalCase,
        dataTypeSql: DataType,
        dataTypeSqlWithLength,
        dataTypeDotNet: dotNetType,
        defaultValue: defaultValue,
        isNullable: IsNullable,
        isEncrypted,
        isReadOnly,
        isProtected,
      };

      if (!acc[TableName]) {
        acc[TableName] = {
          columns: [currentObject],
        };
      } else {
        acc[TableName].columns.push(currentObject);
      }

      return acc;
    },
    {}
  );

  // Create a new object that will hold the procedure data and add it to the table data
  const resultData = procedureInfo.reduce(
    (
      acc,
      { ProcedureName, ParameterName, DataType, MaxLength, DefaultValue }
    ) => {
      let dotNetType = sqlDataTypeMapping[DataType];
      let procedureNameParts = ProcedureName.split("_");
      // let procedureType = procedureNameParts[0];
      let tableName = procedureNameParts[1];
      let procedureKey = procedureNameParts[2];
      let propertyKey = tableName + _.upperFirst(_.camelCase(procedureKey));
      let defaultValue = DefaultValue.replace(/\r/g, "");
      let parameterCamelCase = _.camelCase(
        ParameterName.replace("_iOS", "iO_s")
      );
      let parameterPascalCase = _.upperFirst(parameterCamelCase);

      if (dotNetType == "bool") {
        if (defaultValue == "0") {
          defaultValue = "false";
        }
        if (defaultValue == "1") {
          defaultValue = "true";
        }
      }

      let dataTypeSqlWithLength = toDataTypeSqlWithLength(DataType, MaxLength);
      let currentParameter = {
        name: ParameterName,
        nameCamel: parameterCamelCase,
        namePascal: parameterPascalCase,
        dataTypeSql: DataType,
        dataTypeSqlWithLength,
        dataTypeDotNet: dotNetType,
        defaultValue,
        isRequired: defaultValue === "" ? true : false,
      };

      if (!acc[tableName]) {
        console.error(
          "Procedure name does not match table name - " + tableName
        );
        return acc;
      }

      // If the table data doesn't have 'procedures' property, then create it
      if (acc[tableName].procedures === undefined) {
        acc[tableName].procedures = {
          [procedureKey]: {
            key: propertyKey,
            name: ProcedureName,
            nameWithSchema: `[${tableSchema}].[${ProcedureName}]`,
            parameters: [currentParameter],
          },
        };
      } else {
        // If the table data already has a 'procedures' property, then check if the procedure key exists
        if (acc[tableName].procedures[procedureKey] === undefined) {
          acc[tableName].procedures[procedureKey] = {
            key: propertyKey,
            name: ProcedureName,
            nameWithSchema: `[${tableSchema}].[${ProcedureName}]`,
            parameters: [currentParameter],
          };
        } else {
          acc[tableName].procedures[procedureKey].parameters.push(
            currentParameter
          );
        }
      }

      return acc;
    },
    tables
  );

  saveTextToFile("./data/tables.json", jsonStringifyOrder(resultData, 2));
};

console.log("Connecting to database...");
mssql
  .connect(databaseConfig)
  .then(async () => {
    console.log("Connected to database.");

    // Execute the table info query and save the result.
    await mssql.query(tableInfoScript).then((result) => {
      tableInfo = result.recordset;
      processTableInfo(result.recordset);
    });

    // Execute the table info query and save the result.
    await mssql.query(procedureInfoScript).then((result) => {
      procedureInfo = result.recordset;
      processProcedureInfo(result.recordset);
    });

    // Process the result data.
    processResultData(tableInfo, procedureInfo);

    // Close the connection.
    mssql.close();
  })
  .catch((err) => {
    console.log(err);
  });
