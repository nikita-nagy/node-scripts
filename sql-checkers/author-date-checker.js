const tableData = require("../data/tables.json");
const tableNames = Object.keys(tableData);

// For each table, log the table that has Created_Date and Modified_Date columns
tableNames.forEach((tableName) => {
  const table = tableData[tableName];
  const { columns } = table;
  const hasCreatedDate = columns.find(
    (column) => column.name === "Created_Date"
  );
  const hasModifiedDate = columns.find(
    (column) => column.name === "Modified_Date"
  );

  if (hasCreatedDate || hasModifiedDate) {
    console.log("--------------------------------------------------");
    console.log("Table: " + tableName);
    if (hasModifiedDate) {
      console.log(`Modified_Date:`);
      console.log(`\t[Data Type: ${hasModifiedDate?.dataTypeDotNet}];`);
      console.log(`\t[Default Value: ${hasModifiedDate?.defaultValue}];`);
    }

    if (hasCreatedDate) {
      console.log(`Created_Date:`);
      console.log(`\t[Data Type: ${hasCreatedDate?.dataTypeDotNet}];`);
      console.log(`\t[Default Value: ${hasCreatedDate?.defaultValue}];`);
    }
  }
});
