SELECT
    p.name AS 'ProcedureName',
    pa.name AS 'ParameterName',
    ty.name AS 'DataType',
    pa.max_length AS 'MaxLength',
    d.DefaultValue AS 'DefaultValue'
FROM
    sys.procedures p
    INNER JOIN
    sys.parameters pa ON p.object_id = pa.object_id
    INNER JOIN
    sys.types ty ON pa.user_type_id = ty.user_type_id
    OUTER APPLY (
        SELECT [JFW].[fn_GetParameterDefaultValue](SCHEMA_NAME(p.schema_id) + '.' + p.name, pa.name, ty.name, 0) AS 'DefaultValue'
    ) AS d
ORDER BY
    p.name,
    pa.parameter_id