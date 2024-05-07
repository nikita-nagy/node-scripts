// Purpose: Generates stored procedures for a table.
const { tableSchema } = require("../config");
const { authorDevCode, currentDate } = require("./variables");

const definitions = {
  Parameter: `\t@{{columnName}} {{dataType}}{{defaultValue}},`,
  Column: "\t\t[{{columnName}}],",
  Value: "\t\t@{{columnName}},",
};

const replacements = {
  Parameters: "",
  Columns: "",
  Values: "",
  entityName: "",
};

const spTemplateInsert = `
IF OBJECT_ID('[${tableSchema}].[asp_{{entityName}}_Insert]') IS NOT NULL
    DROP PROCEDURE [${tableSchema}].[asp_{{entityName}}_Insert]
GO
/*
* Description: Inserts a record into the [${tableSchema}].[{{entityName}}] table.
* Author: ${authorDevCode}
* History:
* - ${currentDate}: Created - ${authorDevCode}.
*/
CREATE PROCEDURE [${tableSchema}].[asp_{{entityName}}_Insert]
(
{{Parameters}}
    @Created_By BIGINT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [${tableSchema}].[{{entityName}}]
    (
{{Columns}}
        [Modified_By],
        [Created_By]
    )
    VALUES
    (
{{Values}}
        @Created_By,
        @Created_By
    )

    SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS [ID]
END
GO
`;

module.exports = { template: spTemplateInsert, definitions, replacements };
