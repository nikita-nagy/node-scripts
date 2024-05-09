// Purpose: Generates stored procedures for a table.
const { tableSchema } = require("../config");
const { authorDevCode, currentDate } = require("./variables");

const definitions = {
  Parameter: `\t@{{columnName}} {{dataType}} = NULL,`,
  FilterCriteria: `\tSET @whereClause = CONCAT(@whereClause, [${tableSchema}].[fn_GetFilterCriteria]('{{columnName}}', @{{columnName}}), @newLine)`,
  FilterCriteriaDateRange: `\tSET @whereClause = CONCAT(@whereClause, [${tableSchema}].[fn_GetFilterCriteriaByDateRange]('{{columnName}}', @{{columnName}}_From, @{{columnName}}_To), @newLine)`,
  FilterCriteriaList: `\tSET @whereClause = CONCAT(@whereClause, [${tableSchema}].[fn_GetFilterCriteriaByList]('{{columnName}}', @{{columnName}}), @newLine)`,
};

const replacements = {
  Parameters: "",
  FilterCriterias: "",
  entityName: "",
};

const spTemplateList = `
IF OBJECT_ID('[${tableSchema}].[asp_{{entityName}}_List]') IS NOT NULL
    DROP PROCEDURE [${tableSchema}].[asp_{{entityName}}_List]
GO
/*
* Description: Gets all records from the [${tableSchema}].[{{entityName}}] table that match the specified criteria.
* Author: ${authorDevCode}
* Example:
*      EXEC [${tableSchema}].[asp_{{entityName}}_List] @Limit = 10, @Page_Number = 1, @Page_Size = 10, @Sort_Data_Field = 'ID', @Sort_Order = 'DESC', @Total_Rows = 0
* History:
* - ${currentDate}: Created - ${authorDevCode}.
*/
CREATE PROCEDURE [${tableSchema}].[asp_{{entityName}}_List]
(
{{Parameters}}
    @Modified_By BIGINT = NULL,
    @Modified_Date_From DATETIME = NULL,
    @Modified_Date_To DATETIME = NULL,
    @Created_By BIGINT = NULL,
    @Created_Date_From DATETIME = NULL,
    @Created_Date_To DATETIME = NULL,
    @Limit INT = NULL,
    @Page_Number INT = NULL,
    @Page_Size INT = NULL,
    @Sort_Data_Field VARCHAR(50) = 'ID',
    @Sort_Order VARCHAR(4) = 'DESC',
    @Total_Rows INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @newLine nvarchar(2) = CHAR(13) + CHAR(10)
    DECLARE @limitClause nvarchar(max) = [${tableSchema}].[fn_GetLimitClause](@Limit)
    DECLARE @offsetClause nvarchar(max) = [${tableSchema}].[fn_GetOffsetClause](@Page_Number, @Page_Size)
    DECLARE @orderByClause nvarchar(max) = [${tableSchema}].[fn_GetOrderByClause](@Sort_Data_Field, @Sort_Order)
    DECLARE @whereClause nvarchar(max) = CONCAT('1 = 1', @newLine)
    DECLARE @sqlCommand nvarchar(max) = ''

    -- Sets filter criterias
{{FilterCriterias}}

    -- Sets common filter criterias
    SET @whereClause = CONCAT(@whereClause, [${tableSchema}].[fn_GetFilterCriteria]('Modified_By', @Modified_By), @newLine)
    SET @whereClause = CONCAT(@whereClause, [${tableSchema}].[fn_GetFilterCriteriaByDateRange]('Modified_Date', @Modified_Date_From, @Modified_Date_To), @newLine)
    SET @whereClause = CONCAT(@whereClause, [${tableSchema}].[fn_GetFilterCriteria]('Created_By', @Created_By), @newLine)
    SET @whereClause = CONCAT(@whereClause, [${tableSchema}].[fn_GetFilterCriteriaByDateRange]('Created_Date', @Created_Date_From, @Created_Date_To), @newLine)

    -- print @whereClause
    -- Disables the limit clause if the offset clause is set.
    IF (@offsetClause IS NOT NULL AND @offsetClause <> '')
    BEGIN
        SET @limitClause = ''
    END

    -- Sets the select SQL statement
    SET @sqlCommand = CONCAT('SELECT ', @limitClause, ' * FROM [${tableSchema}].[{{entityName}}] WHERE ', @whereClause, @orderByClause, @offsetClause)
    
    -- Executes the SQL statement
    EXEC sp_executesql @sqlCommand

    -- Sets the count SQL statement
    SET @sqlCommand = CONCAT('SELECT @Total_Rows = COUNT(*) FROM [${tableSchema}].[{{entityName}}] WHERE ', @whereClause)

    -- Executes the SQL statement
    EXEC sp_executesql @sqlCommand, N'@Total_Rows INT OUTPUT', @Total_Rows OUTPUT

END
GO
`;

module.exports = { template: spTemplateList, definitions, replacements };
