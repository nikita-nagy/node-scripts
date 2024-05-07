SELECT
    t.name AS 'TableName',
    c.name AS 'ColumnName',
    ic.COLUMN_DEFAULT AS 'DefaultValue',
    ty.name AS 'DataType',
    ic.CHARACTER_MAXIMUM_LENGTH AS 'MaxLength',
    c.is_nullable AS 'IsNullable'
FROM
    sys.tables t
    INNER JOIN
    sys.columns c ON t.object_id = c.object_id
    INNER JOIN
    sys.types ty ON c.user_type_id = ty.user_type_id
    INNER JOIN
    INFORMATION_SCHEMA.COLUMNS ic ON t.name = ic.TABLE_NAME AND c.name = ic.COLUMN_NAME
ORDER BY
    t.name,
    c.column_id