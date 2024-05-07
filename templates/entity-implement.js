const { authorFullName, authorDevCode, currentDate } = require("./variables");

const defaultUsings = ["Jfw.Models.Entities.Interfaces"];

const definitionEncryptField = `\t\tprivate {{columnType}} _{{columnNameCamel}} = string.Empty;
\t\tprivate string _encrypted{{columnNamePascal}} = string.Empty;`;
const definitionColumn = `\t\tpublic {{columnType}} {{columnNamePascal}} { get; set; }`;
const definitionEncryptedColumn = `\t\tpublic string {{columnNamePascal}}
        {
            get => _{{columnNameCamel}};
            set
            {
                // {{columnNamePascal}} should be case-insensitive, thus we use lowercase string.
                _{{columnNameCamel}} = !string.IsNullOrWhiteSpace(value) ? value{{toLower}}.Trim() : string.Empty;

                try
                {
                    // Try to encrypt the value to _encrypted{{columnNamePascal}}.
                    _encrypted{{columnNamePascal}} = CryptographyHelper.Encrypt(_{{columnNameCamel}});
                }
                catch (ArgumentNullException)
                {
                    // If the value is null or empty, we set the encrypted {{columnNamePascal}} to empty string.
                    _encrypted{{columnNamePascal}} = string.Empty;
                }
            }
        }

        public string Encrypted{{columnNamePascal}}
        {
            get => _encrypted{{columnNamePascal}};
            protected set
            {
                // Sets the encrypted value to string.Empty if the value is null or white space.
                if (string.IsNullOrWhiteSpace(value))
                {
                    _encrypted{{columnNamePascal}} = string.Empty;
                    _{{columnNameCamel}} = string.Empty;
                    return;
                }

                try
                {
                    // Try to decrypt the value to _{{columnNameCamel}}.
                    _{{columnNameCamel}} = CryptographyHelper.Decrypt(value);
                    _encrypted{{columnNamePascal}} = value;
                }
                catch (Exception ex)
                {
                    _logger.Error(ex, CryptographyHelper.ErrorMessageDecryptFailed, nameof(Encrypted{{columnNamePascal}}), value);
                    _{{columnNameCamel}} = string.Empty;
                    _encrypted{{columnNamePascal}} = string.Empty;
                }
            }
        }`;

const definitions = {
  Column: definitionColumn,
  EncryptedColumn: definitionEncryptedColumn,
  EncryptedField: definitionEncryptField,
};

const templateReplacements = {
  EntityName: "TableName",
  Usings: "",
  EncryptedFields: "",
  ColumnDefinitions: "// ColumnDefinitions",
};

const template = `/*
* Description: This file defines the {{EntityName}}Entity class.
* Author: ${authorFullName}.
* History:
* - ${currentDate}: Created - ${authorDevCode}.
*/

{{Usings}}namespace Jfw.Models.Entities.Implements
{
    public partial class {{EntityName}}Entity : BaseEntity, I{{EntityName}}Entity
    {{{EncryptedFields}}
{{ColumnDefinitions}}

        /// <summary>
        /// Default constructor.
        /// </summary>
        public {{EntityName}}Entity() : base() { }
    }
}
`;

module.exports = {
  defaultUsings,
  definitions,
  templateReplacements,
  template,
};
