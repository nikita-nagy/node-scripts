CREATE SCHEMA [JFW]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--================================================================================================
-- Created by:   jin.jackson
-- Created date: 2023-02-23
-- Description:  This function generates a comma separated list of column aliases for a given table.  The column aliases are prefixed with the given prefix.
-- Example:      SELECT [JFW].[fn_GenerateColumnAliases]('BrandLink', 'BrandLink_', 'BL')
--================================================================================================
CREATE FUNCTION [JFW].[fn_GenerateColumnAliases]
(
    @tableName NVARCHAR(100), 
    @columnPrefix NVARCHAR(50),
    @tablePrefix NVARCHAR(100)
)

RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @sql NVARCHAR(MAX) = ''
	DECLARE @cols NVARCHAR(MAX) = ''

	SELECT @cols = @cols + ', ' + @tablePrefix + '.[' + COLUMN_NAME + '] AS [' + @columnPrefix + COLUMN_NAME + ']'
	FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = @tableName

	-- remove leading comma and space
	SET @cols = STUFF(@cols, 1, 1, '')

	RETURN @cols
END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



IF OBJECT_ID('[JFW].[fn_GetBrandId]') IS NOT NULL
	DROP FUNCTION [JFW].[fn_GetBrandId]
GO
--================================================================================================
-- Created by:   jin.jackson
-- Created date: 2023-03-06
-- Description:  This function returns the brand's ID based on the brand url
-- Example:      SELECT [JFW].[fn_GetBrandId]('http://www.jframework.live')
--================================================================================================
CREATE FUNCTION [JFW].[fn_GetBrandId]
(
	@pBrandURL nvarchar(1000)
)
RETURNS bigint
AS
BEGIN
	-- DECLARE the RETURN variable here
	DECLARE @Result BIGINT

	-- Add the T-SQL statements to compute the RETURN value here
	SELECT @Result = ISNULL(b.[ID], -1)
	FROM [JFW].[Brand] b
		LEFT JOIN [JFW].[BrandProfile] bp ON bp.[Brand_ID] = b.[ID]
		LEFT JOIN [JFW].[BrandSetting] bs ON bs.[Brand_ID] = b.[ID]
	WHERE bp.[Website] LIKE CONCAT('%',@pBrandURL,'%')
		OR bs.[Website_CPanel] LIKE CONCAT('%',@pBrandURL,'%')
		OR bs.[Website_Admin_Tool] LIKE CONCAT('%',@pBrandURL,'%')
		OR bs.[Website_Admin_Tool_2] LIKE CONCAT('%',@pBrandURL,'%')
		OR bs.[Website_Admin_Tool_3] LIKE CONCAT('%',@pBrandURL,'%')
		OR bs.[Website_Protocol] LIKE CONCAT('%',@pBrandURL,'%')
		OR bs.[Domain_WhiteList] LIKE CONCAT('%',@pBrandURL,'%')

	-- Return the result of the function
	RETURN @Result
END
GO

