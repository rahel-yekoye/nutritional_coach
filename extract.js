const fs = require('fs');
const pdf = require('pdf-parse');

async function extractText() {
  const dataBuffer = fs.readFileSync(
    './Ethiopian-Food-Composition-Table-2025-1.pdf'
  );

  const data = await pdf(dataBuffer);

  console.log(data.text.substring(0, 5000));

  fs.writeFileSync('output.txt', data.text);

  console.log('PDF text saved to output.txt');
}

extractText();