const { authorFullName, authorDevCode, currentDate } = require("./variables");
const { tableSchema } = require("../config");

const defaultUsings = [
  "System",
  "System.Collections.Generic",
  "System.Data",
  "Jfw.Models.Entities.Interfaces",
];

const definitionParameter = `\t\t\t\tnew KeyValuePair<string, object>(Column.{{columnNamePascal}}, {{columnNamePascal}}{{defaultValue}})`;
const definitionEncryptedParameter = `\t\t\t\tnew KeyValuePair<string, object>(Column.{{columnNamePascal}}, Encrypted{{columnNamePascal}}{{defaultValue}})`;

const definitionColumnParse = `\t\t\t\t{{columnNamePascal}} = dataRow.Field<{{columnType}}>(tablePrefix + Column.{{columnNamePascal}});`;
const definitionEncryptedColumnParse = `\t\t\t\tEncrypted{{columnNamePascal}} = dataRow.Field<{{columnType}}>(tablePrefix + Column.{{columnNamePascal}});`;

const definitionColumnConstant = `\t\t\t/// <summary>
\t\t\t/// Maps to the name of column [{{columnName}}] in the table.
\t\t\t/// </summary>
\t\t\tpublic const string {{columnNamePascal}} = "{{columnName}}";`;

const definitions = {
  Parameter: definitionParameter,
  EncryptedParameter: definitionEncryptedParameter,
  ColumnParse: definitionColumnParse,
  EncryptedColumnParse: definitionEncryptedColumnParse,
  ColumnConstant: definitionColumnConstant,
};

const templateReplacements = {
  EntityName: "TableName",
  Usings: "",
  InsertParameters: "// InsertParameters",
  UpdateParameters: "// UpdateParameters",
  ColumnParseDefinitions: "// ColumnParseDefinitions",
  ColumnConstantDefinitions: "// ColumnDefinitions",
};

const template = `/*
* Description: This file defines the {{EntityName}}Entity class.
* Author: ${authorFullName}.
* History:
* - ${currentDate}: Created - ${authorDevCode}.
*/

{{Usings}}namespace Jfw.Models.Entities.Implements
{
    /// <summary>
    /// This class is used to define the structure of [${tableSchema}].[{{EntityName}}] table.
    /// </summary>
    public partial class {{EntityName}}Entity
    {
        /// <summary>
        /// The table name of the Entity.
        /// </summary>
        public const string TableName = "{{EntityName}}";

        public I{{EntityName}}Entity Clone()
        {
            return (I{{EntityName}}Entity)MemberwiseClone();
        }

        public void SetPropertiesFrom(I{{EntityName}}Entity entity, bool ignoreNull = true)
        {
            SetPropertiesFrom((object)entity, ignoreNull);
        }

        public KeyValuePair<string, object>[] GetInsertParameters()
        {
            var parameters = new KeyValuePair<string, object>[]
            {
{{InsertParameters}}
            };

            return parameters;
        }

        public KeyValuePair<string, object>[] GetUpdateParameters()
        {
            var parameters = new KeyValuePair<string, object>[]
            {
{{UpdateParameters}}
            };

            return parameters;
        }

        public I{{EntityName}}Entity ParseDataRow(DataRow dataRow, bool hasPrefix = false)
        {
            string tablePrefix = hasPrefix ? TableName + "_" : "";

            try
            {
{{ColumnParseDefinitions}}
            }
            catch (Exception ex)
            {
                _logger.Error(ex, ModelConstants.Messages.ParseDataRow, TableName);
                return null;
            }

            return this;
        }

        /// <inheritdoc cref="ParseDataRow(DataRow, bool)"/>
        public static I{{EntityName}}Entity Parse(DataRow dataRow, bool hasPrefix = false)
        {
            return new {{EntityName}}Entity().ParseDataRow(dataRow, hasPrefix);
        }

        public new class Column : BaseEntity.Column
        {
{{ColumnDefinitions}}
        }
    }
}
`;

module.exports = {
  defaultUsings,
  template,
  templateReplacements,
  definitions,
};