-- fn_GetLimitClause
---================================================================================================
-- Created by:   jin.jackson
-- Created date: 2023-04-28
-- Description:  This function returns the limit clause.
-- Example:      SELECT [JFW].[fn_GetLimitClause](10)
--================================================================================================
CREATE FUNCTION [JFW].[fn_GetLimitClause]
(
	@pLimit INT
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @vLimitClause NVARCHAR(MAX) = ''

	IF(@pLimit IS NOT NULL)
		SELECT @vLimitClause = CONCAT('TOP ', @pLimit, ' ')

	RETURN @vLimitClause
END
GO

-- fn_GetOrderByClause
---================================================================================================
-- Created by:   jin.jackson
-- Created date: 2023-04-28
-- Description:  This function returns the order by clause.
-- Example:      SELECT [JFW].[fn_GetOrderByClause]('Brand_ID', 'DESC')
--================================================================================================
CREATE FUNCTION [JFW].[fn_GetOrderByClause]
(
	@pOrderByColumn NVARCHAR(100),
	@pOrderByDirection NVARCHAR(4)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @vOrderByClause NVARCHAR(MAX) = ''

	IF(@pOrderByColumn IS NOT NULL)
		SELECT @vOrderByClause = CONCAT('ORDER BY ', @pOrderByColumn, ' ', @pOrderByDirection, ' ')

	RETURN @vOrderByClause
END
GO

-- fn_GetOffsetClause
---================================================================================================
-- Created by:   jin.jackson
-- Created date: 2023-04-28
-- Description:  This function returns the offset clause.
-- Example:      SELECT [JFW].[fn_GetOffsetClause](10, 20)
--================================================================================================
CREATE FUNCTION [JFW].[fn_GetOffsetClause]
(
	@pPageNumber INT,
	@pPageSize INT
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @vOffsetClause NVARCHAR(MAX) = ''

	IF(@pPageNumber IS NOT NULL AND @pPageSize IS NOT NULL)
		SELECT @vOffsetClause = CONCAT('OFFSET ', @pPageNumber, ' ROWS FETCH NEXT ', @pPageSize, ' ROWS ONLY ')

	RETURN @vOffsetClause
END
GO

-- fn_GetFilterCriteria
---================================================================================================
-- Created by:   jin.jackson
-- Created date: 2023-04-28
-- Description:  This function returns the where clause for filtering.
-- Example:      SELECT [JFW].[fn_GetFilterCriteria]('Brand_ID', 1)
--================================================================================================
CREATE FUNCTION [JFW].[fn_GetFilterCriteria]
(
	@pColumnName NVARCHAR(100),
	@pColumnValue NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @vWhereClause NVARCHAR(MAX) = ''

	IF(@pColumnName IS NOT NULL AND @pColumnName <> '')
	BEGIN
		IF (@pColumnValue IS NOT NULL AND @pColumnValue <> '')
		BEGIN
			-- If the column value is a string, then add single quotes around it
			IF (ISNUMERIC(@pColumnValue) = 0)
				SELECT @vWhereClause = CONCAT(' AND [', @pColumnName, '] = ''', @pColumnValue, ''' ')
			ELSE
				SELECT @vWhereClause = CONCAT(' AND [', @pColumnName, '] = ', @pColumnValue, ' ')
		END
	END
	RETURN @vWhereClause
END
GO

--fn_GetFilterCriteriaByDateRange
---================================================================================================
-- Created by:   jin.jackson
-- Created date: 2023-04-28
-- Description:  This function returns the where clause for filtering by date range.
-- Example:      SELECT [JFW].[fn_GetFilterCriteriaByDateRange]('Created_Date', '2019-01-01', '2019-12-31')
--================================================================================================
CREATE FUNCTION [JFW].[fn_GetFilterCriteriaByDateRange]
(
	@pColumnName NVARCHAR(100),
	@pStartDate DATETIME,
	@pEndDate DATETIME
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @vWhereClause NVARCHAR(MAX) = ''

	IF(@pColumnName IS NOT NULL AND @pColumnName <> '')
	BEGIN
		-- Checks if the start date is not null
		IF(@pStartDate IS NOT NULL AND @pStartDate <> '')
			SELECT @vWhereClause = CONCAT(@vWhereClause, ' AND [', @pColumnName, '] >= ''', @pStartDate, ''' ')

		-- Checks if the end date is not null
		IF(@pEndDate IS NOT NULL AND @pEndDate <> '')
			SELECT @vWhereClause = CONCAT(@vWhereClause, ' AND [', @pColumnName, '] <= ''', @pEndDate, ''' ')
	END

	RETURN @vWhereClause
END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--================================================================================================
-- Created by:    jin.jackson
-- Created date:  2023-02-23
-- Description:   This function returns the default value of a parameter of a stored procedure or function
-- Example:       SELECT [JFW].[fn_GetParameterDefaultValue]('[JFW].[usp_Brand_GetBrandIdByUrl]', 'Brand_URL', 'NVARCHAR(1000)')
--================================================================================================
-- CREATE FUNCTION [JFW].[fn_GetParameterDefaultValue]
ALTER FUNCTION [JFW].[fn_GetParameterDefaultValue]
(  
    @pSPName varchar(1000)='',
    @pParameterName varchar(100),
    @pDataType varchar(100),
    @pType bit=0 --0 for Stored Procedure and 1 for Function
)
RETURNS varchar(1000)
AS
BEGIN
	DECLARE @pOutPut varchar(1000)
	DECLARE @vStartPosition int
	DECLARE @vStartPosition2 int
	DECLARE @vStartPosition3 int
	DECLARE @vStartPosition4 int
	DECLARE @vStartPosition5 int
	DECLARE @vSPText varchar(max)
	DECLARE @vSPText2 varchar(max)


	-- Get the text fro syscomments (first 4000 characters IF length of SP is > 4000)
	IF @pType = 0
    BEGIN
		SELECT @vSPtext = (SELECT text
			FROM syscomments
			WHERE id = object_id(@pSPName) and colid=1 and number = 1)

		SET @vSPtext = SubString(@vSPtext,CharIndex('CREATE PROCEDURE',@vSPtext),4000)
	END
    ELSE
        SELECT @vSPtext = (SELECT text
		FROM syscomments
		WHERE id = object_id(@pSPName) and colid=1 and number = 0)

	SET @vSPtext = SubString(@vSPtext,CharIndex('CREATE FUNCTION',@vSPtext),4000)

	IF IsNull(@vSPtext,'') = ''
    BEGIN
		-- Exit IF SP Name Not found in syscomments....
		SELECT @pOutPut = ''
		RETURN @pOutPut
	END

	SET @pOutPut = ''

	WHILE 1=1
    BEGIN
		-- Get the position of the parameter definition. 
		SELECT @vStartPosition = PatIndex('%' + @pParameterName + '%',@vSPText)
		-- Check IF parameter exists
		IF @vStartPosition > 0
        BEGIN
			-- Get the Definition String
			SELECT @vSPText = RIGHT ( @vSPText, DataLength(@vSPText)-(@vStartPosition -1))

			-- Get the string breaker
			IF (CharIndex(',',@vSPText) > 0) or (CharIndex('-',@vSPText) > 0)
				or (CharIndex(Char(10),@vSPText) > 0) or (CharIndex('AS',@vSPText) > 0)
            BEGIN
				SET @vStartPosition = CharIndex(',',@vSPText,Len(@pParameterName))-1
				SET @vStartPosition2 = CharIndex('-',@vSPText,Len(@pParameterName))-1
				SET @vStartPosition3 = CharIndex(Char(10),@vSPText,Len(@pParameterName))-1
				SET @vStartPosition4 = CharIndex('AS',@vSPText,Len(@pParameterName))-1
				SET @vStartPosition5 = CharIndex('OUT',@vSPText,Len(@pParameterName)) -1

				IF @vStartPosition <= (Len(@pParameterName) + Len(@pDataType) + case when CharIndex('AS',@vSPText) between CharIndex(@pParameterName,@vSPText) And CharIndex(@pDataType,@vSPText) then 2 ELSE 0 END)
                    SET @vStartPosition = 10000000

				IF @vStartPosition2 <= (Len(@pParameterName) + Len(@pDataType) + case when CharIndex('AS',@vSPText) between CharIndex(@pParameterName,@vSPText) And CharIndex(@pDataType,@vSPText) then 2 ELSE 0 END)
                    SET @vStartPosition2 = 10000000

				IF @vStartPosition3 <= (Len(@pParameterName) + Len(@pDataType) + case when CharIndex('AS',@vSPText) between CharIndex(@pParameterName,@vSPText) And CharIndex(@pDataType,@vSPText) then 2 ELSE 0 END)
                    SET @vStartPosition3 = 10000000

				IF @vStartPosition4 <= (Len(@pParameterName) + Len(@pDataType) + case when CharIndex('AS',@vSPText) between CharIndex(@pParameterName,@vSPText) And CharIndex(@pDataType,@vSPText) then 2 ELSE 0 END)
                    SET @vStartPosition4 = 10000000

				IF @vStartPosition5 <= (Len(@pParameterName) + Len(@pDataType) + case when CharIndex('AS',@vSPText) between CharIndex(@pParameterName,@vSPText) And CharIndex(@pDataType,@vSPText) then 2 ELSE 0 END)
                    SET @vStartPosition5 = 10000000

				SELECT TOP 1
					@vStartPosition = [tvalue]
				FROM [JFW].[fn_Split](Cast(@vStartPosition as varchar(10)) + ',' + Cast(@vStartPosition2 as varchar(10)) 
                                + ',' + Cast(@vStartPosition3 as varchar(10)) 
                                + ',' + Cast(@vStartPosition4 as varchar(10)) 
                                + ',' + Cast(@vStartPosition5 as varchar(10)) ,',')
				ORDER BY Cast([tvalue] AS INT)
			END
            ELSE
            BEGIN
				-- SP text must atleast have AS to break the parameter definition string
				SET @vStartPosition = CharIndex('AS',@vSPText) - 1
			END

			-- Get the specific Definition String
			SET @vSPText2 = Left(@vSPText,@vStartPosition)

			-- Check IF you got the right one by data type...            
			IF CharIndex(@pDataType,@vSPText2) > 0
            BEGIN
				--SELECT 'IN'
				--SELECT @text2
				IF CharIndex('=',@vSPText2) > 0 
                BEGIN
					-- check the default value
					SELECT @pOutPut = Right(@vSPText2,DataLength(@vSPText2) - CharIndex('=',@vSPText2))
					-- We have default value assigned here

					IF Right(@pOutPut,1) = ','
                        SET @pOutPut = Left(@pOutPut,DataLength(@pOutPut)-1)
				END
                ELSE
                BEGIN
					--SET @pOutPut = 'No Default Value Defined...'
					-- We DO NOT have default value assigned here
					SET @pOutPut = ''
				END
				--No need to work further with this parameter
				BREAK
			END
            ELSE 
            BEGIN
				--SET @vSPText = SubString(@vSPText,@vStartPosition + Len(@vSPText2),4000)
				-- Cut the SP text short and loop again
				SET @vSPText = SubString(@vSPText,@vStartPosition,4000)
			END
			-- This should never be the case. Just a check....
			IF Datalength(@vSPText) < Datalength(@pParameterName)
                BREAK
		END
        ELSE
        BEGIN
			--SET @pOutPut = 'Parameter Not Found...'
			-- Wrong parameter search...
			SET @pOutPut = ''
			BREAK
		END
	END
	SELECT @pOutPut = rtrim(ltrim(@pOutPut))
	RETURN @pOutPut
END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--================================================================================================
-- Created by:   jin.jackson
-- Created date: 2022-05-15
-- Description:  This function returns the search query for the table view
-- Example:      SELECT * FROM [JFW].[fn_GetTableViewSearchQuery]('JFW','User','')
--================================================================================================
CREATE FUNCTION [JFW].[fn_GetTableViewSearchQuery]
(
    @pSchemaName varchar(128) = 'JFW',
    @pTableName varchar(MAX) = '',
    @pSearchString varchar(100)
)
RETURNS varchar(MAX)
AS
    BEGIN
	DECLARE @pOutPut varchar(MAX)
	IF @pSchemaName = '' OR @pSchemaName IS NULL
        BEGIN
		SET @pOutPut = 'SELECT * FROM [' + @pTableName + '] WHERE 1 = 2 '
	END
    ELSE
        BEGIN
		SET @pOutPut = 'SELECT * FROM ['+ @pSchemaName + '].[' + @pTableName + '] WHERE 1 = 2 '
	END
	SELECT
		@pOutPut = @pOutPut + ' OR [' + SYSCOLUMNS.NAME + '] LIKE ''%' + @pSearchString + '%'' '
	FROM SYSCOLUMNS
	WHERE OBJECT_NAME(id) = @pTableName
		AND TYPE_NAME(SYSCOLUMNS.XTYPE) IN ('VARCHAR','NVARCHAR','CHAR','NCHAR')
	ORDER BY COLID

	RETURN @pOutPut
END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--================================================================================================
-- Created by:   jin.jackson
-- Created date: 2022-05-15
-- Description:  This function splits the string based on the split character
-- Example:      SELECT * FROM [JFW].[fn_Split]('1,2,3,4,5',',')
--================================================================================================
CREATE FUNCTION [JFW].[fn_Split]
(
    @pString nvarchar(max), 
    @pSplitChar char(1)
)

returns @tblTemp table (tid int,
	tvalue varchar(1000))
as

BEGIN
	DECLARE @vStartPosition int
	DECLARE @vSplitPosition int
	DECLARE @vSplitValue varchar(1000)
	DECLARE @vCounter int
	SET @vCounter=1
	SELECT @vStartPosition = 1, @vSplitPosition=0
	SET @vSplitPosition = charindex( @pSplitChar , @pString , @vStartPosition )
	IF (@vSplitPosition=0 and len(@pString) != 0)
    BEGIN
		INSERT INTO @tblTemp
			(tid, tvalue)
		VALUES(1, @pString)
		RETURN--------------------------------------------------------------->>
	END

	SET @pString=@pString+@pSplitChar
	WHILE (@vSplitPosition > 0 )
    BEGIN
		SET @vSplitValue = substring( @pString , @vStartPosition , @vSplitPosition - @vStartPosition )
		SET @vSplitValue = ltrim(rtrim(@vSplitValue))
		INSERT INTO @tblTemp
			(tid, tvalue)
		VALUES
			(@vCounter, @vSplitValue)

		SET @vCounter=@vCounter+1
		SET @vStartPosition = @vSplitPosition + 1
		SET @vSplitPosition = charindex( @pSplitChar , @pString , @vStartPosition )
	END
	RETURN
END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[Activity]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[User_ID] [bigint] NOT NULL,
	[Device_ID] [bigint] NULL,
	[Tracking_Action_ID] [bigint] NOT NULL,
	[URL] [nvarchar](1000) NULL,
	[IP_Address] [varchar](20) NULL,
	[OS] [nvarchar](50) NULL,
	[Browser_Name] [nvarchar](50) NULL,
	[Browser_Version] [nvarchar](50) NULL,
	[Request_From_Mobile] [bit] NULL CONSTRAINT [DF_Activity_RequestFromMobile]  DEFAULT ((0)),
	[User_Agent] [nvarchar](500) NULL,
	[Location] [nvarchar](250) NULL,
	[Latitude] [float] NULL,
	[Longitude] [float] NULL,
	[Description] [nvarchar](1000) NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_Activity_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_Activity_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_Activity] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [JFW].[BlackList]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Block_Type] [int] NULL,
	[Values] [nvarchar](50) NULL,
	[Description] [nvarchar](500) NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL,
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL,
	CONSTRAINT [PK_BlackList] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[Brand]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Parent_ID] [bigint] NULL,
	[Brand_Code] [varchar](50) NOT NULL,
	[Is_Default] [bit] NOT NULL CONSTRAINT [DF_Brand_IsDefault]  DEFAULT ((0)),
	[Is_System] [bit] NOT NULL CONSTRAINT [DF_Brand_IsSystem]  DEFAULT ((0)),
	[Status] [smallint] NOT NULL CONSTRAINT [DF_Brand_Status]  DEFAULT ((1)),
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_Brand_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_Brand_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_Brand] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
	CONSTRAINT [UK_Brand_BrandCode] UNIQUE NONCLUSTERED 
(
	[Brand_Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[BrandEmail]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Brand_ID] [bigint] NOT NULL,
	[Email_Support] [varchar](150) NULL,
	[Email_Support_Title] [nvarchar](500) NULL,
	[System_Email] [varchar](150) NULL,
	[System_Email_Title] [nvarchar](500) NULL,
	[Login_Notification_Emails] [varchar](150) NULL,
	[Purchase_Notification_Emails] [varchar](150) NULL,
	[Order_Notification_Emails] [varchar](150) NULL,
	[Refund_Notification_Emails] [varchar](150) NULL,
	[Chargeback_Notification_Emails] [varchar](150) NULL,
	[Developer_Team_Emails] [varchar](150) NULL,
	[Maintenance_Team_Emails] [varchar](150) NULL,
	[System_Admin_Notification_Emails] [varchar](150) NULL,
	[System_Admin_Emails] [varchar](150) NULL,
	[Bcc_Notification_Emails] [varchar](150) NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_BrandEmail_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_BrandEmail_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_BrandEmail] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
	CONSTRAINT [UK_BrandEmail_BrandId] UNIQUE NONCLUSTERED 
(
	[Brand_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [JFW].[BrandLink]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Brand_ID] [bigint] NOT NULL,
	[Website_Android_Download] [nvarchar](500) NULL,
	[Website_iOS_Download] [nvarchar](500) NULL,
	[Website_Affiliate] [nvarchar](500) NULL,
	[Website_Support] [nvarchar](500) NULL,
	[Website_Forum] [nvarchar](500) NULL,
	[Website_Blog] [nvarchar](500) NULL,
	[Link_How_To_Jailbreak_An_iOS_Device] [nvarchar](500) NULL,
	[Link_Essential_Settings_Android] [nvarchar](500) NULL,
	[Link_Essential_Settings_iOS] [nvarchar](500) NULL,
	[Link_Prices] [nvarchar](500) NULL,
	[Link_How_To_Add_Device_iOS] [nvarchar](500) NULL,
	[Link_How_To_Add_Devices_Android] [nvarchar](500) NULL,
	[Link_Term_Of_Uses] [nvarchar](500) NULL,
	[Link_Brand_Terms_And_Conditions] [nvarchar](500) NULL,
	[Link_FAQ] [nvarchar](500) NULL,
	[Link_Contact_Us] [nvarchar](500) NULL,
	[Link_Forum] [nvarchar](500) NULL,
	[Link_Blog] [nvarchar](500) NULL,
	[Link_How_To_Root_An_Android] [nvarchar](500) NULL,
	[Link_Extra_Notes_For_Useful_Links] [nvarchar](500) NULL,
	[Link_Refund_Policy] [nvarchar](500) NULL,
	[Link_Help_Protected_App] [nvarchar](500) NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_BrandLink_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_BrandLink_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_BrandLink] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
	CONSTRAINT [UK_BrandLink_BrandId] UNIQUE NONCLUSTERED 
(
	[Brand_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [JFW].[BrandProfile]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Brand_ID] [bigint] NOT NULL,
	[Company_Name] [nvarchar](100) NULL,
	[Website] [nvarchar](100) NULL,
	[Logo_Image_Path] [nvarchar](500) NULL,
	[Shortcut_Icon_Path] [nvarchar](500) NULL,
	[Tags] [nvarchar](max) NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_BrandProfile_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_BrandProfile_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_BrandProfile] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
	CONSTRAINT [UK_BrandProfile_BrandId] UNIQUE NONCLUSTERED 
(
	[Brand_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[BrandSetting]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Brand_ID] [bigint] NOT NULL,
	[Default_Package_ID] [bigint] NULL,
	[Default_SubscriptionType_ID] [bigint] NULL,
	[Smtp_Setting_ID] [bigint] NULL,
	[Product_Website] [nvarchar](100) NULL,
	[Product_Name] [nvarchar](50) NULL,
	[Product_Alias] [nvarchar](50) NULL,
	[Product_Prefix_Name] [nvarchar](50) NULL,
	[Website_CPanel] [nvarchar](500) NULL,
	[Website_Admin_Tool] [nvarchar](500) NULL,
	[Website_Admin_Tool_2] [nvarchar](500) NULL,
	[Website_Admin_Tool_3] [nvarchar](500) NULL,
	[Website_Protocol] [nvarchar](500) NULL,
	[Domain_WhiteList] [nvarchar](4000) NULL,
	[Google_Analytics_Account] [varchar](50) NULL,
	[Google_Account_Used_For_Google_Analytics] [varchar](150) NULL,
	[Cdn_Url] [nvarchar](255) NULL,
	[Cdn_Folder] [nvarchar](255) NULL,
	[Bundle_Identifier] [nvarchar](250) NULL,
	[Author_Name] [nvarchar](100) NULL,
	[App_Description] [nvarchar](250) NULL,
	[App_Version] [varchar](20) NULL,
	[Access_Code] [varchar](20) NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_BrandSetting_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_BrandSetting_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_BrandSetting] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
	CONSTRAINT [UK_BrandSetting_BrandId] UNIQUE NONCLUSTERED 
(
	[Brand_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[City]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Country_Code] [varchar](2) NULL,
	[State_Code] [varchar](5) NULL,
	[Name] [nvarchar](max) NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_City_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_City_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_City] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[Configuration]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Group_Code] [varchar](100) NOT NULL,
	[Code] [varchar](100) NOT NULL,
	[Name] [varchar](100) NOT NULL,
	[Description] [nvarchar](240) NULL,
	[Value] [nvarchar](max) NULL,
	[Status] [smallint] NOT NULL CONSTRAINT [DF_Configuration_Status]  DEFAULT ((1)),
	[Is_System] [bit] NOT NULL CONSTRAINT [DF_Configuration_IsSystem]  DEFAULT ((0)),
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_Configuration_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_Configuration_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_Configuration] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[Country]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Region] [nvarchar](50) NULL,
	[Subregion] [nvarchar](50) NULL,
	[Name] [nvarchar](50) NOT NULL,
	[ISO3166] [varchar](2) NOT NULL,
	[ISO3] [varchar](3) NOT NULL,
	[Numeric_Code] [smallint] NOT NULL,
	[Phone_Code] [nvarchar](50) NOT NULL,
	[Capital] [nvarchar](50) NULL,
	[Currency] [varchar](3) NOT NULL,
	[Tld] [nvarchar](50) NOT NULL,
	[Native] [nvarchar](100) NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_Country_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_Country_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_Country] PRIMARY KEY CLUSTERED 
(
	[ID] ASC,
	[ISO3166] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[Coupon]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Brand_ID] [bigint] NOT NULL,
	[Coupon_Code] [varchar](50) NULL,
	[Description] [nvarchar](250) NULL,
	[Coupon_Percent] [float] NULL,
	[Quantity] [int] NULL,
	[Start_Date] [datetime] NULL,
	[End_Date] [datetime] NULL,
	[Auto_Apply_To_Price] [bit] NULL,
	[Status] [smallint] NOT NULL CONSTRAINT [DF_Coupon_Status]  DEFAULT ((1)),
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_Coupon_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_Coupon_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_Coupon] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [JFW].[CouponUser]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Coupon_ID] [bigint] NOT NULL,
	[User_ID] [bigint] NOT NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL,
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL,
	CONSTRAINT [PK_CouponUser] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[Currency]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](20) NOT NULL,
	[Code] [varchar](3) NOT NULL,
	[Symbol] [varchar](5) NULL,
	[Is_Default] [bit] NOT NULL CONSTRAINT [DF_Currency_IsDefault]  DEFAULT ((0)),
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_Currency_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_Currency_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_Currency] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
	CONSTRAINT [UK_Currency_Code] UNIQUE NONCLUSTERED 
(
	[Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[Device]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[User_ID] [bigint] NOT NULL,
	[Device_Identifier] [varchar](100) NULL,
	[Device_Token] [varchar](250) NULL,
	[Device_Session] [varchar](100) NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_Device_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_Device_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_Device] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[DeviceProfile]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Device_ID] [bigint] NOT NULL,
	[Device_Name] [nvarchar](100) NULL,
	[Phone_Number] [varchar](50) NULL,
	[OS_Device] [nvarchar](50) NULL,
	[App_Version_Number] [varchar](20) NULL,
	[ICCID] [varchar](50) NULL,
	[IMSI] [varchar](50) NULL,
	[IMEI] [varchar](50) NULL,
	[SimCard_Info] [varchar](50) NULL,
	[Country_ID] [bigint] NULL,
	[TimeZone_ID] [bigint] NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_DeviceProfile_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_DeviceProfile_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_DeviceProfile] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[EmailTracking]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Brand_ID] [bigint] NOT NULL,
	[Support_Code] [varchar](150) NULL,
	[Pattern_Code] [varchar](150) NULL,
	[Email_From] [varchar](500) NULL,
	[Email_To] [varchar](max) NULL,
	[Email_CC] [varchar](max) NULL,
	[Email_BCC] [varchar](max) NULL,
	[Email_Subject] [nvarchar](1024) NULL,
	[Email_Body] [nvarchar](max) NULL,
	[Sent_Time] [datetime] NULL,
	[Status] [smallint] NOT NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_EmailTracking_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_EmailTracking_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_EmailTracking] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[Event]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Group_Code] [varchar](150) NULL,
	[Code] [varchar](150) NULL,
	[Name] [nvarchar](500) NULL,
	[Description] [nvarchar](2048) NULL,
	[ZOrder] [bigint] NULL,
	[Status] [smallint] NOT NULL,
	[Is_System] [bit] NOT NULL CONSTRAINT [DF_Pattern_IsSystem]  DEFAULT ((0)),
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_Pattern_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_Pattern_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_Pattern] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [JFW].[EventPattern]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Pattern_ID] [bigint] NOT NULL,
	[Country_ID] [bigint] NOT NULL,
	[Subject] [nvarchar](max) NULL,
	[Content] [nvarchar](max) NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_PatternContent_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_PatternContent_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_PatternMapping] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[ExternalProvider]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Code] [varchar](50) NULL,
	[Name] [varchar](50) NOT NULL,
	[Description] [nvarchar](250) NULL,
	[Client_ID] [varchar](200) NOT NULL,
	[Client_Secret] [varchar](200) NOT NULL,
	[Redirect_Uri] [nvarchar](100) NOT NULL,
	[Scope] [nvarchar](200) NULL,
	[Auth_Endpoint] [nvarchar](200) NULL,
	[Token_Endpoint] [nvarchar](200) NULL,
	[Icon_Url] [nvarchar](200) NULL,
	[Status] [smallint] NOT NULL CONSTRAINT [DF_ExternalProvider_Status]  DEFAULT ((1)),
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_ExternalProvider_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_ExternalProvider_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_ExternalProvider] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [JFW].[Feature]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Code] [nvarchar](255) NOT NULL,
	[Name] [nvarchar](255) NOT NULL,
	[Description] [nvarchar](1000) NULL,
	[Feature_Value] [int] NULL,
	[Is_Beta] [bit] NULL,
	[OS_Available] [nvarchar](255) NULL,
	[Root_Access_Required] [bit] NULL,
	[Display_Data_Even_Expired] [bit] NULL,
	[Tooltip] [nvarchar](1000) NULL,
	[Public_Note] [nvarchar](max) NULL,
	[ZOrder] [bigint] NULL,
	[Status] [smallint] NOT NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_Feature_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_Feature_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_Feature] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[HelpDesk]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Parent_ID] [bigint] NULL,
	[Group_Code] [varchar](100) NULL,
	[Code] [varchar](100) NULL,
	[Name] [varchar](250) NULL,
	[Description] [nvarchar](500) NULL,
	[Content] [nvarchar](max) NULL,
	[Positive] [bigint] NULL,
	[Negative] [bigint] NULL,
	[Total_View] [bigint] NULL,
	[ZOrder] [bigint] NULL,
	[Status] [smallint] NOT NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL,
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL,
	CONSTRAINT [PK_HelpDesk] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [JFW].[HelpDeskFeedback]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Brand_ID] [bigint] NOT NULL,
	[User_ID] [bigint] NOT NULL,
	[Help_Desk_ID] [bigint] NOT NULL,
	[Priority] [tinyint] NULL,
	[Feedback_Content] [nvarchar](max) NULL,
	[Status] [smallint] NOT NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL,
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL,
	CONSTRAINT [PK_HelpDeskFeedback] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[License]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Brand_ID] [bigint] NOT NULL,
	[Package_ID] [bigint] NOT NULL,
	[SubscriptionType_ID] [bigint] NOT NULL,
	[License_Key] [varchar](30) NOT NULL,
	[Source_ID] [tinyint] NOT NULL,
	[Ref_License] [varchar](30) NOT NULL,
	[Description] [nvarchar](255) NULL,
	[Start_Date] [datetime] NOT NULL,
	[End_Date] [datetime] NOT NULL,
	[Status] [smallint] NOT NULL,
	[Used_By] [bigint] NULL,
	[Used_Date] [datetime] NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_License_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_License_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_License] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[Merchant]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Merchant_Type] [smallint] NOT NULL,
	[Code] [varchar](50) NOT NULL,
	[Name] [nvarchar](50) NULL,
	[Description] [nvarchar](500) NULL,
	[Website] [nvarchar](250) NULL,
	[ZOrder] [bigint] NULL,
	[Status] [smallint] NOT NULL,
	[Is_Default] [bit] NOT NULL CONSTRAINT [DF_Merchant_IsDefault]  DEFAULT ((0)),
	[Is_System] [bit] NOT NULL CONSTRAINT [DF_Merchant_IsSystem]  DEFAULT ((0)),
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_Merchant_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_Merchant_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_Merchant] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[Package]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Code] [varchar](50) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[Description] [nvarchar](4000) NULL,
	[ZOrder] [bigint] NULL,
	[Status] [smallint] NOT NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_Package_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_Package_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_Package] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [JFW].[PackageFeature]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Package_ID] [bigint] NOT NULL,
	[Feature_ID] [bigint] NOT NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_PackageFeature_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_PackageFeature_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_PackageFeature] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
	CONSTRAINT [UK_PackageFeature] UNIQUE NONCLUSTERED 
(
	[Package_ID] ASC,
	[Feature_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[Payment]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Brand_ID] [bigint] NOT NULL,
	[Merchant_ID] [bigint] NOT NULL,
	[Price_ID] [bigint] NULL,
	[Coupon_ID] [bigint] NULL,
	[User_ID] [bigint] NOT NULL,
	[Payment_Type] [varchar](50) NULL,
	[Payment_Date] [datetime] NULL,
	[Completed_Date] [datetime] NULL,
	[Invoice_No] [varchar](50) NULL,
	[Description] [nvarchar](max) NULL,
	[Amount] [float] NULL,
	[Amount_Fee] [float] NULL,
	[Status] [smallint] NOT NULL,
	[Merchant_Ref_No] [varchar](100) NULL,
	[Merchant_Account_Buyer] [varchar](150) NULL,
	[Merchant_Account_Seller] [varchar](150) NULL,
	[IP_Address] [varchar](50) NULL,
	[Notes] [nvarchar](1000) NULL,
	[Risk_Mark] [tinyint] NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_Payment_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_Payment_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_Payment] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [JFW].[PaymentHistory]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[User_ID] [bigint] NOT NULL,
	[Payment_ID] [bigint] NOT NULL,
	[Payment_Status] [smallint] NULL,
	[Notes] [nvarchar](max) NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_PaymentHistory_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_PaymentHistory_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_PaymentHistory] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[PaymentMethod]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Brand_ID] [bigint] NOT NULL,
	[Payment_Merchant_ID] [bigint] NOT NULL,
	[Payment_Info] [varchar](150) NULL,
	[Ipn_Listener_Link] [nvarchar](1000) NULL,
	[Cancel_Link_Without_Login] [nvarchar](1000) NULL,
	[Cancel_Link] [nvarchar](1000) NULL,
	[Return_Link] [nvarchar](1000) NULL,
	[Public_Key] [varchar](150) NULL,
	[Private_Key] [varchar](150) NULL,
	[Interal_Note] [nvarchar](max) NULL,
	[ZOrder] [bigint] NULL,
	[Status] [smallint] NOT NULL,
	[Is_Default] [bit] NOT NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL,
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL,
	CONSTRAINT [PK_PaymentMethod] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [JFW].[Permission]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NULL,
	[Description] [nvarchar](500) NULL,
	[Is_System] [bit] NOT NULL CONSTRAINT [DF_Permission_IsSystem]  DEFAULT ((0)),
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_Permission_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_Permission_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_Permission] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[PointHistory]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[User_ID] [bigint] NOT NULL,
	[Amount] [int] NOT NULL,
	[Changed_Type] [tinyint] NULL,
	[Reason] [varchar](255) NOT NULL,
	[Reference] [varchar](255) NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL,
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL,
	CONSTRAINT [PK_PointHistory] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[Price]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Payment_Method_ID] [bigint] NOT NULL,
	[Package_ID] [bigint] NOT NULL,
	[Subscription_Type_ID] [bigint] NOT NULL,
	[Code] [varchar](50) NOT NULL,
	[Name] [nvarchar](50) NULL,
	[Description] [nvarchar](1000) NULL,
	[Amount] [float] NULL,
	[Currency] [varchar](3) NULL,
	[Checkout_Link] [nvarchar](1000) NULL,
	[ZOrder] [bigint] NULL,
	[Status] [smallint] NOT NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_Price_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_Price_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_Price] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[Reward]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Brand_ID] [bigint] NOT NULL,
	[Name] [varchar](255) NOT NULL,
	[Description] [varchar](max) NOT NULL,
	[Point_Value] [int] NOT NULL,
	[Redemption_Instructions] [varchar](max) NULL,
	[Required_Level] [int] NULL,
	[Expiration_Date] [datetime] NULL,
	[ZOrder] [bigint] NULL,
	[Status] [smallint] NOT NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL,
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL,
	CONSTRAINT [PK_Reward] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [JFW].[Role]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](250) NOT NULL,
	[Description] [nvarchar](500) NULL,
	[Is_System] [bit] NOT NULL CONSTRAINT [DF_Role_IsSystem]  DEFAULT ((0)),
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_Role_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_Role_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_Role] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [JFW].[RolePermission]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Role_ID] [bigint] NOT NULL,
	[Permission_ID] [bigint] NOT NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_RolePermission_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_RolePermission_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_RolePermission] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[SmtpSetting]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](200) NOT NULL,
	[SMTP_Host] [varchar](100) NOT NULL,
	[SMTP_Port] [int] NOT NULL,
	[SMTP_Username] [varchar](255) NOT NULL,
	[SMTP_Password] [varchar](255) NOT NULL,
	[Description] [nvarchar](1000) NULL,
	[Use_TLS] [bit] NULL,
	[Is_Default] [bit] NOT NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL,
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL,
	CONSTRAINT [PK_SmtpSetting] PRIMARY KEY CLUSTERED 
(
	[ID] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[State]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Country_Code] [varchar](2) NOT NULL,
	[Code] [varchar](5) NOT NULL,
	[Name] [nvarchar](200) NOT NULL,
	[State_Type] [nvarchar](max) NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_State_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_State_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_State] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [JFW].[SubscriptionType]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](500) NOT NULL,
	[Description] [nvarchar](500) NULL,
	[Number_Of_Days] [smallint] NOT NULL,
	[Is_Default] [bit] NOT NULL,
	[ZOrder] [bigint] NULL,
	[Status] [smallint] NOT NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_SubscriptionType_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_SubscriptionType_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_SubscriptionType] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[TimeZone]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[ISO3166] [varchar](2) NULL,
	[Name] [nvarchar](250) NULL,
	[Value] [nvarchar](250) NULL,
	[Description] [nvarchar](500) NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL,
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[TrackingAction]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Code] [varchar](250) NOT NULL,
	[Name] [nvarchar](250) NOT NULL,
	[Tracking_Level] [smallint] NOT NULL,
	[Description] [nvarchar](1000) NULL,
	[Is_System] [bit] NOT NULL CONSTRAINT [DF_TrackingAction_IsSystem]  DEFAULT ((0)),
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_TrackingAction_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_TrackingAction_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_TrackingAction] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[User]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Parent_ID] [bigint] NULL,
	[Brand_ID] [bigint] NOT NULL,
	[User_Code] [varchar](100) NOT NULL,
	[Username] [varchar](150) NOT NULL,
	[Password] [varchar](150) NOT NULL,
	[Passphrase] [varchar](6) NULL,
	[User_Type] [smallint] NULL CONSTRAINT [DF_User_Type]  DEFAULT ((1)),
	[Is_Email_Address_Verified] [bit] NULL CONSTRAINT [DF_User_IsEmailAddressVerified]  DEFAULT ((0)),
	[Is_User_Verified] [bit] NULL CONSTRAINT [DF_User_IsUserVerified]  DEFAULT ((0)),
	[Is_System] [bit] NOT NULL CONSTRAINT [DF_User_IsSystem]  DEFAULT ((0)),
	[Risk_Mark] [tinyint] NULL CONSTRAINT [DF_User_RiskMark]  DEFAULT ((0)),
	[Status] [smallint] NOT NULL CONSTRAINT [DF_User_Status]  DEFAULT ((0)),
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_User_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_User_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_User] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
	CONSTRAINT [UK_User_UserCode] UNIQUE NONCLUSTERED 
(
	[User_Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
	CONSTRAINT [UK_User_Username] UNIQUE NONCLUSTERED 
(
	[Brand_ID] ASC,
	[Username] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[UserAddress]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[User_ID] [bigint] NOT NULL,
	[Address] [nvarchar](250) NULL,
	[Country_ID] [bigint] NULL,
	[State_ID] [bigint] NULL,
	[City_ID] [bigint] NULL,
	[Postal_Code] [varchar](50) NULL,
	[Is_Default] [bit] NOT NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL,
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL,
	CONSTRAINT [PK_Address] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[UserExternalLogin]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[User_ID] [bigint] NOT NULL,
	[External_Provider_ID] [bigint] NOT NULL,
	[External_User_ID] [varchar](50) NOT NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_UserExternalLogin_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_UserExternalLogin_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_UserExternalLogin] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[UserNotification]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Brand_ID] [bigint] NULL,
	[User_ID] [bigint] NULL,
	[Title] [nvarchar](100) NULL,
	[Content] [nvarchar](max) NULL,
	[Link] [nvarchar](500) NULL,
	[Type] [varchar](50) NOT NULL,
	[Status] [smallint] NOT NULL CONSTRAINT [DF_UserNotification_Status]  DEFAULT ((1)),
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_UserNotification_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_UserNotification_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_UserNotification] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [JFW].[UserPermission]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[User_ID] [bigint] NOT NULL,
	[Permission_ID] [bigint] NOT NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL,
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL,
	CONSTRAINT [PK_UserPermission] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[UserProfile]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[User_ID] [bigint] NOT NULL,
	[First_Name] [nvarchar](50) NULL,
	[Last_Name] [nvarchar](50) NULL,
	[Nick_Name] [nvarchar](50) NULL,
	[Avatar] [nvarchar](500) NULL,
	[Email_Address] [varchar](150) NULL,
	[PhoneNumber1] [varchar](20) NULL,
	[PhoneNumber2] [varchar](20) NULL,
	[PhoneNumber3] [varchar](20) NULL,
	[Website] [nvarchar](200) NULL,
	[TimeZone_ID] [bigint] NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_UserProfile_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_UserProfile_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_UserProfile] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [JFW].[UserRole]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Role_ID] [bigint] NOT NULL,
	[User_ID] [bigint] NOT NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_UserRole_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_UserRole_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_UserRole] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[UserSetting]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[User_ID] [bigint] NOT NULL,
	[Package_ID] [bigint] NOT NULL,
	[Tracking_Level] [smallint] NULL CONSTRAINT [DF_UserSetting_TrackingLevel]  DEFAULT ((1000)),
	[Max_Allowed_Device_Number] [int] NULL CONSTRAINT [DF_UserSetting_MaxAllowedDeviceNumber]  DEFAULT ((1)),
	[Theme_Style] [varchar](50) NULL,
	[Referral_Code] [varchar](10) NULL,
	[Commission] [float] NULL,
	[Waiting_Period] [smallint] NULL,
	[Enable_Sign_In_Detection] [bit] NULL CONSTRAINT [DF_UserSetting_EnableSignInDetection]  DEFAULT ((0)),
	[Expiry_Date] [datetime] NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL CONSTRAINT [DF_UserSetting_ModifiedDate]  DEFAULT (getutcdate()),
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL CONSTRAINT [DF_UserSetting_CreatedDate]  DEFAULT (getutcdate()),
	CONSTRAINT [PK_UserSetting] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [JFW].[Wallet]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[User_ID] [bigint] NOT NULL,
	[Currency] [varchar](3) NOT NULL,
	[Balance] [float] NULL,
	[Status] [smallint] NOT NULL,
	[Is_Default] [bit] NOT NULL,
	[Modified_By] [bigint] NULL,
	[Modified_Date] [datetime] NOT NULL,
	[Created_By] [bigint] NULL,
	[Created_Date] [datetime] NOT NULL,
	CONSTRAINT [PK_Wallet2022] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
ALTER TABLE [JFW].[BlackList] ADD  CONSTRAINT [DF_BlackList_ModifiedDate]  DEFAULT (getutcdate()) FOR [Modified_Date]
GO
ALTER TABLE [JFW].[BlackList] ADD  CONSTRAINT [DF_BlackList_CreatedDate]  DEFAULT (getutcdate()) FOR [Created_Date]
GO
ALTER TABLE [JFW].[CouponUser] ADD  CONSTRAINT [DF_CouponUser_ModifiedDate]  DEFAULT (getutcdate()) FOR [Modified_Date]
GO
ALTER TABLE [JFW].[CouponUser] ADD  CONSTRAINT [DF_CouponUser_CreatedDate]  DEFAULT (getutcdate()) FOR [Created_Date]
GO
ALTER TABLE [JFW].[HelpDesk] ADD  CONSTRAINT [DF_HelpDesk_ModifiedDate]  DEFAULT (getutcdate()) FOR [Modified_Date]
GO
ALTER TABLE [JFW].[HelpDesk] ADD  CONSTRAINT [DF_HelpDesk_CreatedDate]  DEFAULT (getutcdate()) FOR [Created_Date]
GO
ALTER TABLE [JFW].[HelpDeskFeedback] ADD  CONSTRAINT [DF_HelpDeskFeedback_ModifiedDate]  DEFAULT (getutcdate()) FOR [Modified_Date]
GO
ALTER TABLE [JFW].[HelpDeskFeedback] ADD  CONSTRAINT [DF_HelpDeskFeedback_CreatedDate]  DEFAULT (getutcdate()) FOR [Created_Date]
GO
ALTER TABLE [JFW].[PaymentMethod] ADD  CONSTRAINT [DF_MerchantMethod_IsDefault]  DEFAULT ((0)) FOR [Is_Default]
GO
ALTER TABLE [JFW].[PaymentMethod] ADD  CONSTRAINT [DF_PaymentMethod_ModifiedDate]  DEFAULT (getutcdate()) FOR [Modified_Date]
GO
ALTER TABLE [JFW].[PaymentMethod] ADD  CONSTRAINT [DF_PaymentMethod_CreatedDate]  DEFAULT (getutcdate()) FOR [Created_Date]
GO
ALTER TABLE [JFW].[PointHistory] ADD  CONSTRAINT [DF_PointHistory_ModifiedDate]  DEFAULT (getutcdate()) FOR [Modified_Date]
GO
ALTER TABLE [JFW].[PointHistory] ADD  CONSTRAINT [DF_PointHistory_CreatedDate]  DEFAULT (getutcdate()) FOR [Created_Date]
GO
ALTER TABLE [JFW].[Reward] ADD  CONSTRAINT [DF_Reward_RequiredLevel]  DEFAULT ((0)) FOR [Required_Level]
GO
ALTER TABLE [JFW].[Reward] ADD  CONSTRAINT [DF_Reward_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [JFW].[Reward] ADD  CONSTRAINT [DF_Reward_ModifiedDate]  DEFAULT (getutcdate()) FOR [Modified_Date]
GO
ALTER TABLE [JFW].[Reward] ADD  CONSTRAINT [DF_Reward_CreatedDate]  DEFAULT (getutcdate()) FOR [Created_Date]
GO
ALTER TABLE [JFW].[SmtpSetting] ADD  CONSTRAINT [DF_SmtpSetting_UseTLS]  DEFAULT ((0)) FOR [Use_TLS]
GO
ALTER TABLE [JFW].[SmtpSetting] ADD  CONSTRAINT [DF_SmtpSetting_IsDefault]  DEFAULT ((0)) FOR [Is_Default]
GO
ALTER TABLE [JFW].[SmtpSetting] ADD  CONSTRAINT [DF_SmtpSetting_ModifiedDate]  DEFAULT (getutcdate()) FOR [Modified_Date]
GO
ALTER TABLE [JFW].[SmtpSetting] ADD  CONSTRAINT [DF_SmtpSetting_CreatedDate]  DEFAULT (getutcdate()) FOR [Created_Date]
GO
ALTER TABLE [JFW].[UserAddress] ADD  CONSTRAINT [DF_Address_IsDefault]  DEFAULT ((0)) FOR [Is_Default]
GO
ALTER TABLE [JFW].[UserAddress] ADD  CONSTRAINT [DF_UserAddress_ModifiedDate]  DEFAULT (getutcdate()) FOR [Modified_Date]
GO
ALTER TABLE [JFW].[UserAddress] ADD  CONSTRAINT [DF_UserAddress_CreatedDate]  DEFAULT (getutcdate()) FOR [Created_Date]
GO
ALTER TABLE [JFW].[UserPermission] ADD  CONSTRAINT [DF_UserPermission_ModifiedDate]  DEFAULT (getutcdate()) FOR [Modified_Date]
GO
ALTER TABLE [JFW].[UserPermission] ADD  CONSTRAINT [DF_UserPermission_CreatedDate]  DEFAULT (getutcdate()) FOR [Created_Date]
GO
ALTER TABLE [JFW].[Wallet] ADD  CONSTRAINT [DF_Wallet_Balance]  DEFAULT ((0)) FOR [Balance]
GO
ALTER TABLE [JFW].[Wallet] ADD  CONSTRAINT [DF_Wallet_IsDefault]  DEFAULT ((0)) FOR [Is_Default]
GO
ALTER TABLE [JFW].[Wallet] ADD  CONSTRAINT [DF_Wallet_ModifiedDate]  DEFAULT (getutcdate()) FOR [Modified_Date]
GO
ALTER TABLE [JFW].[Wallet] ADD  CONSTRAINT [DF_Wallet_CreatedDate]  DEFAULT (getutcdate()) FOR [Created_Date]
GO
ALTER TABLE [JFW].[BrandEmail]  WITH CHECK ADD  CONSTRAINT [FK_BrandEmail] FOREIGN KEY([Brand_ID])
REFERENCES [JFW].[Brand] ([ID])
GO
ALTER TABLE [JFW].[BrandEmail] CHECK CONSTRAINT [FK_BrandEmail]
GO
ALTER TABLE [JFW].[BrandLink]  WITH CHECK ADD  CONSTRAINT [FK_BrandLink] FOREIGN KEY([Brand_ID])
REFERENCES [JFW].[Brand] ([ID])
GO
ALTER TABLE [JFW].[BrandLink] CHECK CONSTRAINT [FK_BrandLink]
GO
ALTER TABLE [JFW].[BrandProfile]  WITH CHECK ADD  CONSTRAINT [FK_BrandProfile] FOREIGN KEY([Brand_ID])
REFERENCES [JFW].[Brand] ([ID])
GO
ALTER TABLE [JFW].[BrandProfile] CHECK CONSTRAINT [FK_BrandProfile]
GO
ALTER TABLE [JFW].[BrandSetting]  WITH CHECK ADD  CONSTRAINT [FK_BrandSetting] FOREIGN KEY([Brand_ID])
REFERENCES [JFW].[Brand] ([ID])
GO
ALTER TABLE [JFW].[BrandSetting] CHECK CONSTRAINT [FK_BrandSetting]
GO
ALTER TABLE [JFW].[Device]  WITH CHECK ADD  CONSTRAINT [FK_Device] FOREIGN KEY([User_ID])
REFERENCES [JFW].[User] ([ID])
GO
ALTER TABLE [JFW].[Device] CHECK CONSTRAINT [FK_Device]
GO
ALTER TABLE [JFW].[DeviceProfile]  WITH CHECK ADD  CONSTRAINT [FK_DeviceProfile] FOREIGN KEY([Device_ID])
REFERENCES [JFW].[Device] ([ID])
GO
ALTER TABLE [JFW].[DeviceProfile] CHECK CONSTRAINT [FK_DeviceProfile]
GO
ALTER TABLE [JFW].[PackageFeature]  WITH CHECK ADD  CONSTRAINT [FK_PackageFeature_Feature] FOREIGN KEY([Feature_ID])
REFERENCES [JFW].[Feature] ([ID])
GO
ALTER TABLE [JFW].[PackageFeature] CHECK CONSTRAINT [FK_PackageFeature_Feature]
GO
ALTER TABLE [JFW].[PackageFeature]  WITH CHECK ADD  CONSTRAINT [FK_PackageFeature_Package] FOREIGN KEY([Package_ID])
REFERENCES [JFW].[Package] ([ID])
GO
ALTER TABLE [JFW].[PackageFeature] CHECK CONSTRAINT [FK_PackageFeature_Package]
GO
ALTER TABLE [JFW].[PointHistory]  WITH CHECK ADD  CONSTRAINT [FK_PointHistory_User] FOREIGN KEY([User_ID])
REFERENCES [JFW].[User] ([ID])
GO
ALTER TABLE [JFW].[PointHistory] CHECK CONSTRAINT [FK_PointHistory_User]
GO
ALTER TABLE [JFW].[Reward]  WITH CHECK ADD  CONSTRAINT [FK_Reward_Brand] FOREIGN KEY([Brand_ID])
REFERENCES [JFW].[Brand] ([ID])
GO
ALTER TABLE [JFW].[Reward] CHECK CONSTRAINT [FK_Reward_Brand]
GO
ALTER TABLE [JFW].[RolePermission]  WITH CHECK ADD  CONSTRAINT [FK_RolePermission] FOREIGN KEY([Role_ID])
REFERENCES [JFW].[Role] ([ID])
GO
ALTER TABLE [JFW].[RolePermission] CHECK CONSTRAINT [FK_RolePermission]
GO
ALTER TABLE [JFW].[UserProfile]  WITH CHECK ADD  CONSTRAINT [FK_UserProfile] FOREIGN KEY([User_ID])
REFERENCES [JFW].[User] ([ID])
GO
ALTER TABLE [JFW].[UserProfile] CHECK CONSTRAINT [FK_UserProfile]
GO
ALTER TABLE [JFW].[UserSetting]  WITH CHECK ADD  CONSTRAINT [FK_UserSetting] FOREIGN KEY([User_ID])
REFERENCES [JFW].[User] ([ID])
GO
ALTER TABLE [JFW].[UserSetting] CHECK CONSTRAINT [FK_UserSetting]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 06, 2021
-- Description:  this method deletes multiple rows in the [JFW].[Activity] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Activity_Delete]
	@ID bigint
AS

DELETE FROM
    [JFW].[Activity]
WHERE [ID] = @ID


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 06, 2021
-- Description:  this method gets data of the [JFW].[Activity] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Activity_Get]
	@ID bigint
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT
	*
FROM
	[JFW].[Activity]
WHERE ID = @ID




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 06, 2021
-- Description:  this method inserts data into the [JFW].[Activity] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Activity_Insert]
	@User_ID bigint,
	@Device_ID bigint,
	@Tracking_Action_ID bigint,
	@URL nvarchar(1000) = null,
	@IP_Address varchar(20) = null,
	@OS nvarchar(50) = null,
	@Browser_Name nvarchar(50) = null,
	@Browser_Version nvarchar(50) = null,
	@Request_From_Mobile bit = null,
	@User_Agent nvarchar(250) = null,
	@Location nvarchar(250) = null,
	@Latitude float = null,
	@Longitude float = null,
	@Description nvarchar(1000) = null,
	@Created_By bigint = null

AS

INSERT INTO [JFW].[Activity]
	(
	[User_ID],
	[Device_ID],
	[Tracking_Action_ID],
	[URL],
	[IP_Address],
	[OS],
	[Browser_Name],
	[Browser_Version],
	[Request_From_Mobile],
	[User_Agent],
	[Location],
	[Latitude],
	[Longitude],
	[Description],
	[Modified_By],
	[Modified_Date],
	[Created_By],
	[Created_Date]
	)
VALUES
	(
		@User_ID,
		@Device_ID,
		@Tracking_Action_ID,
		@URL,
		@IP_Address,
		@OS,
		@Browser_Name,
		@Browser_Version,
		@Request_From_Mobile,
		@User_Agent,
		@Location,
		@Latitude,
		@Longitude,
		@Description,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- EXEC [JFW].[usp_Activity_List] 
-- EXEC [JFW].[usp_Activity_List] @LIMIT=100
-- EXEC [JFW].[usp_Activity_List] @Page_Number='',@Page_Size=''
-- EXEC [JFW].[usp_Activity_List] @Page_Number='5',@Page_Size='50'
-- =============================================
-- Created by:        dba03@jexpcom
-- Create date: 2021-02-17
-- Description:    this stored procedure retrieves the list of activities according to the search criteri
-- =============================================
CREATE PROCEDURE [JFW].[usp_Activity_List]
	@User_ID bigint = null,
	@Device_ID bigint = null,
	@Tracking_Action_ID bigint = null,
	@URL nvarchar(1000) = null,
	@IP_Address varchar(20) = null,
	@OS nvarchar(50) = null,
	@Browser_Name nvarchar(50) = null,
	@Browser_Version nvarchar(50) = null,
	@Request_From_Mobile bit = null,
	@User_Agent nvarchar(250) = null,
	@Location nvarchar(250) = null,
	@Latitude float = null,
	@Longitude float = null,
	@Description nvarchar(1000) = null,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC',
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null

AS
BEGIN


	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size


	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	IF(@User_ID IS NOT NULL AND @User_ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [User_ID] = ''', @User_ID, ''' ')

	IF(@Device_ID IS NOT NULL AND @Device_ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Device_ID] = ''', @Device_ID, ''' ')

	IF(@Tracking_Action_ID IS NOT NULL AND @Tracking_Action_ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Tracking_Action_ID] = ''', @Tracking_Action_ID, ''' ')

	IF(@URL IS NOT NULL AND @URL <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [URL] = ''', @URL, ''' ')

	IF(@IP_Address IS NOT NULL AND @IP_Address <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [IP_Address] = ''', @IP_Address,''' ')

	IF(@OS IS NOT NULL AND @OS <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [OS] = ''', @OS, ''' ')

	IF(@Browser_Name IS NOT NULL AND @Browser_Name <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Browser_Name] = ''', @Browser_Name, ''' ')

	IF(@Browser_Version IS NOT NULL AND @Browser_Version <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Browser_Version] = ''', @Browser_Version, ''' ')

	IF(@Request_From_Mobile IS NOT NULL AND @Request_From_Mobile <> '')
    SELECT @whereClause = CONCAT(@Request_From_Mobile,' AND [Request_From_Mobile] = ''', @Request_From_Mobile, ''' ')

	IF(@User_Agent IS NOT NULL AND @User_Agent <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [User_Agent] = ''', @User_Agent, ''' ')

	IF(@Location IS NOT NULL AND @Location <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Location] = ''', @Location, ''' ')

	IF(@Longitude IS NOT NULL AND @Longitude <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Longitude] = ''', @Longitude, ''' ')

	IF(@Longitude IS NOT NULL AND @Longitude <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Longitude] = ''', @Longitude, ''' ')

	IF(@Description IS NOT NULL AND @Description <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Description] = ''', @Description, ''' ')

	IF(@Created_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] >= ''', @Created_Date_From, ''' ')

	IF(@Created_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] <= ''', @Created_Date_To, ''' ')

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' + 
    ' FROM [JFW].[Activity]' +
    ' WHERE ' +@whereClause + 
    ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order
    + @PAGINATION
	-- Execute the SQL statement
	--PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString


END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 06, 2021
-- Description:  this method updates data for the [JFW].[Activity] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Activity_Update]
	@ID bigint,
	@User_ID bigint,
	@Device_ID bigint,
	@Tracking_Action_ID bigint,
	@URL nvarchar(1000),
	@IP_Address varchar(20),
	@OS nvarchar(50),
	@Browser_Name nvarchar(50),
	@Browser_Version nvarchar(50),
	@Request_From_Mobile bit,
	@User_Agent nvarchar(250),
	@Location nvarchar(250),
	@Latitude float,
	@Longitude float,
	@Description nvarchar(1000),
	@Modified_By bigint
AS

UPDATE [JFW].[Activity] SET
    [User_ID] = @User_ID,
    [Device_ID] = @Device_ID,
    [Tracking_Action_ID] = @Tracking_Action_ID,
    [URL] = @URL,
    [IP_Address] = @IP_Address,
    [OS] = @OS,
    [Browser_Name] = @Browser_Name,
    [Browser_Version] = @Browser_Version,
    [Request_From_Mobile] = @Request_From_Mobile,
    [User_Agent] = @User_Agent,
    [Location] = @Location,
    [Latitude] = @Latitude,
    [Longitude] = @Longitude,
    [Description] = @Description,
	[Modified_By] = @Modified_By,
	[Modified_Date] = GETUTCDATE()

WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [JFW].[usp_BlackList_Delete]
	@ID bigint
AS

DELETE FROM [JFW].[BlackList]
    WHERE ID = @ID



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [JFW].[usp_BlackList_Get]
	@ID bigint

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

Select *
From [JFW].[BlackList]
Where ID = @ID 



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [JFW].[usp_BlackList_Insert]
	@Block_Type int,
	@Values nvarchar(50),
	@Description nvarchar(500),
	@Created_By  bigint
as

Insert Into JFW.BlackList
	(
	[Block_Type] ,
	[Values],
	[Description] ,
	Modified_By,
	Modified_Date,
	Created_By,
	Created_Date
	)
Values
	(
		@Block_Type,
		@Values,
		@Description,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
    )

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Created by:        dba03@jexpa.com
-- Create date: 2021-07-22
-- Description:    this stored procedure retrieves the list of userprofiles according to the search criteria.
-- =============================================
CREATE PROCEDURE [JFW].[usp_BlackList_List]
	@ID bigint = null,
	@Block_Type int = null,
	@Values nvarchar(50) = null,
	@Description nvarchar(500) = null,
	@Created_Date_From datetime = null,
	@Created_Date_To datetime = null,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN
	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	IF(@ID IS NOT NULL AND @ID <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([ID] = ''', @ID, ''') ')
	END

	IF(@Block_Type IS NOT NULL)
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Block_Type] = ', @Block_Type, ') ')
	END

	IF(@Values IS NOT NULL AND @Values <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Values] = ''', @Values, ''') ')
	END

	IF(@Description IS NOT NULL AND @Description <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Description] = ''', @Description, ''') ')
	END


	IF(@Created_Date_From IS NOT NULL AND @Created_Date_From <> '')
	BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Created_Date_From] >= ''', @Created_Date_From, ''') ')
	END

	IF(@Created_Date_To IS NOT NULL AND @Created_Date_To <> '')
	BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Created_Date_To] <= ''', @Created_Date_To, ''') ')
	END

	SELECT @sqlString = 'SELECT * '+
                'FROM [JFW].[BlackList] '+
                ' WHERE ' +@whereClause + 
                ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order +
                @PAGINATION


	-- Execute the SQL statement
	--PRINT @sqlString
	EXEC sp_executesql @sqlString

END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [JFW].[usp_BlackList_Update]
	@ID bigint,
	@Block_Type int,
	@Values nvarchar(50),
	@Description nvarchar(500),
	@Modified_By bigint

as

Update JFW.BlackList
    Set 
        [Block_Type] = @Block_Type,
        [Description] = @Description,
        Modified_By = @Modified_By,
        [Modified_Date] = GETUTCDATE()
    where [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--============================================
-- Created by:   :	jin.jackson
-- Created by
-- Create date: 2023-03-05
-- Description: This deletes the brand and all its related data from the database.
--============================================
CREATE PROCEDURE [JFW].[usp_Brand_Delete]
	-- CREATE PROCEDURE [JFW].[usp_Brand_Delete]
	@ID bigint
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Is_System bit;
	SELECT @Is_System = [Is_System]
	FROM [JFW].[Brand]
	WHERE [ID] = @ID;

	IF @Is_System = 0
    BEGIN
		DELETE FROM [JFW].[BrandEmail] WHERE [Brand_ID] = @ID;
		DELETE FROM [JFW].[BrandLink] WHERE [Brand_ID] = @ID;
		DELETE FROM [JFW].[BrandSetting] WHERE [Brand_ID] = @ID;
		DELETE FROM [JFW].[BrandProfile] WHERE [Brand_ID] = @ID;
		DELETE FROM [JFW].[Brand] WHERE [ID] = @ID;
		SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows';
	END
    ELSE
    BEGIN
		SELECT 0 AS 'TotalRows';
	END
END



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [JFW].[usp_Brand_Get]
	@ID bigint

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

Select *
From [JFW].[Brand]
Where ID = @ID 



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Created by:     dba03@jexpa.com
-- Created date:   2021-02-17
-- Modified by:    jin.jackson
-- Modified date:  2023-03-12
-- Description:    this stored procedure retrieves the value of the ID column.
-- =============================================
CREATE PROCEDURE [JFW].[usp_Brand_GetBrandCodeByUrl]
	@URL_String nvarchar(1000)
AS
BEGIN

	IF(@URL_String IS NOT NULL OR @URL_String <> '')
    BEGIN
		SELECT [Brand_Code]
		FROM [JFW].[Brand]
		WHERE [ID] = [JFW].[fn_GetBrandId](@URL_String)
	END

END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Created by:    dba03@jexpa.com
-- Created date:  2021-02-17
-- Modified by:   jin.jackson
-- Modified date: 2023-03-12
-- Description:   Gets the brand ID from the URL.
-- =============================================
CREATE PROCEDURE [JFW].[usp_Brand_GetBrandIdByUrl]
	@URL_String nvarchar(1000)
AS
BEGIN

	IF(@URL_String IS NOT NULL OR @URL_String <> '')
    BEGIN
		SELECT [ID]
		FROM [JFW].[Brand]
		WHERE [ID] = [JFW].[fn_GetBrandId](@URL_String)
	END

END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, March 30, 2021
-- Description:  this method inserts data into the [JFW].[Brand] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Brand_Insert]
	@Parent_ID bigint,
	@Brand_Code varchar(50),
	@Status smallint = 0,
	@Created_By bigint = null
AS


INSERT INTO [JFW].[Brand]
	(
	[Parent_ID],
	[Brand_Code],
	[Is_Default],
	[Status],
	Modified_By,
	[Modified_Date],
	Created_By,
	[Created_Date]
	)
VALUES
	(
		@Parent_ID,
		@Brand_Code,
		0,
		@Status,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
	)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Created by:  dba03@jexpa.com
-- Create date: 2021-02-22
-- Description: this stored procedure retrieves the list of smtp settings according to the search criteria.
-- =============================================

CREATE PROCEDURE [JFW].[usp_Brand_List]
	@Parent_ID bigint = null,
	@Brand_Code varchar(50) = null,
	@Is_Default bit = 0,
	@Is_System bit = null,
	@Status smallint = null,
	@Modified_Date_From datetime = NULL,
	@Modified_Date_To datetime = NULL,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC',
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null
AS
BEGIN

	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	IF(@Brand_Code IS NOT NULL AND @Brand_Code <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Brand_Code] = ''', @Brand_Code, ''' ')

	IF(@Parent_ID IS NOT NULL AND @Parent_ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Parent_ID] = ''', @Parent_ID, ''' ')

	IF(@Is_Default IS NOT NULL AND @Is_Default <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Is_Default] = ', @Is_Default, ''' ')

	IF(@Is_System IS NOT NULL AND @Is_System <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Is_System] = ''', @Is_System, ''' ')

	IF(@Status IS NOT NULL OR @Status <> '')
    SELECT @whereClause = CONCAT(@whereClause, ' AND [Status] = ''',@Status,''' ')

	IF(@Modified_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] >= ''', @Modified_Date_From, ''' ')

	IF(@Modified_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] <= ''', @Modified_Date_To, ''' ')

	IF(@Created_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] >= ''', @Created_Date_From, ''' ')

	IF(@Created_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] <= ''', @Created_Date_To, ''' ')

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')


	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' +  
    ' FROM [JFW].[Brand]' +
    ' WHERE ' +@whereClause + 
    ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order +
    @PAGINATION


	-- Execute the SQL statement
	--PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString

END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, March 30, 2021
-- Description:  this method updates data for the [JFW].[Brand] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Brand_Update]
	@ID bigint,
	@Parent_ID bigint,
	@Brand_Code varchar(50),
	@Is_Default bit,
	@Status smallint,
	@Modified_By bigint
AS

-- We need to make sure that only one brand is set as default
IF (@Is_Default = 1)
BEGIN
	UPDATE [JFW].[Brand]
	SET [Is_Default] = 0
	WHERE [Is_Default] = 1
END

UPDATE [JFW].[Brand] SET
    [Parent_ID] = @Parent_ID,
    [Brand_Code] = @Brand_Code,
    [Is_Default] = @Is_Default,
    [Status] = @Status,
	Modified_By = @Modified_By,
    [Modified_Date] = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- EXEC [JFW].[usp_Brand_View]
-- EXEC [JFW].[usp_Brand_View] @Keyword = 'JFW'
-- =============================================
-- Created by:   jin.jackson
-- Created date: 2022-01-26
-- Updated date: 2023-03-05
-- Description:  this stored procedure retrieves the list of brands according to the search criteria.
-- =============================================
CREATE PROCEDURE [JFW].[usp_Brand_View]
	-- CREATE PROCEDURE [JFW].[usp_Brand_View]
	@Brand_ID bigint = NULL,
	@Brand_Code varchar(50) = NULL,
	@Is_Default bit = 0,
	@Is_System bit = null,
	@Status smallint = NULL,
	@Keyword nvarchar(1000) = NULL,
	@Brand_URL nvarchar(1000) = NULL,
	@Modified_Date_From datetime = NULL,
	@Modified_Date_To datetime = NULL,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Limit int = NULL,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC',
	@Page_Number int = null,
	@Page_Size int = null
AS
BEGIN
	DECLARE
    @selectClause nvarchar(max) = 'SELECT ',
    @whereClause nvarchar(max) = CONCAT(CHAR(13), 'WHERE 1=1 '),
    @fromClause NVARCHAR(MAX) =  CONCAT(CHAR(13), 'FROM '),
	@offsetClause nvarchar(max) = '',
    @brandFilterQuery nvarchar(max),
    @brandEmailFilterQuery nvarchar(max),
    @brandLinkFilterQuery nvarchar(max),
    @brandProfileFilterQuery nvarchar(max),
    @brandSettingFilterQuery nvarchar(max),
    @tmpSqlString nvarchar(max),
    @sqlString nvarchar(max),
	@skip bigint = @Page_Number * @Page_Size

	CREATE TABLE #temp
	(
		tmpId bigint not null unique
	)

	--- Build the from clause
	SET @fromClause = CONCAT(@fromClause, '[JFW].[Brand] AS B')
	SET @fromClause = CONCAT(@fromClause, CHAR(13), 'LEFT JOIN [JFW].[BrandEmail] AS BE ON B.[ID] = BE.[Brand_ID]')
	SET @fromClause = CONCAT(@fromClause, CHAR(13), 'LEFT JOIN [JFW].[BrandLink] AS BL ON B.[ID] = BL.[Brand_ID]')
	SET @fromClause = CONCAT(@fromClause, CHAR(13), 'LEFT JOIN [JFW].[BrandProfile] AS BP ON B.[ID] = BP.[Brand_ID]')
	SET @fromClause = CONCAT(@fromClause, CHAR(13), 'LEFT JOIN [JFW].[BrandSetting] AS BS ON B.[ID] = BS.[Brand_ID]')

	--- Build the select clause
	IF(@Limit IS NOT NULL)
    BEGIN
		SET @selectClause += CONCAT('TOP (', @Limit, ') ')
	END

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @offsetClause = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	SET @selectClause = CONCAT(@selectClause, 'B.*, ')

	--- Build the select clause for BrandEmail
	SET @selectClause = CONCAT(@selectClause, [JFW].[fn_GenerateColumnAliases]('BrandEmail', 'BrandEmail_', 'BE'), ', ')

	--- Build the select clause for BrandLink
	SET @selectClause = CONCAT(@selectClause, [JFW].[fn_GenerateColumnAliases]('BrandLink', 'BrandLink_', 'BL'), ', ')

	--- Build the select clause for BrandProfile
	SET @selectClause = CONCAT(@selectClause, [JFW].[fn_GenerateColumnAliases]('BrandProfile', 'BrandProfile_', 'BP'), ', ')

	--- Build the select clause for BrandSetting
	SET @selectClause = CONCAT(@selectClause, [JFW].[fn_GenerateColumnAliases]('BrandSetting', 'BrandSetting_', 'BS'))

	--- Build where clause

	IF (@Keyword IS NOT NULL)
    BEGIN
		SET @brandFilterQuery = [JFW].[fn_GetTableViewSearchQuery]('JFW', 'Brand', @Keyword)
		SET @brandEmailFilterQuery = [JFW].[fn_GetTableViewSearchQuery]('JFW', 'BrandEmail', @Keyword)
		SET @brandLinkFilterQuery = [JFW].[fn_GetTableViewSearchQuery]('JFW', 'BrandLink', @Keyword)
		SET @brandProfileFilterQuery = [JFW].[fn_GetTableViewSearchQuery]('JFW', 'BrandProfile', @Keyword)
		SET @brandSettingFilterQuery = [JFW].[fn_GetTableViewSearchQuery]('JFW', 'BrandSetting', @Keyword)
		SET @tmpSqlString = CONCAT('INSERT INTO #temp(tmpId) SELECT [ID] FROM (', @brandFilterQuery, ') as X')
		-- PRINT CONCAT('SQL string: ', @tmpSqlString)
		EXEC sp_executesql @tmpSqlString
		SET @tmpSqlString = CONCAT('INSERT INTO #temp(tmpId) SELECT [Brand_ID] FROM (', @brandEmailFilterQuery, ') as X WHERE [Brand_ID] NOT IN (SELECT tmpId FROM #temp)')
		-- PRINT CONCAT('SQL string: ', @tmpSqlString)
		EXEC sp_executesql @tmpSqlString
		SET @tmpSqlString = CONCAT('INSERT INTO #temp(tmpId) SELECT [Brand_ID] FROM (', @brandLinkFilterQuery, ') as X WHERE [Brand_ID] NOT IN (SELECT tmpId FROM #temp)')
		-- PRINT CONCAT('SQL string: ', @tmpSqlString)
		EXEC sp_executesql @tmpSqlString
		SET @tmpSqlString = CONCAT('INSERT INTO #temp(tmpId) SELECT [Brand_ID] FROM (', @brandProfileFilterQuery, ') as X WHERE [Brand_ID] NOT IN (SELECT tmpId FROM #temp)')
		-- PRINT CONCAT('SQL string: ', @tmpSqlString)
		EXEC sp_executesql @tmpSqlString
		SET @tmpSqlString = CONCAT('INSERT INTO #temp(tmpId) SELECT [Brand_ID] FROM (', @brandSettingFilterQuery, ') as X WHERE [Brand_ID] NOT IN (SELECT tmpId FROM #temp)')
		-- PRINT CONCAT('SQL string: ', @tmpSqlString)
		EXEC sp_executesql @tmpSqlString

		SET @whereClause = CONCAT(@whereClause, ' AND B.[ID] IN (SELECT tmpId FROM #temp)')
	END

	IF (@Brand_URL IS NOT NULL AND @Brand_URL <> '' AND @Brand_ID IS NULL)
	BEGIN
		SET @Brand_ID = [JFW].[fn_GetBrandId](@Brand_URL)
	END

	IF (@Brand_ID IS NOT NULL)
    BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND B.[ID] = ', @Brand_ID)
	END

	IF (@Brand_Code IS NOT NULL)
    BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND B.[Brand_Code] = ''', @Brand_Code, '''')
	END

	IF (@Brand_URL IS NOT NULL AND @Brand_URL <> '')
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND (B.[Is_Default] IS NOT NULL) ')
		SET @whereClause = CONCAT(@whereClause, ' AND (BP.[Website] LIKE CONCAT(''%'',', @Brand_URL, '''%''))')
		SET @whereClause = CONCAT(@whereClause, ' OR (BS.[Website_CPanel] LIKE CONCAT(''%'',', @Brand_URL, '''%''))')
		SET @whereClause = CONCAT(@whereClause, ' OR (BS.[Website_Admin_Tool] LIKE CONCAT(''%'',', @Brand_URL, '''%''))')
		SET @whereClause = CONCAT(@whereClause, ' OR (BS.[Website_Admin_Tool_2] LIKE CONCAT(''%'',', @Brand_URL, '''%''))')
		SET @whereClause = CONCAT(@whereClause, ' OR (BS.[Website_Admin_Tool_3] LIKE CONCAT(''%'',', @Brand_URL, '''%''))')
		SET @whereClause = CONCAT(@whereClause, ' OR (BS.[Website_Protocol] LIKE CONCAT(''%'',', @Brand_URL, '''%''))')
		SET @whereClause = CONCAT(@whereClause, ' OR (BS.[Domain_WhiteList] LIKE CONCAT(''%'',', @Brand_URL, '''%''))')
	END

	IF (@Modified_Date_From IS NOT NULL)
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND B.[Modified_Date] >= ''', @Modified_Date_From, '''')
	END

	IF (@Modified_Date_To IS NOT NULL)
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND B.[Modified_Date] <= ''', @Modified_Date_To, '''')
	END

	IF (@Created_Date_From IS NOT NULL)
    BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND B.[Created_Date] >= ''', @Created_Date_From, '''')
	END

	IF (@Created_Date_To IS NOT NULL)
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND B.[Created_Date] <= ''', @Created_Date_To, '''')
	END

	IF (@Is_Default IS NOT NULL)
    BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND B.[Is_Default] = ', @Is_Default)
	END

	IF (@Is_System IS NOT NULL)
    BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND B.[Is_System] = ', @Is_System)
	END

	IF (@Status IS NOT NULL)
    BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND B.[Status] = ', @Status)
	END

	SET @sqlString = CONCAT(
		@selectClause, 
		@fromClause, 
		@whereClause,
		' ORDER BY ' , CONCAT('[',@Sort_Data_Field,']') + ' ' , @Sort_Order , 
		@offsetClause)

	-- Execute the SQL statement
	-- PRINT CONCAT('SQL string: ', @sqlString)
	EXEC sp_executesql @sqlString

END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Wednesday, December 22, 2021
-- Description:  this method deletes multiple rows in the [JFW].[BrandEmail] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_BrandEmail_Delete]
	@ID bigint
