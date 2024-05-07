const fs = require('fs');
const path = require('path');
const { outputFolder } = require('./templates/variables');

// Function to merge file contents
function mergeFileContents(folderPath) {
    // Get the list of files in the output folder
    const files = fs.readdirSync(folderPath);

    // Array to store the merged contents
    const mergedContents = [];

    // Iterate over each file
    files.forEach((file) => {
        // Read the file contents
        const filePath = path.join(folderPath, file);
        const fileContents = fs.readFileSync(filePath, 'utf8');

        // Add the file contents to the merged array
        mergedContents.push(fileContents);
    });

    // Return the merged contents
    return mergedContents.join('\n');
}

// Call the mergeFileContents function
const mergedContents = mergeFileContents(`${outputFolder}/sp`);

// Write the merged contents to a new file
const outputPath = `${outputFolder}/sp/merged-stored-procedures.sql`;

fs.writeFileSync(outputPath, mergedContents);

console.log(`Merged stored procedures written to: ${outputPath}`);