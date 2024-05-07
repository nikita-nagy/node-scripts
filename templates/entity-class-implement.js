const {
  author,
  authorFullName,
  authorDevCode,
  currentDate,
} = require("./variables.js");

const definitionPropertyChild = `\t\t\t\tAttached{{childTable}}Entity.{{entityName}}{{columnNamePascal}} = value;`;

const definitionProperty = `\t\t/// <inheritdoc />
\t\tpublic {{columnType}} {{columnNamePascal}}`;

const definitionPropertyFullAccessor = `
\t\t{
\t\t\tget => Attached{{childTable}}Entity.{{columnNamePascal}};
\t\t\tset => Attached{{childTable}}Entity.{{columnNamePascal}} = value;
\t\t}`;

const definitionPropertyProtected = `
\t\t{
\t\t\tget => Attached{{childTable}}Entity.{{columnNamePascal}};
\t\t\tprotected set => Attached{{childTable}}Entity.{{columnNamePascal}} = value;
\t\t}`;

const definitionPropertyReadOnly = ` => AttachedEntity.{{columnNamePascal}};`;

const definitionEncryptedProperty = `\t\t/// <inheritdoc />
\t\tpublic {{columnType}} {{columnNamePascal}}
\t\t{
\t\t\tget => Attached{{childTable}}Entity.{{columnNamePascal}};
\t\t\tset => Attached{{childTable}}Entity.{{columnNamePascal}} = value;
\t\t}

\t\t/// <inheritdoc />
\t\t[System.Text.Json.Serialization.JsonIgnore]
\t\t[Newtonsoft.Json.JsonIgnore]
\t\tpublic string Encrypted{{columnNamePascal}} => Attached{{childTable}}Entity.Encrypted{{columnNamePascal}};`;

const definitionMethod = `\t\t/// <summary>
\t\t/// Gets the value of <see cref="{{columnNamePascal}}"/>.
\t\t/// </summary>
\t\t/// <remarks>
\t\t/// <description>Recommend to use property <see cref="{{columnNamePascal}}"/>.</description>
\t\t/// </remarks>
\t\t[Obsolete("Use property {{columnNamePascal}} instead.")]
\t\tpublic {{columnType}} Get{{columnNamePascal}}()
\t\t{
\t\t\treturn {{columnNamePascal}};
\t\t}`;

const definitionMethodEncrypted = `\t\t/// <summary>
\t\t/// Gets the value of <see cref="{{columnNamePascal}}"/>.
\t\t/// </summary>
\t\t/// <remarks>
\t\t/// <description>Recommend to use property <see cref="{{columnNamePascal}}"/>.</description>
\t\t/// </remarks>
\t\t[Obsolete("Use property {{columnNamePascal}} instead.")]
\t\tpublic {{columnType}} Get{{columnNamePascal}}()
\t\t{
\t\t\treturn {{columnNamePascal}};
\t\t}

\t\t/// <summary>
\t\t/// Gets the value of <see cref="Encrypted{{columnNamePascal}}"/>.
\t\t/// </summary>
\t\t/// <remarks>
\t\t/// <description>Recommend to use property <see cref="Encrypted{{columnNamePascal}}"/>.</description>
\t\t/// </remarks>
\t\t[Obsolete("Use property Encrypted{{columnNamePascal}} instead.")]
\t\tpublic string GetEncrypted{{columnNamePascal}}()
\t\t{
\t\t\treturn Encrypted{{columnNamePascal}};
\t\t}`;

const definitionMethodSet = `\t\t/// <summary>
\t\t/// Sets the value of <see cref="{{columnNamePascal}}"/>.<br/>
\t\t/// </summary>
\t\t/// <remarks>
\t\t/// <description>Recommend to use property <see cref="{{columnNamePascal}}"/>.</description>
\t\t/// </remarks>
\t\t[Obsolete("Use property {{columnNamePascal}} instead.")]
\t\tpublic void Set{{columnNamePascal}}({{columnType}} value)
\t\t{
\t\t\t{{columnNamePascal}} = value;
\t\t}`;

