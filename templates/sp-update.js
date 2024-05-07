// Purpose: Generates stored procedures for a table.
const { tableSchema } = require("../config");
const { authorDevCode, currentDate } = require("./variables");

const definitions = {
  Parameter: `\t@{{columnName}} {{dataType}}{{defaultValue}},`,
  SetCommand: "\t\t[{{columnName}}] = @{{columnName}},",
};

const replacements = {
  Parameters: "",
  SetCommands: "",
  entityName: "",
};

const spTemplateUpdate = `
IF OBJECT_ID('[${tableSchema}].[asp_{{entityName}}_Update]') IS NOT NULL
    DROP PROCEDURE [${tableSchema}].[asp_{{entityName}}_Update]
GO
/*
* Description: Updates a record in the [${tableSchema}].[{{entityName}}] table.
* Author: ${authorDevCode}
* History:
* - ${currentDate}: Created - ${authorDevCode}.
*/
CREATE PROCEDURE [${tableSchema}].[asp_{{entityName}}_Update]
(
    @ID BIGINT,
{{Parameters}}
    @Modified_By BIGINT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [${tableSchema}].[{{entityName}}]
    SET
{{SetCommands}}
        [Modified_By] = @Modified_By,
        [Modified_Date] = GETUTCDATE()
    WHERE
        [ID] = @ID

    SELECT CAST(@@ROWCOUNT AS BIGINT) AS [TotalRows]

END
GO
`;

module.exports = { template: spTemplateUpdate, definitions, replacements };