AS

DELETE FROM
    [JFW].[BrandEmail]
WHERE [ID] = @ID


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Wednesday, December 22, 2021
-- Description:  this method gets data of the [JFW].[BrandEmail] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_BrandEmail_Get]
	@ID bigint
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT
	*
FROM
	[JFW].[BrandEmail]
WHERE ID = @ID




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, December 27, 2021
-- Description:  this method gets data of the [JFW].[BrandEmail] table by the BrandID.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_BrandEmail_GetByBrandId]
	@Brand_ID bigint
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT *
FROM
	[JFW].[BrandEmail]
WHERE Brand_ID = @Brand_ID




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Wednesday, December 22, 2021
-- Description:  this method inserts data into the [JFW].[BrandEmail] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_BrandEmail_Insert]
	@Brand_ID bigint,
	@Email_Support varchar(150) = null,
	@Email_Support_Title nvarchar(500) = null,
	@System_Email varchar(150) = null,
	@System_Email_Title nvarchar(500) = null,
	@Login_Notification_Emails varchar(150) = null,
	@Purchase_Notification_Emails varchar(150) = null,
	@Order_Notification_Emails varchar(150) = null,
	@Refund_Notification_Emails varchar(150) = null,
	@Chargeback_Notification_Emails varchar(150) = null,
	@Developer_Team_Emails varchar(150) = null,
	@Maintenance_Team_Emails varchar(150) = null,
	@System_Admin_Notification_Emails varchar(150) = null,
	@System_Admin_Emails varchar(150) = null,
	@Bcc_Notification_Emails varchar(150) = null,
	@Created_By bigint = null
AS

INSERT INTO [JFW].[BrandEmail]
	(
	[Brand_ID],
	[Email_Support],
	[Email_Support_Title],
	[System_Email],
	[System_Email_Title],
	[Login_Notification_Emails],
	[Purchase_Notification_Emails],
	[Order_Notification_Emails],
	[Refund_Notification_Emails],
	[Chargeback_Notification_Emails],
	[Developer_Team_Emails],
	[Maintenance_Team_Emails],
	[System_Admin_Notification_Emails],
	[System_Admin_Emails],
	[Bcc_Notification_Emails],
	Modified_By,
	[Modified_Date],
	Created_By,
	[Created_Date]
	)
VALUES
	(
		@Brand_ID,
		@Email_Support,
		@Email_Support_Title,
		@System_Email,
		@System_Email_Title,
		@Login_Notification_Emails,
		@Purchase_Notification_Emails,
		@Order_Notification_Emails,
		@Refund_Notification_Emails,
		@Chargeback_Notification_Emails,
		@Developer_Team_Emails,
		@Maintenance_Team_Emails,
		@System_Admin_Notification_Emails,
		@System_Admin_Emails,
		@Bcc_Notification_Emails,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Wednesday, December 22, 2021
-- Description:  this method updates data for the [JFW].[BrandEmail] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_BrandEmail_Update]
	@ID bigint,
	@Brand_ID bigint,
	@Email_Support varchar(150),
	@Email_Support_Title nvarchar(500),
	@System_Email varchar(150),
	@System_Email_Title nvarchar(500),
	@Login_Notification_Emails varchar(150),
	@Purchase_Notification_Emails varchar(150),
	@Order_Notification_Emails varchar(150),
	@Refund_Notification_Emails varchar(150),
	@Chargeback_Notification_Emails varchar(150),
	@Developer_Team_Emails varchar(150),
	@Maintenance_Team_Emails varchar(150),
	@System_Admin_Notification_Emails varchar(150),
	@System_Admin_Emails varchar(150),
	@Bcc_Notification_Emails varchar(150),
	@Modified_By bigint
AS

UPDATE [JFW].[BrandEmail] SET
    [Brand_ID] = @Brand_ID,
    [Email_Support] = @Email_Support,
    [Email_Support_Title] = @Email_Support_Title,
	[System_Email] = @System_Email,
	[System_Email_Title] = @System_Email_Title,
    [Login_Notification_Emails] = @Login_Notification_Emails,
    [Purchase_Notification_Emails] = @Purchase_Notification_Emails,
    [Order_Notification_Emails] = @Order_Notification_Emails,
    [Refund_Notification_Emails] = @Refund_Notification_Emails,
    [Chargeback_Notification_Emails] = @Chargeback_Notification_Emails,
    [Developer_Team_Emails] = @Developer_Team_Emails,
    [Maintenance_Team_Emails] = @Maintenance_Team_Emails,
    [System_Admin_Notification_Emails] = @System_Admin_Notification_Emails,
    [System_Admin_Emails] = @System_Admin_Emails,
    [Bcc_Notification_Emails] = @Bcc_Notification_Emails,
	Modified_By = @Modified_By,
    [Modified_Date] = GETUTCDATE()

WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Wednesday, December 22, 2021
-- Description:  this method deletes multiple rows in the [JFW].[BrandLink] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_BrandLink_Delete]
	@ID bigint
AS

DELETE FROM
    [JFW].[BrandLink]
WHERE [ID] = @ID


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Wednesday, December 22, 2021
-- Description:  this method gets data of the [JFW].[BrandLink] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_BrandLink_Get]
	@ID bigint
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT
	*
FROM
	[JFW].[BrandLink]
WHERE ID = @ID




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, December 27, 2021
-- Description:  this method gets data of the [JFW].[BrandLink] table by the BrandID.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_BrandLink_GetByBrandId]
	@Brand_ID bigint
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT *
FROM
	[JFW].[BrandLink]
WHERE Brand_ID = @Brand_ID




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Wednesday, December 22, 2021
-- Description:  this method inserts data into the [JFW].[BrandLink] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_BrandLink_Insert]
	@Brand_ID bigint,
	@Website_Android_Download nvarchar(500) = null,
	@Website_iOS_Download nvarchar(500) = null,
	@Website_Affiliate nvarchar(500) = null,
	@Website_Support nvarchar(500) = null,
	@Website_Forum nvarchar(500) = null,
	@Website_Blog nvarchar(500) = null,
	@Link_How_To_Jailbreak_An_iOS_Device nvarchar(500) = null,
	@Link_Essential_Settings_Android nvarchar(500) = null,
	@Link_Essential_Settings_iOS nvarchar(500) = null,
	@Link_Prices nvarchar(500) = null,
	@Link_How_To_Add_Device_iOS nvarchar(500) = null,
	@Link_How_To_Add_Devices_Android nvarchar(500) = null,
	@Link_Term_Of_Uses nvarchar(500) = null,
	@Link_Brand_Terms_And_Conditions nvarchar(500) = null,
	@Link_FAQ nvarchar(500) = null,
	@Link_Contact_Us nvarchar(500) = null,
	@Link_Forum nvarchar(500) = null,
	@Link_Blog nvarchar(500) = null,
	@Link_How_To_Root_An_Android nvarchar(500) = null,
	@Link_Extra_Notes_For_Useful_Links nvarchar(500) = null,
	@Link_Refund_Policy nvarchar(500) = null,
	@Link_Help_Protected_App nvarchar(500) = null,
	@Created_By bigint = null
AS

INSERT INTO [JFW].[BrandLink]
	(
	[Brand_ID],
	[Website_Android_Download],
	[Website_iOS_Download],
	[Website_Affiliate],
	[Website_Support],
	[Website_Forum],
	[Website_Blog],
	[Link_How_To_Jailbreak_An_iOS_Device],
	[Link_Essential_Settings_Android],
	[Link_Essential_Settings_iOS],
	[Link_Prices],
	[Link_How_To_Add_Device_iOS],
	[Link_How_To_Add_Devices_Android],
	[Link_Term_Of_Uses],
	[Link_Brand_Terms_And_Conditions],
	[Link_FAQ],
	[Link_Contact_Us],
	[Link_Forum],
	[Link_Blog],
	[Link_How_To_Root_An_Android],
	[Link_Extra_Notes_For_Useful_Links],
	[Link_Refund_Policy],
	[Link_Help_Protected_App],
	Modified_By,
	[Modified_Date],
	Created_By,
	[Created_Date]
	)
VALUES
	(
		@Brand_ID,
		@Website_Android_Download,
		@Website_iOS_Download,
		@Website_Affiliate,
		@Website_Support,
		@Website_Forum,
		@Website_Blog,
		@Link_How_To_Jailbreak_An_iOS_Device,
		@Link_Essential_Settings_Android,
		@Link_Essential_Settings_iOS,
		@Link_Prices,
		@Link_How_To_Add_Device_iOS,
		@Link_How_To_Add_Devices_Android,
		@Link_Term_Of_Uses,
		@Link_Brand_Terms_And_Conditions,
		@Link_FAQ,
		@Link_Contact_Us,
		@Link_Forum,
		@Link_Blog,
		@Link_How_To_Root_An_Android,
		@Link_Extra_Notes_For_Useful_Links,
		@Link_Refund_Policy,
		@Link_Help_Protected_App,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Wednesday, December 22, 2021
-- Description:  this method updates data for the [JFW].[BrandLink] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_BrandLink_Update]
	@ID bigint,
	@Brand_ID bigint,
	@Website_Android_Download nvarchar(500) ,
	@Website_iOS_Download nvarchar(500) ,
	@Website_Affiliate nvarchar(500) ,
	@Website_Support nvarchar(500) ,
	@Website_Forum nvarchar(500) ,
	@Website_Blog nvarchar(500) ,
	@Link_How_To_Jailbreak_An_iOS_Device nvarchar(500) ,
	@Link_Essential_Settings_Android nvarchar(500) ,
	@Link_Essential_Settings_iOS nvarchar(500) ,
	@Link_Prices nvarchar(500) ,
	@Link_How_To_Add_Device_iOS nvarchar(500) ,
	@Link_How_To_Add_Devices_Android nvarchar(500) ,
	@Link_Term_Of_Uses nvarchar(500) ,
	@Link_Brand_Terms_And_Conditions nvarchar(500) ,
	@Link_FAQ nvarchar(500) ,
	@Link_Contact_Us nvarchar(500) ,
	@Link_Forum nvarchar(500) ,
	@Link_Blog nvarchar(500) ,
	@Link_How_To_Root_An_Android nvarchar(500) ,
	@Link_Extra_Notes_For_Useful_Links nvarchar(500) ,
	@Link_Refund_Policy nvarchar(500) ,
	@Link_Help_Protected_App nvarchar(500),
	@Modified_By bigint = null
AS

UPDATE [JFW].[BrandLink] SET
    [Brand_ID] = @Brand_ID,
    [Link_How_To_Jailbreak_An_iOS_Device] = @Link_How_To_Jailbreak_An_iOS_Device,
    [Link_Essential_Settings_Android] = @Link_Essential_Settings_Android,
    [Link_Essential_Settings_iOS] = @Link_Essential_Settings_iOS,
    [Link_Prices] = @Link_Prices,
    [Website_Android_Download] = @Website_Android_Download,
    [Website_iOS_Download] = @Website_iOS_Download,
    [Website_Affiliate] = @Website_Affiliate,
    [Website_Support] = @Website_Support,
    [Website_Forum] = @Website_Forum,
    [Website_Blog] = @Website_Blog,
    [Link_How_To_Add_Device_iOS] = @Link_How_To_Add_Device_iOS,
    [Link_How_To_Add_Devices_Android] = @Link_How_To_Add_Devices_Android,
    [Link_Term_Of_Uses] = @Link_Term_Of_Uses,
    [Link_Brand_Terms_And_Conditions] = @Link_Brand_Terms_And_Conditions,
    [Link_FAQ] = @Link_FAQ,
    [Link_Contact_Us] = @Link_Contact_Us,
    [Link_Forum] = @Link_Forum,
    [Link_Blog] = @Link_Blog,
    [Link_How_To_Root_An_Android] = @Link_How_To_Root_An_Android,
    [Link_Extra_Notes_For_Useful_Links] = @Link_Extra_Notes_For_Useful_Links,
    [Link_Refund_Policy] = @Link_Refund_Policy,
    [Link_Help_Protected_App] = @Link_Help_Protected_App,
	@Modified_By = @Modified_By,
    [Modified_Date] = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, March 30, 2021
-- Description:  this method deletes multiple rows in the [JFW].[BrandProfile] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_BrandProfile_Delete]
	@ID bigint
AS

DELETE FROM
    [JFW].[BrandProfile]
WHERE [ID] = @ID


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, March 30, 2021
-- Description:  this method gets data of the [JFW].[BrandProfile] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_BrandProfile_Get]
	@ID bigint
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT *
FROM
	[JFW].[BrandProfile]
WHERE ID = @ID




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, December 27, 2021
-- Description:  this method gets data of the [JFW].[BrandProfile] table by the BrandID.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_BrandProfile_GetByBrandId]
	@Brand_ID bigint
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT *
FROM
	[JFW].[BrandProfile]
WHERE Brand_ID = @Brand_ID




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, March 30, 2021
-- Description:  this method inserts data into the [JFW].[BrandProfile] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_BrandProfile_Insert]
	@Brand_ID bigint,
	@Company_Name nvarchar(100) = null,
	@Website nvarchar(100) = null,
	@Logo_Image_Path nvarchar(500) = null,
	@Tags nvarchar(max) NULL,
	@Shortcut_Icon_Path nvarchar(500) = null,
	@Created_By bigint = null
AS

INSERT INTO [JFW].[BrandProfile]
	(
	[Brand_ID],
	[Company_Name],
	[Website],
	[Logo_Image_Path],
	[Shortcut_Icon_Path],
	[Tags],
	Modified_By,
	[Modified_Date],
	Created_By,
	[Created_Date]
	)
VALUES
	(
		@Brand_ID,
		@Company_Name,
		@Website,
		@Logo_Image_Path,
		@Shortcut_Icon_Path,
		@Tags,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
	)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, March 30, 2021
-- Description:  this method updates data for the [JFW].[BrandProfile] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_BrandProfile_Update]
	@ID bigint,
	@Brand_ID bigint,
	@Company_Name nvarchar(100),
	@Website nvarchar(100),
	@Logo_Image_Path nvarchar(500),
	@Shortcut_Icon_Path nvarchar(500),
	@Tags nvarchar(max) NULL,
	@Modified_By bigint = null
AS

UPDATE [JFW].[BrandProfile] SET
    [Brand_ID] = @Brand_ID,
    [Company_Name] = @Company_Name,
    [Website] = @Website,
    [Logo_Image_Path] = @Logo_Image_Path,
    [Shortcut_Icon_Path] = @Shortcut_Icon_Path,
	[Tags] = @Tags,
	Modified_By = @Modified_By,
    [Modified_Date] = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Wednesday, December 22, 2021
-- Description:  this method deletes multiple rows in the [JFW].[BrandSetting] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_BrandSetting_Delete]
	@ID bigint
AS

DELETE FROM
    [JFW].[BrandSetting]
WHERE [ID] = @ID


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Wednesday, December 22, 2021
-- Description:  this method gets data of the [JFW].[BrandSetting] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_BrandSetting_Get]
	@ID bigint
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT
	*
FROM
	[JFW].[BrandSetting]
WHERE ID = @ID




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, December 27, 2021
-- Description:  this method gets data of the [JFW].[BrandSetting] table by the BrandID.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_BrandSetting_GetByBrandId]
	@Brand_ID bigint
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT *
FROM
	[JFW].[BrandSetting]
WHERE Brand_ID = @Brand_ID




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Wednesday, December 22, 2021
-- Description:  this method inserts data into the [JFW].[BrandSetting] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_BrandSetting_Insert]
	@Brand_ID bigint,
	@Default_Package_ID bigint = null,
	@Default_SubscriptionType_ID bigint = null,
	@Smtp_Setting_ID bigint = null,
	@Product_Website nvarchar(100) = null,
	@Product_Name nvarchar(50) = null,
	@Product_Alias nvarchar(50) = null,
	@Product_Prefix_Name nvarchar(50) = null,
	@Website_CPanel nvarchar(500) = null,
	@Website_Admin_Tool nvarchar(500) = null,
	@Website_Admin_Tool_2 nvarchar(500) = null,
	@Website_Admin_Tool_3 nvarchar(500) = null,
	@Website_Protocol nvarchar(500) = null,
	@Domain_WhiteList nvarchar(4000) = null,
	@Google_Analytics_Account varchar(50) = null,
	@Google_Account_Used_For_Google_Analytics varchar(150) = null,
	@Cdn_Url nvarchar(255) = null,
	@Cdn_Folder nvarchar(255) = null,
	@Bundle_Identifier nvarchar(250) = null,
	@Author_Name nvarchar(100) = null,
	@App_Description nvarchar(250) = null,
	@App_Version varchar(20) = null,
	@Access_Code varchar(20) = null,
	@Created_By	bigint = null
AS

INSERT INTO [JFW].[BrandSetting]
	(
	[Brand_ID],
	[Default_Package_ID],
	[Default_SubscriptionType_ID],
	[Smtp_Setting_ID],
	[Product_Website],
	[Product_Name],
	[Product_Alias],
	[Product_Prefix_Name],
	[Website_CPanel],
	[Website_Admin_Tool],
	[Website_Admin_Tool_2],
	[Website_Admin_Tool_3],
	[Website_Protocol],
	[Domain_WhiteList],
	[Google_Analytics_Account],
	[Google_Account_Used_For_Google_Analytics],
	[Cdn_Url],
	[Cdn_Folder],
	[Bundle_Identifier],
	[Author_Name],
	[App_Description],
	[App_Version],
	[Access_Code],
	Modified_By,
	[Modified_Date],
	Created_By,
	[Created_Date]
	)
VALUES
	(
		@Brand_ID,
		@Default_Package_ID,
		@Default_SubscriptionType_ID,
		@Smtp_Setting_ID,
		@Product_Website,
		@Product_Name,
		@Product_Alias,
		@Product_Prefix_Name,
		@Website_CPanel,
		@Website_Admin_Tool,
		@Website_Admin_Tool_2,
		@Website_Admin_Tool_3,
		@Website_Protocol,
		@Domain_WhiteList,
		@Google_Analytics_Account,
		@Google_Account_Used_For_Google_Analytics,
		@Cdn_Url,
		@Cdn_Folder,
		@Bundle_Identifier,
		@Author_Name,
		@App_Description,
		@App_Version,
		@Access_Code,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
	)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Wednesday, December 22, 2021
-- Description:  this method updates data for the [JFW].[BrandSetting] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_BrandSetting_Update]
	@ID bigint,
	@Brand_ID bigint,
	@Default_Package_ID bigint = null,
	@Default_SubscriptionType_ID bigint = null,
	@Smtp_Setting_ID bigint = null,
	@Product_Website nvarchar(100),
	@Product_Name nvarchar(50),
	@Product_Alias nvarchar(50),
	@Product_Prefix_Name nvarchar(50),
	@Website_CPanel nvarchar(500),
	@Website_Admin_Tool nvarchar(500),
	@Website_Admin_Tool_2 nvarchar(500),
	@Website_Admin_Tool_3 nvarchar(500),
	@Website_Protocol nvarchar(500),
	@Domain_WhiteList nvarchar(4000),
	@Google_Analytics_Account varchar(50),
	@Google_Account_Used_For_Google_Analytics varchar(150),
	@Cdn_Url nvarchar(255),
	@Cdn_Folder nvarchar(255),
	@Bundle_Identifier nvarchar(250),
	@Author_Name nvarchar(100),
	@App_Description nvarchar(250),
	@App_Version varchar(20),
	@Access_Code varchar(20),
	@Modified_By bigint = null
AS

UPDATE [JFW].[BrandSetting] SET
    [Brand_ID] = @Brand_ID,
	[Default_Package_ID] = @Default_Package_ID,
	[Default_SubscriptionType_ID] = @Default_SubscriptionType_ID,
	[Smtp_Setting_ID] = @Smtp_Setting_ID,
    [Product_Website] = @Product_Website,
    [Product_Name] = @Product_Name,
    [Product_Alias] = @Product_Alias,
    [Product_Prefix_Name] = @Product_Prefix_Name,
    [Website_CPanel] = @Website_CPanel,
    [Website_Admin_Tool] = @Website_Admin_Tool,
    [Website_Admin_Tool_2] = @Website_Admin_Tool_2,
    [Website_Admin_Tool_3] = @Website_Admin_Tool_3,
    [Website_Protocol] = @Website_Protocol,
    [Domain_WhiteList] = @Domain_WhiteList,
    [Google_Analytics_Account] = @Google_Analytics_Account,
    [Google_Account_Used_For_Google_Analytics] = @Google_Account_Used_For_Google_Analytics,
    [Cdn_Url] = @Cdn_Url,
    [Cdn_Folder] = @Cdn_Folder,
	[Bundle_Identifier] = @Bundle_Identifier,
	[Author_Name] = @Author_Name,
	[App_Description] = @App_Description,
	[App_Version] = @App_Version,
	[Access_Code] = @Access_Code,
	Modified_By = @Modified_By,
    [Modified_Date] = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, March 30, 2021
-- Description:  this method delete single or multiple rows in the [JFW].[City] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_City_Delete]
	@ID bigint
AS

DELETE FROM
    [JFW].[City]
WHERE [ID] = @ID


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, March 30, 2021
-- Description:  this method gets data of the [JFW].[City] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_City_Get]
	@ID bigint
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT
	*
FROM
	[JFW].[City]
WHERE [ID] = @ID




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [JFW].[usp_City_Insert]
	@Country_Code varchar(2),
	@State_Code varchar(5),
	@Name nvarchar(150),
	@Created_By bigint
AS

INSERT INTO [JFW].[City]
	(
	[Country_Code],
	[State_Code],
	[Name],
	Modified_By,
	Modified_Date,
	Created_By,
	Created_Date
	)
VALUES
	(
		@Country_Code,
		@State_Code,
		@Name,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- EXEC [JFW].[usp_City_List]
------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, March 30, 2021
-- Description:  This method list data for the [JFW].[City] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_City_List]
	@Country_Code varchar(2) = null,
	@State_Code varchar(5) = null,
	@Name nvarchar(50) = null,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'Country_Code',
	@Sort_Order varchar(5) = 'ASC'
AS

BEGIN

	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	IF(@Country_Code IS NOT NULL AND @Country_Code <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Country_Code] = ''', @Country_Code, ''' ')

	IF(@State_Code IS NOT NULL AND @State_Code <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [State_Code] = ''', @State_Code, ''' ')

	IF(@Name IS NOT NULL AND @Name <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [City_Name] = ''', @Name, ''' ')

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')


	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' +  
    ' FROM [JFW].[City]' +
    ' WHERE ' +@whereClause + 
    ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order +
    @PAGINATION


	-- Execute the SQL statement
	--PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString
END



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, March 30, 2021
-- Description:  this method updates data for the [JFW].[City] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_City_Update]
	@ID bigint,
	@Country_Code varchar(2),
	@State_Code varchar(5),
	@Name nvarchar(MAX),
	@Modified_By bigint
AS

UPDATE [JFW].[City] SET
    [Country_Code] = @Country_Code,
    [State_Code] = @State_Code,
    [Name] = @Name,
	Modified_By = @Modified_By,
	Modified_Date = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpcom
-- Created date: Tuesday, July 06, 2021
-- Description:  this method deletes multiple rows in the [JFW].[Configuration] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Configuration_Delete]
	@ID bigint
AS

DELETE FROM
    [JFW].[Configuration]
WHERE [ID] = @ID
	-- We don't allow to delete system configurations
	AND Is_System = 0


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpcom
-- Created date: Tuesday, July 06, 2021
-- Description:  this method gets data of the [JFW].[Configuration] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Configuration_Get]
	@ID bigint
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT
	*
FROM
	[JFW].[Configuration]
WHERE ID = @ID




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- EXEC [JFW].[usp_Configuration_Insert] @Group_Code = 'SYSTEM', @Code = 'DEFAULT_BRAND_DOMAIN', @Name = 'Default brand domain', @Value = 'jfwlab.com', @Description = 'This is the default brand domain'
------------------------------------------------------------------------------------------------------------------------
-- Created by:    dba03
-- Created date:  2021-07-06
-- Modified by:   jin.jackson
-- Modified date: 2022-11-03
-- Description:   this method inserts data into the [JFW].[Configuration] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Configuration_Insert]
	@Group_Code varchar(100),
	@Code varchar(100),
	@Name varchar(100),
	@Description nvarchar(240),
	@Value nvarchar(max),
	@Status smallint = 0,
	@Created_By bigint = null
AS

INSERT INTO [JFW].[Configuration]
	(
	[Group_Code],
	[Code],
	[Name],
	[Description],
	[Value],
	[Status],
	[Modified_By],
	[Modified_Date],
	[Created_By],
	[Created_Date]
	)
VALUES
	(
		@Group_Code,
		@Code,
		@Name,
		@Description,
		@Value,
		@Status,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
	)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- EXEC [JFW].[usp_Configuration_List] @Created_Date_From='20170101', @End_Date='20221230'
-- =============================================
-- Created by:    dba3
-- Created date:  2021-02-17
-- Modified by:   jin.jackson
-- Modified date: 2022-11-03
-- Description:   this stored procedure retrieves the list of activities according to the search criteria
-- =============================================
CREATE PROCEDURE [JFW].[usp_Configuration_List]
	@ID bigint = NULL,
	@Group_Code varchar(100) = NULL,
	@Code varchar(100) = NULL,
	@Name varchar(100) = NULL,
	@Description nvarchar(240) = NULL,
	@Value nvarchar(max) = NULL,
	@Status SMALLINT = NULL,
	@Modified_Date_From datetime = NULL,
	@Modified_Date_To datetime = NULL,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN

	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	IF(@ID IS NOT NULL AND @ID <> '' )
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND [ID] = ''', @ID, ''' ')
	END

	IF(@Group_Code IS NOT NULL AND @Group_Code <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND [Group_Code] = ''', @Group_Code, ''' ')
	END

	IF(@Code IS NOT NULL AND @Code <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND [Code] = ''', @Code, ''' ')
	END

	IF(@Name IS NOT NULL AND @Name <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND [Name] = ''', @Name, ''' ')
	END

	IF(@Description IS NOT NULL AND @Description <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND [Description] = ''', @Description, ''' ')
	END

	IF(@Value IS NOT NULL AND @Value <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND [Value] = ''', @Value, ''' ')
	END

	IF(@Status IS NOT NULL AND @Status <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND [Status] = ''', @Status, ''' ')
	END

	IF(@Modified_Date_From IS NOT NULL)
	BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] >= ''', @Modified_Date_From, ''' ')
	END

	IF(@Modified_Date_To IS NOT NULL)
	BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] <= ''', @Modified_Date_To, ''' ')
	END


	IF(@Created_Date_From IS NOT NULL)
	BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] >= ''', @Created_Date_From, ''' ')
	END

	IF(@Created_Date_To IS NOT NULL)
	BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] <= ''', @Created_Date_To, ''' ')
	END

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' +  
    ' FROM [JFW].[Configuration]' +
    ' WHERE ' +@whereClause + 
    ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order +
    @PAGINATION


	-- Execute the SQL statement
	--PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString


END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- EXEC [JFW].[usp_Configuration_Update] @ID = 1, @Group_Code = 'SYSTEM', @Code = 'DEFAULT_BRAND_DOMAIN', @Name = 'Default brand domain', @Value = 'jfwlab.com', @Description = 'This is the default brand domain', @Status = 1, @Modified_By = 1
------------------------------------------------------------------------------------------------------------------------
-- Created by:    dba3
-- Created date:  2021-07-06
-- Modified by:   jin.jackson
-- Modified date: 2022-11-03
-- Description:   this method updates data for the [JFW].[Configuration] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Configuration_Update]
	@ID bigint,
	@Group_Code varchar(100),
	@Code varchar(100),
	@Name varchar(100),
	@Description nvarchar(240),
	@Value nvarchar(max),
	@Status SMALLINT,
	@Modified_By bigint
AS

UPDATE [JFW].[Configuration] SET
    [Group_Code] = @Group_Code,
    [Code] = @Code, 
    [Name] = @Name,
    [Description] = @Description, 
    [Value] = @Value,
    [Status] = @Status,
    [Modified_By] = @Modified_By,
    [Modified_Date] = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method delete single or multiple rows in the [JFW].[Country] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Country_Delete]
	@ID bigint
AS

DELETE FROM
    [JFW].[Country]
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method gets data of the [JFW].[Country] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Country_Get]
	@ID bigint
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT *
FROM
	[JFW].[Country]
WHERE ID = @ID
    


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method gets data of the [JFW].[Country] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Country_GetByIso]
	@ISO3166 varchar(2) = NULL

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT *

FROM [JFW].[Country]

WHERE ISO3166 = @ISO3166 
    


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [JFW].[usp_Country_Insert]
	@Region nvarchar(50) ,
	@Subregion nvarchar(50) ,
	@Name nvarchar(50)  ,
	@ISO3166 varchar(2)  ,
	@ISO3 varchar(3),
	@Numeric_Code smallint,
	@Phone_Code nvarchar(50),
	@Capital nvarchar(50) ,
	@Currency varchar(3),
	@Tld nvarchar(50)  ,
	@Native nvarchar(150),
	@Created_By bigint

AS

INSERT INTO [JFW].[Country]
	(
	[Region],
	[Subregion],
	[Name],
	[ISO3166],
	[ISO3],
	[Numeric_Code],
	[Phone_Code],
	[Capital],
	[Currency],
	[Tld],
	[Native],
	[Created_By],
	[Created_Date],
	[Modified_By],
	[Modified_Date]
	)
VALUES
	(
		@Region,
		@Subregion,
		@Name,
		@ISO3166,
		@ISO3,
		@Numeric_Code,
		@Phone_Code,
		@Capital,
		@Currency,
		@Tld,
		@Native,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
    )

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Created by:   dba03@jexpa.com
-- Created date: 2021-02-22
-- Description:
-- =============================================

CREATE PROCEDURE [JFW].[usp_Country_List]
	@Region nvarchar(50) = null,
	@Subregion nvarchar(50) = null,
	@Name nvarchar(50) = null,
	@ISO3166 varchar(2) = null,
	@ISO3 varchar(3) = null,
	@Numeric_Code smallint = null,
	@Phone_Code nvarchar(50) = null,
	@Capital nvarchar(50) = null,
	@Currency varchar(3) = null,
	@Tld nvarchar(50) = null,
	@Native nvarchar(150) = null,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ISO3166',
	@Sort_Order varchar(5) = 'ASC'
AS
BEGIN

	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	IF(@Region IS NOT NULL AND @Region <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Region] = ''', @Region, ''' ')

	IF(@Subregion IS NOT NULL AND @Subregion <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Subregion] = ''', @Subregion, ''' ')

	IF(@Name IS NOT NULL AND @Name <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Name] = ''', @Name, ''' ')

	IF(@ISO3166 IS NOT NULL AND @ISO3166 <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [ISO3166] = ''', @ISO3166, ''' ')

	IF(@ISO3 IS NOT NULL AND @ISO3 <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [ISO3] = ''', @ISO3, ''' ')

	IF(@Numeric_Code IS NOT NULL AND @Numeric_Code <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Numeric_Code] = ''', @Numeric_Code, ''' ')

	IF(@Phone_Code IS NOT NULL AND @Phone_Code <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Phone_Code] = ''', @Phone_Code, ''' ')

	IF(@Capital IS NOT NULL AND @Capital <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Capital] = ''', @Capital, ''' ')

	IF(@Currency IS NOT NULL AND @Currency <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Currency] = ''', @Currency, ''' ')

	IF(@Tld IS NOT NULL AND @Tld <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Tld] = ''', @Tld, ''' ')

	IF(@Native IS NOT NULL AND @Native <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Native] = ''', @Native, ''' ')

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')


	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' +  + 
    ' FROM [JFW].[Country]' +
    ' WHERE ' +@whereClause + 
    ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order +
    @PAGINATION


	-- Execute the SQL statement
	--PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString

END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method updates data for the [JFW].[Country] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Country_Update]
	@ID bigint,
	@Region nvarchar(50) ,
	@Subregion nvarchar(50) ,
	@Name nvarchar(50)  ,
	@ISO3166 varchar(2)  ,
	@ISO3 varchar(3),
	@Numeric_Code smallint,
	@Phone_Code nvarchar(50),
	@Capital nvarchar(50) ,
	@Currency varchar(3) ,
	@Tld nvarchar(50)  ,
	@Native nvarchar(150),
	@Modified_By bigint
AS

UPDATE [JFW].[Country] SET
    [Region] = @Region, 
    [Subregion] = @Subregion, 
    [Name] = @Name, 
    [ISO3166] = @ISO3166,
    [ISO3] = @ISO3, 
    [Numeric_Code] = @Numeric_Code, 
    [Phone_Code] = @Phone_Code, 
    [Capital] = @Capital, 
    [Currency] = @Currency,
    [Tld] = @Tld, 
    [Native] = @Native,
	Modified_By = @Modified_By,
	Modified_Date = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, April 27, 2021
-- Description:  this method deletes multiple rows in the [JFW].[Coupon] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Coupon_Delete]
	@ID bigint
AS

DELETE FROM
    [JFW].[Coupon]
WHERE [ID] = @ID


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [JFW].[usp_Coupon_Get]
	@ID bigint
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT
	[ID],
	[Brand_ID],
	[Coupon_Code],
	[Coupon_Percent],
	[Quantity],
	[Start_Date],
	[End_Date],
	[Auto_Apply_To_Price],
	[Description],
	[Status],
	[Modified_By],
	[Modified_Date],
	[Created_By],
	[Created_Date]
FROM
	[JFW].[Coupon]
WHERE ID = @ID



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Coupon Table - Insert
-- EXEC [JFW].[usp_Coupon_Insert] @Brand_ID = 1, @Coupon_Code = 'SAMPLECOUPON', @Coupon_Percent = 10, @Quantity = 1, @Start_Date = '2021-07-06', @End_Date = '2021-07-06', @Auto_Apply_To_Price = 0, @Description = 'SAMPLECOUPON', @Status = 0, @Modified_By = 1, @Created_By = 1
------------------------------------------------------------------------------------------------------------------------
-- Created by:    dba03
-- Created date:  2021-07-06
-- Modified by:   jin.jackson
-- Modified date: 2022-11-03
-- Description:   this method inserts data into the [JFW].[Coupon] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Coupon_Insert]
	@Brand_ID bigint,
	@Coupon_Code varchar(50),
	@Coupon_Percent float = null,
	@Quantity int = 1,
	@Start_Date datetime = null,
	@End_Date datetime = null,
	@Auto_Apply_To_Price bit = 0,
	@Description nvarchar(250) = null,
	@Status SMALLINT = 0,
	@Modified_By bigint,
	@Created_By bigint
AS

INSERT INTO [JFW].[Coupon]
	(
	[Brand_ID],
	[Coupon_Code],
	[Coupon_Percent],
	[Quantity],
	[Start_Date],
	[End_Date],
	[Auto_Apply_To_Price],
	[Description],
	[Status],
	[Modified_By],
	[Modified_Date],
	[Created_By],
	[Created_Date]
	)
VALUES
	(
		@Brand_ID,
		@Coupon_Code,
		@Coupon_Percent,
		@Quantity,
		@Start_Date,
		@End_Date,
		@Auto_Apply_To_Price,
		@Description,
		@Status,
		@Modified_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Coupon Table - List
-- EXEC [JFW].[usp_Coupon_List] @Brand_ID = 1, @Coupon_Code = 'SAMPLECOUPON', @Coupon_Percent = 10, @Quantity = 1, @Auto_Apply_To_Price = 0, @Status = 0, @Modified_By = 1, @Created_By = 1
-- ------------------------------------------------------------------------------------------------------------------------
-- Created by:    dba03
-- Created date:  2021-07-06
-- Modified by:   jin.jackson
-- Modified date: 2023-02-24
-- Description:   lists data from the [JFW].[Coupon] table.
-- ------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_Coupon_List]
	@Brand_ID bigint = null,
	@Coupon_Code varchar(50) = null,
	@Coupon_Percent float = null,
	@Quantity int = null,
	@Start_Date datetime = null,
	@End_Date datetime = null,
	@Auto_Apply_To_Price bit = null,
	@Description nvarchar(250) = null,
	@Status SMALLINT = null,
	@Modified_Date_From datetime = NULL,
	@Modified_Date_To datetime = NULL,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN

	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	IF(@Brand_ID IS NOT NULL AND @Brand_ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Brand_ID] = ''', @Brand_ID, ''' ')

	IF(@Coupon_Code IS NOT NULL AND @Coupon_Code <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Coupon_Code] = ''', @Coupon_Code, ''' ')

	IF(@Coupon_Percent IS NOT NULL AND @Coupon_Percent <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Coupon_Percent] = ''', @Coupon_Percent, ''' ')

	IF(@Quantity IS NOT NULL AND @Quantity <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Quantity] = ''', @Quantity, ''' ')

	IF(@Start_Date IS NOT NULL AND @Start_Date <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Start_Date] = ''', @Start_Date, ''' ')

	IF(@End_Date IS NOT NULL AND @End_Date <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [End_Date] = ''', @End_Date, ''' ')

	IF(@Auto_Apply_To_Price IS NOT NULL AND @Auto_Apply_To_Price <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Auto_Apply_To_Price] = ''', @Auto_Apply_To_Price, ''' ')

	IF(@Description IS NOT NULL AND @Description <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Description] = ''', @Description, ''' ')

	IF(@Status IS NOT NULL AND @Status <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Status] = ''', @Status, ''' ')

	IF(@Modified_Date_From IS NOT NULL AND @Modified_Date_From <> '')
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] >= ''', @Modified_Date_From, ''' ')

	IF(@Modified_Date_To IS NOT NULL AND @Modified_Date_To <> '')
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] <= ''', @Modified_Date_To, ''' ')

	IF(@Created_Date_From IS NOT NULL AND @Created_Date_From <> '')
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] >= ''', @Created_Date_From, ''' ')

	IF(@Created_Date_To IS NOT NULL AND @Created_Date_To <> '')
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] <= ''', @Created_Date_To, ''' ')

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')


	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' + 
    ' FROM [JFW].[Coupon]' +
    ' WHERE ' +@whereClause + 
    ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order +
    @PAGINATION


	-- Execute the SQL statement
	--PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString

