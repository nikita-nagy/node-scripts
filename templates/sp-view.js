// Purpose: Generates stored procedures for a table.
const { tableSchema } = require("../config");
const { authorDevCode, currentDate } = require("./variables");

const definitions = {
  Parameter: `\t@{{columnName}} {{dataType}} = NULL,`,
  FilterCriteria: `\tSET @whereClause = CONCAT(@whereClause, [${tableSchema}].[fn_GetFilterCriteriaWithTableAlias]('{{columnName}}', @{{columnName}}, '{{entityAlias}}'), @newLine)`,
  FilterCriteriaDateRange: `\tSET @whereClause = CONCAT(@whereClause, [${tableSchema}].[fn_GetFilterCriteriaByDateRangeWithTableAlias]('{{columnName}}', @{{columnName}}_From, @{{columnName}}_To, '{{entityAlias}}'), @newLine)`,
  FilterCriteriaList: `\tSET @whereClause = CONCAT(@whereClause, [${tableSchema}].[fn_GetFilterCriteriaByListWithTableAlias]('{{columnName}}', @{{columnName}}, '{{entityAlias}}'), @newLine)`,
  KeywordFilterCriteria: `\t\tDECLARE @{{childEntityName}}FilterQuery NVARCHAR(max) = [${tableSchema}].[fn_GetTableViewSearchQuery]('${tableSchema}', '{{childEntityName}}', @Keywords)
\t\tSET @tmpSqlString = CONCAT('INSERT INTO #temp(tmpId) SELECT [{{entityName}}_ID] FROM (', @{{childEntityName}}FilterQuery, ') as X WHERE [{{entityName}}_ID] NOT IN (SELECT tmpId FROM #temp)')
\t\t-- PRINT CONCAT('SQL string: ', @tmpSqlString)
\t\tEXEC sp_executesql @tmpSqlString
`,
  ChildSelectClause: `\tSET @selectClause = CONCAT(@selectClause, [${tableSchema}].[fn_GenerateColumnAliases]('{{childEntityName}}', '{{childEntityName}}_', '{{childEntityAlias}}'), ', ')`,
  ChildFromClause: `\tSET @fromClause = CONCAT(@fromClause, 'LEFT JOIN [${tableSchema}].[{{childEntityName}}] AS {{childEntityAlias}} ON {{entityAlias}}.[ID] = {{childEntityAlias}}.[{{entityName}}_ID]', @newLine)`,
};

const replacements = {
  Parameters: "",
  FilterCriterias: "",
  entityName: "",
  KeywordFilterCriterias: "",
  PreExecutionStatements: "",
};

