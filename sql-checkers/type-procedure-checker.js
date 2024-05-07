const tableData = require("../data/tables.json");
const tableNames = Object.keys(tableData);

// For each table, log the parameters of the procedures that do not have same type as the column
tableNames.forEach((tableName) => {
  // Get the table
  const table = tableData[tableName];

  // Get the columns and procedures
  const { columns, procedures } = table;

  if (procedures === undefined) {
    console.log(`Table: ${tableName} does not have procedures.`);
    return;
  }

  // For each procedure, check the parameters
  const procedureNames = Object.keys(procedures);
  procedureNames.forEach((procedureName) => {
    // Get the procedure
    const procedure = procedures[procedureName];
    let listExtraColumns = [
      "Limit",
      "Page_Size",
      "Page_Number",
      "Sort_Data_Field",
      "Sort_Order",
    ];
    let ignoreColumnsCount = 0;
    let expectedColumns = columns.length;
    columns.forEach((column) => {
      // Ignore the Is_System column for Insert/Update procedures
      switch (procedureName) {
        case "List":
          if (column.name === "ID") {
            ignoreColumnsCount++;
          }
          if (
            column.name === "Created_Date" ||
            column.name === "Modified_Date"
          ) {
            expectedColumns++;
          } else {
            if (column.dataTypeSql === "datetime") {
              expectedColumns++;
            }
          }
          break;
        case "Insert":
          if (
            column.name === "ID" ||
            column.name === "Is_System" ||
            column.name === "Created_Date" ||
            column.name === "Modified_Date" ||
            (tableName === "BlackList" && column.name === "Blocked_Date")
          ) {
            ignoreColumnsCount++;
          }
          break;
        case "Update":
          if (
            column.name === "Is_System" ||
            column.name === "Created_By" ||
            column.name === "Created_Date" ||
            column.name === "Modified_Date" ||
            (tableName === "BlackList" && column.name === "Blocked_Date")
          ) {
            ignoreColumnsCount++;
          }
          break;
      }
    });

    switch (procedureName) {
      case "Delete":
      case "Get":
        // Delete/Get procedures should have only one parameter - the id
        if (procedure.parameters.length !== 1) {
          console.log(
            `Table [${tableName}] - Procedure: ${procedureName} - ${procedure.nameWithSchema}`
          );
          console.log("\tWARNING: Should have only one parameter - the id");
        }
        break;
      case "Insert":
        expectedColumns = expectedColumns - ignoreColumnsCount;
        break;
      case "List":
        expectedColumns =
          expectedColumns - ignoreColumnsCount + listExtraColumns.length;
        switch (tableName) {
          case "City":
          case "Country":
          case "State":
          case "Currency":
          case "TimeZone":
            break;
          case "EmailTracking": // There are 2 extra parameters for Sent_Time and Keyword for this table
          case "Permission": // There are 2 extra parameters for User_ID and Role_ID for this table
            expectedColumns = expectedColumns + 2;
            break;
        }
        break;
      case "Update":
        expectedColumns = expectedColumns - ignoreColumnsCount;
        switch (tableName) {
          case "User": // We don't update Brand_ID and User_Code for this table
            expectedColumns = expectedColumns - 2;
        }
        break;
    }

    if (procedureName !== "Get" && procedureName !== "Delete") {
      if (procedure.parameters.length !== expectedColumns) {
        console.log(
          `Table [${tableName}] - Procedure: ${procedureName} - ${procedure.nameWithSchema}`
        );
        console.log(
          `\tWARNING: Should have ${expectedColumns} parameters - ${procedure.parameters.length}`
        );
      }
    }

    // Get the parameters
    const { parameters } = procedure;

    // For each parameter, check the type
    parameters.forEach((parameter) => {
      switch (parameter.name) {
        case "@Limit":
        case "@Page_Size":
        case "@Page_Number":
        case "@Sort_Data_Field":
        case "@Sort_Order":
          return;
      }
      // Get the column
      const column = columns.find(
        (column) => column.namePascal === parameter.namePascal
      );

      if (column === undefined) {
        // console.log(`Table [${tableName}] - Procedure: ${procedureName}`);
        // console.log(
        //   `\tWARNING: No matching column with Parameter: ${parameter.name} - ${parameter.dataTypeSql}`
        // );
        return;
      }

      // Check the type
      if (column?.dataTypeSql !== parameter.dataTypeSql) {
        // Log the table with procedure with schema
        console.log(`Table [${tableName}] - Procedure: ${procedureName}`);
        console.log(`\tParameter: ${parameter.name} ${parameter.dataTypeSql}`);
        console.log(`\tColumn: ${column.name} ${column.dataTypeSql}`);
      }
    });
  });
});
