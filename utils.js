const fs = require("fs");
const axios = require("axios");
const config = require("./config");

/*
Description: Common functions for the code generator
Replace all the dynamic data in the template with the actual data
@param {string} template - The template string
@param {object} dynamicData - The dynamic data
@returns {string} The template with the dynamic data replaced
*/
const replaceTemplate = (template, replacement, replaceTab = true) => {
  // Checks if the template is a string
  if (typeof template !== "string") {
    throw new Error("The template must be a string");
  }

  let result = template;

  Object.keys(replacement).forEach((key) => {
    result = result.replaceAll(`{{${key}}}`, replacement[key]);
  });

  if (replaceTab) result = result.replaceAll("\t", "    ");

  return result;
};

/**
 * @module HelperModule
 * @description Save text to a file
 * @param {string} fileName - The file name
 * @param {string} text - The text to save
 * @returns {void}
 */
const saveTextToFile = (fileName, text, options) => {
  // Create the file if it does not exist
  if (!fs.existsSync(fileName)) {
    // Create the containing folder if it does not exist
    fs.mkdirSync(fileName.substring(0, fileName.lastIndexOf("/")), {
      recursive: true,
    });
  }

  // Write the text to the file
  fs.writeFile(fileName, text, options, (error) => {
    if (error) {
      console.error(error);
    } else {
      console.log(`The file ${fileName} has been saved.`);
    }
  });
};

function jsonStringifyOrder(obj, space) {
  const allKeys = new Set();
  JSON.stringify(obj, (key, value) => (allKeys.add(key), value));
  return JSON.stringify(obj, Array.from(allKeys).sort(), space);
}

const getUsingTemplate = (usings) => {
  if (usings.length === 0) {
    return "";
  }

  if (usings.length === 1) {
    return `using ${usings[0]};\n\n`;
  }

  let result = "";
  for (let i = 0; i < usings.length; i++) {
    result += `using ${usings[i]};\n`;

    if (i >= usings.length - 1) {
      result += "\n";
    }
  }

  return result;
};

const getInheritanceTemplate = (interfaces) => {
  if (interfaces.length === 0) {
    return "";
  }

  let result = " : ";
  for (let i = 0; i < interfaces.length; i++) {
    result += `${interfaces[i]}`;
    if (i < interfaces.length - 1) {
      result += ", ";
    }
  }

  return result;
};

const walkthroughTableData = (tableData, callback) => {
  for (const tableName in tableData) {
    // Skips the table if it is not included in the list.
    if (
      config.includedEntityList.length > 0 &&
      !config.includedEntityList.includes(tableName)
    )
      continue;

    // Skips the table if it is excluded in the list.
    if (
      config.excludedEntityList.length > 0 &&
      config.excludedEntityList.includes(tableName)
    )
      continue;

    // Calls the callback function
    callback(tableName);
  }
};

// Check if a URL exists
async function urlExists(url) {
  try {
    await axios.get(url);
    return true;
  } catch (error) {
    return false;
  }
}

module.exports = {
  fs,
  replaceTemplate,
  saveTextToFile,
  jsonStringifyOrder,
  getUsingTemplate,
  getInheritanceTemplate,
  walkthroughTableData,
  urlExists,
};
