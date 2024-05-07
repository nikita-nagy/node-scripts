// Purpose: Generates stored procedures for a table.
import { tableSchema } from "../variables";
import { author, currentDate } from "./variables";

const spTemplateInsert = `
-- =============================================
-- Created by:   ${author}
-- Created date: ${currentDate}
-- Description:	 Inserts a record into the [${tableSchema}].[{{entityName}}] table.
-- =============================================
CREATE PROCEDURE [${tableSchema}].[asp_{{entityName}}_Insert]
(
    {{Columns}}
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

const spTemplateUpdate = `
-- =============================================
-- Created by:   ${author}
-- Created date: ${currentDate}
-- Description:	 Updates a record in the [${tableSchema}].[{{entityName}}] table.
-- =============================================
CREATE PROCEDURE [${tableSchema}].[asp_{{entityName}}_Update]
(
    @ID BIGINT,
{{Columns}}
    @Modified_By BIGINT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [${tableSchema}].[{{entityName}}]
    SET
{{SetCommands}}
        [Modified_By] = @Modified_By
    WHERE
        [ID] = @ID

    SELECT CAST(@@ROWCOUNT AS BIGINT) AS [TotalRows]

END
GO
`;

const spTemplateDelete = `
-- =============================================
-- Created by:   ${author}
-- Created date: ${currentDate}
-- Description:	 Deletes a record from the [${tableSchema}].[{{entityName}}] table.
-- =============================================
CREATE PROCEDURE [${tableSchema}].[asp_{{entityName}}_Delete]
(
    @ID BIGINT
)
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM [${tableSchema}].[{{entityName}}]
    WHERE [ID] = @ID

    SELECT CAST(@@ROWCOUNT AS BIGINT) AS [TotalRows]

END
GO
`;

const spTemplateGet = `
-- =============================================
-- Created by:   ${author}
-- Created date: ${currentDate}
-- Description:	 Gets a record from the [${tableSchema}].[{{entityName}}] table.
-- =============================================
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

const spTemplateList = `
-- =============================================
-- Created by:   ${author}
-- Created date: ${currentDate}
-- Description:	 Gets all records from the [${tableSchema}].[{{entityName}}] table that match the specified criteria.
-- =============================================
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

	DECLARE @limitClause nvarchar(max) = [JFW].[fn_GetLimitClause](@Limit),
            @offsetClause nvarchar(max) = [JFW].[fn_GetOffsetClause](@Page_Number, @Page_Size),
            @orderByClause nvarchar(max) = [JFW].[fn_GetOrderByClause](@Sort_Data_Field, @Sort_Order),
            @whereClause nvarchar(max) = CONCAT('1 = 1 '),
            @sqlCommand nvarchar(max) = '',

    -- Sets filter criterias
    {{FilterCriterias}}

    -- Sets common filter criteria
    SET @whereClause = CONCAT(@whereClause, [JFW].[fn_GetFilterCriteria]('Modified_By', @Modified_By))
    SET @whereClause = CONCAT(@whereClause, [JFW].[fn_GetFilterCriteriaByDateRange]('Modified_Date', @Modified_Date_From, @Modified_Date_To))
    SET @whereClause = CONCAT(@whereClause, [JFW].[fn_GetFilterCriteria]('Created_By', @Created_By))
    SET @whereClause = CONCAT(@whereClause, [JFW].[fn_GetFilterCriteriaByDateRange]('Created_Date', @Created_Date_From, @Created_Date_To))

    -- Sets the SQL statement
    SET @sqlCommand = CONCAT('SELECT ', @limitClause, ' * FROM [${tableSchema}].[{{entityName}}] WHERE ', @whereClause, @orderByClause, @offsetClause)

    -- Sets the total rows
    SET @Total_Rows = (SELECT COUNT(*) FROM [${tableSchema}].[{{entityName}}] WHERE @whereClause)

    -- Executes the SQL statement
    EXEC sp_executesql @sqlCommand
END
GO
`;