END




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Coupon Table - Update
-- EXEC [JFW].[usp_Coupon_Update] @ID = 1, @Brand_ID = 1, @Coupon_Code = 'SAMPLECOUPON', @Coupon_Percent = 10, @Quantity = 1, @Start_Date = '2021-07-06', @End_Date = '2021-07-06', @Auto_Apply_To_Price = 0, @Description = 'Sample', @Status = 1, @Modified_By = 1
-------------------------------------------------------------------------------------------------------------------------
-- Created by:    dba03
-- Created date:  2021-07-06
-- Modified by:   jin.jackson
-- Modified date: 2022-11-03
-- Description:   this method updates data in the [JFW].[Coupon] table.
-------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_Coupon_Update]
	@ID bigint,
	@Brand_ID bigint,
	@Coupon_Code varchar(50),
	@Coupon_Percent float,
	@Quantity int,
	@Start_Date datetime,
	@End_Date datetime,
	@Auto_Apply_To_Price bit,
	@Description nvarchar(250),
	@Status SMALLINT,
	@Modified_By bigint
AS

UPDATE [JFW].[Coupon] SET
    [Brand_ID] = @Brand_ID,
    [Coupon_Code] = @Coupon_Code,
    [Coupon_Percent] = @Coupon_Percent,
    [Quantity] = @Quantity,
    [Start_Date] = @Start_Date,
    [End_Date] = @End_Date,
    [Auto_Apply_To_Price] = @Auto_Apply_To_Price,
    [Description] = @Description,
    [Status] = @Status,
    [Modified_By] = @Modified_By,
    [Modified_Date] = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method deletes multiple rows in the [JFW].[CouponUser] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_CouponUser_Delete]
	@ID bigint
AS

DELETE FROM
    [JFW].[CouponUser]
WHERE [ID] = @ID


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method gets data of the [JFW].[CouponUser] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_CouponUser_Get]
	@ID bigint
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT *
FROM
	[JFW].[CouponUser]
WHERE ID = @ID



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Created by:        dba03@jexpa.com
-- Create date: 2021-02-17
-- Description:    this stored procedure counts the total number of coupon uses.
-- =============================================
CREATE PROCEDURE [JFW].[usp_CouponUser_GetQuantityUsed]
	@Coupon_ID bigint
AS
BEGIN
	SELECT COUNT_BIG(ID) AS 'Total'
	FROM [JFW].[CouponUser] cpu
	WHERE cpu.Coupon_ID = @Coupon_ID
END



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method inserts data into the [JFW].[CouponUser] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_CouponUser_Insert]
	@Coupon_ID bigint,
	@User_ID bigint,
	@Created_By bigint
AS

INSERT INTO [JFW].[CouponUser]
	(
	[Coupon_ID],
	[User_ID],
	Modified_By,
	Modified_Date,
	Created_By,
	[Created_Date]
	)
VALUES
	(
		@Coupon_ID,
		@User_ID,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Coupon Table - List
CREATE PROCEDURE [JFW].[usp_CouponUser_List]
	@Coupon_ID bigint = null,
	@User_ID bigint = null,
	@Created_Date_From datetime = null,
	@Created_Date_To datetime = null,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN
	DECLARE @sqlString nvarchar(max)
	DECLARE @whereClause nvarchar(max) = ''
	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = '',
	@skip bigint = @Page_Number * @Page_Size

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	IF(@Coupon_ID IS NOT NULL AND @Coupon_ID <> '')
	SELECT @whereClause = CONCAT(@whereClause,' AND [Coupon_ID] = ', @Coupon_ID)

	IF(@User_ID IS NOT NULL AND @User_ID <> '')
	SELECT @whereClause = CONCAT(@whereClause,' AND [User_ID] = ', @User_ID)

	IF(@Created_Date_From IS NOT NULL AND @Created_Date_From <> '')
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] >= ''', @Created_Date_From, ''' ')

	IF(@Created_Date_To IS NOT NULL AND @Created_Date_To <> '')
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] <= ''', @Created_Date_To, ''' ')

	IF(@Limit IS NOT NULL AND @Limit <> '')
	SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	SELECT @sqlString = CONCAT('SELECT ', @LimitClause, ' * FROM [JFW].[CouponUser] WHERE 1 = 1 ', @whereClause, ' ORDER BY ', @Sort_Data_Field, ' ', @Sort_Order, ' ', @PAGINATION)

	EXEC sp_executesql @sqlString
END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method updates data for the [JFW].[CouponUser] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_CouponUser_Update]
	@ID bigint,
	@Coupon_ID bigint,
	@User_ID bigint,
	@Modified_By bigint
AS

UPDATE [JFW].[CouponUser] SET
    [Coupon_ID] = @Coupon_ID,
    [User_ID] = @User_ID,
	Modified_By = @Modified_By,
	Modified_Date = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   jin.jackson
-- Created date: 2023-02-24
-- Description:  delete row(s) from the [JFW].[Currency] table by the ID list.
------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_Currency_Delete]
	@ID bigint
AS

DELETE FROM
	[JFW].[Currency]
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   jin.jackson
-- Created date: 2023-02-24
-- Description:  gets data of the [JFW].[Currency] table by ID.
------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_Currency_Get]
	@ID bigint
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT *
FROM
	[JFW].[Currency]
WHERE ID = @ID



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   jin.jackson
-- Created date: 2023-02-24
-- Description:  insert data into the [JFW].[Currency] table.
------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_Currency_Insert]
	@Name varchar(20),
	@Code varchar(3),
	@Symbol varchar(5),
	@Is_Default bit = 0,
	@Created_By bigint
AS

--- If the currency is default, then set all other currencies to not default.
IF @Is_Default <> 0
BEGIN
	UPDATE [JFW].[Currency] SET [Is_Default] = 0
END

INSERT INTO [JFW].[Currency]
	(
	[Name],
	[Code],
	[Symbol],
	[Is_Default],
	[Created_By],
	[Created_Date],
	[Modified_By],
	[Modified_Date]
	)
VALUES
	(
		@Name,
		@Code,
		@Symbol,
		@Is_Default,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
	)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   jin.jackson
-- Created date: 2023-02-24
-- Description:  lists data of the [JFW].[Currency] table.
------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_Currency_List]
	@Name varchar(20) = NULL,
	@Code varchar(3) = NULL,
	@Symbol varchar(5) = NULL,
	@Is_Default bit = 0,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'ASC'
AS
BEGIN
	DECLARE @limitClause nvarchar(100) = '',
	@offsetClause nvarchar(max) = '',
	@whereClause nvarchar(max) = '1 = 1',
	@sql nvarchar(max) = '',
    @skip bigint = @Page_Number * @Page_Size

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @offsetClause = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'


	IF (@Name IS NOT NULL AND @Name <> '')
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Name] = ''', @Name, '''')
	END

	IF (@Code IS NOT NULL AND @Code <> '')
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Code] = ''', @Code, '''')
	END

	IF (@Symbol IS NOT NULL AND @Symbol <> '')
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Symbol] = ''', @Symbol, '''')
	END

	IF (@Is_Default IS NOT NULL)
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Is_Default] = ', @Is_Default)
	END

	IF (@Limit IS NOT NULL AND @Limit > 0)
	BEGIN
		SET @limitClause = CONCAT('TOP ', @Limit)
	END

	SET @sql = CONCAT('SELECT ', @limitClause, 
	' * FROM [JFW].[Currency]',
	' WHERE ', @whereClause, 
	' ORDER BY ', @Sort_Data_Field, ' ', @Sort_Order, CHAR(13), 
	@offsetClause)

	-- PRINT CONCAT('SQL: ', @sql)
	EXEC sp_executesql @sql
END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   jin.jackson
-- Created date: 2023-02-24
-- Description:  update data of the [JFW].[Currency] table.
------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_Currency_Update]
	@ID bigint,
	@Name varchar(20),
	@Code varchar(3),
	@Symbol varchar(5),
	@Is_Default bit = 0,
	@Modified_By bigint
AS

--- If the currency is default, then set all other currencies to not default.
IF @Is_Default <> 0
BEGIN
	UPDATE [JFW].[Currency] SET [Is_Default] = 0 WHERE [ID] <> @ID
END

UPDATE [JFW].[Currency] SET
	[Name] = @Name,
	[Code] = @Code,
	[Symbol] = @Symbol,
	[Is_Default] = @Is_Default,
	Modified_By = @Modified_By,
	Modified_Date = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method deletes multiple rows in the [JFW].[Device] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Device_Delete]
	@ID bigint
AS


DELETE FROM
    [JFW].[DeviceProfile]
WHERE [Device_ID] = @ID

DELETE FROM
    [JFW].[Device]
WHERE [ID] = @ID


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method gets data of the [JFW].[Device] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Device_Get]
	@ID bigint
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT *
FROM
	[JFW].[Device]
WHERE ID = @ID



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, August 23, 2022
-- Description:  this method gets data of the [JFW].[Device] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Device_GetByImei]
	@IMEI NVARCHAR(100)
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT a.*
FROM
	[JFW].[Device] a left join
	JFW.DeviceProfile b on a.ID = b.Device_ID
WHERE b.IMEI = @IMEI



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method inserts data into the [JFW].[Device] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Device_Insert]
	@User_ID bigint,
	@Device_Identifier varchar(100),
	@Device_Token varchar(250) = null,
	@Device_Session varchar(100) = null,
	@Created_By bigint = null
AS

INSERT INTO [JFW].[Device]
	(
	[User_ID],
	[Device_Identifier],
	[Device_Token],
	[Device_Session],
	[Modified_By],
	[Modified_Date],
	[Created_By],
	[Created_Date]
	)
VALUES
	(
		@User_ID,
		@Device_Identifier,
		@Device_Token,
		@Device_Session,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
	)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Created by:        dba03@jexpa.com
