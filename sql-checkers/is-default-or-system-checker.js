const tableData = require("../data/tables.json");
const tableNames = Object.keys(tableData);

// For each table, log the parameters of the procedures that do not have same type as the column
tableNames.forEach((tableName) => {
  // Get the table
  const table = tableData[tableName];

  // Get the columns and procedures
  const { columns } = table;

  // Prints those tables that have Is_System and Is_Default columns
  const hasIsSystem = columns.find((column) => column.name === "Is_System");

  const hasIsDefault = columns.find((column) => column.name === "Is_Default");

  if (hasIsSystem || hasIsDefault) {
    console.log("--------------------------------------------------");
    console.log("Table: " + tableName);
    if (hasIsSystem) {
      console.log(`Is_System:`);
      console.log(`\t[Data Type: ${hasIsSystem?.dataTypeDotNet}];`);
      console.log(`\t[Default Value: ${hasIsSystem?.defaultValue}];`);
    }

    if (hasIsDefault) {
      console.log(`Is_Default:`);
      console.log(`\t[Data Type: ${hasIsDefault?.dataTypeDotNet}];`);
      console.log(`\t[Default Value: ${hasIsDefault?.defaultValue}];`);
    }
  }
});
