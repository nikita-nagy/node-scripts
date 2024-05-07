const templateDefinition = {
  entityName: "EntityName",
};

const template =
  `#pragma warning disable CS1591 // Missing XML comment for publicly visible type or member

// We put the constants and enums in this file so that we can use them in the other parts of the {{entityName}} class.
namespace Jfw.Core.EntityClasses
{
\tpublic partial class C{{entityName}} { }
}
#pragma warning restore CS1591 // Missing XML comment for publicly visible type or member
`.replace(/\t/g, "    ");

module.exports = { template, templateDefinition };