const definitionPartialClass = `\t/// <summary>
\t/// This class holds all data related to {{EntityName}} and provides methods to work with {{EntityName}}.
\t/// </summary>
\tpublic partial class C{{EntityName}} : BaseEntityClass<C{{EntityName}}, I{{EntityName}}Repository, I{{EntityName}}Entity>, I{{EntityName}}
\t{
\t\tprivate I{{EntityName}}Entity _attachedEntity = new {{EntityName}}Entity();

\t\tinternal override I{{EntityName}}Entity AttachedEntity
\t\t{
\t\t\tget => _attachedEntity;
\t\t\tset => _attachedEntity = value?.Clone() ?? new {{EntityName}}Entity();
\t\t}`;

const definitionPartialClassChild = `\tpublic partial class C{{ParentEntityName}}
\t{
\t\tprivate I{{EntityName}}Entity _attached{{EntityName}}Entity = new {{EntityName}}Entity();

\t\tinternal I{{EntityName}}Entity Attached{{EntityName}}Entity
\t\t{
\t\t\tget => _attached{{EntityName}}Entity;
\t\t\tset => _attached{{EntityName}}Entity = value?.Clone() ?? new {{EntityName}}Entity();
\t\t}`;

const definitionPropertyExtendedId = `\t\t/// <inheritdoc cref="IBaseEntityClass.Id" />
\t\tpublic override long Id
\t\t{
\t\t\tget => AttachedEntity.Id;
\t\t\tprotected set
\t\t\t{
\t\t\t\tAttachedEntity.Id = value;
{{ExtraSetters}}
\t\t\t}
\t\t}`;

const definitionPropertyExtendedFullAccessor = `
\t\t{
\t\t\tget => AttachedEntity.{{columnNamePascal}};
\t\t\tset
\t\t\t{
\t\t\t\tAttachedEntity.{{columnNamePascal}} = value;
{{ExtraSetters}}
\t\t\t}
\t\t}`;


const definitions = {
  PartialClass: definitionPartialClass,
  PartialClassChild: definitionPartialClassChild,
  PropertyExtendedId: definitionPropertyExtendedId,
  PropertyExtend: definitionPropertyChild,
  PropertyEncrypted: definitionEncryptedProperty,
  PropertyFullAccessor: definitionProperty + definitionPropertyFullAccessor,
  PropertyExtendedFullAccessor: definitionProperty + definitionPropertyExtendedFullAccessor,
  PropertyProtected: definitionProperty + definitionPropertyProtected,
  PropertyReadOnly: definitionProperty + definitionPropertyReadOnly,
  MethodGet: definitionMethod,
  MethodGetEncrypted: definitionMethodEncrypted,
  MethodSet: definitionMethodSet,
};

const defaultUsings = [
  "System",
  "Jfw.Core.EntityClasses.Interfaces",
  "Jfw.Models.Entities.Implements",
  "Jfw.Models.Entities.Interfaces",
  "Jfw.Repositories.Interfaces",
];

const templateReplacements = {
  EntityName: "EntityName",
  PartialClass: "PartialClass",
  Usings: "",
  PropertyDefinitions: "// PropertyDefinitions",
  MethodDefinitions: "// MethodDefinitions",
};

const template = `/*
* Description: This file contains all data related to {{EntityName}} and provides methods to work with {{EntityName}} properties.
* Author: ${authorFullName}.
* History:
* - ${currentDate}: Created - ${authorDevCode}.
*/

{{Usings}}namespace Jfw.Core.EntityClasses
{
{{PartialClass}}

        #region Attached Properties
{{PropertyDefinitions}}
        #endregion

        #region Attached Property Accessor Methods
{{MethodDefinitions}}
        #endregion
    }
}
`;

module.exports = {
  template,
  templateId: definitionPropertyExtendedId,
  templateReplacements,
  definitions,
  defaultUsings,
};
