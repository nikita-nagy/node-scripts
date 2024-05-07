const author = `jin.jackson`;
const authorFullName = `Jin Jackson`;
const authorDevCode = `dev22`;
const now = new Date();
const year = now.getUTCFullYear();
const month = now.getUTCMonth() + 1; // months are zero-indexed, so add 1
const day = now.getUTCDate();

const jfwCore = `Jfw.Core`;
const jfwDataAccess = `Jfw.DataAccess`;
const jfwModels = `Jfw.Models`;
const jfwRepositories = `Jfw.Repositories`;

const outputFolder = `./output`;
const frameworkFolder = `../jframework/Framework`;
const suffixFileName = `.Generated`;

const projectPaths = {
  jfwCore: `${outputFolder}/${jfwCore}`,
  jfwDataAccess: `${outputFolder}/${jfwDataAccess}`,
  jfwModels: `${outputFolder}/${jfwModels}`,
  jfwRepositories: `${outputFolder}/${jfwRepositories}`,
};

const outputPaths = {
  jfwModels: {
    entities: `${projectPaths.jfwModels}/Entities`,
    interfaces: `${projectPaths.jfwModels}/Entities/Interfaces`,
    implements: `${projectPaths.jfwModels}/Entities/Implements`,
    filters: `${projectPaths.jfwModels}/Filters`,
  },
  jfwDataAccess: {
    interfaces: `${projectPaths.jfwDataAccess}/Interfaces`,
    implements: `${projectPaths.jfwDataAccess}/Implements`,
  },
  jfwRepositories: {
    interfaces: `${projectPaths.jfwRepositories}/Interfaces`,
    implements: `${projectPaths.jfwRepositories}/Implements`,
  },
  jfwCore: {
    modelInterfaces: `${projectPaths.jfwCore}/Interfaces/Models`,
    entityClasses: `${projectPaths.jfwCore}/EntityClasses`,
    entityClassesInterfaces: `${projectPaths.jfwCore}/EntityClasses/Interfaces`,
    entityClassesModelInterfaces: `${projectPaths.jfwCore}/EntityClasses/Interfaces/Models`,
    entityClassesImplements: `${projectPaths.jfwCore}/EntityClasses/Implements`,
    memoryClasses: `${projectPaths.jfwCore}/MemoryClasses`,
    memoryClassesInterfaces: `${projectPaths.jfwCore}/MemoryClasses/Interfaces`,
    memoryClassesImplements: `${projectPaths.jfwCore}/MemoryClasses/Implements`,
  },
};

const currentDate = `${year}-${month.toString().padStart(2, "0")}-${day
  .toString()
  .padStart(2, "0")}`;

module.exports = {
  author,
  authorFullName,
  authorDevCode,
  currentDate,
  outputFolder,
  frameworkFolder,
  projectPaths,
  outputPaths,
  suffixFileName,
};