-- Create date: 2021-02-17
-- Description:    this stored procedure retrieves the list of licenses according to the search criteria.
-- =============================================
CREATE PROCEDURE [JFW].[usp_Device_List]
	@ID bigint = NULL,
	@User_ID bigint = NULL,
	@Device_Identifier varchar(100) = null,
	@Device_Token varchar(250) = null,
	@Modified_Date_From datetime = NULL,
	@Modified_Date_To datetime = NULL,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN
	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	IF(@ID IS NOT NULL AND @ID <> '') 
    SELECT @whereClause = CONCAT(@whereClause,' AND [ID] = ', @ID, ' ')

	IF(@User_ID IS NOT NULL AND @User_ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [User_ID] = ', @User_ID, ' ')

	IF(@Device_Identifier IS NOT NULL AND @Device_Identifier <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Device_Identifier] = ''', @Device_Identifier, ''' ')

	IF(@Device_Token IS NOT NULL AND @Device_Token <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Device_Token] = ''', @Device_Token, ''' ')

	IF(@Modified_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause, ' AND [Modified_Date] >= ''', @Modified_Date_From, ''' ')

	IF(@Modified_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause, ' AND [Modified_Date] <= ''', @Modified_Date_To, ''' ')

	IF(@Created_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause, ' AND [Created_Date] >= ''', @Created_Date_From, ''' ')

	IF(@Created_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause, ' AND [Created_Date] <= ''', @Created_Date_To, ''' ')

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')


	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' +  
    ' FROM [JFW].[Device]' +
    ' WHERE ' +@whereClause + 
    ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order +
    @PAGINATION


	-- Execute the SQL statement
	--PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString

END



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method updates data for the [JFW].[Device] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Device_Update]
	@ID bigint,
	@User_ID bigint,
	@Device_Identifier varchar(100),
	@Device_Token varchar(250),
	@Device_Session varchar(100),
	@Modified_By bigint
AS

UPDATE [JFW].[Device] SET
    [User_ID] = @User_ID,
    [Device_Identifier] = @Device_Identifier,
    [Device_Token] = @Device_Token,
	[Device_Session] = @Device_Session,
    [Modified_By] = @Modified_By,
    [Modified_Date] = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- EXEC [JFW].[usp_Device_View]
-- EXEC [JFW].[usp_Device_View] @Keyword='MyPhone'
-- =============================================
-- Created by:        jin.jackson
-- Create date: 2022-01-24
-- Update date: 2023-02-23
-- Description: Gets a list of devices and their associated data.
-- =============================================
CREATE PROCEDURE [JFW].[usp_Device_View]
	@Device_ID bigint = NULL,
	@User_ID bigint = NULL,
	@Device_Identifier varchar(100) = NULL,
	@Created_Date_From datetime = NULL,
	@End_Date datetime = NULL,
	@Keyword nvarchar(1000) = NULL,
	@Limit int = NULL,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN
	DECLARE 
    @selectClause nvarchar(max) = 'SELECT ',
    @whereClause nvarchar(max) = CONCAT(CHAR(13), 'WHERE 1=1 '),
    @fromClause NVARCHAR(MAX) =  CONCAT(CHAR(13), 'FROM '),
    @deviceFilterQuery nvarchar(max),
    @deviceProfileFilterQuery nvarchar(max),
    @deviceSettingFilterQuery nvarchar(max),
    @tmpSqlString nvarchar(max),
    @sqlString nvarchar(max)

	CREATE TABLE #temp
	(
		tmpId bigint not null unique
	)

	--- Build the from clause
	SET @fromClause = CONCAT(@fromClause, '[JFW].[Device] AS D')
	SET @fromClause = CONCAT(@fromClause, CHAR(13), 'LEFT JOIN [JFW].[DeviceProfile] AS DP ON D.[ID] = DP.[Device_ID]')

	--- Build the select clause
	IF(@Limit IS NOT NULL)
    BEGIN
		SET @selectClause += CONCAT('TOP (', @Limit, ') ')
	END

	SET @selectClause = CONCAT(@selectClause, 'D.*, ')

	--- Build the select clause for DeviceProfile
	SET @selectClause = CONCAT(@selectClause, [JFW].[fn_GenerateColumnAliases]('DeviceProfile', 'DeviceProfile_', 'DP'))

	--- Build the where clause
	SET @deviceFilterQuery = [JFW].[fn_GetTableViewSearchQuery]('JFW', 'Device', @Keyword)
	SET @deviceProfileFilterQuery = [JFW].[fn_GetTableViewSearchQuery]('JFW', 'DeviceProfile', @Keyword)

	IF(@Device_ID IS NOT NULL)
    BEGIN
		SET @whereClause = CONCAT(@whereClause, 'AND D.[ID] = ', @Device_ID)
	END

	IF(@User_ID IS NOT NULL)
    BEGIN
		SET @whereClause = CONCAT(@whereClause, 'AND D.[User_ID] = ', @User_ID)
	END

	IF(@Device_Identifier IS NOT NULL)
    BEGIN
		SET @whereClause = CONCAT(@whereClause, 'AND D.[Device_Identifier] = ''', @Device_Identifier, '''')
	END

	IF (@Keyword IS NOT NULL)
    BEGIN
		SET @tmpSqlString = CONCAT('INSERT INTO #temp(tmpId) SELECT [ID] FROM (', @deviceFilterQuery, ') as X')
		-- PRINT CONCAT('SQL string: ', @tmpSqlString)
		EXEC sp_executesql @tmpSqlString
		SET @tmpSqlString = CONCAT('INSERT INTO #temp(tmpId) SELECT [Device_ID] FROM (', @deviceProfileFilterQuery, ') as X WHERE [Device_ID] NOT IN (SELECT tmpId FROM #temp)')
		-- PRINT CONCAT('SQL string: ', @tmpSqlString)
		EXEC sp_executesql @tmpSqlString
		SET @whereClause = CONCAT(@whereClause, ' AND D.[ID] IN (SELECT tmpId FROM #temp)')
	END

	IF (@Created_Date_From IS NOT NULL)
    BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND D.[Created_Date] >= ''', @Created_Date_From, '''')
	END

	IF(@End_Date IS NOT NULL)
    BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND D.[Created_Date] <= ''', @End_Date, '''')
	END

	SET @sqlString = @selectClause + @fromClause + @whereClause + ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order

	-- Execute the SQL statement
	-- PRINT CONCAT('SQL string: ', @sqlString)
	EXEC sp_executesql @sqlString

END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, March 30, 2021
-- Description:  this method delete single or multiple rows in the [JFW].[DeviceProfile] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_DeviceProfile_Delete]
	@ID bigint
AS

DELETE FROM
    [JFW].[DeviceProfile]
WHERE [ID] = @ID


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method gets data of the [JFW].[DeviceProfile] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_DeviceProfile_Get]
	@ID bigint
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT *
FROM
	[JFW].[DeviceProfile]
WHERE ID = @ID


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method inserts data into the [JFW].[DeviceProfile] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_DeviceProfile_Insert]
	@Device_ID bigint,
	@Device_Name nvarchar(50),
	@Phone_Number varchar(100),
	@OS_Device nvarchar(50),
	@App_Version_Number varchar(20),
	@ICCID varchar(50),
	@IMSI varchar(50),
	@IMEI varchar(50),
	@Country_ID bigint,
	@SimCard_Info varchar(50),
	@TimeZone_ID bigint,
	@Modified_By bigint,
	@Created_By bigint
AS

INSERT INTO [JFW].[DeviceProfile]
	(
	[Device_ID],
	[Device_Name],
	[Phone_Number],
	[OS_Device],
	[App_Version_Number],
	[ICCID],
	[IMSI],
	[IMEI],
	[Country_ID],
	[SimCard_Info],
	[TimeZone_ID],
	[Modified_By],
	[Modified_Date],
	[Created_By],
	[Created_Date]
	)
VALUES
	(
		@Device_ID,
		@Device_Name,
		@Phone_Number,
		@OS_Device,
		@App_Version_Number,
		@ICCID,
		@IMSI,
		@IMEI,
		@Country_ID,
		@SimCard_Info,
		@TimeZone_ID,
		@Modified_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Created by:        dba03@jexpa.com
-- Create date: 2021-12-17
-- Description:    this stored procedure retrieves the list of licenses according to the search criteria.

-- =============================================
CREATE PROCEDURE [JFW].[usp_DeviceProfile_List]
	@Device_ID bigint = null,
	@Device_Name nvarchar(50) = null,
	@Phone_Number varchar(100) = null,
	@OS_Device nvarchar(50) = null,
	@App_Version_Number varchar(20) = null,
	@ICCID varchar(50) = null,
	@IMSI varchar(50) = null,
	@IMEI varchar(50) = null,
	@Country_ID bigint = null,
	@SimCard_Info varchar(50) = null,
	@TimeZone_ID bigint = null,
	@Modified_Date_From datetime = NULL,
	@Modified_Date_To datetime = NULL,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'

AS
BEGIN
	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	IF(@Device_ID IS NOT NULL AND @Device_ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Device_ID] = ', @Device_ID, ' ')

	IF(@Device_Name IS NOT NULL AND @Device_Name <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Device_Name] = ''', @Device_Name, ''' ')

	IF(@Phone_Number IS NOT NULL AND @Phone_Number <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Phone_Number] = ''', @Phone_Number, ''' ')

	IF(@OS_Device IS NOT NULL AND @OS_Device <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [OS_Device] = ''', @OS_Device, ''' ')

	IF(@App_Version_Number IS NOT NULL AND @App_Version_Number <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [App_Version_Number] = ''', @App_Version_Number, ''' ')

	IF(@ICCID IS NOT NULL AND @ICCID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [ICCID] = ''', @ICCID, ''' ')

	IF(@IMSI IS NOT NULL AND @IMSI <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [IMSI] = ''', @IMSI, ''' ')

	IF(@IMEI IS NOT NULL AND @IMEI <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [IMEI] = ''', @IMEI, ''' ')

	IF(@Country_ID IS NOT NULL AND @Country_ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Country_ID] = ''', @Country_ID, ''' ')

	IF(@SimCard_Info IS NOT NULL AND @SimCard_Info <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [SimCard_Info] = ''', @SimCard_Info, ''' ')

	IF(@TimeZone_ID IS NOT NULL AND @TimeZone_ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [TimeZone_ID] = ''', @TimeZone_ID, ''' ')


	IF(@Modified_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] >= ''', @Modified_Date_From, ''' ')

	IF(@Modified_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] <= ''', @Modified_Date_To, ''' ')

	IF(@Created_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] >= ''', @Created_Date_From, ''' ')

	IF(@Created_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] <= ''', @Created_Date_To, ''' ')

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')


	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' +
    ' FROM [JFW].[DeviceProfile]' +
    ' WHERE ' +@whereClause + 
    ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order +
    @PAGINATION


	-- Execute the SQL statement
	--PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString

END



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method updates data for the [JFW].[DeviceProfile] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_DeviceProfile_Update]
	@ID bigint,
	@Device_ID bigint,
	@Device_Name nvarchar(50),
	@Phone_Number varchar(100),
	@OS_Device nvarchar(50),
	@App_Version_Number varchar(20),
	@ICCID varchar(50),
	@IMSI varchar(50),
	@IMEI varchar(50),
	@Country_ID bigint,
	@SimCard_Info varchar(50),
	@TimeZone_ID bigint,
	@Modified_By bigint
AS

UPDATE [JFW].[DeviceProfile] SET
    [Device_ID] = @Device_ID,
    [Device_Name] = @Device_Name,
    [Phone_Number] = @Phone_Number,
    [OS_Device] = @OS_Device,
    [App_Version_Number] = @App_Version_Number,
    [ICCID] = @ICCID,
    [IMSI] = @IMSI,
    [IMEI] = @IMEI,
    [Country_ID] = @Country_ID,
    [SimCard_Info] = @SimCard_Info,
    [TimeZone_ID] = @TimeZone_ID,
    [Modified_By] = @Modified_By,
    [Modified_Date] = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 20, 2021
-- Description:  this method deletes multiple rows in the [JFW].[EmailTracking] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_EmailTracking_Delete]
	@ID bigint
AS




DELETE FROM
    [JFW].[EmailTracking]
WHERE [ID] = @ID


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- EmailTracking table - Get
-- EXEC [JFW].[usp_EmailTracking_Get] @ID = 1
------------------------------------------------------------
-- Created by:    dba03
-- Created date:  2021-07-20
-- Modified by:   jin.jackson
-- Modified date: 2022-11-03
-- Description:   this method gets data from the [JFW].[EmailTracking] table.
------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_EmailTracking_Get]
	@ID bigint
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT *
FROM
	[JFW].[EmailTracking]
WHERE ID = @ID



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- EXEC [JFW].[usp_EmailTracking_Insert] @Brand_ID = 1, @Support_Code = 'SAMPLESUPPORTCODE', @Pattern_Code = 'SAMPLEPATTERNCODE', @Email_From = 'SAMPLEEMAILFROM', @Email_To = 'SAMPLEEMAILTO', @Email_CC = 'SAMPLEEMAILCC', @Email_BCC = 'SAMPLEEMAILBCC', @Email_Subject = 'SAMPLEEMAILSUBJECT', @Email_Body = 'SAMPLEEMAILBODY', @Sent_Time = '2021-07-20 00:00:00', @Status = 1, @Created_By = 1
------------------------------------------------------------
-- Created by:    dba03@jexpa.com
-- Created date:  2021-07-20
-- Modified by:   jin.jackson
-- Modified date: 2022-11-03
-- Description:   this method inserts data into the [JFW].[EmailTracking] table.
------------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_EmailTracking_Insert]
	@Brand_ID bigint = 0,
	@Support_Code varchar(150) = NULL,
	@Pattern_Code varchar(150) = NULL,
	@Email_From varchar(500) = NULL,
	@Email_To varchar(max) = NULL,
	@Email_CC varchar(max) = NULL,
	@Email_BCC varchar(max) = NULL,
	@Email_Subject nvarchar(1024) = NULL,
	@Email_Body nvarchar(max) = NULL,
	@Sent_Time datetime = NULL,
	@Status smallint = 1,
	@Created_By bigint = null
AS

INSERT INTO [JFW].[EmailTracking]
	(
	[Brand_ID],
	[Support_Code],
	[Pattern_Code],
	[Email_From],
	[Email_To],
	[Email_CC],
	[Email_BCC],
	[Email_Subject],
	[Email_Body],
	[Sent_Time],
	[Status],
	Modified_By,
	Modified_Date,
	[Created_By],
	[Created_Date]
	)
VALUES
	(
		@Brand_ID,
		@Support_Code,
		@Pattern_Code,
		@Email_From,
		@Email_To,
		@Email_CC,
		@Email_BCC,
		@Email_Subject,
		@Email_Body,
		@Sent_Time,
		@Status,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- EmailTracking table - List
-- EXEC [JFW].[usp_EmailTracking_List] @Email_CC = 'admin@jfwlab.com'
------------------------------------------------------------
-- Created by:    dba03
-- Created date:  2021-07-20
-- Modified by:   jin.jackson
-- Modified date: 2022-11-03
-- Description:   this method lists data from the [JFW].[EmailTracking] table.
------------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_EmailTracking_List]
	@Brand_ID bigint = NULL,
	@Support_Code varchar(150) = NULL,
	@Pattern_Code varchar(150) = NULL,
	@Email_From varchar(500) = NULL,
	@Email_To varchar(max) = NULL,
	@Email_CC varchar(max) = NULL,
	@Email_BCC varchar(max) = NULL,
	@Email_Subject nvarchar(1024) = NULL,
	@Email_Body nvarchar(max) = NULL,
	@Sent_Time_From datetime = NULL,
	@Sent_Time_To datetime = NULL,
	@Status smallint = NULL,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Keyword nvarchar(1000) = NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN

	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @CrossApply nvarchar(max) = '',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	IF (@Brand_ID IS NOT NULL AND @Brand_ID > 0)
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND (et.[Brand_ID] = ', @Brand_ID, ') ')
	END

	IF (@Support_Code IS NOT NULL AND @Support_Code <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND (et.[Support_Code] = ''', @Support_Code, ''') ')
	END

	IF (@Pattern_Code IS NOT NULL AND @Pattern_Code <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND (et.[Pattern_Code] = ''', @Pattern_Code, ''') ')
	END

	-- If Email_From is not null, then we will use the cross apply to split the email addresses
	IF (@Email_From IS NOT NULL AND @Email_From <> '')
    BEGIN
		SELECT @CrossApply = CONCAT(@CrossApply, ' CROSS APPLY [JFW].[fn_Split](et.Email_From, '';'') etFrom ')
		SELECT @whereClause = CONCAT(@whereClause,' AND (etFrom.tvalue = ''', @Email_From, ''') ')
	END

	-- If Email_To is not null, then we will use the cross apply to split the email addresses
	IF (@Email_To IS NOT NULL AND @Email_To <> '')
    BEGIN
		SELECT @CrossApply = CONCAT(@CrossApply, ' CROSS APPLY [JFW].[fn_Split](et.Email_To, '';'') etTo ')
		SELECT @whereClause = CONCAT(@whereClause,' AND (etTo.tvalue = ''', @Email_To, ''') ')
	END

	-- If Email_CC is not null, then we will use the cross apply to split the email addresses
	IF (@Email_CC IS NOT NULL AND @Email_CC <> '')
    BEGIN
		SELECT @CrossApply = CONCAT(@CrossApply, ' CROSS APPLY [JFW].[fn_Split](et.Email_CC, '';'') etCC ')
		SELECT @whereClause = CONCAT(@whereClause,' AND (etCC.tvalue = ''', @Email_CC, ''') ')
	END

	-- If Email_BCC is not null, then we will use the cross apply to split the email addresses
	IF (@Email_BCC IS NOT NULL AND @Email_BCC <> '')
    BEGIN
		SELECT @CrossApply = CONCAT(@CrossApply, ' CROSS APPLY [JFW].[fn_Split](et.Email_BCC, '';'') etBCC ')
		SELECT @whereClause = CONCAT(@whereClause,' AND (etBCC.tvalue = ''', @Email_BCC, ''') ')
	END

	IF (@Email_Subject IS NOT NULL AND @Email_Subject <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND (et.[Email_Subject] LIKE ''%', @Email_Subject, '%'') ')
	END

	IF (@Email_Body IS NOT NULL AND @Email_Body <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND (et.[Email_Body] LIKE ''%', @Email_Body, '%'') ')
	END

	IF (@Sent_Time_From IS NOT NULL)
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND (et.[Sent_Time] >= ''', @Sent_Time_From, ''') ')
	END

	IF (@Sent_Time_To IS NOT NULL)
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND (et.[Sent_Time] <= ''', @Sent_Time_To, ''') ')
	END

	IF (@Status IS NOT NULL)
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND (et.[Status] = ', @Status, ') ')
	END

	IF(@Created_Date_From IS NOT NULL AND @Created_Date_To IS NOT NULL)
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause, ' AND (et.[Created_Date] >= ''', @Created_Date_From, ''' AND et.[Created_Date] <= ''',@Created_Date_To, ''') ')
	END

	-- If Keyword is not null, then we will search in the following fields: Email_From, Email_To, Email_CC, Email_BCC, Email_Subject, Email_Body
	IF(@Keyword IS NOT NULL AND @Keyword <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause, ' AND (et.[Email_From] LIKE N''%', @Keyword, '%'') OR (et.[Email_To] LIKE N''%', @Keyword, '%'') OR (et.[Email_CC] LIKE N''%', @Keyword, '%'') OR (et.[Email_BCC] LIKE N''%', @Keyword, '%'') OR (et.[Email_Subject] LIKE N''%', @Keyword, '%'') OR (et.[Email_Body] LIKE N''%', @Keyword, '%'') ')
	END

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	SELECT @sqlString = 'SELECT '+ @LimitClause +' et.*' +
    ' FROM [JFW].[EmailTracking] et' + @CrossApply +
    ' WHERE ' + @whereClause + 
    ' ORDER BY ' + CONCAT('et.[',@Sort_Data_Field,']') + ' ' + @Sort_Order + 
    @PAGINATION


	-- Execute the SQL statement
	--PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString

-- SELECT @sqlString = 'SELECT COUNT(et.[ID]) AS Total' +
-- ' FROM [JFW].[EmailTracking] et' + 
-- ' WHERE ' + @whereClause
--PRINT CONCAT('SQL string (count): ',@sqlString)
-- EXEC sp_executesql @sqlString

END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- EmailTracking table - Update
-- EXEC [JFW].[usp_EmailTracking_Update] @ID = 1, @Brand_ID = 1, @Support_Code = 'SUPPORT_CODE', @Pattern_Code = 'PATTERN_CODE', @Email_From = 'support@jfwlab.com', @Email_To = 'customer@jfwlab.com', @Email_CC = 'admin@jfwlab.com;superadmin@jfwlab.com', @Email_BCC = 'admin@jfwlab.com;superadmin@jfwlab.com', @Email_Subject = 'EMAIL_SUBJECT', @Email_Body = 'EMAIL_BODY', @Sent_Time = '2021-07-20 00:00:00', @Status = 1
------------------------------------------------------------
-- Created by:    dba03
-- Created date:  2021-07-20
-- Modified by:   jin.jackson
-- Modified date: 2022-11-03
-- Description:   this method updates data from the [JFW].[EmailTracking] table.
------------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_EmailTracking_Update]
	@ID bigint = 0,
	@Brand_ID bigint = 0,
	@Support_Code varchar(150) = NULL,
	@Pattern_Code varchar(150) = NULL,
	@Email_From varchar(500) = NULL,
	@Email_To varchar(max) = NULL,
	@Email_CC varchar(max) = NULL,
	@Email_BCC varchar(max) = NULL,
	@Email_Subject nvarchar(1024) = NULL,
	@Email_Body nvarchar(max) = NULL,
	@Sent_Time datetime = NULL,
	@Status smallint = 1,
	@Modified_By bigint
AS
UPDATE [JFW].[EmailTracking] SET
    [Brand_ID] = @Brand_ID,
    [Support_Code] = @Support_Code,
    [Pattern_Code] = @Pattern_Code,
    [Email_From] = @Email_From,
    [Email_To] = @Email_To,
    [Email_CC] = @Email_CC,
    [Email_BCC] = @Email_BCC,
    [Email_Subject] = @Email_Subject,
    [Email_Body] = @Email_Body,
    [Sent_Time] = @Sent_Time,
    [Status] = @Status,
	Modified_By = @Modified_By,
	Modified_Date = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows' 

--- Delete

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:     jin.jackson
-- Created date:   2023-02-24
-- Description:    This method deletes a row in the [JFW].[ExternalProvider] table by the ID.
-- Example:        EXEC [JFW].[usp_ExternalProvider_Delete] @ID = 1
------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_ExternalProvider_Delete]
	@ID bigint
AS
BEGIN
	DELETE FROM [JFW].[ExternalProvider] WHERE [ID] = @ID
	SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'
END

--- GET

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:     jin.jackson
-- Created date:   2023-02-24
-- Description:    This method gets a row in the [JFW].[ExternalProvider] table by the ID.
-- Example:        EXEC [JFW].[usp_ExternalProvider_Get] @ID = 1
------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_ExternalProvider_Get]
	@ID bigint
AS
BEGIN
	SELECT *
	FROM [JFW].[ExternalProvider]
	WHERE [ID] = @ID
END

--- Insert

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:     jin.jackson
-- Created date:   2023-02-24
-- Description:    This method inserts a row in the [JFW].[ExternalProvider] table.
-- Example:        EXEC [JFW].[usp_ExternalProvider_Insert] @Name = 'Google', @Description = 'Google OAuth2', @Client_ID = '626742627356-tqorecfi9kkvo1cus7ncj0lcq042c8gm.apps.googleusercontent.com', @Client_Secret = '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', @Redirect_URI = 'https://localhost:7028/api/accounts/auth/google/callback', @Status = 1
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_ExternalProvider_Insert]
	@Code varchar(150),
	@Name varchar(150),
	@Description nvarchar(250),
	@Client_ID varchar(200),
	@Client_Secret varchar(200),
	@Redirect_URI nvarchar(200),
	@Scope nvarchar(200) = NULL,
	@Auth_Endpoint nvarchar(200) = NULL,
	@Token_Endpoint nvarchar(200) = NULL,
	@Icon_Url nvarchar(200) = NULL,
	@Status smallint = 1,
	@Created_By bigint
AS
BEGIN
	INSERT INTO [JFW].[ExternalProvider]
		(
		Code,
		[Name],
		[Description],
		[Client_ID],
		[Client_Secret],
		[Redirect_URI],
		[Scope],
		[Auth_Endpoint],
		[Token_Endpoint],
		[Icon_Url],
		[Status],
		[Created_By],
		[Created_Date],
		[Modified_By],
		[Modified_Date]
		)
	VALUES
		(
			@Code,
			@Name,
			@Description,
			@Client_ID,
			@Client_Secret,
			@Redirect_URI,
			@Scope,
			@Auth_Endpoint,
			@Token_Endpoint,
			@Icon_Url,
			@Status,
			@Created_By,
			GETUTCDATE(),
			@Created_By,
			GETUTCDATE()
	)
	SELECT CAST(@@IDENTITY AS bigint) as 'ID'
END

--- List

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:     jin.jackson
-- Created date:   2023-02-24
-- Description:    This method lists all rows in the [JFW].[ExternalProvider] table.
-- Example:        EXEC [JFW].[usp_ExternalProvider_List]
------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_ExternalProvider_List]
	@Code varchar(50) = null,
	@Name varchar(150) = NULL,
	@Description nvarchar(250) = NULL,
	@Client_ID varchar(200) = NULL,
	@Client_Secret varchar(200) = NULL,
	@Redirect_URI nvarchar(200) = NULL,
	@Scope nvarchar(200) = NULL,
	@Auth_Endpoint nvarchar(200) = NULL,
	@Token_Endpoint nvarchar(200) = NULL,
	@Icon_Url nvarchar(200) = NULL,
	@Status smallint = NULL,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Limit int = NULL,
	@Page_Size int = NULL,
	@Page_Number int = NULL,
	@Sort_Data_Field varchar(50) = 'ID',
	@Sort_Order varchar(4) = 'ASC'
AS
BEGIN
	DECLARE @limitClause nvarchar(max) = ''
	DECLARE @offsetClause nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF @Limit IS NOT NULL
	BEGIN
		SET @limitClause = CONCAT('TOP ', @Limit)
	END

	IF @Page_Size IS NOT NULL AND @Page_Number IS NOT NULL
	BEGIN
		SET @offsetClause = CONCAT('OFFSET ', @skip, ' ROWS FETCH NEXT ', @Page_Size, ' ROWS ONLY')
	END

	IF @Code IS NOT NULL AND @Code <> ''
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Code] = ''', @Code, '''')
	END

	IF @Name IS NOT NULL AND @Name <> ''
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Name] = ''', @Name, '''')
	END

	IF @Description IS NOT NULL AND @Description <> ''
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Description] = ''', @Description, '''')
	END

	IF @Client_ID IS NOT NULL AND @Client_ID <> ''
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Client_ID] = ''', @Client_ID, '''')
	END

	IF @Client_Secret IS NOT NULL AND @Client_Secret <> ''
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Client_Secret] = ''', @Client_Secret, '''')
	END

	IF @Redirect_URI IS NOT NULL AND @Redirect_URI <> ''
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Redirect_URI] = ''', @Redirect_URI, '''')
	END

	IF @Scope IS NOT NULL AND @Scope <> ''
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Scope] = ''', @Scope, '''')
	END

	IF @Auth_Endpoint IS NOT NULL AND @Auth_Endpoint <> ''
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Auth_Endpoint] = ''', @Auth_Endpoint, '''')
	END

	IF @Token_Endpoint IS NOT NULL AND @Token_Endpoint <> ''
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Token_Endpoint] = ''', @Token_Endpoint, '''')
	END

	IF @Icon_Url IS NOT NULL AND @Icon_Url <> ''
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Icon_Url] = ''', @Icon_Url, '''')
	END

	IF @Status IS NOT NULL
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Status] = ', @Status)
	END

	IF @Created_Date_From IS NOT NULL
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Created_Date] >= ''', @Created_Date_From, '''')
	END

	IF @Created_Date_To IS NOT NULL
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Created_Date] <= ''', @Created_Date_To, '''')
	END

	SET @sqlString = CONCAT('SELECT ', @limitClause, ' * FROM [JFW].[ExternalProvider]',
	' WHERE ', @whereClause, 
	' ORDER BY ', @Sort_Data_Field, ' ', @Sort_Order, ' ', 
	@offsetClause)

END

--- Update

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:     jin.jackson
-- Created date:   2023-02-24
-- Description:    This method updates a row in the [JFW].[ExternalProvider] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_ExternalProvider_Update]
	@ID bigint,
	@Name varchar(150),
	@Description nvarchar(250),
	@Client_ID varchar(200),
	@Client_Secret varchar(200),
	@Redirect_URI nvarchar(200),
	@Scope nvarchar(200) = NULL,
	@Auth_Endpoint nvarchar(200) = NULL,
	@Token_Endpoint nvarchar(200) = NULL,
	@Icon_Url nvarchar(200) = NULL,
	@Status smallint = NULL,
	@Modified_By bigint = null
AS
BEGIN
	UPDATE [JFW].[ExternalProvider]
	SET [Name] = @Name,
	[Description] = @Description,
	[Client_ID] = @Client_ID,
	[Client_Secret] = @Client_Secret,
	[Redirect_URI] = @Redirect_URI,
	[Scope] = @Scope,
	[Auth_Endpoint] = @Auth_Endpoint,
	[Token_Endpoint] = @Token_Endpoint,
	[Icon_Url] = @Icon_Url,
	[Status] = @Status,
	Modified_By = @Modified_By,
	Modified_Date = GETUTCDATE()
	WHERE [ID] = @ID

	SELECT CAST(@@ROWCOUNT AS bigint) AS 'TotalRows'
END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:     dba03@jexpa.com
-- Created date:   Tuesday, March 30, 2021
-- Modified by:    jin.jackson
-- Modified date:  2022-09-23
-- Description:    This method deletes multiple rows in the [JFW].[Feature] table by the ID list.
-- Example:        EXEC [JFW].[usp_Feature_Delete] @ID_List = '1,2,3'
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Feature_Delete]
	@ID bigint = NULL
AS

BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DELETE FROM [JFW].[Feature]
        WHERE ID = @ID

END

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'







GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, March 30, 2021
-- Description:  this method gets data of the [JFW].[Feature] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Feature_Get]
	@ID bigint = null
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED


SELECT *
FROM
	[JFW].[Feature]
WHERE ID = @ID







GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Feature Table - Insert
-- EXEC [JFW].[usp_Feature_Insert] @Code = 'SAMPLECODE', @Name = 'SAMPLENAME', @Descripton = 'SAMPLEDESCRIPTION', @Status = 1, @Is_Beta = 0, @OS_Available = 1, @Root_Access_Required = 0, @Display_Data_Even_Expired = 0, @Tooltip = 'SAMPLETOOLTIP', @Public_Note = 'SAMPLEPUBLICNOTE', @ZOrder = 1, @Created_By = 1
------------------------------------------------------------------------------------------------------------------------
-- Created by:    dba03
-- Created date:  2021-07-06
-- Modified by:   jin.jackson
-- Modified date: 2022-11-03
-- Description:   this method inserts data into the [JFW].[Feature] table.
------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_Feature_Insert]
	@Code nvarchar(255),
	@Name nvarchar(255),
	@Description nvarchar(1000),
	@Feature_Value int,
	@Status SMALLINT,
	@Is_Beta bit,
	@OS_Available nvarchar(255),
	@Root_Access_Required bit,
	@Display_Data_Even_Expired bit,
	@Tooltip nvarchar(100),
	@Public_Note nvarchar(max),
	@ZOrder bigint,
	@Created_By bigint
AS

INSERT INTO [JFW].[Feature]
	(
	[Code],
	[Name],
	[Description],
	[Feature_Value],
	[Status],
	[Is_Beta],
	[OS_Available],
	[Root_Access_Required],
	[Display_Data_Even_Expired],
	[Tooltip],
	[Public_Note],
	[ZOrder],
	Modified_By,
	Modified_Date,
	[Created_By],
	[Created_Date]
	)
VALUES
	(
		@Code,
		@Name,
		@Description,
		@Feature_Value,
		@Status,
		@Is_Beta,
		@OS_Available,
		@Root_Access_Required,
		@Display_Data_Even_Expired,
		@Tooltip,
		@Public_Note,
		@ZOrder,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [JFW].[usp_Feature_List]
	@ID bigint = null,
	@Package_ID bigint = null,
	@Code nvarchar(255)  = null,
	@Name nvarchar(255) = null,
	@Description nvarchar(1000) = null,
	@Status SMALLINT = null,
	@Feature_Value int = null,
	@Is_Beta bit = null,
	@OS_Available nvarchar(255) = null,
	@Root_Access_Required bit = null,
	@Display_Data_Even_Expired bit = null,
	@Tooltip nvarchar(100) = null,
	@Public_Note nvarchar(max) = null,
	@ZOrder bigint = null,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN
	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	IF(@ID IS NOT NULL AND @ID <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([ID] = ''', @ID, ''') ')
	END

	IF(@Package_ID IS NOT NULL AND @Package_ID <> '')
	BEGIN
		-- Look up the package ID from the packagefeature table
		SELECT @whereClause = CONCAT(@whereClause,' AND ([ID] IN (SELECT [Feature_ID] FROM [JFW].[PackageFeature] WHERE [Package_ID] = ', @Package_ID, ')) ')
	END

	IF(@Code IS NOT NULL AND @Code <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Code] = ''', @Code, ''') ')
	END

	IF(@Name IS NOT NULL AND @Name <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Name] = ''', @Name, ''') ')
	END

	IF(@Description IS NOT NULL AND @Description <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Description] = ''', @Description, ''') ')
	END

	IF(@Feature_Value IS NOT NULL AND @Feature_Value <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Feature_Value] = ''', @Feature_Value, ''') ')
	END

	IF(@Is_Beta IS NOT NULL AND @Is_Beta <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Is_Beta] = ''', @Is_Beta, ''') ')
	END

	IF(@Status IS NOT NULL AND @Status <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Status] = ''', @Status, ''') ')
	END

	IF(@OS_Available IS NOT NULL AND @OS_Available <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([OS_Available] = ''', @OS_Available, ''') ')
	END

	IF(@Root_Access_Required IS NOT NULL AND @Root_Access_Required <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Root_Access_Required] = ''', @Root_Access_Required, ''') ')
	END

	IF(@Display_Data_Even_Expired IS NOT NULL AND @Display_Data_Even_Expired <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Display_Data_Even_Expired] = ''', @Display_Data_Even_Expired, ''') ')
	END

	IF(@Tooltip IS NOT NULL AND @Tooltip <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Tooltip] = ''', @Tooltip, ''') ')
	END

	IF(@Public_Note IS NOT NULL AND @Public_Note <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Public_Note] = ''', @Public_Note, ''') ')
	END

	IF(@ZOrder IS NOT NULL AND @ZOrder <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([ZOrder] = ''', @ZOrder, ''') ')
	END

	IF(@Created_Date_From IS NOT NULL)
	BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Created_Date] >= ''', @Created_Date_From, ''') ')
	END

	IF(@Created_Date_To IS NOT NULL)
	BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Created_Date] <= ''', @Created_Date_To, ''') ')
	END

	SELECT @sqlString = 'SELECT * '+
                'FROM [JFW].[Feature] '+
                ' WHERE ' +@whereClause + 
                ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order +
                @PAGINATION

	-- Execute the SQL statement
	PRINT @sqlString
	EXEC sp_executesql @sqlString
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Feature Table - Update
-- EXEC [JFW].[usp_Feature_Update] @Id = 1, @Code = 'SAMPLECODE', @Name = 'SAMPLENAME', @Descripton = 'SAMPLEDESCRIPTION', @Status = 1, @Icon = 'SAMPLEICON', @URL = 'SAMPLEURL', @Is_Beta = 0, @OS_Available = 1, @Root_Access_Required = 0, @Display_Data_Even_Expired = 0, @Tooltip = 'SAMPLETOOLTIP', @Public_Note = 'SAMPLEPUBLICNOTE', @ZOrder = 1, @Created_By = 1
------------------------------------------------------------------------------------------------------------------------
-- Created by:    dba03
-- Created date:  2021-07-06
-- Modified by:   jin.jackson
-- Modified date: 2022-11-03
-- Description:   this method updates data into the [JFW].[Feature] table.
------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_Feature_Update]
	@ID bigint,
	@Code nvarchar(255),
	@Name nvarchar(255),
	@Description nvarchar(1000),
	@Feature_Value int,
	@Status SMALLINT,
	@Is_Beta bit,
	@OS_Available nvarchar(255),
	@Root_Access_Required bit,
	@Display_Data_Even_Expired bit,
	@Tooltip nvarchar(100),
	@Public_Note nvarchar(max),
	@ZOrder bigint,
	@Modified_By bigint
AS

UPDATE [JFW].Feature SET
    [Code] = @Code, 
    [Name] = @Name, 
    [Description] = @Description,
	[Feature_Value] = @Feature_Value,
    [Status] = @Status, 
    [Is_Beta] = @Is_Beta, 
    [OS_Available] = @OS_Available, 
    [Root_Access_Required] = @Root_Access_Required, 
    [Display_Data_Even_Expired] = @Display_Data_Even_Expired, 
    [Tooltip] = @Tooltip, 
    [Public_Note] = @Public_Note, 
    [ZOrder] = @ZOrder,
	Modified_By = @Modified_By,
	Modified_Date = GETUTCDATE()

WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method deletes multiple rows in the [JFW].[HelpDesk] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_HelpDesk_Delete]
	@ID bigint
AS




DELETE FROM
    [JFW].[HelpDesk]
WHERE [ID] = @ID


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [JFW].[usp_HelpDesk_Get]
	@ID bigint
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT *
FROM
	[JFW].[HelpDesk]
WHERE
    ID = @ID



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method inserts data into the [JFW].[HelpDesk] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_HelpDesk_Insert]
	@Parent_ID bigint = null,
	@Group_Code varchar(100) = null,
	@Code varchar(100) = null,
	@Name varchar(250) = null,
	@Content nvarchar(max) = null,
	@Description nvarchar(500) = null,
	@Status smallint = 0,
	@Positive bigint  = null,
	@Negative bigint = null,
	@Total_View bigint = null,
	@ZOrder bigint = null,
	@Created_By bigint = null

AS

INSERT INTO [JFW].[HelpDesk]
	(
	[Parent_ID],
	[Group_Code],
	[Code],
	[Name],
	[Content],
	[Description],
	[Status],
	[Positive],
	[Negative],
	[Total_View],
	[ZOrder],
	[Modified_By],
	[Modified_Date],
	[Created_By],
	[Created_Date]
	)
VALUES
	(
		@Parent_ID,
		@Group_Code,
		@Code,
		@Name,
		@Content,
		@Description,
		@Status,
		@Positive,
		@Negative,
		@Total_View,
		@ZOrder,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [JFW].[usp_HelpDesk_List]
	@Parent_ID bigint = NULL,
	@Group_Code varchar(100) = NULL,
	@Code varchar(100) = NULL,
	@Name varchar(250) = NULL,
	@Content nvarchar(max) = NULL,
	@Description nvarchar(500) = NULL,
	@Status smallint = NULL,
	@Positive bigint = NULL,
	@Negative bigint = NULL,
	@Total_View bigint = NULL,
	@ZOrder bigint = NULL,
	@Is_System bit = NULL,
	@Modified_Date_From datetime = NULL,
	@Modified_Date_To datetime = NULL,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN
	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	IF(@Parent_ID IS NOT NULL AND @Parent_ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Parent_ID] = ', @Parent_ID, ' ')

	IF(@Group_Code IS NOT NULL AND @Group_Code <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Group_Code] = ''', @Group_Code, ''' ')

	IF(@Code IS NOT NULL AND @Code <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Code] = ''', @Code, ''' ')

	IF(@Name IS NOT NULL AND @Name <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Name] = ''', @Name, ''' ')

	IF(@Content IS NOT NULL AND @Content <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Content] = ''', @Content, ''' ')

	IF(@Description IS NOT NULL AND @Description <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Description] = ''', @Description, ''' ')

	IF(@Status IS NOT NULL AND @Status <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Status] = ''', @Status, ''' ')

	IF(@Positive IS NOT NULL AND @Positive <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Positive] = ''', @Positive, ''' ')

	IF(@Negative IS NOT NULL AND @Negative <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Negative] = ''', @Negative, ''' ')

	IF(@Total_View IS NOT NULL AND @Total_View <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Total_View] = ''', @Total_View, ''' ')

	IF(@ZOrder IS NOT NULL)
    SELECT @whereClause = CONCAT(@whereClause,' AND [@ZOrder] = ', @ZOrder, ' ')

	IF(@Is_System IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Is_System] = ', @Is_System, ' ')

	IF(@Modified_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] >= ''', @Modified_Date_From, ''' ')

	IF(@Modified_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] <= ''', @Modified_Date_To, ''' ')

	IF(@Created_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] >= ''', @Created_Date_From, ''' ')

	IF(@Created_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] <= ''', @Created_Date_To, ''' ')

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')


	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' + 
    ' FROM [JFW].[HelpDesk]' +
    ' WHERE ' +@whereClause + 
    ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order +
    @PAGINATION


	-- Execute the SQL statement
	--PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString

END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [JFW].[usp_HelpDesk_Update]
	@ID bigint,
	@Parent_ID bigint,
	@Group_Code varchar(100),
	@Code varchar(100),
	@Name varchar(250),
	@Content nvarchar(max),
	@Description nvarchar(500),
	@Status smallint,
	@Positive bigint,
	@Negative bigint,
	@Total_View bigint,
	@ZOrder bigint,
	@Modified_By bigint
AS

UPDATE [JFW].[HelpDesk] SET
    [Parent_ID] = @Parent_ID,
    [Group_Code] = @Group_Code,
    [Code] = @Code,
    [Name] = @Name,
    [Content] = @Content,
    [Description] = @Description,
    [Status] = @Status,
    [Positive] = @Positive,
    [Negative] = @Negative,
    [Total_View] = @Total_View,
    [ZOrder] = @ZOrder,
    [Modified_By] = @Modified_By,
    [Modified_Date] = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method deletes multiple rows in the [JFW].[HelpDeskFeedback] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_HelpDeskFeedback_Delete]
	@ID bigint
AS




DELETE FROM
    [JFW].[HelpDeskFeedback]
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method gets data of the [JFW].[HelpDeskFeedback] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_HelpDeskFeedback_Get]
	@ID bigint

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED



SELECT *
FROM
	[JFW].[HelpDeskFeedback]
WHERE
    ID = @ID




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method inserts data into the [JFW].[HelpDeskFeedback] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_HelpDeskFeedback_Insert]
	@Brand_ID bigint,
	@User_ID bigint,
	@Help_Desk_ID bigint,
	@Priority TINYINT = 0,
	@Feedback_Content nvarchar(max) = null,
	@Status smallint = 0,
	@Created_By bigint = null
AS

INSERT INTO [JFW].[HelpDeskFeedback]
	(
	[Brand_ID],
	[User_ID],
	[Help_Desk_ID],
	[Priority],
	[Feedback_Content],
	[Status],
	Modified_By,
	Modified_Date,
	Created_By,
	[Created_Date]
	)
VALUES
	(
		@Brand_ID,
		@User_ID,
		@Help_Desk_ID,
		@Priority,
		@Feedback_Content,
		@Status,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
	)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Created by:        dba03@jexpa.com
-- Create date: 2021-02-17
-- Description:    this stored procedure retrieves the list of HelpDeskFeedback according to the search criteria.
-- =============================================
CREATE PROCEDURE [JFW].[usp_HelpDeskFeedback_List]
	@Brand_ID bigint = NULL,
	@User_ID bigint = NULL,
	@Help_Desk_ID bigint = NULL,
	@Priority TINYINT = 0,
	@Feedback_Content nvarchar(max) = null,
	@Status smallint = null,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN

	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	IF(@Brand_ID IS NOT NULL AND @Brand_ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Brand_ID] = ', @Brand_ID, ' ')

	IF(@User_ID IS NOT NULL AND @User_ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [User_ID] = ', @User_ID, ' ')

	IF(@Help_Desk_ID IS NOT NULL AND @Help_Desk_ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Help_Desk_ID] = ', @Help_Desk_ID, ' ')

	IF(@Priority IS NOT NULL AND @Priority <> '')
	SELECT @whereClause = CONCAT(@whereClause,' AND [Priority] = ', @Priority, ' ')

	IF(@Feedback_Content IS NOT NULL AND @Feedback_Content <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Feedback_Content] = ', @Feedback_Content, ' ')

	IF(@Status IS NOT NULL AND @Status <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Status] = ', @Status, ' ')

	IF(@Created_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] >= ', @Created_Date_From, ' ')

	IF(@Created_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] <= ', @Created_Date_To, ' ')

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')


	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' + 
    ' FROM [JFW].[HelpDeskFeedback]' +
    ' WHERE ' +@whereClause + 
    ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order +
    @PAGINATION


	-- Execute the SQL statement
	--PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString

END



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method updates data for the [JFW].[HelpDeskFeedback] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_HelpDeskFeedback_Update]
	@ID bigint,
	@Brand_ID bigint,
	@User_ID bigint,
	@Help_Desk_ID bigint,
	@Priority TINYINT,
	@Feedback_Content nvarchar(max),
	@Status smallint,
	@Modified_By bigint
AS

UPDATE [JFW].[HelpDeskFeedback] SET
    [Brand_ID] = @Brand_ID,
    [User_ID] = @User_ID,
    [Help_Desk_ID] = @Help_Desk_ID,
	[Priority] = @Priority,
    [Feedback_Content] = @Feedback_Content,
    [Status] = @Status,
	Modified_By = @Modified_By,
	Modified_Date = GETUTCDATE()

WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method deletes multiple rows in the [JFW].[License] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_License_Delete]
	@ID bigint
AS

DELETE FROM
    [JFW].[License]
WHERE [ID] = @ID


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [JFW].[usp_License_Get]
	@ID bigint

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED


SELECT *
FROM
	[JFW].[License]
WHERE
    ID = @ID




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [JFW].[usp_License_GetByLicenseKey]
	@License_Key varchar(50)

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED


SELECT *
FROM
	[JFW].[License]
WHERE
    License_Key = @License_Key




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- EXEC
------------------------------------------------------------------------------------------------------------------------
-- Created by:    dba03@jexpa.com
-- Created date:  2021-07-13
-- Modified by:   jin.jackson
-- Modified date: 2022-09-30 11:12:39
-- Description:   Insert a new license into the database - [JFW].[License]
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_License_Insert]
	@Brand_ID bigint,
	@Package_ID bigint,
	@SubscriptionType_ID bigint,
	@Source_ID tinyint,
	@License_Key varchar(30),
	@Ref_License varchar(30),
	@Description nvarchar(255) = null,
	@Start_Date datetime,
	@End_Date datetime,
	@Status smallint,
	@Used_By bigint = null,
	@Used_Date datetime = null,
	@Modified_By bigint,
	@Created_By bigint
AS

INSERT INTO [JFW].[License]
	(
	[Brand_ID],
	[Package_ID],
	[SubscriptionType_ID],
	[Source_ID],
	[License_Key],
	[Ref_License],
	[Description],
	[Start_Date],
	[End_Date],
	[Status],
	[Used_By],
	[Used_Date],
	[Modified_By],
	[Modified_Date],
	[Created_By],
	[Created_Date]
	)
VALUES
	(
		@Brand_ID,
		@Package_ID,
		@SubscriptionType_ID,
		@Source_ID,
		@License_Key,
		@Ref_License,
		@Description,
		@Start_Date,
		@End_Date,
		@Status,
		@Used_By,
		@Used_Date,
		@Modified_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- EXEC [JFW].[usp_License_List] @Created_Date_From = '2022-09-01 00:00:00.000', @Created_Date_To = '2022-09-02 00:00:00.000'

CREATE PROCEDURE [JFW].[usp_License_List]
	@Brand_ID bigint = null,
	@Package_ID bigint = null,
	@SubscriptionType_ID bigint = null,
	@Source_ID tinyint = null,
	@License_Key varchar(30) = null,
	@Ref_License varchar(30) = null,
	@Description nvarchar(255) = null,
	@Start_Date datetime = null,
	@End_Date datetime = null,
	@Status smallint = null,
	@Used_By bigint = null,
	@Used_Date datetime = null,
	@Modified_Date_From datetime = null,
	@Modified_Date_To datetime = null,
	@Created_Date_From date = NULL,
	@Created_Date_To date = NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN
	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	IF(@Brand_ID IS NOT NULL AND @Brand_ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Brand_ID] = ', @Brand_ID, ' ')

	IF(@Package_ID IS NOT NULL AND @Package_ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Package_ID] = ', @Package_ID, ' ')

	IF(@SubscriptionType_ID IS NOT NULL AND @SubscriptionType_ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [SubscriptionType_ID] = ', @SubscriptionType_ID, ' ')

	IF(@Source_ID IS NOT NULL AND @Source_ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Source_ID] = ', @Source_ID, ' ')

	IF(@License_Key IS NOT NULL AND @License_Key <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [License_Key] = ''', @License_Key, ''' ')

	IF(@Ref_License IS NOT NULL AND @Ref_License <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Ref_License] = ''', @Ref_License, ''' ')

	IF(@Description IS NOT NULL AND @Description <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Description] = ''', @Description, ''' ')

	IF(@Start_Date IS NOT NULL AND @Start_Date <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Start_Date] = ''', @Start_Date, ''' ')

	IF(@End_Date IS NOT NULL AND @End_Date <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [End_Date] = ''', @End_Date, ''' ')

	IF(@Status IS NOT NULL AND @Status <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Status] = ''', @Status, ''' ')

	IF(@Used_By IS NOT NULL AND @Used_By <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Used_By] = ''', @Used_By, ''' ')

	IF(@Used_Date IS NOT NULL AND @Used_Date <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Used_Date] = ''', @Used_Date, ''' ')

	IF(@Modified_Date_From IS NOT NULL AND @Modified_Date_From <> '')
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] >= ''', @Modified_Date_From, ''' ')

	IF(@Modified_Date_To IS NOT NULL AND @Modified_Date_To <> '')
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] <= ''', @Modified_Date_To, ''' ')

	IF(@Created_Date_From IS NOT NULL AND @Created_Date_From <> '')
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] >= ''', @Created_Date_From, ''' ')

	IF(@Created_Date_To IS NOT NULL AND @Created_Date_To <> '')
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] <= ''', @Created_Date_To, ''' ')

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')


	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' + 
    ' FROM [JFW].[License]' +
    ' WHERE ' +@whereClause + 
    ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order +
    @PAGINATION


	-- Execute the SQL statement
	-- PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString

END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [JFW].[usp_License_Update]
	@ID bigint,
	@Brand_ID bigint,
	@Package_ID bigint,
	@SubscriptionType_ID bigint,
	@Source_ID tinyint,
	@License_Key varchar(30),
	@Ref_License varchar(30),
	@Description nvarchar(255),
	@Start_Date datetime,
	@End_Date datetime,
	@Status smallint,
	@Used_By bigint,
	@Used_Date datetime,
	@Modified_By bigint

AS

UPDATE [JFW].[License] SET
    [Brand_ID] = @Brand_ID,
    [Package_ID] = @Package_ID,
    [Source_ID] = @Source_ID,
    [License_Key] = @License_Key,
    [Ref_License] = @Ref_License,
    [Description] = @Description,
    [Start_Date] = @Start_Date,
    [End_Date] = @End_Date,
    [SubscriptionType_ID] = @SubscriptionType_ID,
    [Status] = @Status,
    [Used_By] = @Used_By,
    [Used_Date] = @Used_Date,
    [Modified_By] = @Modified_By,
    [Modified_Date] = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method deletes multiple rows in the [JFW].[Merchant] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Merchant_Delete]
	@ID bigint
AS


DELETE FROM
    [JFW].[Merchant]
WHERE [ID] = @ID
	AND [Is_System] = 0


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method gets data of the [JFW].[Merchant] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Merchant_Get]
	@ID bigint

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED




SELECT *
FROM
	[JFW].[Merchant]
WHERE
    ID = @ID



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method inserts data into the [JFW].[Merchant] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Merchant_Insert]
	@Merchant_Type smallint,
	@Code varchar(50),
	@Name nvarchar(50) = null,
	@Website nvarchar(250) = null,
	@Description nvarchar(500) = null,
	@ZOrder bigint = null,
	@Status smallint = 1,
	@Is_Default bit = 0,
	@Created_By bigint = null
AS

-- If the merchant is default, then set all other merchants to non-default
IF @Is_Default <> 0
BEGIN
	UPDATE [JFW].[Merchant] SET [Is_Default] = 0
END

INSERT INTO [JFW].[Merchant]
	(
	[Merchant_Type],
	[Code],
	[Name],
	[Website],
	[Description],
	[ZOrder],
	[Status],
	[Is_Default],
	[Modified_By],
	[Modified_Date],
	[Created_By],
	[Created_Date]
	)
VALUES
	(
		@Merchant_Type,
		@Code,
		@Name,
		@Website,
		@Description,
		@ZOrder,
		@Status,
		@Is_Default,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [JFW].[usp_Merchant_List]
	@Merchant_Type smallint = NULL,
	@Code varchar(50) = NULL,
	@Name nvarchar(50) = NULL,
	@Website nvarchar(250) = NULL,
	@Status smallint = NULL,
	@Description nvarchar(500) = NULL,
	@Long_Description nvarchar(max) = NULL,
	@Payment_Link nvarchar(1000) = NULL,
	@ZOrder bigint = NULL,
	@Modified_Date_From datetime = NULL,
	@Modified_Date_To datetime = NULL,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN
	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	IF(@Merchant_Type IS NOT NULL AND @Merchant_Type <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Merchant_Type] = ''', @Merchant_Type, ''' ')

	IF(@Code IS NOT NULL AND @Code <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Code] = ''', @Code, ''' ')

	IF(@Name IS NOT NULL AND @Name <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Name] = ''', @Name, ''' ')

	IF(@Website IS NOT NULL AND @Website <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Website] = ''', @Website, ''' ')

	IF(@Status IS NOT NULL AND @Status <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Status] = ''', @Status, ''' ')

	IF(@Description IS NOT NULL AND @Description <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Description] = ''', @Description, ''' ')

	IF(@Long_Description IS NOT NULL AND @Long_Description <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Long_Description] = ''', @Long_Description, ''' ')

	IF(@Payment_Link IS NOT NULL AND @Payment_Link <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Payment_Link] = ''', @Payment_Link, ''' ')

	IF(@ZOrder IS NOT NULL AND @ZOrder <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [ZOrder] = ''', @ZOrder, ''' ')

	IF(@Modified_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] >= ''', @Modified_Date_From, ''' ')

	IF(@Modified_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] <= ''', @Modified_Date_To, ''' ')

	IF(@Created_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] >= ''', @Created_Date_From, ''' ')

	IF(@Created_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] <= ''', @Created_Date_To, ''' ')

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' + 
    ' FROM [JFW].[Merchant]' +
    ' WHERE ' +@whereClause + 
    ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order +
    @PAGINATION


	-- Execute the SQL statement
	--PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString

END



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method updates data for the [JFW].[Merchant] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Merchant_Update]
	@ID bigint,
	@Merchant_Type smallint,
	@Code varchar(50),
	@Name nvarchar(50),
	@Website nvarchar(250),
	@Description nvarchar(500),
	@Status smallint,
	@Is_Default bit,
	@ZOrder bigint,
	@Modified_By bigint
AS

-- If Is_Default is true, then set all other merchants to false
IF @Is_Default <> 0
BEGIN
	UPDATE [JFW].[Merchant] SET
		[Is_Default] = 0
	WHERE [ID] <> @ID
END

UPDATE [JFW].[Merchant] SET
    [Merchant_Type] = @Merchant_Type,
    [Code] = @Code,
    [Name] = @Name,
    [Website] = @Website,
    [Description] = @Description,
    [Status] = @Status,
    [Is_Default] = @Is_Default,
    [Modified_By] = @Modified_By,
    [Modified_Date] = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [JFW].[usp_Package_Delete]
	@ID bigint
AS

DELETE FROM
        [JFW].[Package]
    WHERE [ID] = @ID


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [JFW].[usp_Package_Get]
	@ID bigint

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT *
FROM
	[JFW].[Package]
WHERE
        ID = @ID



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [JFW].[usp_Package_List]
	@Code varchar(50) = NULl,
	@Name nvarchar(50) = NULl,
	@Description nvarchar(4000) = NULl,
	@Status smallint = NULl,
	@ZOrder bigint = NULl,
	@Modified_Date_From datetime = NULL,
	@Modified_Date_To datetime = NULL,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN
	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
        @sqlString nvarchar(max),
        @skip bigint = @Page_Number * @Page_Size

	IF(@Code IS NOT NULL AND @Code <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Code] = ''', @Code, ''' ')

	IF(@Name IS NOT NULL AND @Name <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Name] = ''', @Name, ''' ')

	IF(@Description IS NOT NULL AND @Description <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Description] = ''', @Description, ''' ')

	IF(@Status IS NOT NULL AND @Status <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Status] = ''', @Status, ''' ')

	IF(@ZOrder IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [ZOrder] = ', @ZOrder, ' ')

	IF(@Modified_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] >= ''', @Modified_Date_From, ''' ')

	IF(@Modified_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] <= ''', @Modified_Date_To, ''' ')

	IF(@Created_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] >= ''', @Created_Date_From, ''' ')

	IF(@Created_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] <= ''', @Created_Date_To, ''' ')

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' + 
    ' FROM [JFW].[Package]' +
    ' WHERE ' +@whereClause + 
    ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order +
    @PAGINATION


	-- Execute the SQL statement
	--PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString
END



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [JFW].[usp_Package_Update]
	@ID bigint,
	@Code varchar(50),
	@Name nvarchar(50),
	@Description nvarchar(4000),
	@Status smallint = 1,
	@ZOrder bigint,
	@Modified_By bigint
AS

UPDATE [JFW].[Package] SET
        [Code] = @Code,
        [Name] = @Name,
        [Description] = @Description,
        [Status] = @Status,
        [ZOrder] = @ZOrder,
        [Modified_By] = @Modified_By,
        [Modified_Date] = GETUTCDATE()
    WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:     jin.jackson
-- Created date:   2023-04-12 11:00:00
-- Description:    This method deletes multiple rows in the [JFW].[PackageFeature] table by the ID list.
-- Example:        EXEC [JFW].[usp_PackageFeature_Delete] @ID_List = '1,2,3'
------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_PackageFeature_Delete]
	@ID bigint = NULL,
	@ID_List nvarchar(max) = NULL,
	@Package_ID bigint = NULL,
	@Package_ID_List nvarchar(max) = NULL,
	@Feature_ID bigint = NULL,
	@Feature_ID_List nvarchar(max) = NULL
AS

BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Delete statements for procedure here
	IF @ID IS NOT NULL
    BEGIN
		DELETE FROM [JFW].[PackageFeature] WHERE ID = @ID
	END
    ELSE IF @ID_List IS NOT NULL
    BEGIN
		DELETE FROM [JFW].[PackageFeature] WHERE ID IN (SELECT tvalue
		FROM [JFW].[fn_Split](@ID_List, ','))
	END
    ELSE IF @Package_ID IS NOT NULL
    BEGIN
		DELETE FROM [JFW].[PackageFeature] WHERE Package_ID = @Package_ID
	END
    ELSE IF @Package_ID_List IS NOT NULL
    BEGIN
		DELETE FROM [JFW].[PackageFeature] WHERE Package_ID IN (SELECT tvalue
		FROM [JFW].[fn_Split](@Package_ID_List, ','))
	END
    ELSE IF @Feature_ID IS NOT NULL
    BEGIN
		DELETE FROM [JFW].[PackageFeature] WHERE Feature_ID = @Feature_ID
	END
    ELSE IF @Feature_ID_List IS NOT NULL
    BEGIN
		DELETE FROM [JFW].[PackageFeature] WHERE Feature_ID IN (SELECT tvalue
		FROM [JFW].[fn_Split](@Feature_ID_List, ','))
	END
    ELSE
    BEGIN
		RAISERROR('No condition is specified.', 16, 1)
	END

END

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   jin.jackson
-- Created date: 2023-04-12 11:00:00
-- Description:  this method gets data of the [JFW].[PackageFeature] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_PackageFeature_Get]
	@ID bigint
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT *
FROM
	[JFW].[PackageFeature]
WHERE
    ID = @ID

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   jin.jackson
-- Created date: 2023-04-12 11:00:00
-- Description:  this method inserts data into the [JFW].[PackageFeature] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_PackageFeature_Insert]
	@Package_ID bigint,
	@Feature_ID bigint,
	@Created_By bigint = null
AS

INSERT INTO [JFW].[PackageFeature]
	(
	[Package_ID],
	[Feature_ID],
	[Modified_By],
	Modified_Date,
	[Created_By],
	Created_Date
	)
VALUES
	(
		@Package_ID,
		@Feature_ID,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
	)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   jin.jackson
-- Created date: 2023-04-12 11:00:00
-- Description:  this method list   data for the [JFW].[PackageFeature] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_PackageFeature_List]
	@Package_ID bigint = NULL,
	@Feature_ID bigint = NULL,
	@Modified_Date_From datetime = NULL,
	@Modified_Date_To datetime = NULL,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS

Begin
	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF(@Feature_ID IS NOT NULL AND @Feature_ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Feature_ID] = ', @Feature_ID, ' ')

	IF(@Package_ID IS NOT NULL AND @Package_ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Package_ID] = ', @Package_ID, ' ')

	IF(@Modified_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] >= ''', @Modified_Date_From, ''' ')

	IF(@Modified_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] <= ''', @Modified_Date_To, ''' ')


	IF(@Created_Date_From IS NOT NULL)
    SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] >= ''', @Created_Date_From, ''' ')

	IF(@Created_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] <= ''', @Created_Date_To, ''' ')

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'


	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' + 
    ' FROM [JFW].[PackageFeature]' +
    ' WHERE ' +@whereClause + 
    ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order +
    @PAGINATION


	-- Execute the SQL statement
	--PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString

End


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method updates data for the [JFW].[PackageFeature] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_PackageFeature_Update]
	@ID bigint,
	@Package_ID bigint,
	@Feature_ID bigint,
	@Modified_By bigint
AS

UPDATE [JFW].[PackageFeature] SET
    [Feature_ID] = @Feature_ID,
    [Package_ID] = @Package_ID,
	[Modified_By] = @Modified_By,
	[Modified_Date] = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method deletes multiple rows in the [JFW].[Pattern] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Pattern_Delete]
	@ID bigint
AS


DELETE FROM
    [JFW].[Pattern]
WHERE [ID] = @ID
	AND [Is_System] = 0


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method gets data of the [JFW].[Pattern] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Pattern_Get]
	@ID bigint

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT *
FROM
	[JFW].[Pattern]
WHERE
    ID = @ID




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Pattern Table - Insert
-- EXEC [JFW].[usp_Pattern_Insert] @Group_Code = 'SAMPLEGROUPCODE', @Code = 'SAMPLECODE', @Name = 'SAMPLENAME', @Status = 1, @Class_Mapping = 'SAMPLECLASSMAPPING', @ZOrder = 1, @Modified_By = 1, @Created_By = 1
----------------------------------------------------------
-- Created by:    dba03
-- Created date:  2021-07-06
-- Modified by:   jin.jackson
-- Modified date: 2022-11-03
-- Description:   this method inserts data into the [JFW].[Pattern] table.
----------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_Pattern_Insert]
	@Group_Code varchar(150),
	@Code varchar(150),
	@Name nvarchar(1024),
	@Status smallint = 1,
	@ZOrder bigint = 0,
	@Created_By bigint = null
AS

INSERT INTO [JFW].[Pattern]
	(
	[Group_Code],
	[Code],
	[Name],
	[Status],
	[ZOrder],
	[Modified_By],
	[Modified_Date],
	[Created_By],
	[Created_Date]
	)
VALUES
	(
		@Group_Code,
		@Code,
		@Name,
		@Status,
		@ZOrder,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Pattern Table - List
-- EXEC [JFW].[usp_Pattern_List] @Group_Code = 'SAMPLEGROUPCODE'
----------------------------------------------------------
-- Created by:    dba03
-- Created date:  2021-02-22
-- Modified by:   jin.jackson
-- Modified date: 2022-11-03
-- Description:   this method lists data from the [JFW].[Pattern] table.
----------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_Pattern_List]
	@Group_Code varchar(150) = NULL,
	@Code varchar(150) = NULL,
	@Name nvarchar(1024) = NULL,
	@Status smallint = NULL,
	@ZOrder bigint = NULL,
	@Modified_Date_From datetime = NULL,
	@Modified_Date_To datetime = NULL,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN
	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF(@Group_Code IS NOT NULL AND @Group_Code <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Group_Code] = ''', @Group_Code, ''' ')

	IF(@Code IS NOT NULL AND @Code <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Code] = ''', @Code, ''' ')

	IF(@Name IS NOT NULL AND @Name <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Name] = ''', @Name, ''' ')

	IF(@Status IS NOT NULL AND @Status <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Status] = ''', @Status, ''' ')

	IF(@ZOrder IS NOT NULL AND @ZOrder <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [ZOrder] = ''', @ZOrder, ''' ')

	IF(@Modified_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] >= ''', @Modified_Date_From, ''' ')

	IF(@Modified_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] <= ''', @Modified_Date_To, ''' ')

	IF(@Created_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] >= ''', @Created_Date_From, ''' ')

	IF(@Created_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] <= ''', @Created_Date_To, ''' ')

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' + 
    ' FROM [JFW].[Pattern]' +
    ' WHERE ' +@whereClause + 
    ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order +
    @PAGINATION


	-- Execute the SQL statement
	PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString

END



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Pattern Table - Update
-- EXEC [JFW].[usp_Pattern_Update] @ID = 1, @Group_Code = 'SAMPLEGROUPCODE', @Code = 'SAMPLECODE', @Name = 'SAMPLENAME', @Status = 1, @Class_Mapping = 'SAMPLECLASSMAPPING', @ZOrder = 1, @Modified_By = 1
----------------------------------------------------------
-- Created by:    dba03
-- Created date:  2021-07-13
-- Modified by:   jin.jackson
-- Modified date: 2022-11-03
-- Description:   this method updates data into the [JFW].[Pattern] table.
----------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_Pattern_Update]
	@ID bigint,
	@Group_Code varchar(150),
	@Code varchar(150),
	@Name nvarchar(1024),
	@Status smallint,
	@ZOrder bigint,
	@Modified_By bigint
AS

UPDATE [JFW].[Pattern] SET
    [Group_Code] = @Group_Code,
    [Code]= @Code,
    [Name] = @Name,
    [Status] = @Status,
    [ZOrder] = @ZOrder,
    [Modified_By] = @Modified_By,
    [Modified_Date] = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method deletes multiple rows in the [JFW].[PatternContent] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_PatternContent_Delete]
	@ID bigint
AS

DELETE FROM
    [JFW].[PatternContent]
WHERE [ID] = @ID


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method gets data of the [JFW].[PatternContent] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_PatternContent_Get]
	@ID bigint

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT *
FROM
	[JFW].[PatternContent]
WHERE
    ID = @ID



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method inserts data into the [JFW].[PatternContent] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_PatternContent_Insert]
	@Pattern_ID bigint,
	@Country_ID bigint,
	@Subject nvarchar(1024) = null,
	@Content nvarchar(max) = null,
	@Created_By bigint = null

AS

INSERT INTO [JFW].[PatternContent]
	(
	[Pattern_ID],
	[Country_ID],
	[Subject],
	[Content],
	[Modified_By],
	[Modified_Date],
	[Created_By],
	[Created_Date]
	)
VALUES
	(
		@Pattern_ID,
		@Country_ID,
		@Subject,
		@Content,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Created by:        dba03@jexpa.com
-- Create date: 2021-02-22
-- Description:    this stored procedure retrieves the list of pattern mapping according to the search criteria.
CREATE PROCEDURE [JFW].[usp_PatternContent_List]
	@Pattern_ID bigint = NULL,
	@Country_ID bigint = NULL,
	@Subject nvarchar(max) = NULL,
	@Content nvarchar(max) = NULL,
	@Modified_Date_From datetime= NULL,
	@Modified_Date_To datetime= NULL,
	@Created_Date_From datetime= NULL,
	@Created_Date_To datetime= NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN
	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF(@Pattern_ID IS NOT NULL)
    SELECT @whereClause = CONCAT(@whereClause,' AND [Pattern_ID] = ', @Pattern_ID, ' ')

	IF(@Country_ID IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Country_ID] = ', @Country_ID, ' ')

	IF(@Subject IS NOT NULL AND @Subject <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Subject] = ''', @Subject, ''' ')

	IF(@Content IS NOT NULL AND @Content <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Content] = ''', @Content, ''' ')

	IF(@Modified_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] >= ', @Modified_Date_From, ' ')

	IF(@Modified_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] <= ', @Modified_Date_To, ' ')

	IF(@Created_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] >= ''', @Created_Date_From, ''' ')

	IF(@Created_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] <= ''', @Created_Date_To, ''' ')

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' + 
    ' FROM [JFW].[PatternContent]' +
    ' WHERE ' +@whereClause + 
    ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order +
    @PAGINATION


	-- Execute the SQL statement
	--PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString

END



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method updates data for the [JFW].[PatternContent] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_PatternContent_Update]
	@ID bigint,
	@Pattern_ID bigint,
	@Country_ID bigint,
	@Subject nvarchar(1024),
	@Content nvarchar(max),
	@Modified_By bigint
AS

UPDATE [JFW].[PatternContent] SET
    [Pattern_ID] = @Pattern_ID,
	[Country_ID] = @Country_ID,
    [Subject] = @Subject,
    [Content] = @Content,
    [Modified_By] = @Modified_By,
    [Modified_Date] = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 06, 2021
-- Description:  this method deletes multiple rows in the [JFW].[Payment] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Payment_Delete]
	@ID bigint
AS

DELETE FROM
    [JFW].[Payment]
WHERE [ID] = @ID


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 06, 2021
-- Description:  this method gets data of the [JFW].[Payment] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Payment_Get]
	@ID bigint

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT
	*
FROM
	[JFW].[Payment]
WHERE
    ID = @ID




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method inserts data into the [JFW].[Payment] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Payment_Insert]
	@Brand_ID bigint,
	@Merchant_ID bigint,
	@Price_ID bigint,
	@Coupon_ID bigint,
	@User_ID bigint,
	@Payment_Type varchar(50),
	@Payment_Date datetime = null,
	@Invoice_No varchar(50) = null,
	@Description nvarchar(250) = null,
	@Amount float = null,
	@Amount_Fee float = null,
	@Merchant_Ref_No varchar(100) = null,
	@Merchant_Account_Buyer varchar(150) = null,
	@Merchant_Account_Seller varchar(150) = null,
	@IP_Address varchar(50) = null,
	@Notes nvarchar(1000) = null,
	@Risk_Mark tinyint = null,
	@Status smallint = 0,
	@Completed_Date datetime  = null,
	@Created_By bigint = null

AS

INSERT INTO [JFW].[Payment]
	(
	[Brand_ID],
	[Merchant_ID],
	[Price_ID],
	[Coupon_ID],
	[User_ID],
	[Payment_Type],
	[Payment_Date],
	[Completed_Date],
	[Invoice_No],
	[Description],
	[Amount],
	[Amount_Fee],
	[Status],
	[Merchant_Ref_No],
	[Merchant_Account_Buyer],
	[Merchant_Account_Seller],
	[IP_Address],
	[Notes],
	[Risk_Mark],
	[Modified_By],
	[Modified_Date],
	[Created_By],
	[Created_Date]

	)
VALUES
	(
		@Brand_ID,
		@Merchant_ID,
		@Price_ID,
		@Coupon_ID,
		@User_ID,
		@Payment_Type,
		@Payment_Date,
		@Completed_Date,
		@Invoice_No,
		@Description,
		@Amount,
		@Amount_Fee,
		@Status,
		@Merchant_Ref_No,
		@Merchant_Account_Buyer,
		@Merchant_Account_Seller,
		@IP_Address,
		@Notes,
		@Risk_Mark,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- EXEC  [JFW].[usp_Payment_List] @User_ID = '1',@Created_Date_From='20170101',@End_Date='20211230'
-- =============================================
-- Created by:		dba03@jexpa.com
-- Create date:		2021-02-26
-- Description:		this stored procedure retrieves the list of payments according to the search criteria.
-- =============================================
CREATE PROCEDURE [JFW].[usp_Payment_List]
	@Brand_ID bigint = NULL,
	@Merchant_ID bigint = NULL,
	@Price_ID bigint = NULL,
	@Coupon_ID bigint = NULL,
	@User_ID bigint = NULL,
	@Payment_Type varchar(50) = null,
	@Payment_Date datetime = null,
	@Completed_Date datetime = null,
	@Invoice_No varchar(50) = null,
	@Description nvarchar(max) = null,
	@Amount float = null,
	@Amount_Fee float = null,
	@Merchant_Ref_No varchar(100) = null,
	@Merchant_Account_Buyer varchar(150) = null,
	@Merchant_Account_Seller varchar(150) = null,
	@IP_Address varchar(50) = null,
	@Notes nvarchar(1000) = null,
	@Risk_Mark tinyint = null,
	@Status smallint = NULL,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN

	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF(@Brand_ID IS NOT NULL AND @Brand_ID <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Brand_ID] = ', @Brand_ID, ') ')
	END

	IF(@Merchant_ID IS NOT NULL AND @Merchant_ID <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Merchant_ID] = ', @Merchant_ID, ') ')
	END

	IF(@Price_ID IS NOT NULL AND @Price_ID <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Price_ID] = ', @Price_ID, ') ')
	END

	IF(@Coupon_ID IS NOT NULL AND @Coupon_ID <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Coupon_ID] = ', @Coupon_ID, ') ')
	END

	IF(@User_ID IS NOT NULL AND @User_ID <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([User_ID] = ', @User_ID, ') ')
	END

	IF(@Payment_Type IS NOT NULL AND @Payment_Type <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Payment_Type] = ', @Payment_Type, ') ')
	END

	IF(@Payment_Date IS NOT NULL AND @Payment_Date <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Payment_Date] = ', @Payment_Date, ') ')
	END

	IF(@Completed_Date IS NOT NULL AND @Completed_Date <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Completed_Date] = ', @Completed_Date, ') ')
	END

	IF(@Invoice_No IS NOT NULL AND @Invoice_No <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Invoice_No] = ', @Invoice_No, ') ')
	END

	IF(@Description IS NOT NULL AND @Description <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Description] = ', @Description, ') ')
	END

	IF(@Amount IS NOT NULL AND @Amount <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Amount] = ', @Amount, ') ')
	END

	IF(@Amount_Fee IS NOT NULL AND @Amount_Fee <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Amount_Fee] = ', @Amount_Fee, ') ')
	END

	IF(@Status IS NOT NULL AND @Status <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Status] = ', @Status, ') ')
	END

	IF(@Merchant_Account_Buyer IS NOT NULL AND @Merchant_Account_Buyer <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Merchant_Account_Buyer] = ', @Merchant_Account_Buyer, ') ')
	END

	IF(@Merchant_Account_Seller IS NOT NULL AND @Merchant_Account_Seller <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Merchant_Account_Seller] = ', @Merchant_Account_Seller, ') ')
	END

	IF(@IP_Address IS NOT NULL AND @IP_Address <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([IP_Address] = ', @IP_Address, ') ')
	END

	IF(@Notes IS NOT NULL AND @Notes <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Notes] = ', @Notes, ') ')
	END

	IF(@Risk_Mark IS NOT NULL AND @Risk_Mark <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Risk_Mark] = ', @Risk_Mark, ') ')
	END

	IF(@Created_Date_From IS NOT NULL)
	BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] >= ''', @Created_Date_From, ''' ')
	END

	IF(@Created_Date_To IS NOT NULL)
	BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] <= ''', @Created_Date_To, ''' ')
	END

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' + 
    ' FROM [JFW].[Payment] ' + 
    ' WHERE ' +@whereClause + 
    ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order

	-- Execute the SQL statement
	--PRINT @sqlString
	EXEC sp_executesql @sqlString


END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 06, 2021
-- Description:  this method updates data for the [JFW].[Payment] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Payment_Update]
	@ID bigint,
	@Brand_ID bigint,
	@Merchant_ID bigint,
	@Price_ID bigint,
	@Coupon_ID bigint,
	@User_ID bigint,
	@Payment_Type varchar(50),
	@Payment_Date datetime,
	@Completed_Date datetime,
	@Invoice_No varchar(50),
	@Description nvarchar(250),
	@Amount float,
	@Amount_Fee float,
	@Status smallint,
	@Merchant_Ref_No varchar(100),
	@Merchant_Account_Buyer varchar(150),
	@Merchant_Account_Seller varchar(150),
	@IP_Address varchar(50),
	@Notes nvarchar(1000),
	@Risk_Mark tinyint,
	@Modified_By bigint
AS

UPDATE [JFW].[Payment] SET
    [Brand_ID] = @Brand_ID,
    [Merchant_ID] = @Merchant_ID,
    [Price_ID] = @Price_ID,
    [Coupon_ID] = @Coupon_ID,
    [User_ID] = @User_ID,
    [Payment_Type] = @Payment_Type,
    [Payment_Date] = @Payment_Date,
    [Completed_Date] = @Completed_Date,
    [Invoice_No] = @Invoice_No,
    [Description] = @Description,
    [Amount] = @Amount,
    [Amount_Fee] = @Amount_Fee,
    [Status] = @Status,
    [Merchant_Ref_No] = @Merchant_Ref_No,
    [Merchant_Account_Buyer] = @Merchant_Account_Buyer,
    [Merchant_Account_Seller] = @Merchant_Account_Seller,
    [IP_Address] = @IP_Address,
    [Notes] = @Notes,
    [Risk_Mark] = @Risk_Mark,
	Modified_By = @Modified_By,
	Modified_Date = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method deletes multiple rows in the [JFW].[PaymentHistory] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_PaymentHistory_Delete]
	@ID bigint
AS


DELETE FROM
    [JFW].[PaymentHistory]
WHERE [ID] = @ID


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method gets data of the [JFW].[PaymentHistory] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_PaymentHistory_Get]
	@ID bigint

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT
	*
FROM
	[JFW].[PaymentHistory]
WHERE
    ID = @ID



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- PaymentHistory Table - Insert
-- EXEC [JFW].[usp_PaymentHistory_Insert] @User_ID = 1, @Payment_ID = 1, @Payment_Status = 1, @Notes = 'SAMPLENOTES', @Modified_By = 1, @Created_By = 1
----------------------------------------------------------
-- Created by:    dba03
-- Created date:  2021-07-13
-- Modified by:   jin.jackson
-- Modified date: 2022-11-03
-- Description:   this method inserts data into the [JFW].[PaymentHistory] table.
----------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_PaymentHistory_Insert]
	@User_ID bigint,
	@Payment_ID bigint,
	@Payment_Status SMALLINT = 0,
	@Notes nvarchar(2000) = null,
	@Created_By bigint = null
AS

INSERT INTO [JFW].[PaymentHistory]
	(
	[User_ID],
	[Payment_ID],
	[Payment_Status],
	[Notes],
	[Modified_By],
	[Modified_Date],
	[Created_By],
	[Created_Date]
	)
VALUES
	(
		@User_ID,
		@Payment_ID,
		@Payment_Status,
		@Notes,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- PaymentHistory Table - List
-- EXEC [JFW].[usp_PaymentHistory_List] @User_ID = 1, @Payment_ID = 1, @Payment_Status = 1, @Notes = 'SAMPLENOTES'
----------------------------------------------------------
-- Created by:    dba03
-- Created date:  2021-02-22
-- Modified by:   jin.jackson
-- Modified date: 2022-11-03
-- Description:   this method lists data from the [JFW].[PaymentHistory] table.
----------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_PaymentHistory_List]
	@User_ID bigint = null,
	@Payment_ID bigint = null,
	@Payment_Status SMALLINT = null,
	@Notes nvarchar(2000) = null,
	@Modified_Date_From datetime = NULL,
	@Modified_Date_To datetime = NULL,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN
	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF(@User_ID IS NOT NULL AND @User_ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [User_ID] = ', @User_ID, ' ')

	IF(@Payment_ID IS NOT NULL AND @Payment_ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Payment_ID] = ', @Payment_ID, ' ')

	IF(@Payment_Status IS NOT NULL AND @Payment_Status <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Payment_Status] = ', @Payment_Status, ' ')

	IF(@Notes IS NOT NULL AND @Notes <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Notes] = ''', @Notes, ''' ')


	IF(@Modified_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] >= ''', @Modified_Date_From, ''' ')

	IF(@Modified_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] <= ''', @Modified_Date_To, ''' ')


	IF(@Created_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] >= ''', @Created_Date_From, ''' ')

	IF(@Created_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] <= ''', @Created_Date_To, ''' ')

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'


	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' + 
    ' FROM [JFW].[PaymentHistory]' +
    ' WHERE ' +@whereClause + 
    ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order
    + @PAGINATION

	-- Execute the SQL statement
	PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString

END



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- PaymentHistory Table - Update
-- EXEC [JFW].[usp_PaymentHistory_Update] @ID = 1, @User_ID = 1, @Payment_ID = 1, @Payment_Status = 1, @Notes = 'SAMPLENOTES', @Modified_By = 1
----------------------------------------------------------
-- Created by:    dba03
-- Created date:  2021-07-13
-- Modified by:   jin.jackson
-- Modified date: 2022-11-03
-- Description:   this method updates data into the [JFW].[PaymentHistory] table.
----------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_PaymentHistory_Update]
	@ID bigint,
	@User_ID bigint,
	@Payment_ID bigint,
	@Payment_Status smallint = 0,
	@Notes nvarchar(Max) = null,
	@Modified_By bigint
AS

UPDATE  [JFW].[PaymentHistory] SET
[User_ID] = @User_ID, 
[Payment_ID] = @Payment_ID, 
[Payment_Status] = @Payment_Status, 
[Notes] = @Notes, 
[Modified_By] = @Modified_By, 
[Modified_Date] = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 06, 2021
-- Description:  this method deletes multiple rows in the [JFW].[PaymentMethod] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_PaymentMethod_Delete]
	@ID bigint
AS

DELETE FROM
    [JFW].[PaymentMethod]
WHERE [ID] = @ID


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 06, 2021
-- Description:  this method gets data of the [JFW].[PaymentMethod] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_PaymentMethod_Get]
	@ID bigint

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT *
FROM
	[JFW].[PaymentMethod]
WHERE
    ID = @ID



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 06, 2021
-- Description:  this method inserts data into the [JFW].[PaymentMethod] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_PaymentMethod_Insert]
	@Brand_ID bigint,
	@Payment_Merchant_ID bigint,
	@Payment_Info varchar(150) = null,
	@Ipn_Listener_Link nvarchar(1000) = null,
	@Cancel_Link_Without_Login nvarchar(1000) = null,
	@Cancel_Link nvarchar(1000) = null,
	@Return_Link nvarchar(1000) = null,
	@Public_Key varchar(150) = null,
	@Private_Key varchar(150) = null,
	@Interal_Note nvarchar(max) = null,
	@Status smallint = 0,
	@Is_Default bit = 0,
	@ZOrder bigint = null,
	@Created_By bigint = null
AS

-- Each brand can only have one default payment method
IF @Is_Default <> 0
BEGIN
	UPDATE [JFW].[PaymentMethod] SET
		[Is_Default] = 0
	WHERE [Brand_ID] = @Brand_ID
END

INSERT INTO [JFW].[PaymentMethod]
	(
	[Brand_ID],
	[Payment_Merchant_ID],
	[Payment_Info],
	[Ipn_Listener_Link],
	[Cancel_Link_Without_Login],
	[Cancel_Link],
	[Return_Link],
	[Public_Key],
	[Private_Key],
	[Interal_Note],
	[Status],
	[Is_Default],
	[ZOrder],
	[Modified_By],
	[Modified_Date],
	[Created_By],
	[Created_Date]
	)
VALUES
	(
		@Brand_ID,
		@Payment_Merchant_ID,
		@Payment_Info,
		@Ipn_Listener_Link,
		@Cancel_Link_Without_Login,
		@Cancel_Link,
		@Return_Link,
		@Public_Key,
		@Private_Key,
		@Interal_Note,
		@Status,
		@Is_Default,
		@ZOrder,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [JFW].[usp_PaymentMethod_List]
	@Brand_ID bigint = NULL,
	@Payment_Merchant_ID bigint = NULL,
	@Payment_Info varchar(150) = NULL,
	@Ipn_Listener_Link nvarchar(1000) = NULL,
	@Cancel_Link_Without_Login nvarchar(1000) = NULL,
	@Cancel_Link nvarchar(1000) = NULL,
	@Return_Link nvarchar(1000) = NULL,
	@Public_Key varchar(150) = NULL,
	@Private_Key varchar(150) = NULL,
	@Interal_Note nvarchar(max) = NULL,
	@Status smallint = NULL,
	@Is_Default bit = 0,
	@ZOrder bigint = NULL,
	@Modified_Date_From datetime = NULL,
	@Modified_Date_To datetime = NULL,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN
	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	IF(@Brand_ID IS NOT NULL AND @Brand_ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Brand_ID] = ', @Brand_ID, ' ')

	IF(@Payment_Merchant_ID IS NOT NULL AND @Payment_Merchant_ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Payment_Merchant_ID] = ', @Payment_Merchant_ID, ' ')

	IF(@Payment_Info IS NOT NULL AND @Payment_Info <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Payment_Info] = ''', @Payment_Info, ''' ')

	IF(@Ipn_Listener_Link IS NOT NULL AND @Ipn_Listener_Link <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Ipn_Listener_Link] = ''', @Ipn_Listener_Link, ''' ')

	IF(@Cancel_Link_Without_Login IS NOT NULL AND @Cancel_Link_Without_Login <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Cancel_Link_Without_Login] = ''', @Cancel_Link_Without_Login, ''' ')

	IF(@Cancel_Link IS NOT NULL AND @Cancel_Link <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Cancel_Link] = ''', @Cancel_Link, ''' ')

	IF(@Return_Link IS NOT NULL AND @Return_Link <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Return_Link] = ''', @Return_Link, ''' ')

	IF(@Public_Key IS NOT NULL AND @Public_Key <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Public_Key] = ''', @Public_Key, ''' ')

	IF(@Private_Key IS NOT NULL AND @Private_Key <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Private_Key] = ''', @Private_Key, ''' ')

	IF(@Interal_Note IS NOT NULL AND @Interal_Note <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Interal_Note] = ''', @Interal_Note, ''' ')

	IF(@Status IS NOT NULL AND @Status <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Status] = ''', @Status, ''' ')

	IF(@Is_Default IS NOT NULL AND @Is_Default <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Is_Default] = ''', @Is_Default, ''' ')

	IF(@ZOrder IS NOT NULL AND @ZOrder <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [ZOrder] = ''', @ZOrder, ''' ')

	IF(@Modified_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] >= ''', @Modified_Date_From, ''' ')

	IF(@Modified_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] <= ''', @Modified_Date_To, ''' ')

	IF(@Created_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] >= ''', @Created_Date_From, ''' ')

	IF(@Created_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] <= ''', @Created_Date_To, ''' ')

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' + 
    ' FROM [JFW].[PaymentMethod]' +
    ' WHERE ' +@whereClause + 
    ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order +
    @PAGINATION


	-- Execute the SQL statement
	--PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString

END



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 06, 2021
-- Description:  this method updates data for the [JFW].[PaymentMethod] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_PaymentMethod_Update]
	@ID bigint,
	@Brand_ID bigint,
	@Payment_Merchant_ID bigint,
	@Payment_Info varchar(150),
	@Ipn_Listener_Link nvarchar(1000),
	@Cancel_Link_Without_Login nvarchar(1000),
	@Cancel_Link nvarchar(1000),
	@Return_Link nvarchar(1000),
	@Public_Key varchar(150),
	@Private_Key varchar(150),
	@Interal_Note nvarchar(max),
	@Status smallint,
	@Is_Default bit,
	@ZOrder bigint,
	@Modified_By bigint
AS

--- Each brand should have only one default payment method
IF @Is_Default <> 0
BEGIN
	UPDATE [JFW].[PaymentMethod] SET [Is_Default] = 0
	WHERE [Brand_ID] = @Brand_ID
END

UPDATE [JFW].[PaymentMethod] SET
    [Brand_ID] = @Brand_ID,
    [Payment_Merchant_ID] = @Payment_Merchant_ID,
    [Payment_Info] = @Payment_Info,
    [Ipn_Listener_Link] = @Ipn_Listener_Link,
    [Cancel_Link_Without_Login] = @Cancel_Link_Without_Login,
    [Cancel_Link] = @Cancel_Link,
    [Return_Link] = @Return_Link,
    [Public_Key] = @Public_Key,
    [Private_Key] = @Private_Key,
    [Interal_Note] = @Interal_Note,
    [Status] = @Status,
    [Is_Default] = @Is_Default,
    [ZOrder] = @ZOrder,
    [Modified_By] = @Modified_By,
    [Modified_Date] = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, March 30, 2021
-- Description:  this method deletes a row in the [JFW].[Permission] table by value of the column "ID".
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Permission_Delete]
	@ID bigint
AS

DELETE FROM [JFW].[Permission]
WHERE [ID] = @ID
	AND [Is_System] = 0

SELECT CAST(@@ROWCOUNT AS bigint)



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, March 30, 2021
-- Description:  this method gets data of the [JFW].[Permission] table by value in the ID column.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Permission_Get]
	@ID bigint
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT *
FROM
	[JFW].[Permission]
WHERE
    [ID] = @ID




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, March 30, 2021
-- Description:  this method inserts data into the [JFW].[Permission] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Permission_Insert]
	@Name nvarchar(50),
	@Description nvarchar(250),
	@Created_By bigint = null
AS

INSERT INTO [JFW].[Permission]
	(
	[Name],
	[Description],
	[Modified_By],
	[Modified_Date],
	[Created_By],
	[Created_Date]
	)
VALUES
	(
		@Name,
		@Description,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
	)

SELECT CAST(SCOPE_IDENTITY() AS bigint)




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- EXEC [JFW].[usp_Permission_List] @Role_ID = 21
-- =============================================
-- Created by:  dba03@jexpa.com
-- Create date: 2021-02-22
-- Modify by:   jin.jackson
-- Modify date: 2022-10-04
-- Description:  this stored procedure retrieves the list of permissions according to the search criteria.
-- =============================================
CREATE PROCEDURE [JFW].[usp_Permission_List]
	@Name nvarchar(50) = null,
	@Description nvarchar (500) = null,
	@Is_System bit = null,
	@User_ID bigint = NULL,
	@Role_ID bigint = NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN
	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF(@Name IS NOT NULL AND @Name <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND (Name = ', @Name, ') ')
	END

	IF(@Is_System IS NOT NULL AND @Is_System <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND (Is_System = ', @Is_System, ') ')
	END

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	SELECT @sqlString = 'SELECT '+ @LimitClause +' p.*' + 
    ' FROM [JFW].[Permission] p' + 
    (CASE WHEN @User_ID IS NOT NULL THEN CONCAT(' INNER JOIN  [JFW].[UserPermission] up ON up.[Permission_ID] = p.[ID] AND up.[User_ID] = ', @User_ID) ELSE CONCAT('','') END) +
    (CASE WHEN @Role_ID IS NOT NULL THEN CONCAT(' INNER JOIN  [JFW].[RolePermission] rp ON rp.[Permission_ID] = p.[ID] AND rp.[Role_ID] = ', @Role_ID) ELSE CONCAT('','') END) +
    ' WHERE ' +@whereClause + 
    ' ORDER BY ' + CONCAT('p.[',@Sort_Data_Field,']') + ' ' + @Sort_Order  +
    @PAGINATION

	-- Execute the SQL statement
	--PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString

END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, March 30, 2021
-- Description:  this method updates data for the [JFW].[Permission] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Permission_Update]
	@ID bigint,
	@Name nvarchar(50),
	@Description nvarchar(250),
	@Modified_By bigint = null
AS

UPDATE [JFW].[Permission] SET
    [Name] = @Name,
    [Description] = @Description,
	Modified_By = @Modified_By,
	Modified_Date = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'


-- PointHistory
-- Delete

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   jin.jackson
-- Created date: 2023-02-24
-- Description:  deletes data from the [JFW].[PointHistory] table by the ID.
------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_PointHistory_Delete]
	@ID bigint
AS
BEGIN
	DELETE FROM [JFW].[PointHistory]
	WHERE [ID] = @ID

	SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'
END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   jin.jackson
-- Created date: 2023-02-24
-- Description:  retrieves data from the [JFW].[PointHistory] table by the ID.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_PointHistory_Get]
	@ID bigint
AS

SELECT *
FROM [JFW].[PointHistory]
WHERE [ID] = @ID



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   jin.jackson
-- Created date: 2023-02-24
-- Description:  inserts data into the [JFW].[PointHistory] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_PointHistory_Insert]
	@User_ID bigint,
	@Amount int,
	@Changed_Type tinyint,
	@Reason varchar(255),
	@Reference varchar(255),
	@Created_By bigint = null
AS
BEGIN
	INSERT INTO [JFW].[PointHistory]
		(
		[User_ID],
		[Amount],
		[Changed_Type],
		[Reason],
		[Reference],
		[Modified_By],
		[Modified_Date],
		[Created_By],
		[Created_Date]
		)
	VALUES
		(
			@User_ID,
			@Amount,
			@Changed_Type,
			@Reason,
			@Reference,
			@Created_By,
			GETUTCDATE(),
			@Created_By,
			GETUTCDATE()
	)

	SELECT CAST(@@IDENTITY AS bigint) as 'ID'
END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   jin.jackson
-- Created date: 2023-02-24
-- Description:  lists data from the [JFW].[PointHistory] table with parameters.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_PointHistory_List]
	@User_ID bigint = NULL,
	@Amount int = NULL,
	@Changed_Type tinyint = NULL,
	@Reason varchar(255) = NULL,
	@Reference varchar(255) = NULL,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Modified_Date_From datetime = NULL,
	@Modified_Date_To datetime = NULL,
	@Limit int = NULL,
	@Page_Number bigint = NULL,
	@Page_Size bigint = NULL,
	@Sort_Data_Field varchar(50) = 'ID',
	@Sort_Order varchar(50) = 'DESC'
AS
BEGIN
	DECLARE @sqlString nvarchar(max)
	DECLARE @whereClause nvarchar(max)
	DECLARE @LimitClause nvarchar(max)
	DECLARE @PAGINATION nvarchar(max)
	DECLARE @skip bigint

	SET @whereClause = '1=1'
	SET @LimitClause = ''
	SET @PAGINATION = ''
	SET @skip = @Page_Number * @Page_Size

	IF(@User_ID IS NOT NULL AND @User_ID <> '')
	SELECT @whereClause = CONCAT(@whereClause,' AND (User_ID = ', @User_ID, ') ')

	IF(@Changed_Type IS NOT NULL AND @Changed_Type <> '')
	SELECT @whereClause = CONCAT(@whereClause,' AND (Changed_Type = ', @Changed_Type, ') ')

	IF(@Reason IS NOT NULL AND @Reason <> '')
	SELECT @whereClause = CONCAT(@whereClause,' AND (Reason = ''', @Reason, ''') ')

	IF(@Reference IS NOT NULL AND @Reference <> '')
	SELECT @whereClause = CONCAT(@whereClause,' AND (Reference = ''', @Reference, ''') ')

	IF(@Modified_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] >= ''', @Modified_Date_From, ''' ')

	IF(@Modified_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] <= ''', @Modified_Date_To, ''' ')

	IF(@Created_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND (Created_Date >= ''', @Created_Date_From, ''') ')

	IF(@Created_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND (Created_Date <= ''', @Created_Date_To, ''') ')

	IF (@Page_Number is not null and @Page_Size is not null )
	SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	SELECT @sqlString = 'SELECT p.*' + 
	' FROM [JFW].[PointHistory] p' + 
	' WHERE ' +@whereClause + 
	' ORDER BY ' + CONCAT('p.[',@Sort_Data_Field,']') + ' ' + @Sort_Order  +
	@PAGINATION

	-- Execute the SQL statement
	--PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString

END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   jin.jackson
-- Created date: 2023-02-24
-- Description:  updates data for the [JFW].[PointHistory] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_PointHistory_Update]
	@ID bigint,
	@User_ID bigint,
	@Amount int,
	@Changed_Type tinyint,
	@Reason varchar(255),
	@Reference varchar(255)
AS
BEGIN
	UPDATE [JFW].[PointHistory] SET
		[User_ID] = @User_ID,
		[Amount] = @Amount,
		[Changed_Type] = @Changed_Type,
		[Reason] = @Reason,
		[Reference] = @Reference
	WHERE [ID] = @ID

	SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'
END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 7, 2021
-- Description:  this method deletes multiple rows in the [JFW].[Price] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Price_Delete]
	@ID bigint
AS



DELETE FROM
    [JFW].[Price]
WHERE [ID] = @ID


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 7, 2021
-- Description:  this method gets data of the [JFW].[Price] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Price_Get]
	@ID bigint

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT *
FROM
	[JFW].[Price]
WHERE
    ID = @ID




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 7, 2021
-- Description:  this method inserts data into the [JFW].[Price] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Price_Insert]
	@Payment_Method_ID bigint,
	@Package_ID bigint,
	@Subscription_Type_ID bigint,
	@Currency varchar(3),
	@Code varchar(50) = null,
	@Name nvarchar(50) = null,
	@Amount float = null,
	@Status smallint = 0,
	@Checkout_Link nvarchar(1000) = null,
	@Description nvarchar(250) = null,
	@ZOrder bigint = null,
	@Created_By bigint = null

AS

INSERT INTO [JFW].[Price]
	(
	[Payment_Method_ID]
	,[Package_ID]
	,[Subscription_Type_ID]
	,[Code]
	,[Name]
	,[Amount]
	,[Currency]
	,[Status]
	,[Checkout_Link]
	,[Description]
	,[ZOrder]
	,[Modified_By]
	,[Modified_Date]
	,[Created_By]
	,[Created_Date]
	)
VALUES
	(
		@Payment_Method_ID,
		@Package_ID,
		@Subscription_Type_ID,
		@Code,
		@Name,
		@Amount,
		@Currency,
		@Status,
		@Checkout_Link,
		@Description,
		@ZOrder,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Created by:        dba03@jexpa.com
-- Create date: 2021-02-22
-- Description:    this stored procedure retrieves the list of permissions according to the search criteria.
-- =============================================

CREATE PROCEDURE [JFW].[usp_Price_List]
	@Payment_Method_ID bigint = null,
	@Package_ID bigint = null,
	@Subscription_Type_ID bigint = null,
	@Currency varchar(3) = null,
	@Code varchar(50) = null,
	@Name nvarchar(50) = null,
	@Amount float = null,
	@Checkout_Link nvarchar(1000) = null,
	@Description nvarchar(250) = null,
	@ZOrder bigint = null,
	@Status smallint = null,
	@Modified_Date_From datetime = NULL,
	@Modified_Date_To datetime = NULL,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'

AS
BEGIN
	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF(@Payment_Method_ID IS NOT NULL AND @Payment_Method_ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Payment_Method_ID] = ''', @Payment_Method_ID, ''' ')

	IF(@Package_ID IS NOT NULL AND @Package_ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Package_ID] = ''', @Package_ID, ''' ')

	IF(@Subscription_Type_ID IS NOT NULL AND @Subscription_Type_ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Subscription_Type_ID] = ''', @Subscription_Type_ID, ''' ')

	IF(@Currency IS NOT NULL AND @Currency <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Currency] = ''', @Currency, ''' ')

	IF(@Code IS NOT NULL AND @Code <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Code] = ''', @Code, ''' ')

	IF(@Name IS NOT NULL AND @Name <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Name] = ''', @Name, ''' ')

	IF(@Amount IS NOT NULL)
    SELECT @whereClause = CONCAT(@whereClause,' AND [Amount] = ', @Amount, ' ')

	IF(@Checkout_Link IS NOT NULL AND @Checkout_Link <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Checkout_Link] = ''', @Checkout_Link, ''' ')

	IF(@Description IS NOT NULL AND @Description <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Description] = ''', @Description, ''' ')

	IF(@ZOrder IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [ZOrder] = ', @ZOrder, ' ')

	IF(@Status IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Status] = ', @Status, ' ')

	IF(@Modified_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] >= ''', @Modified_Date_From, ''' ')

	IF(@Modified_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] <= ''', @Modified_Date_To, ''' ')

	IF(@Created_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] >= ''', @Created_Date_From, ''' ')

	IF(@Created_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] <= ''', @Created_Date_To, ''' ')

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')


	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' + 
    ' FROM [JFW].[Price]' +
    ' WHERE ' +@whereClause + 
    ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order+
    @PAGINATION


	-- Execute the SQL statement
	--PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString

END



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 7, 2021
-- Description:  this method updates data for the [JFW].[Price] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Price_Update]
	@ID bigint,
	@Payment_Method_ID bigint,
	@Package_ID bigint,
	@Subscription_Type_ID bigint,
	@Code varchar(50),
	@Name nvarchar(50),
	@Amount float,
	@Currency varchar(3),
	@Status smallint,
	@Checkout_Link nvarchar(1000),
	@Description nvarchar(250),
	@ZOrder bigint,
	@Modified_By bigint
AS

UPDATE [JFW].[Price] SET
    [Payment_Method_ID] = @Payment_Method_ID,
    [Package_ID] = @Package_ID,
    [Subscription_Type_ID] = @Subscription_Type_ID,
    Currency = @Currency,
    [Code] = @Code,
    [Name] = @Name,
    [Amount] = @Amount,
    [Status] = @Status,
    [Checkout_Link] = @Checkout_Link,
    [Description] = @Description,
    [ZOrder] = @ZOrder,
    [Modified_By] = @Modified_By,
    [Modified_Date] = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'

--- Delete

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   jin.jackson
-- Created date: 2023-02-24
-- Description:  This deletes a row in the [JFW].[Reward] table by the ID.
------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_Reward_Delete]
	@ID bigint
AS
BEGIN
	DELETE FROM [JFW].[Reward]
	WHERE [ID] = @ID
	SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'
END

--- Get

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   jin.jackson
-- Created date: 2023-02-24
-- Description:  This gets a row in the [JFW].[Reward] table by the ID.
------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_Reward_Get]
	@ID bigint
AS
BEGIN
	SELECT *
	FROM [JFW].[Reward]
	WHERE [ID] = @ID
END

--- Insert

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   jin.jackson
-- Created date: 2023-02-24
-- Description:  This inserts a row in the [JFW].[Reward] table.
------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_Reward_Insert]
	@Brand_ID bigint,
	@Name varchar(255),
	@Description varchar(max),
	@Point_Value int = 0,
	@Redemption_Instructions varchar(max),
	@Required_Level int,
	@Expiration_Date datetime,
	@Status smallint = 1,
	@ZOrder bigint,
	@Created_By bigint = null
AS
BEGIN
	INSERT INTO [JFW].[Reward]
		(
		[Brand_ID],
		[Name],
		[Description],
		[Point_Value],
		[Redemption_Instructions],
		[Required_Level],
		[Expiration_Date],
		[Status],
		[ZOrder],
		[Modified_By],
		[Modified_Date],
		[Created_By],
		[Created_Date]
		)
	VALUES
		(
			@Brand_ID,
			@Name,
			@Description,
			@Point_Value,
			@Redemption_Instructions,
			@Required_Level,
			@Expiration_Date,
			@Status,
			@ZOrder,
			@Created_By,
			GETUTCDATE(),
			@Created_By,
			GETUTCDATE()
	)
	SELECT CAST(@@IDENTITY AS bigint) as 'ID'
END

--- List

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   jin.jackson
-- Created date: 2023-02-24
-- Description:  This gets a list of rows in the [JFW].[Reward] table.
------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_Reward_List]
	@Brand_ID bigint = NULL,
	@Name varchar(255) = NULL,
	@Description varchar(max) = NULL,
	@Point_Value int = NULL,
	@Redemption_Instructions varchar(max) = NULL,
	@Required_Level int = NULL,
	@Expiration_Date_From datetime = NULL,
	@Expiration_Date_To datetime = NULL,
	@Status smallint = NULL,
	@ZOrder bigint = NULL,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Modified_Date_From datetime = NULL,
	@Modified_Date_To datetime = NULL,
	@Limit int = NULL,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(255) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN
	DECLARE @limitClause nvarchar(100) = '',
	@offsetClause nvarchar(max) = '',
	@whereClause nvarchar(max) = '1 = 1',
	@sql nvarchar(max) = '',
    @skip bigint = @Page_Number * @Page_Size

	IF (@Brand_ID IS NOT NULL)
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Brand_ID] = ', @Brand_ID)
	END

	IF (@Name IS NOT NULL AND @Name <> '')
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Name] = ''', @Name, '''')
	END

	IF (@Description IS NOT NULL AND @Description <> '')
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Description] = ''', @Description, '''')
	END

	IF (@Point_Value IS NOT NULL)
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Point_Value] = ', @Point_Value)
	END

	IF (@Redemption_Instructions IS NOT NULL AND @Redemption_Instructions <> '')
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Redemption_Instructions] = ''', @Redemption_Instructions, '''')
	END

	IF (@Required_Level IS NOT NULL)
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Required_Level] = ', @Required_Level)
	END

	IF (@Expiration_Date_From IS NOT NULL)
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Expiration_Date] >= ''', @Expiration_Date_From, '''')
	END

	IF (@Expiration_Date_To IS NOT NULL)
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Expiration_Date] <= ''', @Expiration_Date_To, '''')
	END

	IF (@Status IS NOT NULL)
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Status] = ', @Status)
	END

	IF (@ZOrder IS NOT NULL)
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [ZOrder] = ', @ZOrder)
	END

	IF (@Created_Date_From IS NOT NULL)
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Created_Date] >= ''', @Created_Date_From, '''')
	END

	IF (@Created_Date_To IS NOT NULL)
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Created_Date] <= ''', @Created_Date_To, '''')
	END

	IF (@Modified_Date_From IS NOT NULL)
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Modified_Date] >= ''', @Modified_Date_From, '''')
	END

	IF (@Modified_Date_To IS NOT NULL)
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [Modified_Date] <= ''', @Modified_Date_To, '''')
	END

	IF (@Page_Number IS NOT NULL AND @Page_Size IS NOT NULL)
	BEGIN
		SET @offsetClause = 'OFFSET ' + CAST(@skip AS varchar(10)) + ' ROWS' + CHAR(13) + 'FETCH NEXT ' + CAST(@Page_Size AS varchar(10)) + ' ROWS ONLY'
	END

	IF (@Limit IS NOT NULL AND @Limit > 0)
	BEGIN
		SET @limitClause = CONCAT('TOP ', @Limit)
	END

	SET @sql = CONCAT('SELECT ', @limitClause, 
	' * FROM [JFW].[Currency]',
	' WHERE ', @whereClause, 
	' ORDER BY ', @Sort_Data_Field, ' ', @Sort_Order, CHAR(13), 
	@offsetClause)

	-- PRINT CONCAT('SQL: ', @sql)
	EXEC sp_executesql @sql
END

-- Update

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   jin.jackson
-- Created date: 2023-02-24
-- Description:  This updates a row in the [JFW].[Reward] table.
------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_Reward_Update]
	@ID bigint,
	@Brand_ID bigint = NULL,
	@Name varchar(255) = NULL,
	@Description varchar(max) = NULL,
	@Point_Value int = NULL,
	@Redemption_Instructions varchar(max) = NULL,
	@Required_Level int = NULL,
	@Expiration_Date datetime = NULL,
	@Status smallint = NULL,
	@ZOrder bigint = NULL,
	@Modified_By bigint = null
AS
BEGIN
	UPDATE [JFW].[Reward] SET
		[Brand_ID] = @Brand_ID,
		[Name] = @Name,
		[Description] = @Description,
		[Point_Value] = @Point_Value,
		[Redemption_Instructions] = @Redemption_Instructions,
		[Required_Level] = @Required_Level,
		[Expiration_Date] = @Expiration_Date,
		[Status] = @Status,
		[ZOrder] = @ZOrder,
		Modified_By = @Modified_By,
		[Modified_Date] = GETUTCDATE()
	WHERE [ID] = @ID

	SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'
END



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method deletes multiple rows in the [JFW].[Role] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Role_Delete]
	@ID bigint
AS


DELETE FROM
    [JFW].[Role]
WHERE [ID] = @ID
	AND [Is_System] = 0


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method gets data of the [JFW].[Role] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Role_Get]
	@ID bigint

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT *
FROM
	[JFW].[Role]
WHERE
    ID = @ID




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method inserts data into the [JFW].[Role] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Role_Insert]
	@Name nvarchar(250),
	@Description nvarchar(500),
	@Created_By bigint = null
AS

INSERT INTO [JFW].[Role]
	(
	[Name],
	[Description],
	[Modified_By],
	[Modified_Date],
	[Created_By],
	[Created_Date]
	)
VALUES
	(
		@Name,
		@Description,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- EXEC [JFW].[usp_Role_List] @User_ID = 21
-- =============================================
-- Created by:        dba03@jexpa.com
-- Create date: 2021-02-22
-- Modify date: 2022-10-01
-- Description:    this stored procedure retrieves the list of permissions according to the search criteria.
-- =============================================
CREATE PROCEDURE [JFW].[usp_Role_List]
	@User_ID bigint = NULL,
	@Permission_ID bigint = NULL,
	@Name nvarchar(250) = NULL,
	@Description nvarchar(500) = NULL,
	@Is_System bit = NULL,
	@Modified_Date_From datetime = NULL,
	@Modified_Date_To datetime = NULL,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN
	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF (@Name IS NOT NULL AND @Name <> '')
	SELECT @whereClause = CONCAT(@whereClause,' AND r.[Name] = ''', @Name, '''')

	IF (@Description IS NOT NULL AND @Description <> '')
	SELECT @whereClause = CONCAT(@whereClause,' AND r.[Description] = ''', @Description, '''')

	IF (@Is_System IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND r.[Is_System] = ', @Is_System)

	IF(@Modified_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] >= ''', @Modified_Date_From, ''' ')

	IF(@Modified_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] <= ''', @Modified_Date_To, ''' ')

	IF(@Created_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] >= ''', @Created_Date_From, ''' ')

	IF(@Created_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] <= ''', @Created_Date_To, ''' ')

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	SELECT @sqlString = 'SELECT '+ @LimitClause +' r.*' +  
    ' FROM [JFW].[Role] r' + 
    (CASE WHEN @User_ID IS NOT NULL THEN CONCAT(' INNER JOIN  [JFW].[UserRole] ur ON ur.[Role_ID] = r.[ID] AND ur.[User_ID] = ', @User_ID) ELSE CONCAT('','') END) +
    (CASE WHEN @Permission_ID IS NOT NULL THEN CONCAT(' INNER JOIN  [JFW].[RolePermission] rp ON rp.[Role_ID] = r.[ID] AND rp.[Permission_ID] = ', @Permission_ID) ELSE CONCAT('','') END) +
    ' WHERE ' +@whereClause + 
    ' ORDER BY ' + CONCAT('r.[',@Sort_Data_Field,']') + ' ' + @Sort_Order + 
    @PAGINATION

	-- Execute the SQL statement
	-- PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString
END



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method updates data for the [JFW].[Role] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Role_Update]
	@ID bigint,
	@Name nvarchar(250),
	@Description nvarchar(500),
	@Modified_By bigint = null
AS

UPDATE [JFW].[Role] SET
    [Name] = @Name,
    [Description] = @Description,
	Modified_By = @Modified_By,
	Modified_Date = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:     dba03@jexpa.com
-- Created date:   Tuesday, July 13, 2021
-- Modified by:    jin.jackson
-- Modified date:  2022-10-01
-- Description:    This method deletes multiple rows in the [JFW].[RolePermission] table by the ID list.
-- Example:        EXEC [JFW].[usp_RolePermission_Delete] @ID_List = '1,2,3'
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_RolePermission_Delete]
	@ID bigint = NULL,
	@ID_List nvarchar(max) = NULL,
	@Permission_ID bigint = NULL,
	@Permission_ID_List nvarchar(max) = NULL,
	@Role_ID bigint = NULL,
	@Role_ID_List nvarchar(max) = NULL
AS

BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Delete statements for procedure here
	IF @ID IS NOT NULL
    BEGIN
		DELETE FROM [JFW].[RolePermission] WHERE ID = @ID
	END
    ELSE IF @ID_List IS NOT NULL
    BEGIN
		DELETE FROM [JFW].[RolePermission] WHERE ID IN (SELECT tvalue
		FROM [JFW].[fn_Split](@ID_List, ','))
	END
    ELSE IF @Permission_ID IS NOT NULL
    BEGIN
		DELETE FROM [JFW].[RolePermission] WHERE Permission_ID = @Permission_ID
	END
    ELSE IF @Permission_ID_List IS NOT NULL
    BEGIN
		DELETE FROM [JFW].[RolePermission] WHERE Permission_ID IN (SELECT tvalue
		FROM [JFW].[fn_Split](@Permission_ID_List, ','))
	END
    ELSE IF @Role_ID IS NOT NULL
    BEGIN
		DELETE FROM [JFW].[RolePermission] WHERE Role_ID = @Role_ID
	END
    ELSE IF @Role_ID_List IS NOT NULL
    BEGIN
		DELETE FROM [JFW].[RolePermission] WHERE Role_ID IN (SELECT tvalue
		FROM [JFW].[fn_Split](@Role_ID_List, ','))
	END
    ELSE
    BEGIN
		RAISERROR('No condition is specified.', 16, 1)
	END

END

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method gets data of the [JFW].[RolePermission] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_RolePermission_Get]
	@ID bigint

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT *
FROM
	[JFW].[RolePermission]
WHERE
    ID = @ID




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method inserts data into the [JFW].[RolePermission] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_RolePermission_Insert]
	@Role_ID bigint,
	@Permission_ID bigint,
	@Created_By bigint = null
AS

INSERT INTO [JFW].[RolePermission]
	(
	[Role_ID],
	[Permission_ID],
	[Modified_By],
	[Modified_Date],
	[Created_By],
	[Created_Date]
	)
VALUES
	(
		@Role_ID,
		@Permission_ID,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method list   data for the [JFW].[RolePermission] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_RolePermission_List]
	@Role_ID bigint = NULL,
	@Permission_ID bigint = NULL,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS

Begin

	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF(@Role_ID IS NOT NULL AND @Role_ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Role_ID] = ', @Role_ID, ' ')

	IF(@Permission_ID IS NOT NULL AND @Permission_ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Permission_ID] = ''', @Permission_ID, ''' ')

	IF(@Created_Date_From IS NOT NULL)
    SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] >= ''', @Created_Date_From, ''' ')

	IF(@Created_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] <= ''', @Created_Date_To, ''' ')

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'


	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' + 
    ' FROM [JFW].[RolePermission]' +
    ' WHERE ' +@whereClause + 
    ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order+
    @PAGINATION


	-- Execute the SQL statement
	--PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString

End


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method updates data for the [JFW].[RolePermission] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_RolePermission_Update]
	@ID bigint,
	@Role_ID bigint,
	@Permission_ID bigint
AS

UPDATE [JFW].[RolePermission] SET
    [Role_ID] = @Role_ID,
    Permission_ID = @Permission_ID

WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method deletes multiple rows in the [JFW].[SMTPSetting] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_SmtpSetting_Delete]
	@ID bigint
AS


DELETE FROM
    [JFW].[SMTPSetting]
WHERE [ID] = @ID


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method gets data of the [JFW].[SMTPSetting] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_SmtpSetting_Get]
	@ID bigint

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT *
FROM
	[JFW].[SMTPSetting]
WHERE
    ID = @ID




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method inserts data into the [JFW].[SMTPSetting] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_SmtpSetting_Insert]
	@Name nvarchar(200),
	@SMTP_Host varchar(100),
	@SMTP_Port int,
	@SMTP_Username varchar(255),
	@SMTP_Password varchar(255),
	@Description nvarchar(1000) = null,
	@Use_TLS bit = null,
	@Is_Default bit = 0,
	@Created_By bigint  = null
AS

-- No more than one default SMTP setting
IF @Is_Default <> 0
BEGIN
	UPDATE [JFW].[SMTPSetting] SET [Is_Default] = 0
END

INSERT INTO [JFW].[SMTPSetting]
	(
	[Name],
	[SMTP_Host],
	[SMTP_Port],
	[SMTP_Username],
	[SMTP_Password],
	[Description],
	[Use_TLS],
	[Is_Default],
	Modified_By,
	[Modified_Date],
	[Created_By],
	[Created_Date]
	)
VALUES
	(
		@Name,
		@SMTP_Host,
		@SMTP_Port,
		@SMTP_Username,
		@SMTP_Password,
		@Description,
		@Use_TLS,
		@Is_Default,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Created by:        dba03@jexpa.com
-- Create date: 2021-02-22
-- Description:    this stored procedure retrieves the list of tracking actions according to the search criteria.
CREATE PROCEDURE [JFW].[usp_SmtpSetting_List]
	@ID bigint = null,
	@Name nvarchar(200) = null,
	@SMTP_Host varchar(100) = null,
	@SMTP_Port int = null,
	@SMTP_Username varchar(255) = null,
	@SMTP_Password varchar(255) = null,
	@Description nvarchar(1000) = null,
	@Use_TLS bit = null,
	@Is_Default bit = 0,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN
	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF(@ID IS NOT NULL AND @ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [ID] = ', @ID, ' ')

	IF(@Name IS NOT NULL AND @Name <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Name] = ''', @Name, ''' ')

	IF(@SMTP_Host IS NOT NULL AND @SMTP_Host <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [SMTP_Host] = ''', @SMTP_Host, ''' ')

	IF(@SMTP_Port IS NOT NULL AND @SMTP_Port <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [SMTP_Port] = ''', @SMTP_Port, ''' ')

	IF(@SMTP_Username IS NOT NULL AND @SMTP_Username <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [SMTP_Username] = ''', @SMTP_Username, ''' ')

	IF(@SMTP_Password IS NOT NULL AND @SMTP_Password <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [SMTP_Password] = ''', @SMTP_Password, ''' ')

	IF(@Description IS NOT NULL AND @Description <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Description] = ''', @Description, ''' ')

	IF(@Use_TLS IS NOT NULL AND @Use_TLS <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Use_TLS] = ''', @Use_TLS, ''' ')

	IF(@Is_Default IS NOT NULL AND @Is_Default <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Is_Default] = ''', @Is_Default, ''' ')

	IF(@Created_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] >= ''', @Created_Date_From, ''' ')

	IF(@Created_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] <= ''', @Created_Date_To, ''' ')

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'


	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' + 
    ' FROM [JFW].[SMTPSetting]' +
    ' WHERE ' +@whereClause + 
    ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order+
    @PAGINATION


	-- Execute the SQL statement
	--PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString

END



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method updates data for the [JFW].[SMTPSetting] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_SmtpSetting_Update]
	@ID bigint,
	@Name nvarchar(200),
	@SMTP_Host varchar(100),
	@SMTP_Port int,
	@SMTP_Username varchar(255),
	@SMTP_Password varchar(255),
	@Description nvarchar(1000),
	@Use_TLS bit,
	@Is_Default bit,
	@Modified_By bigint = null
AS

-- No more than one record can be set as default
IF @Is_Default <> 0
BEGIN
	UPDATE [JFW].[SMTPSetting] SET [Is_Default] = 0 WHERE [ID] <> @ID
END

UPDATE [JFW].[SMTPSetting] SET
    [Name] = @Name,
    [SMTP_Host] = @SMTP_Host,
    [SMTP_Port] = @SMTP_Port,
    [SMTP_Username] = @SMTP_Username,
    [SMTP_Password] = @SMTP_Password,
    [Description] = @Description,
    [Use_TLS] = @Use_TLS,
    [Is_Default] = @Is_Default,
	Modified_By = @Modified_By,
    [Modified_Date] = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method deletes multiple rows in the [JFW].[State] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_State_Delete]
	@ID bigint
AS

DELETE FROM
    [JFW].[State]
WHERE [ID] = @ID


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method gets data of the [JFW].[State] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_State_Get]
	@ID bigint

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT *
FROM
	[JFW].[State]
WHERE
    ID = @ID




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method inserts data into the [JFW].[State] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_State_Insert]
	@Country_Code varchar(2),
	@Code varchar(5),
	@Name nvarchar(200),
	@State_Type nvarchar(Max),
	@Created_By bigint = null
AS

INSERT INTO [JFW].[State]
	(
	[Country_Code],
	[Code],
	[Name],
	[State_Type],
	[Modified_By],
	[Modified_Date],
	[Created_By],
	[Created_Date]
	)
VALUES
	(
		@Country_Code,
		@Code,
		@Name,
		@State_Type,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()

)
SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method List data for the [JFW].[State] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_State_List]
	@Country_Code varchar(2) = null,
	@Code varchar(5) = null,
	@Name nvarchar(200) = null,
	@State_Type nvarchar(Max) = null,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'Country_Code',
	@Sort_Order varchar(5) = 'ASC'
AS
BEGIN
	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF(@Country_Code IS NOT NULL AND @Country_Code <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Country_Code] = ''', @Country_Code, ''' ')

	IF(@Code IS NOT NULL AND @Code <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Code] = ''', @Code, ''' ')

	IF(@Name IS NOT NULL AND @Name <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Name] = ''', @Name, ''' ')

	IF(@State_Type IS NOT NULL AND @State_Type <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [State_Type] = ''', @State_Type, ''' ')

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' + 
    ' FROM [JFW].[State]' +
    ' WHERE ' +@whereClause + 
    ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order+
    @PAGINATION


	-- Execute the SQL statement
	--PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString

END



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method updates data for the [JFW].[State] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_State_Update]
	@ID bigint,
	@Country_Code varchar(2),
	@Code varchar(5),
	@Name nvarchar(200),
	@State_Type nvarchar(max),
	@Modified_By bigint = null
AS

UPDATE [JFW].[State] SET
    [Country_Code] = @Country_Code,
    [Code] = @Code,
    [Name] = @Name,
    [State_Type] = @State_Type,
	Modified_By = @Modified_By,
	Modified_Date = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [JFW].[usp_SubscriptionType_Delete]
	@ID bigint
AS


DELETE FROM
        [JFW].[SubscriptionType]
    WHERE [ID] = @ID


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [JFW].[usp_SubscriptionType_Get]
	@ID bigint

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED


SELECT *
FROM
	[JFW].[SubscriptionType]
WHERE
        ID = @ID



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [JFW].[usp_SubscriptionType_List]
	@Name nvarchar(500) = NULL,
	@Number_Of_Days smallint = NULL,
	@Status smallint = NULL,
	@Is_Default bit = NULL,
	@Description nvarchar(500) = NULL,
	@ZOrder bigint = NULL,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN
	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF(@Name IS NOT NULL AND @Name <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Name] = ''', @Name, ''' ')

	IF(@Number_Of_Days IS NOT NULL AND @Number_Of_Days <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Number_Of_Days] = ''', @Number_Of_Days, ''' ')

	IF(@Status IS NOT NULL AND @Status <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Status] = ''', @Status, ''' ')

	IF(@Is_Default IS NOT NULL AND @Is_Default <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Is_Default] = ''', @Is_Default, ''' ')

	IF(@Description IS NOT NULL AND @Description <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Description] = ''', @Description, ''' ')

	IF(@ZOrder IS NOT NULL AND @ZOrder <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [ZOrder] = ''', @ZOrder, ''' ')

	IF(@Created_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] >= ''', @Created_Date_From, ''' ')

	IF(@Created_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] <= ''', @Created_Date_To, ''' ')

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'


	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' + 
    ' FROM [JFW].[SubscriptionType]' +
    ' WHERE ' +@whereClause + 
    ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order+
    @PAGINATION


	-- Execute the SQL statement
	--PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString

END 



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [JFW].[usp_SubscriptionType_Update]
	@ID bigint,
	@Name nvarchar(500),
	@Description nvarchar(500),
	@Number_Of_Days smallint,
	@Is_Default bit,
	@ZOrder bigint,
	@Status smallint,
	@Modified_By bigint = null
AS

UPDATE [JFW].[SubscriptionType] SET
        [Name] = @Name,
        [Number_Of_Days] = @Number_Of_Days,
        [Status] = @Status,
        [Is_Default] = @Is_Default,
        [Description] = @Description,
        [ZOrder] = @ZOrder,
		Modified_By = @Modified_By,
		Modified_Date = GETUTCDATE()
    WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'





GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method deletes multiple rows in the [JFW].[TimeZone] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_TimeZone_Delete]
	@ID bigint
AS

DELETE FROM
    [JFW].[TimeZone]
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method gets data of the [JFW].[TimeZone] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_TimeZone_Get]
	@ID bigint

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT *
FROM
	[JFW].[TimeZone]
WHERE
    ID = @ID



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method gets data of the [JFW].[TimeZone] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_TimeZone_GetByIso]
	---ISO3166-2
	@Country_Code varchar(2)
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT *
FROM
	[JFW].[TimeZone]
WHERE
    [Country_Code] = @Country_Code

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method inserts data into the [JFW].[TimeZone] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_TimeZone_Insert]
	-- ISO3166-2
	@Country_Code varchar(2),
	@Name varchar(50),
	@IANA_Name varchar(100),
	@Value varchar(10),
	@Description varchar(200),
	@Created_By bigint = null
AS

INSERT INTO [JFW].[TimeZone]
	(
	[Country_Code],
	[Name],
	[Value],
	[Description],
	[Modified_By],
	[Modified_Date],
	[Created_By],
	[Created_Date]
	)
VALUES
	(
		@Country_Code,
		@Name,
		@Value,
		@Description,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Created by:        dba03@jexpa.com
-- Create date:		2021-02-22
-- Description:    this stored procedure retrieves the list of permissions according to the search criteria.
-- =============================================

CREATE PROCEDURE [JFW].[usp_TimeZone_List]
	@Country_Code varchar(2) = null,
	@Name varchar(50) = null,
	@IANA_Name varchar(100) = null,
	@Value varchar(10) = null,
	@Description varchar(200) = null,
	@Modified_Date_From datetime = NULL,
	@Modified_Date_To datetime = NULL,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'ASC'
AS
BEGIN
	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF(@Country_Code IS NOT NULL AND @Country_Code <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Country_Code] = ''', @Country_Code, ''' ')

	IF(@Name IS NOT NULL AND @Name <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Name] = ''', @Name, ''' ')

	IF(@IANA_Name IS NOT NULL AND @IANA_Name <> '')
	SELECT @whereClause = CONCAT(@whereClause,' AND [IANA_Name] = ''', @IANA_Name, ''' ')

	IF(@Value IS NOT NULL AND @Value <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Value] = ''', @Value, ''' ')

	IF(@Description IS NOT NULL AND @Description <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Description] = ''', @Description, ''' ')

	IF(@Modified_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] >= ''', @Modified_Date_From, ''' ')

	IF(@Modified_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Modified_Date] <= ''', @Modified_Date_To, ''' ')

	IF(@Created_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] >= ''', @Created_Date_From, ''' ')

	IF(@Created_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause,' AND [Created_Date] <= ''', @Created_Date_To, ''' ')

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'


	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' + 
    ' FROM [JFW].[TimeZone]' +
    ' WHERE ' +@whereClause + 
    ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order+
    @PAGINATION


	-- Execute the SQL statement
	--PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString

END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [JFW].[usp_TimeZone_Update]
	@ID bigint,
	@Country_Code varchar(2),
	@Name varchar(50),
	@IANA_Name varchar(100),
	@Value varchar(10),
	@Description varchar(200),
	@Modified_By bigint = null
AS

UPDATE [JFW].[TimeZone] SET
    [Country_Code] = @Country_Code, 
    [Name] = @Name, 
	[IANA_Name] = @IANA_Name,
    [Value] = @Value, 
    [Description] = @Description,
	Modified_By = @Modified_By,
	Modified_Date = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method deletes multiple rows in the [JFW].[TrackingAction] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_TrackingAction_Delete]
	@ID bigint
AS

DELETE FROM
    [JFW].[TrackingAction]
WHERE [ID] = @ID
	AND [Is_System] = 0


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method gets data of the [JFW].[TrackingAction] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_TrackingAction_Get]
	@ID bigint

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED


SELECT *
FROM
	[JFW].[TrackingAction]
WHERE
    ID = @ID



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method inserts data into the [JFW].[TrackingAction] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_TrackingAction_Insert]
	@Code varchar(250),
	@Name nvarchar(250),
	@Tracking_Level smallint,
	@Description nvarchar(1000) = null,
	@Created_By bigint = null
AS

INSERT INTO [JFW].[TrackingAction]
	(
	[Code],
	[Name],
	[Tracking_Level],
	[Description],
	Modified_By,
	[Modified_Date],
	Created_By,
	[Created_Date]
	)
VALUES
	(
		@Code,
		@Name,
		@Tracking_Level,
		@Description,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
	)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Created by:        dba03@jexpa.com
-- Create date: 2021-02-22
-- Description:    this stored procedure retrieves the list of tracking actions according to the search criteria.
CREATE PROCEDURE [JFW].[usp_TrackingAction_List]
	@Code varchar(250) = NULL,
	@Name nvarchar(250) = NULL,
	@Tracking_Level smallint = NULL,
	@Description nvarchar(1000) = NULL,
	@Is_System bit = NULL,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN
	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF(@Code IS NOT NULL AND @Code <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Code] = ''', @Code, ''' ')

	IF(@Name IS NOT NULL AND @Name <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Name] = ''', @Name, ''' ')

	IF(@Tracking_Level IS NOT NULL AND @Tracking_Level <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Tracking_Level] = ''', @Tracking_Level, ''' ')

	IF(@Description IS NOT NULL AND @Description <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Description] = ''', @Description, ''' ')

	IF(@Is_System IS NOT NULL AND @Is_System <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Is_System] = ''', @Is_System, ''' ')

	IF(@Created_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause, ' AND [Created_Date] >= ''', @Created_Date_From, ''' ')

	IF(@Created_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause, ' AND [Created_Date] <= ''', @Created_Date_To, ''' ')

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'


	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' + 
    ' FROM [JFW].[TrackingAction]' +
    ' WHERE ' +@whereClause + 
    ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order+
    @PAGINATION



	-- Execute the SQL statement
	--PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString

END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method updates data for the [JFW].[TrackingAction] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_TrackingAction_Update]
	@ID bigint,
	@Code varchar(250),
	@Name nvarchar(250),
	@Tracking_Level smallint,
	@Description nvarchar(1000),
	@Modified_By bigint = null
AS

UPDATE [JFW].[TrackingAction] SET
    [Code] = @Code,
    [Name] = @Name,
    [Tracking_Level] = @Tracking_Level,
    [Description] = @Description,
	Modified_By = @Modified_By,
    [Modified_Date] = GETUTCDATE()

    
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- EXEC [JFW].[usp_User_Delete] '16'
------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method deletes multiple rows in the [JFW].[User] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_User_Delete]
	@ID bigint
AS
BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED


	UPDATE [JFW].[User] SET
    [Status] = -4,
    [Modified_Date] = GETUTCDATE()
WHERE [ID] = @ID


	SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'

END




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


-- EXEC [JFW].[usp_User_Get] '','','','U1122'
------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, November 8, 2021
-- Description:  this method gets data of the [JFW].[User] table by the the param.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_User_Get]
	@ID bigint

AS
BEGIN


	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED

	SELECT *
	FROM [JFW].[User]
	WHERE ID = @ID

END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


-- EXEC [JFW].[usp_User_GetByCode] '1','u08da7682cc959b11'
------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, August 23, 2022
-- Description:  this method gets data of the [JFW].[User] table by the the param.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_User_GetByCode]
	@Brand_ID bigint,
	@User_Code varchar(100)

AS
BEGIN


	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED

	SELECT a.*
	FROM [JFW].[User] a
	WHERE a.Brand_ID = @Brand_ID and a.User_Code = @User_Code

END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


-- EXEC [JFW].[usp_User_GetByEmail] '1','testuser@jexpaframework.com'
------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, November 8, 2021
-- Description:  this method gets data of the [JFW].[User] table by the the param.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_User_GetByEmail]
	@BrandID bigint,
	@Email nvarchar(150)

AS
BEGIN


	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED

	SELECT a.*
	FROM [JFW].[User] a
		left join [JFW].[UserProfile] b on a.ID = b.User_ID
	WHERE a.Brand_ID = @BrandID and b.Email_Address = @Email

END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
-- EXEC [JFW].[usp_User_GetByExternalLogin] @Brand_ID = 1, @Provider_ID = 1, @External_User_ID = 12345
------------------------------------------------------------------------------------------------------------------------
-- Created by:   jin.jackson
-- Created date: 2023-01-04
-- Description:  Gets a user by external login
-- Parameters:   @Brand_ID bigint = null,
--               @Provider_ID bigint = null,
--               @External_User_ID bigint = null
------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_User_GetByExternalLogin]
	@Brand_ID bigint = NULL,
	@Provider_ID bigint = NULL,
	@External_User_ID varchar(50) = NULL
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	DECLARE @SqlString nvarchar(max)

	SET @SqlString = 'SELECT U.* FROM [JFW].[User] AS U JOIN [JFW].[UserExternalLogin] AS UEL ON U.[ID] = UEL.[User_ID] WHERE 1 = 1'

	IF @Brand_ID IS NOT NULL
    BEGIN
		SELECT @SqlString = CONCAT(@SqlString, ' AND UEL.[Brand_ID] = ', @Brand_ID)
	END

	IF @Provider_ID IS NOT NULL
    BEGIN
		SELECT @SqlString = CONCAT(@SqlString, ' AND UEL.[Provider_ID] = ', @Provider_ID)
	END

	IF @External_User_ID IS NOT NULL
    BEGIN
		SELECT @SqlString = CONCAT(@SqlString, ' AND UEL.[External_User_ID] = ''', @External_User_ID, '''')
	END

	-- PRINT @SqlString
	EXEC sp_executesql @SqlString
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- EXEC [JFW].[usp_User_Insert] 1,'abc3vd','1233a1'
------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method inserts data into the [JFW].[User] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_User_Insert]
	@Parrent_ID bigint = null,
	@Brand_ID bigint,
	@User_Code varchar(100),
	@Username varchar(150),
	@Password varchar(150),
	@Passphrase varchar(6) = null ,
	@User_Type smallint = 1,
	--default value
	@Is_Email_Address_Verified bit = 0 ,
	--default value
	@Is_User_Verified bit = 0 ,
	--default value
	@Risk_Mark tinyint = null,
	--default value
	@Status smallint = 1,
	@Created_By bigint = null

AS

INSERT INTO [JFW].[User]
	(
	Parent_ID,
	[Brand_ID],
	[User_Code],
	[Username],
	[Password],
	[Passphrase],
	[User_Type],
	[Is_Email_Address_Verified],
	[Is_User_Verified],
	[Risk_Mark],
	[Status],
	Modified_By,
	[Modified_Date],
	Created_By,
	[Created_Date]
	)
VALUES
	(
		@Parrent_ID,
		@Brand_ID,
		@User_Code,
		@Username,
		@Password,
		@Passphrase,
		@User_Type,
		@Is_Email_Address_Verified,
		@Is_User_Verified,
		@Risk_Mark,
		@Status,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'






GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
-- EXEC [JFW].[usp_User_LinkExternalLogin] @Brand_ID = 1, @User_ID = 111, @Provider_ID = 1, @External_User_ID = '12345611'
------------------------------------------------------------------------------------------------------------------------
-- Created by:   jin.jackson
-- Created date: 2023-01-04
-- Description:  Links an external login to a user
-- Parameters:   @Brand_ID bigint = null,
--               @User_ID bigint = null,
--               @Provider_ID bigint = null,
--               @External_User_ID bigint = null
------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_User_LinkExternalLogin]
	@Brand_ID bigint = NULL,
	@User_ID bigint = NULL,
	@Provider_ID bigint = NULL,
	@External_User_ID varchar(50) = NULL,
	@Created_By bigint = null
AS
BEGIN
	INSERT INTO [JFW].[UserExternalLogin]
		(
		[Brand_ID],
		[User_ID],
		[Provider_ID],
		[External_User_ID],
		[Modified_By],
		[Modified_Date],
		[Created_By],
		[Created_Date]
		)
	VALUES
		(
			@Brand_ID,
			@User_ID,
			@Provider_ID,
			@External_User_ID,
			@Created_By,
			GETUTCDATE(),
			@Created_By,
			GETUTCDATE()
	
    )

	SELECT CAST(SCOPE_IDENTITY() AS bigint) AS [ID]
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- EXEC [JFW].[usp_User_List] '1'
-- =============================================
-- Created by:        dba03@jexpa.com
-- Create date: 2021-07-22
-- Description:    this stored procedure retrieves the list of users according to the search criteria.
-- =============================================
CREATE PROCEDURE [JFW].[usp_User_List]
	@Brand_ID bigint = NULL,
	@User_Code varchar(100) = NULL,
	@Username varchar(150) = null,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Expiry_Date_From datetime = NULL,
	@Expiry_Date_To datetime = NULL,
	@User_Type smallint = NULL,
	@Status smallint = NULL,
	@Having_Device smallint = NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN
	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF(@Brand_ID IS NOT NULL AND @Brand_ID <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Brand_ID] = ''', @Brand_ID, ''') ')
	END

	IF(@User_Code IS NOT NULL AND @User_Code <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([User_Code] = ''', @User_Code, ''') ')
	END

	IF(@Username IS NOT NULL AND @Username <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Username] = ''', @Username, ''') ')
	END

	IF(@Created_Date_From IS NOT NULL)
	BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Created_Date] >= ', @Created_Date_From, ') ')
	END

	IF(@Created_Date_To IS NOT NULL)
	BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Created_Date] <= ', @Created_Date_To, ') ')
	END

	IF(@Expiry_Date_From IS NOT NULL)
	BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Expiry_Date] >= ', @Expiry_Date_From, ') ')
	END

	IF(@Expiry_Date_To IS NOT NULL)
	BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Expiry_Date] <= ', @Expiry_Date_To, ') ')
	END

	IF(@User_Type IS NOT NULL)
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([User_Type] = ''', @User_Type, ''') ')
	END

	IF(@Having_Device IS NOT NULL)
    BEGIN
		IF(@Having_Device =0 ) SELECT @whereClause = CONCAT(@whereClause,' AND  NOT Exists(Select 1 from [JFW].[Device] d where [ID] = d.[User_ID]) ')
		IF(@Having_Device =1 ) SELECT @whereClause = CONCAT(@whereClause,' AND  Exists(Select 1 from [JFW].[Device] d where [ID] = d.[User_ID]) ')
	END

	IF(@Status IS NOT NULL)
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Status] = ''', @Status, ''') ')
	END

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' +
                'FROM [JFW].[User] '+
                ' WHERE ' +@whereClause + 
                ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order +
                @PAGINATION


	-- Execute the SQL statement
	--PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString

END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- EXEC [JFW]
------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method Update data into the [JFW].[User] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_User_Update]
	@ID bigint,
	@Parrent_ID bigint = null,
	@Username varchar(150),
	@Password varchar(150),
	@Passphrase varchar(6),
	@User_Type smallint,
	@Is_Email_Address_Verified bit ,
	@Is_User_Verified bit,
	@Risk_Mark tinyint,
	@Status smallint,
	@Modified_By bigint = null
AS

UPDATE [JFW].[User] SET 
	Parent_ID = @Parrent_ID,
    [Username] = @Username,
    [Password] = @Password, 
    [Passphrase] = @Passphrase, 
    [User_Type] = @User_Type, 
    [Is_Email_Address_Verified] = @Is_Email_Address_Verified,
    [Is_User_Verified] = @Is_User_Verified,
    [Risk_Mark] = @Risk_Mark, 
    [Status] = @Status, 
	Modified_By = @Modified_By,
    [Modified_Date] = GETUTCDATE()
WHERE [ID] = @ID


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [JFW].[usp_User_View]
	@ID bigint = NULL,
	@ID_List varchar(1000) = NULL,
	@Brand_URL nvarchar(1000) = NULL,
	@Brand_ID bigint = NULL,
	@Role_ID bigint = NULL,
	@Referral_User_ID bigint = NULL,
	@User_Type smallint = NULL,
	@User_Code varchar(100) = NULL,
	@Username varchar(150) = NULL,
	@Email_Address varchar(150) = NULL,
	@Expiry_Date_From datetime = NULL,
	@Expiry_Date_To datetime = NULL,
	@Status smallint = NULL,
	@Keywords nvarchar(1000) = NULL,
	@Modified_Date_From datetime = NULL,
	@Modified_Date_To datetime = NULL,
	@Created_Date_From datetime = NULL,
	@Created_Date_To datetime = NULL,
	@Limit int = NULL,
	@Page_Number int = NULL,
	@Page_Size int = NULL,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN
	DECLARE 
    @selectClause nvarchar(max) = 'SELECT ',
    @whereClause nvarchar(max) = CONCAT(CHAR(13), 'WHERE 1=1 '),
    @fromClause NVARCHAR(MAX) =  CONCAT(CHAR(13), 'FROM '),
	@paginationClause nvarchar(max) = '',
    @userFilterQuery nvarchar(max),
    @userProfileFilterQuery nvarchar(max),
    @userSettingFilterQuery nvarchar(max),
    @dateField nvarchar(max),
    @tmpSqlString nvarchar(max),
    @sqlString nvarchar(max)

	CREATE TABLE #temp
	(
		tmpId bigint not null unique
	)

	--- Build the from clause
	SET @fromClause = CONCAT(@fromClause, '[JFW].[User] AS U')
	SET @fromClause = CONCAT(@fromClause, CHAR(13), 'LEFT JOIN [JFW].[UserProfile] AS UP ON U.[ID] = UP.[User_ID]')
	SET @fromClause = CONCAT(@fromClause, CHAR(13), 'LEFT JOIN [JFW].[UserSetting] AS US ON U.[ID] = US.[User_ID]')

	--- Build the select clause

	IF(@Limit IS NOT NULL)
    BEGIN
		SET @selectClause = CONCAT(@selectClause, 'TOP (', @Limit, ') ')
	END

	SET @selectClause = CONCAT(@selectClause, 'U.*, ')

	--- Build the select clause for UserProfile
	SET @selectClause = CONCAT(@selectClause, [JFW].[fn_GenerateColumnAliases]('UserProfile', 'UserProfile_', 'UP'), ', ')

	--- Build the select clause for UserSetting
	SET @selectClause = CONCAT(@selectClause, [JFW].[fn_GenerateColumnAliases]('UserSetting', 'UserSetting_', 'US'))

	--- Build the where clause
	IF (@ID IS NOT NULL)
    BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND U.[ID] = ', @ID)
	END

	IF (@ID_List IS NOT NULL)
    BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND U.[ID] IN (SELECT tvalue FROM [JFW].[fn_Split](''', @ID_List, ''', '',''))')
	END

	IF (@Brand_URL IS NOT NULL AND @Brand_URL <> '' AND @Brand_ID IS NULL)
	BEGIN
		SET @Brand_ID = [JFW].[fn_GetBrandId](@Brand_URL)
	END

	IF (@Brand_ID IS NOT NULL)
    BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND U.[Brand_ID] = ', @Brand_ID)
	END

	IF (@Referral_User_ID IS NOT NULL)
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND U.[ID] IN (SELECT DISTINCT [Referred_User_ID] FROM [JFW].[UserReferral] WHERE [Referral_User_ID] = ', @Referral_User_ID, ')')
	END

	IF (@User_Type IS NOT NULL)
    BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND U.[User_Type] = ', @User_Type)
	END

	IF (@Role_ID IS NOT NULL)
    BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND U.[ID] IN (SELECT [USER_ID] FROM [JFW].[UserRole] AS UR WHERE UR.[ROLE_ID] = ', @Role_ID, ')')
	END

	IF (@Keywords IS NOT NULL)
    BEGIN
		--- Build the filter queries
		SELECT @userFilterQuery = [JFW].[fn_GetTableViewSearchQuery]('JFW', 'User', @Keywords)
		SELECT @userProfileFilterQuery = [JFW].[fn_GetTableViewSearchQuery]('JFW', 'UserProfile', @Keywords)
		SELECT @userSettingFilterQuery = [JFW].[fn_GetTableViewSearchQuery]('JFW', 'UserSetting', @Keywords)

		SET @tmpSqlString = CONCAT('INSERT INTO #temp(tmpId) SELECT [ID] FROM (', @userFilterQuery, ') as X')
		-- PRINT CONCAT('SQL string: ', @tmpSqlString)
		EXEC sp_executesql @tmpSqlString
		SET @tmpSqlString = CONCAT('INSERT INTO #temp(tmpId) SELECT [User_ID] FROM (', @userProfileFilterQuery, ') as X WHERE [User_ID] NOT IN (SELECT tmpId FROM #temp)')
		-- PRINT CONCAT('SQL string: ', @tmpSqlString)
		EXEC sp_executesql @tmpSqlString
		SET @tmpSqlString = CONCAT('INSERT INTO #temp(tmpId) SELECT [User_ID] FROM (', @userSettingFilterQuery, ') as X WHERE [User_ID] NOT IN (SELECT tmpId FROM #temp)')
		-- PRINT CONCAT('SQL string: ', @tmpSqlString)
		EXEC sp_executesql @tmpSqlString
		SELECT @whereClause = CONCAT(@whereClause, ' AND U.[ID] IN (SELECT tmpId FROM #temp)')
	END

	IF (@Created_Date_From IS NOT NULL)
    BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND U.[Created_Date] >= ''', @Created_Date_From, '''')
	END

	IF (@Created_Date_To IS NOT NULL)
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND U.[Created_Date] <= ''', @Created_Date_To, '''')
	END

	IF (@Expiry_Date_From IS NOT NULL)
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [UserSetting_Expiry_Date] >= ''', @Expiry_Date_From, '''')
	END

	IF (@Expiry_Date_To IS NOT NULL)
	BEGIN
		SET @whereClause = CONCAT(@whereClause, ' AND [UserSetting_Expiry_Date] <= ''', @Expiry_Date_To, '''')
	END

	IF (@Status IS NOT NULL)
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND (U.[Status] = ', @Status, ') ')
	END

	IF (@Page_Number IS NOT NULL AND @Page_Size IS NOT NULL)
	BEGIN
		SET @paginationClause = CONCAT(' OFFSET ', @Page_Size, ' * (', @Page_Number, ' - 1) ROWS FETCH NEXT ', @Page_Size, ' ROWS ONLY')
	END

	SET @sqlString = @selectClause + @fromClause + @whereClause + ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order + @paginationClause

	-- Execute the SQL statement
	-- PRINT CONCAT('SQL string: ', @sqlString)
	EXEC sp_executesql @sqlString

END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method deletes multiple rows in the [JFW].[UserAddress] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_UserAddress_Delete]
	@ID bigint
AS


DELETE FROM
    [JFW].[UserAddress]
WHERE [ID] = @ID


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method gets data of the [JFW].[UserAddress] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_UserAddress_Get]
	@ID bigint

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED


SELECT *
FROM
	[JFW].[UserAddress]
WHERE ID = @ID




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method inserts data into the [JFW].[UserAddress] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_UserAddress_Insert]
	@User_ID bigint,
	@Address nvarchar(250) = null,
	@Country_ID bigint = null,
	@State_ID bigint = null,
	@City_ID bigint = null,
	@Postal_Code varchar(50) = null,
	@Is_Default bit = 0,
	@Created_By bigint = null
AS

INSERT INTO [JFW].[UserAddress]
	(
	[User_ID],
	[Address],
	[Country_ID],
	[State_ID],
	[City_ID],
	[Postal_Code],
	[Is_Default],
	[Modified_By],
	[Modified_Date],
	[Created_By],
	[Created_Date]

	)
VALUES
	(
		@User_ID,
		@Address,
		@Country_ID,
		@State_ID,
		@City_ID,
		@Postal_Code,
		@Is_Default,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- EXEC [JFW].[usp_UserAddress_List] '1'
-- =============================================
-- Created by:        dba03@jexpa.com
-- Create date: 2021-07-22
-- Description:    this stored procedure retrieves the list of userprofiles according to the search criteria.
-- =============================================
CREATE PROCEDURE [JFW].[usp_UserAddress_List]
	@User_ID bigint = null,
	@Address nvarchar(250) = null,
	@Country_ID bigint = null,
	@State_ID bigint = null,
	@City_ID bigint = null,
	@Postal_Code varchar(50) = null,
	@Is_Default bit = 0,
	@Keyword nvarchar(1000) = NULL,
	@Keyword_Encryption nvarchar(2000) = NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN
	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	IF(@User_ID IS NOT NULL AND @User_ID <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([User_ID] = ', @User_ID, ') ')
	END

	IF(@Address IS NOT NULL AND @Address <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Address] = ''', @Address, ''') ')
	END

	IF(@Country_ID IS NOT NULL AND @Country_ID <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Country_ID] = ''', @Country_ID, ''') ')
	END

	IF(@State_ID IS NOT NULL AND @State_ID <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([State_ID] = ''', @State_ID, ''') ')
	END

	IF(@City_ID IS NOT NULL AND @City_ID <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([City_ID] = ''', @City_ID, ''') ')
	END

	IF(@Postal_Code IS NOT NULL AND @Postal_Code <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Postal_Code] = ''', @Postal_Code, ''') ')
	END

	IF(@Is_Default IS NOT NULL AND @Is_Default <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Is_Default] = ''', @Is_Default, ''') ')
	END

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' + 
                'FROM [JFW].[UserAddress] '+
                ' WHERE ' +@whereClause + 
                ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order +
                @PAGINATION


	-- Execute the SQL statement
	--PRINT @sqlString
	EXEC sp_executesql @sqlString

END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method updates data for the [JFW].[UserAddress] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_UserAddress_Update]
	@ID bigint,
	@User_ID bigint,
	@Address nvarchar(250) = null,
	@Country_ID bigint = null,
	@State_ID bigint = null,
	@City_ID bigint = null,
	@Postal_Code varchar(50) = null,
	@Is_Default bit = 0,
	@Modified_By bigint = null
AS

-- Each user can have only one primary address
IF @Is_Default <> 0
BEGIN
	UPDATE [JFW].[UserAddress]
	SET
		[Is_Default] = 0
	WHERE [User_ID] = @User_ID
END

BEGIN
	UPDATE [JFW].[UserAddress]
	SET
		[Address] = @Address,
		[Country_ID] = @Country_ID,
		[State_ID] = @State_ID,
		[City_ID] = @City_ID,
		[Postal_Code] = @Postal_Code,
		[Is_Default] = @Is_Default,
		Modified_By = @Modified_By,
		[Modified_Date] = GETUTCDATE()
	WHERE [ID] = @ID

	SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'

END


--- UserExternalLogin
--- Delete

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   jin.jackson
-- Created date: 2023-02-24
-- Description:  This method deletes multiple rows in the [JFW].[UserExternalLogin] table by the ID.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_UserExternalLogin_Delete]
	@ID bigint = null,
	@User_ID bigint = null
AS

BEGIN
	DECLARE @whereClause nvarchar(max) = '1 = 1',
	@sqlString nvarchar(max)

	IF(@ID IS NOT NULL AND @ID > 0)
	BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([ID] = ', @ID, ') ')
	END

	IF(@User_ID IS NOT NULL AND @User_ID > 0)
	BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([User_ID] = ', @User_ID, ') ')
	END

	SELECT @sqlString = 'DELETE FROM [JFW].[UserExternalLogin] WHERE ' + @whereClause

	-- Execute the SQL statement
	--PRINT @sqlString
	EXEC sp_executesql @sqlString

	SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'
END


--- Get

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   jin.jackson
-- Created date: 2023-02-24
-- Description:  This method gets data from the [JFW].[UserExternalLogin] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_UserExternalLogin_Get]
	@ID bigint = null
AS
BEGIN
	SELECT *
	FROM [JFW].[UserExternalLogin]
	WHERE [ID] = @ID
END


--- Insert

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   jin.jackson
-- Created date: 2023-02-24
-- Description:  This method inserts data into the [JFW].[UserExternalLogin] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_UserExternalLogin_Insert]
	@Brand_ID bigint,
	@User_ID bigint,
	@Provider_ID bigint,
	@External_User_ID varchar(50)
AS
BEGIN
	INSERT INTO [JFW].[UserExternalLogin]
		(
		[Brand_ID],
		[User_ID],
		[Provider_ID],
		[External_User_ID]
		)
	VALUES
		(
			@Brand_ID,
			@User_ID,
			@Provider_ID,
			@External_User_ID
    	)

	SELECT CAST(SCOPE_IDENTITY() AS bigint) AS [ID]
END


--- List

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   jin.jackson
-- Created date: 2023-02-24
-- Description:  This method lists data from the [JFW].[UserExternalLogin] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_UserExternalLogin_List]
	@Brand_ID bigint = null,
	@User_ID bigint = null,
	@Provider_ID bigint = null,
	@External_User_ID varchar(50) = null,
	@Created_Date_From datetime = null,
	@Created_Date_To datetime = null,
	@Limit int = null,
	@Sort_Data_Field varchar(50) = 'ID',
	@Sort_Order varchar(4) = 'ASC',
	@Page_Number int = null,
	@Page_Size int = null
AS
BEGIN
	DECLARE @limitClause nvarchar(100) = '',
	@offsetClause nvarchar(max) = '',
	@whereClause nvarchar(max) = '1 = 1',
	@sql nvarchar(max) = '',
	@skip int = @Page_Size * @Page_Number

	IF (@Limit IS NOT NULL AND @Limit > 0)
	BEGIN
		SET @limitClause = 'TOP ' + CAST(@Limit AS varchar(10))
	END

	IF (@Page_Number IS NOT NULL AND @Page_Size IS NOT NULL)
	BEGIN
		SET @offsetClause = 'OFFSET ' + CAST(@skip AS varchar(10)) + ' ROWS' + CHAR(13) + 'FETCH NEXT ' + CAST(@Page_Size AS varchar(10)) + ' ROWS ONLY'
	END

	IF (@Brand_ID IS NOT NULL AND @Brand_ID > 0)
	BEGIN
		SET @whereClause = CONCAT(@whereClause,' AND ([Brand_ID] = ', @Brand_ID, ') ')
	END

	IF (@User_ID IS NOT NULL AND @User_ID > 0)
	BEGIN
		SET @whereClause = CONCAT(@whereClause,' AND ([User_ID] = ', @User_ID, ') ')
	END

	IF (@Provider_ID IS NOT NULL AND @Provider_ID > 0)
	BEGIN
		SET @whereClause = CONCAT(@whereClause,' AND ([Provider_ID] = ', @Provider_ID, ') ')
	END

	IF (@External_User_ID IS NOT NULL AND @External_User_ID <> '')
	BEGIN
		SET @whereClause = CONCAT(@whereClause,' AND ([External_User_ID] = ', @External_User_ID, ') ')
	END

	IF (@Created_Date_From IS NOT NULL)
	BEGIN
		SET @whereClause = CONCAT(@whereClause,' AND ([Created_Date] >= ', @Created_Date_From, ') ')
	END

	IF (@Created_Date_To IS NOT NULL)
	BEGIN
		SET @whereClause = CONCAT(@whereClause,' AND ([Created_Date] <= ', @Created_Date_To, ') ')
	END

	SELECT @sql= CONCAT('SELECT ', @LimitClause, ' *',
		' FROM [JFW].[UserExternalLogin]',
		' WHERE ', @whereClause,
		' ORDER BY ', '[', @Sort_Data_Field, ']', ' ', @Sort_Order,
    	@offsetClause)


	-- Execute the SQL statement
	-- PRINT @sql
	EXEC sp_executesql @sql
END


--- Update

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   jin.jackson
-- Created date: 2023-02-24
-- Description:  This method updates data in the [JFW].[UserExternalLogin] table.
------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_UserExternalLogin_Update]
	-- CREATE PROCEDURE [JFW].[usp_UserExternalLogin_Update]
	@ID bigint,
	@Brand_ID bigint,
	@User_ID bigint,
	@Provider_ID bigint,
	@External_User_ID varchar(50)
AS
BEGIN
	UPDATE [JFW].[UserExternalLogin]
	SET
		[Brand_ID] = @Brand_ID,
		[User_ID] = @User_ID,
		[Provider_ID] = @Provider_ID,
		[External_User_ID] = @External_User_ID,
		[Modified_Date] = GETUTCDATE()
	WHERE [ID] = @ID

	SELECT CAST(@@ROWCOUNT as bigint) AS [TotalRows]
END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:     dba03@jexpa.com
-- Created date:   Tuesday, March 30, 2021
-- Modified date:  2022-10-04
-- Description:    This method deletes multiple rows in the [JFW].[UserPermission] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_UserPermission_Delete]
	@ID bigint = NULL,
	@ID_List varchar(1000) = NULL,
	@User_ID bigint = NULL,
	@User_ID_List varchar(1000) = NULL,
	@Permission_ID bigint = NULL,
	@Permission_ID_List varchar(1000) = NULL
AS

BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	IF @ID IS NOT NULL
    BEGIN
		DELETE FROM [JFW].[UserPermission] WHERE [ID] = @ID
	END
    ELSE IF @ID_List IS NOT NULL
    BEGIN
		DELETE FROM [JFW].[UserPermission] WHERE [ID] IN (SELECT tvalue
		FROM [JFW].[fn_Split](@ID_List, ','))
	END
    ELSE IF @User_ID IS NOT NULL
    BEGIN
		DELETE FROM [JFW].[UserPermission] WHERE [User_ID] = @User_ID
	END
    ELSE IF @User_ID_List IS NOT NULL
    BEGIN
		DELETE FROM [JFW].[UserPermission] WHERE [User_ID] IN (SELECT tvalue
		FROM [JFW].[fn_Split](@User_ID_List, ','))
	END
    ELSE IF @Permission_ID IS NOT NULL
    BEGIN
		DELETE FROM [JFW].[UserPermission] WHERE [Permission_ID] = @Permission_ID
	END
    ELSE IF @Permission_ID_List IS NOT NULL
    BEGIN
		DELETE FROM [JFW].[UserPermission] WHERE [Permission_ID] IN (SELECT tvalue
		FROM [JFW].[fn_Split](@Permission_ID_List, ','))
	END
    ELSE
    BEGIN
		RAISERROR('No parameter is specified.', 16, 1)
	END
END

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, March 30, 2021
-- Description:  this method gets data of the [JFW].[UserPermission] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_UserPermission_Get]
	@ID bigint = null
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED


SELECT *
FROM
	[JFW].UserPermission
WHERE ID = @ID




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, March 30, 2021
-- Description:  this method inserts data into the [JFW].[UserPermission] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_UserPermission_Insert]
	@Permission_ID bigint,
	@User_ID bigint,
	@Created_By bigint = null
AS

INSERT INTO [JFW].UserPermission
	(
	Permission_ID,
	[User_ID],
	[Modified_By],
	[Modified_Date],
	[Created_By],
	[Created_Date]
	)
VALUES
	(
		@Permission_ID,
		@User_ID,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- EXEC [JFW].[usp_UserSetting_List] '1'
-- =============================================
-- Created by:        dba03@jexpa.com
-- Create date: 2021-07-22
-- Description:    this stored procedure retrieves the list of userprofiles according to the search criteria.
-- =============================================
CREATE PROCEDURE [JFW].[usp_UserPermission_List]
	@Permission_ID bigint = null,
	@User_ID bigint = null,
	@Keyword nvarchar(1000) = NULL,
	@Keyword_Encryption nvarchar(2000) = NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN
	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	IF(@User_ID IS NOT NULL AND @User_ID <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([User_ID] = ''', @User_ID, ''') ')
	END

	IF(@Permission_ID IS NOT NULL AND @Permission_ID <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Permission_ID] = ''', @Permission_ID, ''') ')
	END


	SELECT @sqlString = 'SELECT * '+
                'FROM [JFW].[UserPermission] '+
                ' WHERE ' +@whereClause + 
                ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order +
                @PAGINATION


	-- Execute the SQL statement
	--PRINT @sqlString
	EXEC sp_executesql @sqlString

END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   jin.jackson
-- Created date: 2023-02-24
-- Description:  this method updates data of the [JFW].[UserPermission] table.
------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [JFW].[usp_UserPermission_Update]
	-- CREATE PROCEDURE [JFW].[usp_UserPermission_Update]
	@ID bigint,
	@Permission_ID bigint,
	@Modified_By bigint = null,
	@User_ID bigint
AS
BEGIN
	UPDATE [JFW].[UserPermission]
	SET
		[Permission_ID] = @Permission_ID,
		[User_ID] = @User_ID,
		Modified_By = @Modified_By,
	Modified_Date = GETUTCDATE()
	WHERE [ID] = @ID

	SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'
END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, March 30, 2021
-- Description:  this method deletes multiple rows in the [JFW].[UserProfile] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_UserProfile_Delete]
	@ID bigint
AS


DELETE FROM
    [JFW].[UserProfile]
WHERE [ID] = @ID


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method gets data of the [JFW].[UserProfile] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_UserProfile_Get]
	@ID bigint
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED



SELECT *
FROM
	[JFW].[UserAddress]
WHERE ID =@ID



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method inserts data into the [JFW].[UserProfile] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_UserProfile_Insert]
	@User_ID bigint,
	@Nick_Name nvarchar(50) = null,
	@First_Name nvarchar(50) = null,
	@Last_Name nvarchar(50) = null,
	@Avatar nvarchar(500) = null,
	@Email_Address varchar(150),
	@PhoneNumber1 varchar(20) = null,
	@PhoneNumber2 varchar(20) = null,
	@PhoneNumber3 varchar(20) = null,
	@Website nvarchar(100) = null,
	@TimeZone_ID bigint = null,
	@Created_By bigint = null
AS

INSERT INTO [JFW].[UserProfile]
	(
	[User_ID],
	[First_Name],
	[Last_Name],
	[Nick_Name],
	[Avatar],
	[Email_Address],
	[PhoneNumber1],
	[PhoneNumber2],
	[PhoneNumber3],
	[Website],
	[TimeZone_ID],
	[Modified_By],
	[Modified_Date],
	[Created_By],
	[Created_Date]
	)
VALUES
	(
		@User_ID,
		@First_Name,
		@Last_Name,
		@Nick_Name,
		@Avatar,
		@Email_Address,
		@PhoneNumber1,
		@PhoneNumber2,
		@PhoneNumber3,
		@Website,
		@TimeZone_ID,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- EXEC [JFW].[usp_UserProfile_List] '1'
-- =============================================
-- Created by:        dba03@jexpa.com
-- Create date: 2021-07-22
-- Description:    this stored procedure retrieves the list of userprofiles according to the search criteria.
-- =============================================
CREATE PROCEDURE [JFW].[usp_UserProfile_List]
	@User_ID bigint = null,
	@Nick_Name nvarchar(50) = null,
	@First_Name nvarchar(50) = null,
	@Last_Name nvarchar(50) = null,
	@Avatar nvarchar(500) = null,
	@Email_Address varchar(150) = null,
	@PhoneNumber1 varchar(20) = null,
	@PhoneNumber2 varchar(20) = null,
	@PhoneNumber3 varchar(20) = null,
	@Website nvarchar(100) = null,
	@TimeZone_ID bigint = null,
	@Created_Date_From datetime = null,
	@Created_Date_To datetime = null,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN
	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	IF(@User_ID IS NOT NULL AND @User_ID <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([User_ID] = ', @User_ID, ') ')
	END

	IF(@Nick_Name IS NOT NULL AND @Nick_Name <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Nick_Name] = ''', @Nick_Name, ''') ')
	END

	IF(@First_Name IS NOT NULL AND @First_Name <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([First_Name] = ''', @First_Name, ''') ')
	END

	IF(@Last_Name IS NOT NULL AND @Last_Name <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Last_Name] = ''', @Last_Name, ''') ')
	END

	IF(@Avatar IS NOT NULL AND @Avatar <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Avatar] = ''', @Avatar, ''') ')
	END

	IF(@Email_Address IS NOT NULL AND @Email_Address <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Email_Address] = ''', @Email_Address, ''') ')
	END

	IF(@PhoneNumber1 IS NOT NULL AND @PhoneNumber1 <> '')
	BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([PhoneNumber1] = ''', @PhoneNumber1, ''') ')
	END

	IF(@PhoneNumber2 IS NOT NULL AND @PhoneNumber2 <> '')
	BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([PhoneNumber2] = ''', @PhoneNumber2, ''') ')
	END

	IF(@PhoneNumber3 IS NOT NULL AND @PhoneNumber3 <> '')
	BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([PhoneNumber3] = ''', @PhoneNumber3, ''') ')
	END

	IF(@Website IS NOT NULL AND @Website <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Website] = ''', @Website, ''') ')
	END

	IF(@TimeZone_ID IS NOT NULL AND @TimeZone_ID <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([TimeZone_ID] = ''', @TimeZone_ID, ''') ')
	END

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' +
                'FROM [JFW].[UserProfile] '+
                ' WHERE ' +@whereClause + 
                ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order +
                @PAGINATION


	-- Execute the SQL statement
	--PRINT @sqlString
	EXEC sp_executesql @sqlString

END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, April 30, 2022
-- Description:  this method updates data for the [JFW].[UserProfile] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_UserProfile_Update]
	@ID bigint,
	@User_ID bigint,
	@Nick_Name nvarchar(50),
	@First_Name nvarchar(50),
	@Last_Name nvarchar(50),
	@Avatar nvarchar(500),
	@Email_Address varchar(150),
	@PhoneNumber1 varchar(20),
	@PhoneNumber2 varchar(20),
	@PhoneNumber3 varchar(20),
	@Website nvarchar(100),
	@TimeZone_ID bigint,
	@Modified_By bigint = null
AS

UPDATE [JFW].[UserProfile] SET
    [User_ID] = @User_ID,
    [Nick_Name] = @Nick_Name,
    [First_Name] = @First_Name,
    [Last_Name] = @Last_Name,
    [Avatar] = @Avatar,
    [Email_Address] = @Email_Address,
    [PhoneNumber1] = @PhoneNumber1,
    [PhoneNumber2] = @PhoneNumber2,
    [PhoneNumber3] = @PhoneNumber3,
    [Website] = @Website,
    [TimeZone_ID] = @TimeZone_ID,
	Modified_By = @Modified_By,
    [Modified_Date] = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) AS 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:     dba03@jexpa.com
-- Created date:   Tuesday, March 30, 2021
-- Modified by:    jin.jackson
-- Modified date:  2022-09-23
-- Description:    This method deletes multiple rows in the [JFW].[UserReferral] table by the ID list.
-- Example:        EXEC [JFW].[usp_UserReferral_Delete] @ID_List = '1,2,3'
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_UserReferral_Delete]
	@ID bigint = NULL

AS

BEGIN


	DELETE FROM [JFW].[UserReferral] 
        WHERE ID = @ID


	SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'
END



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, March 30, 2021
-- Description:  this method gets data of the [JFW].[UserReferral] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_UserReferral_Get]
	@ID bigint = null
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED


SELECT *
FROM
	[JFW].[UserReferral]
WHERE ID = @ID




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, March 30, 2021
-- Description:  this method inserts data into the [JFW].[UserReferral] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_UserReferral_Insert]
	@Referral_User_ID bigint,
	@Referred_User_ID bigint
AS

INSERT INTO [JFW].[UserReferral]
	(
	[Referral_User_ID],
	[Referred_User_ID],
	Modified_Date,
	Created_Date
	)
VALUES
	(
		@Referral_User_ID,
		@Referred_User_ID,
		GETUTCDATE(),
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- EXEC [JFW].[usp_UserReferral_List] @Referral_User_ID = 1, @Referred_User_ID = 1, @Created_Date_From = '2021-07-22', @Created_Date_To = '2021-07-22', @Limit = 1, @Page_Number = 1, @Page_Size = 1, @Sort_Data_Field = 'ID', @Sort_Order = 'DESC'
-- =============================================
-- Created by:  jin.jackson
-- Create date: 2023-02-24
-- Description: This gets a list of UserReferral records.
-- =============================================
CREATE PROCEDURE [JFW].[usp_UserReferral_List]
	@Referral_User_ID bigint = null,
	@Referred_User_ID bigint = null,
	@Created_Date_From datetime = null,
	@Created_Date_To datetime = null,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN
	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	IF(@Referral_User_ID IS NOT NULL)
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Referral_User_ID] = ', @Referral_User_ID, ') ')
	END

	IF(@Referred_User_ID IS NOT NULL)
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Referred_User_ID] = ', @Referred_User_ID, ') ')
	END

	IF(@Created_Date_From IS NOT NULL)
	BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Created_Date] >= ''', @Created_Date_From, ''') ')
	END

	IF(@Created_Date_To IS NOT NULL)
	BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Created_Date] <= ''', @Created_Date_To, ''') ')
	END

	SELECT @sqlString = 'SELECT * '+
                'FROM [JFW].[UserReferral] '+
                ' WHERE ' +@whereClause + 
                ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order +
                @PAGINATION


	-- Execute the SQL statement
	--PRINT @sqlString
	EXEC sp_executesql @sqlString

END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, March 30, 2021
-- Description:  this method updates data for the [JFW].[UserPermission] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_UserReferral_Update]
	@ID bigint,
	@Referral_User_ID bigint,
	@Referred_User_ID bigint
AS

UPDATE [JFW].UserReferral SET
    [Referral_User_ID] = @Referral_User_ID,
    [Referred_User_ID] = @Referred_User_ID,
    Modified_Date = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:     dba03@jexpa.com
-- Created date:   Tuesday, March 30, 2021
-- Modified by:    jin.jackson
-- Modified date:  2022-09-23
-- Description:    This method deletes multiple rows in the [JFW].[UserRole] table by the ID list.
-- Example:        EXEC [JFW].[usp_UserRole_Delete] @ID_List = '1,2,3'
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_UserRole_Delete]
	@ID bigint = NULL,
	@ID_List varchar(1000) = NULL,
	@User_ID bigint = NULL,
	@User_ID_List varchar(1000) = NULL,
	@Role_ID bigint = NULL,
	@Role_ID_List varchar(1000) = NULL
AS

BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	IF @ID IS NOT NULL
    BEGIN
		DELETE FROM [JFW].[UserRole] WHERE ID = @ID
	END
    ELSE IF @ID_List IS NOT NULL
    BEGIN
		DELETE FROM [JFW].[UserRole] WHERE ID IN (SELECT tvalue
		FROM [JFW].[fn_Split](@ID_List, ','))
	END
    ELSE IF @User_ID IS NOT NULL
    BEGIN
		DELETE FROM [JFW].[UserRole] WHERE User_ID = @User_ID
	END
    ELSE IF @User_ID_List IS NOT NULL
    BEGIN
		DELETE FROM [JFW].[UserRole] WHERE User_ID IN (SELECT tvalue
		FROM [JFW].[fn_Split](@User_ID_List, ','))
	END
    ELSE IF @Role_ID IS NOT NULL
    BEGIN
		DELETE FROM [JFW].[UserRole] WHERE Role_ID = @Role_ID
	END
    ELSE IF @Role_ID_List IS NOT NULL
    BEGIN
		DELETE FROM [JFW].[UserRole] WHERE Role_ID IN (SELECT tvalue
		FROM [JFW].[fn_Split](@Role_ID_List, ','))
	END
    ELSE
    BEGIN
		RAISERROR('No parameter is specified.', 16, 1)
	END
END

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, March 30, 2021
-- Description:  this method gets data of the [JFW].[UserRole] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_UserRole_Get]
	@ID bigint = null
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED


SELECT *
FROM
	[JFW].[UserRole]
WHERE ID = @ID




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, March 30, 2021
-- Description:  this method inserts data into the [JFW].[UserRole] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_UserRole_Insert]
	@Role_ID bigint,
	@User_ID bigint,
	@Created_By bigint = null
AS

INSERT INTO [JFW].[UserRole]
	(
	[Role_ID],
	[User_ID],
	[Modified_By],
	[Modified_Date],
	[Created_By],
	[Created_Date]
	)
VALUES
	(
		@Role_ID,
		@User_ID,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- EXEC [JFW].[usp_UserSetting_List] '1'
-- =============================================
-- Created by:        dba03@jexpa.com
-- Create date: 2021-07-22
-- Description:    this stored procedure retrieves the list of userprofiles according to the search criteria.
-- =============================================
CREATE PROCEDURE [JFW].[usp_UserRole_List]
	@Role_ID bigint = null,
	@User_ID bigint = null,
	@Keyword nvarchar(1000) = NULL,
	@Keyword_Encryption nvarchar(2000) = NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN
	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	IF(@User_ID IS NOT NULL AND @User_ID <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([User_ID] = ''', @User_ID, ''') ')
	END

	IF(@Role_ID IS NOT NULL AND @Role_ID <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Role_ID] = ''', @Role_ID, ''') ')
	END


	SELECT @sqlString = 'SELECT * '+
                'FROM [JFW].[UserRole] '+
                ' WHERE ' +@whereClause + 
                ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order +
                @PAGINATION


	-- Execute the SQL statement
	--PRINT @sqlString
	EXEC sp_executesql @sqlString

END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, March 30, 2021
-- Description:  this method updates data for the [JFW].[UserPermission] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_UserRole_Update]
	@ID bigint,
	@Role_ID bigint,
	@User_ID bigint,
	@Modified_By bigint = null
AS

UPDATE [JFW].UserRole SET
    [User_ID] = @User_ID,
    [Role_ID] = @Role_ID,
	Modified_By = @Modified_By,
	Modified_Date = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, March 30, 2021
-- Description:  this method deletes multiple rows in the [JFW].[UserSetting] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_UserSetting_Delete]
	@ID bigint
AS

DELETE FROM
    [JFW].[UserSetting]
WHERE [ID] = @ID


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'





GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method gets data of the [JFW].[UserSetting] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_UserSetting_Get]
	@ID bigint

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED



SELECT *
FROM
	[JFW].[UserSetting]
WHERE ID = @ID
    




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, July 13, 2021
-- Description:  this method inserts data into the [JFW].[UserSetting] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_UserSetting_Insert]
	@User_ID bigint,
	@Package_ID bigint,
	@Tracking_Level smallint = null,
	@Max_Allowed_Device_Number int = null,
	@Theme_Style varchar(50) = null,
	@Referral_Code varchar(10) = null,
	@Commission float = null,
	@Enable_Sign_In_Detection bit = null,
	@Expiry_Date datetime  = null,
	@Created_By bigint = null
AS

DECLARE @UNI UNIQUEIDENTIFIER
SET @UNI = NEWID()


INSERT INTO [JFW].[UserSetting]
	(
	[User_ID],
	[Package_ID],
	[Tracking_Level],
	[Max_Allowed_Device_Number],
	[Theme_Style],
	Referral_Code,
	Commission,
	[Enable_Sign_In_Detection],
	[Expiry_Date],
	[Modified_By],
	[Modified_Date],
	[Created_By],
	[Created_Date]
	)
VALUES
	(
		@User_ID,
		@Package_ID,
		@Tracking_Level,
		@Max_Allowed_Device_Number,
		@Theme_Style,
		LEFT(@UNI,8),
		@Commission,
		@Enable_Sign_In_Detection,
		@Expiry_Date,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- EXEC [JFW].[usp_UserSetting_List] '1'
-- =============================================
-- Created by:        dba03@jexpa.com
-- Create date: 2021-07-22
-- Description:    this stored procedure retrieves the list of userprofiles according to the search criteria.
-- =============================================
CREATE PROCEDURE [JFW].[usp_UserSetting_List]
	@User_ID bigint = null,
	@Package_ID bigint  = null,
	@Tracking_Level smallint = null,
	@Max_Allowed_Device_Number int = null,
	@Theme_Style varchar(50) = null,
	@Referral_Code varchar(10) = null,
	@Commission float = null,
	@Enable_Sign_In_Detection bit = null,
	@Expiry_Date datetime  = null,
	@Keyword nvarchar(1000) = NULL,
	@Keyword_Encryption nvarchar(2000) = NULL,
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC'
AS
BEGIN
	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	IF(@User_ID IS NOT NULL AND @User_ID <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([User_ID] = ''', @User_ID, ''') ')
	END

	IF(@Package_ID IS NOT NULL AND @Package_ID <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Package_ID] = ''', @Package_ID, ''') ')
	END

	IF(@Tracking_Level IS NOT NULL AND @Tracking_Level <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Tracking_Level] = ''', @Tracking_Level, ''') ')
	END

	IF(@Max_Allowed_Device_Number IS NOT NULL AND @Max_Allowed_Device_Number <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Max_Allowed_Device_Number] = ''', @Max_Allowed_Device_Number, ''') ')
	END

	IF(@Theme_Style IS NOT NULL AND @Theme_Style <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Theme_Style] = ''', @Theme_Style, ''') ')
	END

	IF(@Enable_Sign_In_Detection IS NOT NULL AND @Enable_Sign_In_Detection <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Enable_Sign_In_Detection] = ''', @Enable_Sign_In_Detection, ''') ')
	END

	IF(@Referral_Code IS NOT NULL AND @Referral_Code <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Referral_Code] = ''', @Referral_Code, ''') ')
	END

	IF(@Commission IS NOT NULL AND @Commission <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Commission] = ''', @Commission, ''') ')
	END

	IF(@Expiry_Date IS NOT NULL AND @Expiry_Date <> '')
    BEGIN
		SELECT @whereClause = CONCAT(@whereClause,' AND ([Expiry_Date] = ''', @Expiry_Date, ''') ')
	END

	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' + 
                'FROM [JFW].[UserSetting] '+
                ' WHERE ' +@whereClause + 
                ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order +
                @PAGINATION


	-- Execute the SQL statement
	--PRINT @sqlString
	EXEC sp_executesql @sqlString

END



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Tuesday, March 30, 2021
-- Description:  this method updates data for the [JFW].[UserSetting] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_UserSetting_Update]
	@ID bigint,
	@User_ID bigint,
	@Package_ID bigint,
	@Tracking_Level smallint,
	@Max_Allowed_Device_Number int,
	@Theme_Style varchar(50),
	@Referral_Code varchar(10),
	@Commission float,
	@Enable_Sign_In_Detection bit,
	@Expiry_Date datetime,
	@Modified_By bigint = null
AS

UPDATE [JFW].[UserSetting] SET
    [User_ID] = @User_ID,
    [Package_ID] = @Package_ID,
    [Tracking_Level] = @Tracking_Level,
    [Max_Allowed_Device_Number] = @Max_Allowed_Device_Number,
    [Theme_Style] = @Theme_Style,
    [Referral_Code] = @Referral_Code,
    [Commission] = @Commission,
    [Enable_Sign_In_Detection] = @Enable_Sign_In_Detection,
    [Expiry_Date] = @Expiry_Date,
    Modified_By = @Modified_By,
	Modified_Date = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) AS 'TotalRows'



GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Wednesday, November 30, 2022
-- Description:  this method deletes multiple rows in the [JFW].[Wallet] table by the ID list.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Wallet_Delete]
	@ID bigint
AS

DELETE FROM
    [JFW].[Wallet]
WHERE [ID] = @ID


SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Wednesday, November 30, 2022
-- Description:  this method gets data of the [JFW].[Wallet] table by the where clause string.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Wallet_Get]
	@ID bigint
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SELECT
	*
FROM
	[JFW].[Wallet]
WHERE ID = @ID




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Wednesday, November 30, 2022
-- Description:  this method inserts data into the [JFW].[Wallet] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Wallet_Insert]
	@User_ID bigint,
	@Currency varchar(3),
	@Balance float = 0,
	@Status smallint = 1,
	@Is_Default bit = 0,
	@Created_By bigint = null
AS

--- Each user can have only one default wallet
IF @Is_Default <> 0
BEGIN
	UPDATE [JFW].[Wallet] SET [Is_Default] = 0 WHERE [User_ID] = @User_ID
END

INSERT INTO [JFW].[Wallet]
	(
	[User_ID],
	[Currency],
	[Balance],
	[Status],
	[Is_Default],
	[Modified_By],
	[Modified_Date],
	[Created_By],
	[Created_Date]
	)
VALUES
	(
		@User_ID,
		@Currency,
		@Balance,
		@Status,
		@Is_Default,
		@Created_By,
		GETUTCDATE(),
		@Created_By,
		GETUTCDATE()
)

SELECT CAST(SCOPE_IDENTITY() AS bigint) as 'ID'




GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Created by:        dba03@jexpa.com
-- Create date: Wednesday, November 30, 2022
-- Description:    this stored procedure retrieves the list of activities according to the search criteri
-- =============================================
CREATE PROCEDURE [JFW].[usp_Wallet_List]
	@User_ID bigint = null,
	@Currency varchar(3) = null,
	@Balance float = null,
	@Status smallint = null,
	@Is_Default bit = 0,
	@Created_Date_From datetime = null,
	@Created_Date_To datetime = null,
	@Sort_Data_Field varchar(100) = 'ID',
	@Sort_Order varchar(5) = 'DESC',
	@Limit int = null,
	@Page_Number int = null,
	@Page_Size int = null

AS
BEGIN


	DECLARE @LimitClause nvarchar(max) = ''
	DECLARE @PAGINATION nvarchar(max) = ''
	DECLARE @whereClause nvarchar(max) = '1 = 1',
    @sqlString nvarchar(max),
    @skip bigint = @Page_Number * @Page_Size


	IF (@Page_Number is not null and @Page_Size is not null )
    SELECT @PAGINATION = ' OFFSET ' + CAST(@skip as varchar(50)) + ' ROWS' + ' FETCH NEXT ' + CAST(@Page_Size as varchar(50)) + ' ROWS ONLY'

	IF(@User_ID IS NOT NULL AND @User_ID <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [User_ID] = ', @User_ID, ' ')

	IF(@Currency IS NOT NULL AND @Currency <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Currency] = ''', @Currency, ''' ')

	IF(@Balance IS NOT NULL AND @Balance <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Balance] = ', @Balance, ' ')

	IF(@Status IS NOT NULL AND @Status <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Status] = ', @Status, ' ')

	IF(@Is_Default IS NOT NULL AND @Is_Default <> '')
    SELECT @whereClause = CONCAT(@whereClause,' AND [Is_Default] = ', @Is_Default,' ')

	IF(@Created_Date_From IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause, ' AND [Created_Date] >= ''', @Created_Date_From, ''' ')

	IF(@Created_Date_To IS NOT NULL)
	SELECT @whereClause = CONCAT(@whereClause, ' AND [Created_Date] <= ''', @Created_Date_To, ''' ')

	IF(@Limit IS NOT NULL AND @Limit <> '')
    SELECT @LimitClause = CONCAT(@LimitClause,'TOP (', @Limit,') ')

	SELECT @sqlString = 'SELECT '+ @LimitClause +' *' + 
    ' FROM [JFW].[Wallet]' +
    ' WHERE ' +@whereClause + 
    ' ORDER BY ' + CONCAT('[',@Sort_Data_Field,']') + ' ' + @Sort_Order
    + @PAGINATION
	-- Execute the SQL statement
	--PRINT CONCAT('SQL string: ',@sqlString)
	EXEC sp_executesql @sqlString


END


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------------
-- Created by:   dba03@jexpa.com
-- Created date: Wednesday, November 30, 2022
-- Description:  this method updates data for the [JFW].[Wallet] table.
------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [JFW].[usp_Wallet_Update]
	@ID bigint,
	@User_ID bigint,
	@Currency varchar(3),
	@Balance float,
	@Status smallint,
	@Is_Default bit,
	@Modified_By bigint
AS

-- Each user can only have one default wallet
IF @Is_Default <> 0
BEGIN
	UPDATE [JFW].[Wallet] SET [Is_Default] = 0 WHERE [User_ID] = @User_ID AND [ID] <> @ID
END

UPDATE [JFW].[Wallet] SET
    [User_ID] = @User_ID,
    [Currency] = @Currency,
    [Balance] = @Balance,
    [Status]= @Status,
    [Is_Default] = @Is_Default,
	[Modified_By] = @Modified_By,
    [Modified_Date] = GETUTCDATE()
WHERE [ID] = @ID

SELECT CAST(@@ROWCOUNT AS bigint) as 'TotalRows'



GO
