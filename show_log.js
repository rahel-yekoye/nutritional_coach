const fs = require('fs');

const log = JSON.parse(fs.readFileSync('cleaning_log.json'));

console.log('REMOVED ENTRIES:\n');
log.removed_entries.forEach((e, i) => {
  console.log(`${i + 1}. Code ${e.food_code}: ${e.reason}`);
  console.log(`   Name: ${e.food_name}\n`);
});

console.log('\n\nCORRECTED ENTRIES (first 15):\n');
log.corrected_entries.slice(0, 15).forEach((e, i) => {
  console.log(`${i + 1}. Code ${e.food_code}:`);
  console.log(`   Name: ${e.food_name}`);
  e.fixes.forEach(f => console.log(`   - ${f}`));
  console.log();
});
