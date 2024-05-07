const { saveTextToFile, replaceTemplate } = require("./utils");
const { create } = require("xmlbuilder2");

const tables = require("./data/tables.json");
const { outputPaths, suffixFileName } = require("./templates/variables");
const Template = require("./templates/sp-constants");
const outputPathCs = `${outputPaths.jfwModels.entities}/../StoredProcedureConstants${suffixFileName}.cs`;
const outputPathXml = `${outputPaths.jfwModels.entities}/../StoredProcedures.xml`;

const SUMMARY =
  "This maps to the stored procedure with the same name of the value.";

const root = create({ version: "1.0", encoding: "UTF-8" }).ele("root");

const getStoredProceduresConstantsContent = (tableName, tableData) => {
  let { procedures } = tableData;
  if (
    (procedures && procedures.length === 0) ||
    procedures === undefined ||
    procedures === null
  ) {
    console.log(`No stored procedures found for ${tableName}.`);
    return;
  }

  const procedureKeys = Object.keys(procedures);
  return procedureKeys.map((procedureKey) => {
    const procedure = procedures[procedureKey];
    const replacement = {
      key: procedure.key,
      name: procedure.nameWithSchema,
    };
    return replaceTemplate(
      Template.templateDefinition.ProcedureDefinitions,
      replacement
    );
  });
};

const generateStoredProcedureXmlNodes = (tableName, tableData) => {
  let { procedures } = tableData;

  if (procedures && procedures.length === 0) {
    console.log(`No stored procedures found for ${tableName}.`);
    return;
  }

  for (const [_, value] of Object.entries(procedures)) {
    const { key: procedureKey, parameters } = value;
    const procedure = root.ele("procedure", { key: procedureKey });
    const summary = procedure.ele("summary").txt(SUMMARY);
    const list = summary.ele("list", { type: "number" });
    for (const param of parameters) {
      const { name, dataTypeSqlWithLength } = param;
      const item = list.ele("item");
      const txtTerm = param.isRequired ? name + "*" : name;
      item.ele("term").txt(txtTerm);
      item.ele("description").txt(dataTypeSqlWithLength);
    }
  }
};

let constantsText = [];
let constantsFileContent = "";

for (const tableName in tables) {
  const constantText = getStoredProceduresConstantsContent(
    tableName,
    tables[tableName]
  );

  if (!constantText) {
    continue;
  }

  constantsText.push(
    ...getStoredProceduresConstantsContent(tableName, tables[tableName])
  );

  generateStoredProcedureXmlNodes(tableName, tables[tableName]);
}

const xml = root.end({ prettyPrint: true });

constantsFileContent = replaceTemplate(Template.template, {
  ProcedureDefinitions: constantsText.join("\n\n"),
});

saveTextToFile(outputPathXml, xml);
saveTextToFile(outputPathCs, constantsFileContent);
