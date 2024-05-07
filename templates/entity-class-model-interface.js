const { authorFullName, currentDate, authorDevCode } = require("./variables");

const definitionColumn = `\t\t/// <summary>
\t\t/// Gets or sets the [{{entityName}}].[{{columnName}}] column value.
\t\t/// </summary>
\t\t{{columnType}} {{columnNamePascal}} { get; {{setter}}}`;

const definitionEncryptedColumn = `\t\t/// <summary>
\t\t/// Gets or sets the [{{entityName}}].[{{columnName}}] column's decrypted value.
\t\t/// </summary>
\t\tstring {{columnNamePascal}} { get; set; }

\t\t/// <summary>
\t\t/// Gets the [{{entityName}}].[{{columnName}}] column's raw value.
\t\t/// </summary>
\t\tstring Encrypted{{columnNamePascal}} { get; }`;

const defaultInheritedInterfaces = [];

const defaults = {
  InheritedInterfaces: defaultInheritedInterfaces,
};

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
* Description: This file is used to define the {{EntityName}} entity properties.
* This file is generated by the JFW Code Generator from a template file.
* Be careful when modifying this file as it can be overwritten.
* Author: ${authorFullName}.
* History:
* - ${currentDate}: Created - ${authorDevCode}.
*/

{{Usings}}namespace Jfw.Core.EntityClasses.Interfaces.Models
{
    /// <summary>
    /// This interface is used to define the {{EntityName}} entity properties.<br/>
    /// This can be used to communicate with properties in the {{EntityName}} entity class.
    /// </summary>
    public interface I{{EntityName}}Model{{InheritedInterfaces}}
    {
{{ColumnDefinitions}}
    }
}
`;

module.exports = { template, templateReplacements, definitions, defaults };
