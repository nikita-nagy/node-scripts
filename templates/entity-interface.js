const { authorFullName, currentDate, authorDevCode } = require("./variables");

const defaultInterfaces = [];
const defaultUsings = [];

const definitionColumn = `\t\t/// <summary>
\t\t/// Gets or sets the [{{entityName}}].[{{columnName}}] column value.
\t\t/// </summary>
\t\t{{columnType}} {{columnNamePascal}} { get; set; }`;

const definitionEncryptedColumn = `\t\t/// <summary>
\t\t/// Gets or sets the [{{entityName}}].[{{columnName}}] column decrypted value.
\t\t/// </summary>
\t\t/// <remarks>
\t\t/// This property is used to get or set the encrypted property [{{entityName}}].[{{columnName}}] value.
\t\t/// </remarks>
\t\t{{columnType}} {{columnNamePascal}} { get; set; }

\t\t/// <summary>
\t\t/// Gets the [{{entityName}}].[{{columnName}}] column raw value.
\t\t/// </summary>
\t\t/// <remarks>
\t\t/// This property is used to interact with the database column value directly.
\t\t/// </remarks>
\t\t{{columnType}} Encrypted{{columnNamePascal}} { get; }`;

const definitions = {
  Column: definitionColumn,
  EncryptedColumn: definitionEncryptedColumn,
};

const templateReplacements = {
  EntityName: "EntityName",
  Usings: "",
  ColumnDefinitions: "// ColumnDefinitions",
  InheritedInterfaces: "// InheritedInterfaces",
};

const template = `/*
* Description: This file is used to define the {{EntityName}} in the system.
* Author: ${authorFullName}.
* History:
* - ${currentDate}: Created - ${authorDevCode}.
*/

{{Usings}}namespace Jfw.Models.Entities.Interfaces
{
    /// <summary>
    /// This interface is used to define the properties of [{{EntityName}}] entity.
    /// </summary>
    public interface I{{EntityName}}Entity{{InheritedInterfaces}}
    {
{{ColumnDefinitions}}
    }
}
`;

module.exports = {
  defaultUsings,
  defaultInterfaces,
  template,
  templateReplacements,
  definitions,
};
