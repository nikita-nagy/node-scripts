DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql += N'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(t.schema_id)) + '.' + QUOTENAME(t.name) 
  + ' DROP CONSTRAINT ' + QUOTENAME(f.name) + ';
'
FROM sys.foreign_keys AS f
INNER JOIN sys.tables t
ON f.parent_object_id = t.object_id;

EXEC sp_executesql @sql;

SELECT @sql += N'DROP TABLE ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N';'
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id;

SELECT @sql += N'DROP PROCEDURE ' + QUOTENAME(s.name) + N'.' + QUOTENAME(p.name) + N';'
FROM sys.procedures p
INNER JOIN sys.schemas s ON p.schema_id = s.schema_id;

SELECT @sql += N'DROP FUNCTION ' + QUOTENAME(s.name) + N'.' + QUOTENAME(f.name) + N';'
FROM sys.objects f
INNER JOIN sys.schemas s ON f.schema_id = s.schema_id
WHERE f.type_desc = N'SQL_SCALAR_FUNCTION' OR f.type_desc = N'SQL_TABLE_VALUED_FUNCTION';

EXEC sp_executesql @sql;

-- Delete schema
-- DROP SCHEMA [JFW]