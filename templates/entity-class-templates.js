const { authorFullName, authorDevCode, currentDate } = require("./variables");

const templateDefinition = {
  entityName: "EntityName",
};

const templateConstructor = `/*
* Description: This file is used to define the constructors & methods for the {{entityName}} entity.
* This file is generated by the JFW Code Generator from a template file.
* Feel free to modify this file as needed.
* Author: ${authorFullName}.
* History:
* - ${currentDate}: Created - ${authorDevCode}.
*/

namespace Jfw.Core.EntityClasses
{
\tpublic partial class C{{entityName}}
\t{
\t\t#region Constructors
\t\t/// <inheritdoc />
\t\tpublic C{{entityName}}() : base() { }

\t\t/// <inheritdoc />
\t\tpublic C{{entityName}}(bool withDefaults) : base(withDefaults) { }
\t\t#endregion
\t}
}
`;

const templateConstants = `/*
* Description: This file is used to define the constants and enums for the {{entityName}} entity class.
* This file is generated by the JFW Code Generator from a template file.
* Feel free to modify this file as needed.
* Author: ${authorFullName}.
* History:
* - ${currentDate}: Created - ${authorDevCode}.
*/

#pragma warning disable CS1591 // Missing XML comment for publicly visible type or member

namespace Jfw.Core.EntityClasses
{
\tpublic partial class C{{entityName}}
\t{
\t\tpublic const string EntityName = "{{entityName}}";
\t\tpublic const int EntityCode = (int)Models.EntityCode.{{entityName}};

\t\t// Puts the default values related to {{entityName}} here.
\t\t#region Default Values
\t\t#endregion

\t\t// Puts the message strings related to {{entityName}} here.
\t\t#region Messages

\t\t// csharpier-ignore-start
\t\t/// <summary>
\t\t/// This class contains the messages for the {{entityName}} class.
\t\t/// </summary>
\t\tpublic static class Messages
\t\t{
\t\t\t/// <summary>
\t\t\t/// This is the details of the error message - Unhandled error code.
\t\t\t/// </summary>
\t\t\tpublic const string UnknownErrorCodeDetails = "The error code is not defined in the {{entityName}} class.";

\t\t\t/// <summary>
\t\t\t/// This is the details of the error message - <see cref="ErrorCode.NotFound"/>.
\t\t\t/// </summary>
\t\t\tpublic const string NotFoundDetails = "The {{entityName}} was not found in the system.";
\t\t}

\t\t// csharpier-ignore-end
\t\t#endregion

\t\t// Puts the regular expressions related to {{entityName}} here.
\t\t#region Regular Expressions
\t\t#endregion
\t}

\t// Puts the enums related to {{entityName}} here.
\t#region Enums
\t#endregion
}
#pragma warning restore CS1591 // Missing XML comment for publicly visible type or member
`;

const templateExceptions = `/*
* Description: This file is used to define the exception classes for the {{entityName}} entity.
* This file is generated by the JFW Code Generator from a template file.
* Feel free to modify this file as needed.
* Author: ${authorFullName}.
* History:
* - ${currentDate}: Created - ${authorDevCode}.
*/

namespace Jfw.Core.EntityClasses { }
`.replace(/\t/g, "    ");

const templateOverrides = `/*
* Description: This file is used to define the override methods (except IsValid and CheckValidations) from BaseEntityClass.
* This file is generated by the JFW Code Generator from a template file.
* Feel free to modify this file as needed.
* Author: ${authorFullName}.
* History:
* - ${currentDate}: Created - ${authorDevCode}.
*/

namespace Jfw.Core.EntityClasses
{
\tpublic partial class C{{entityName}}
\t{
\t\t/// <inheritdoc/>
\t\tprotected override void SetDefaultValues()
\t\t{
\t\t}
\t}
}
`.replace(/\t/g, "    ");

const templateErrors = `/*
* Description: This file is used to define the error handling methods and error mappings for the {{entityName}} entity.
* This file is generated by the JFW Code Generator from a template file.
* Feel free to modify this file as needed.
* Author: ${authorFullName}.
* History:
* - ${currentDate}: Created - ${authorDevCode}.
*/

using Jfw.Core.Enums;
using Jfw.Core.MemoryClasses;

namespace Jfw.Core.EntityClasses
{
\tpublic partial class C{{entityName}}
\t{
\t\t/// <summary>
\t\t/// Sets the message information for the given error code in the context of {{entityName}}.
\t\t/// </summary>
\t\t/// <param name="subcode">The error subcode.</param>
\t\t/// <param name="error">The error object.</param>
\t\t/// <returns>A CError object.</returns>
\t\tinternal static void SetMessageInformation(int subcode, ref CError error)
\t\t{
\t\t\tswitch (subcode)
\t\t\t{
\t\t\t\tcase (int)ErrorCode.NotFound:
\t\t\t\t\terror.Details = Messages.NotFoundDetails;
\t\t\t\t\terror.LogLevel = JfwLogLevel.Error;
\t\t\t\t\tbreak;

\t\t\t\tdefault:
\t\t\t\t\terror.Details = Messages.UnknownErrorCodeDetails;
\t\t\t\t\terror.LogLevel = JfwLogLevel.Critical;
\t\t\t\t\tbreak;
\t\t\t}
\t\t}

\t\t/// <summary>
\t\t/// This enum contains the error codes for the {{entityName}} entity.
\t\t/// </summary>
\t\tpublic enum ErrorCode
\t\t{
\t\t\t/// <summary>
\t\t\t/// [404] This code is used to indicate that the {{entityName}} is not found.
\t\t\t/// </summary>
\t\t\tNotFound = 404,
\t\t}
\t}
}
`.replace(/\t/g, "    ");

const templateValidations = `/*
* Description: This file is used to define the validation methods for the {{entityName}} entity.
* This file is generated by the JFW Code Generator from a template file.
* Feel free to modify this file as needed.
* Author: ${authorFullName}.
* History:
* - ${currentDate}: Created - ${authorDevCode}.
*/

namespace Jfw.Core.EntityClasses
{
    public partial class C{{entityName}}
    {
        #region Property Validation Methods
        // TODO: Add property validation methods here
        #endregion

        /// <inheritdoc />
        public override bool IsValid()
        {
            // TODO: Override this method if you want to add more validations.
            return base.IsValid();
        }

        /// <inheritdoc />
        public override bool CheckValidations()
        {
            // TODO: Override this method if you want to add more validations.
            return base.CheckValidations();
        }
    }
}
`;

const templates = [
  {
    template: templateConstructor,
    outputSuffix: "",
  },
  {
    template: templateConstants,
    outputSuffix: ".Constants",
  },
  {
    template: templateExceptions,
    outputSuffix: ".Exceptions",
  },
  {
    template: templateErrors,
    outputSuffix: ".Errors",
  },
  {
    template: templateOverrides,
    outputSuffix: ".Overrides",
  },
  {
    template: templateValidations,
    outputSuffix: ".Validations",
  },
];

module.exports = {
  templates,
  templateDefinition,
};
