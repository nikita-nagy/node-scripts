// Purpose: Generates stored procedures for a table.
const { tableSchema } = require("../config");
const { authorDevCode, currentDate } = require("./variables");

const definitions = {};

const replacements = {
  entityName: "",
};

const spTemplateGet = `
IF OBJECT_ID('[${tableSchema}].[asp_{{entityName}}_Get]') IS NOT NULL
    DROP PROCEDURE [${tableSchema}].[asp_{{entityName}}_Get]
GO
/*
 * Description: Gets a record from the [${tableSchema}].[{{entityName}}] table.
 * Author: ${authorDevCode}
 * Example:
 *      EXEC [${tableSchema}].[asp_{{entityName}}_Get] @ID = 1
 * History:
 * - ${currentDate}: Created - ${authorDevCode}.
 */
CREATE PROCEDURE [${tableSchema}].[asp_{{entityName}}_Get]
(
    @ID BIGINT
)
AS
BEGIN
    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED

    SELECT *
    FROM [${tableSchema}].[{{entityName}}]
    WHERE [ID] = @ID
END
GO
`;

module.exports = { template: spTemplateGet, definitions, replacements };
