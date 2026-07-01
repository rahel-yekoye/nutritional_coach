const fs = require('fs');

const text = fs.readFileSync('output.txt', 'utf8');

const matches = text.match(/\b\d{6}\b/g);

console.log("Food codes found:", matches.length);

console.log(matches.slice(0, 50));