const spTemplateList = `
IF OBJECT_ID('[${tableSchema}].[asp_{{entityName}}_View]') IS NOT NULL
    DROP PROCEDURE [${tableSchema}].[asp_{{entityName}}_View]
GO
/*
* Description: Gets all records from the [${tableSchema}].[{{entityName}}] table that match the specified criteria.
* Author: ${authorDevCode}
* Example:
*      EXEC [${tableSchema}].[asp_{{entityName}}_View] @Limit = 10, @Page_Number = 1, @Page_Size = 10, @Sort_Data_Field = 'ID', @Sort_Order = 'DESC', @Total_Rows = 0
* - With count example:
*      DECLARE @Count INT
*      EXEC [${tableSchema}].[asp_{{entityName}}_View] @Limit = 10, @Page_Number = 1, @Page_Size = 10, @Sort_Data_Field = 'ID', @Sort_Order = 'DESC', @Total_Rows = @Count OUTPUT
*      SELECT @Count AS [Count]
* History:
* - ${currentDate}: Created - ${authorDevCode}.
*/
CREATE PROCEDURE [${tableSchema}].[asp_{{entityName}}_View]
(
{{Parameters}}
    @Keywords NVARCHAR(MAX) = NULL,
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
{{PreExecutionStatements}}
    SET NOCOUNT ON;

    DECLARE @newLine nvarchar(2) = ' '
    DECLARE @limitClause nvarchar(max) = [${tableSchema}].[fn_GetLimitClause](@Limit)
    DECLARE @offsetClause nvarchar(max) = [${tableSchema}].[fn_GetOffsetClause](@Page_Number, @Page_Size)
    DECLARE @orderByClause nvarchar(max) = [${tableSchema}].[fn_GetOrderByClauseWithTableAlias](@Sort_Data_Field, @Sort_Order, '{{entityAlias}}')
    DECLARE @whereClause nvarchar(max) = CONCAT('1 = 1', @newLine)
    DECLARE @selectClause nvarchar(max) = @limitClause
    DECLARE @fromClause nvarchar(max) = CONCAT('[${tableSchema}].[{{entityName}}] AS [{{entityAlias}}]', @newLine)
    DECLARE @sqlCommand nvarchar(max) = ''

    CREATE TABLE #temp
    (
        tmpId BIGINT NOT NULL UNIQUE
    )
    
    --- Builds the SELECT clause
    IF (@offsetClause IS NOT NULL)
    BEGIN
        SET @selectClause = ''
    END
    
    SET @selectClause = CONCAT(@selectClause, '{{entityAlias}}.*, ')
{{ChildEntitySelectClause}}

    --- Builds the FROM clause
{{ChildEntityFromClause}}

    -- Sets filter criterias
{{FilterCriterias}}

    -- Sets keywords filter criterias
    IF (@Keywords IS NOT NULL)
    BEGIN
        DECLARE @tmpSqlString VARCHAR(MAX) = ''
        --- Builds keywords filter criterias
        DECLARE @{{entityName}}FilterQuery VARCHAR(MAX) = [${tableSchema}].[fn_GetTableViewSearchQuery]('${tableSchema}', '{{entityName}}', @Keywords)
        SET @tmpSqlString = CONCAT('INSERT INTO #temp(tmpId) SELECT [ID] FROM (', @{{entityName}}FilterQuery, ') as X')
        -- PRINT CONCAT('SQL string: ', @tmpSqlString)
        EXEC sp_executesql @tmpSqlString

{{KeywordFilterCriterias}}
        SELECT @whereClause = CONCAT(@whereClause, ' AND {{entityAlias}}.[ID] IN (SELECT tmpId FROM #temp)')
    END

    -- Sets common filter criteria
    SET @whereClause = CONCAT(@whereClause, [${tableSchema}].[fn_GetFilterCriteriaWithTableAlias]('Modified_By', @Modified_By, '{{entityAlias}}'), @newLine)
    SET @whereClause = CONCAT(@whereClause, [${tableSchema}].[fn_GetFilterCriteriaByDateRangeWithTableAlias]('Modified_Date', @Modified_Date_From, @Modified_Date_To, '{{entityAlias}}'), @newLine)
    SET @whereClause = CONCAT(@whereClause, [${tableSchema}].[fn_GetFilterCriteriaWithTableAlias]('Created_By', @Created_By, '{{entityAlias}}'), @newLine)
    SET @whereClause = CONCAT(@whereClause, [${tableSchema}].[fn_GetFilterCriteriaByDateRangeWithTableAlias]('Created_Date', @Created_Date_From, @Created_Date_To, '{{entityAlias}}'), @newLine)

    -- print @whereClause
    -- Sets the select SQL statement
    SET @sqlCommand = CONCAT('SELECT ', @selectClause, ' 0 FROM ', @fromClause ,' WHERE ', @whereClause, @orderByClause, @offsetClause)

    -- Executes the SQL statement
    EXEC sp_executesql @sqlCommand

    -- Sets the count SQL statement
    SET @sqlCommand = CONCAT('SELECT @Total_Rows = COUNT(*) FROM ', @fromClause, ' WHERE ', @whereClause)

    -- Executes the SQL statement
    EXEC sp_executesql @sqlCommand, N'@Total_Rows INT OUTPUT', @Total_Rows OUTPUT
END
GO
`;

module.exports = { template: spTemplateList, definitions, replacements };
