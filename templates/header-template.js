const { authorFullName, currentDate, authorDevCode } = require("./variables");

const template = `/*
* Description: This file...
* Author: ${authorFullName}.
* History:
* - 2023-05-27: Created - ${authorDevCode}.
* - ${currentDate}: Added the file header - ${authorDevCode}.
*/

`;

const replacements = {
  CreatedDate: currentDate,
};

module.exports = { template, replacements };
