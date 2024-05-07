const templateDefinition = {
  ProcedureDefinitions:
    `\t\t/// <include file='StoredProcedures.xml' path='root/procedure[@key="{{key}}"]/*' />
\t\tpublic const string {{key}} = "{{name}}";`.replace(/\t/g, "    "),
};

const template = `namespace Jfw.Models
{
    /// <summary>
    /// This maps to the stored procedures in the database.
    /// </summary>
    public static partial class StoredProcedureConstants
    {
{{ProcedureDefinitions}}
    }
}
`;

module.exports = { template, templateDefinition };
