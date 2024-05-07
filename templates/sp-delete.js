// Purpose: Generates stored procedures for a table.
const { tableSchema } = require("../config");
const { authorDevCode, currentDate } = require("./variables");

const definitions = {};
const deleteStatementDefault = `
    SET NOCOUNT ON;

    DELETE FROM
        [${tableSchema}].[{{entityName}}]
    WHERE
        [ID] = @ID
`;

const deleteStatementByUpdatingStatus = `
    SET NOCOUNT ON;

    DECLARE @Deleted smallint = -3;

    UPDATE
        [${tableSchema}].[{{entityName}}]
    SET
        [Status] = @Deleted
    WHERE
        [ID] = @ID
`;

const deleteStatementCommented = `
    SET NOCOUNT ON;
    
    -- DELETE FROM
    --     [${tableSchema}].[{{entityName}}]
    -- WHERE
    --     [ID] = @ID
`;

const replacements = {
  entityName: "",
};

const spTemplatePrefix = `
IF OBJECT_ID('[${tableSchema}].[asp_{{entityName}}_Delete]') IS NOT NULL
    DROP PROCEDURE [${tableSchema}].[asp_{{entityName}}_Delete]
GO

/*
* Description: Deletes a record from the [${tableSchema}].[{{entityName}}] table.
* Author: ${authorDevCode}
* Example:
*      EXEC [${tableSchema}].[asp_{{entityName}}_Delete] @ID = 1
* History:
* - ${currentDate}: Created - ${authorDevCode}.
*/
CREATE PROCEDURE [${tableSchema}].[asp_{{entityName}}_Delete]
(
    @ID BIGINT
)
AS
BEGIN
`;

const spTemplateSuffix = `
    SELECT CAST(@@ROWCOUNT AS BIGINT) AS [TotalRows]
END
GO
`;

const spTemplateDelete = `${spTemplatePrefix}${deleteStatementDefault}${spTemplateSuffix}`;
const spTemplateDeleteByUpdatingStatus = `${spTemplatePrefix}${deleteStatementByUpdatingStatus}${spTemplateSuffix}`;
const spTemplateDeleteCommented = `${spTemplatePrefix}${deleteStatementCommented}${spTemplateSuffix}`;

module.exports = {
  template: {
    default: spTemplateDelete,
    byStatus: spTemplateDeleteByUpdatingStatus,
    commented: spTemplateDeleteCommented,
  },
  definitions,
  replacements,
};
