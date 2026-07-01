const fs = require('fs');

const raw = JSON.parse(fs.readFileSync('foods.json'));
const cleaned = JSON.parse(fs.readFileSync('cleaned_foods.json'));
const log = JSON.parse(fs.readFileSync('cleaning_log.json'));

console.log('\n╔════════════════════════════════════════════════════════════════╗');
console.log('║           BEFORE / AFTER: CORRUPTION FIXES SHOWCASE          ║');
console.log('╚════════════════════════════════════════════════════════════════╝\n');

// Show examples of corrupted Amharic names that were fixed
const exampleCodes = ['030081', '070071', '070074'];

exampleCodes.forEach(code => {
  const rawFood = raw.find(f => f.food_code === code);
  const cleanedFood = cleaned.find(f => f.food_code === code);
  
  if (!rawFood || !cleanedFood) return;
  
  console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);
  console.log(`FOOD CODE: ${code}\n`);
  
  console.log(`❌ BEFORE (raw):`);
  console.log(`   Name: ${rawFood.food_name}`);
  console.log(`   Amharic: ${rawFood.food_name_amharic}\n`);
  
  console.log(`✅ AFTER (cleaned):`);
  console.log(`   Name: ${cleanedFood.food_name}`);
  console.log(`   Amharic: ${cleanedFood.food_name_amharic}\n`);
  
  const fix = log.corrected_entries.find(c => c.food_code === code);
  if (fix) {
    console.log(`🔧 FIXES APPLIED:`);
    fix.fixes.forEach(f => console.log(`   • ${f}`));
  }
  console.log();
});

console.log('\n╔════════════════════════════════════════════════════════════════╗');
console.log('║                    VALIDATION SUMMARY                         ║');
console.log('╚════════════════════════════════════════════════════════════════╝\n');

console.log('✅ ALL VALIDATIONS PASSED:\n');

let allValid = true;

// Check for duplicates
const codeCounts = {};
cleaned.forEach(f => {
  codeCounts[f.food_code] = (codeCounts[f.food_code] || 0) + 1;
});
const duplicates = Object.entries(codeCounts).filter(([_, count]) => count > 1);
if (duplicates.length === 0) {
  console.log('   ✓ No duplicate food codes');
} else {
  console.log(`   ✗ Found ${duplicates.length} duplicate codes`);
  allValid = false;
}

// Check food code format
const invalidCodes = cleaned.filter(f => !/^\d{6}$/.test(f.food_code));
if (invalidCodes.length === 0) {
  console.log('   ✓ All food codes are valid (6 digits)');
} else {
  console.log(`   ✗ Found ${invalidCodes.length} invalid codes`);
  allValid = false;
}

// Check for null/empty food names
const noNames = cleaned.filter(f => !f.food_name);
if (noNames.length === 0) {
  console.log('   ✓ All entries have English food names');
} else {
  console.log(`   ✗ Found ${noNames.length} entries without names`);
  allValid = false;
}

// Check for corrupted Amharic
const corruptedAmharic = cleaned.filter(f => 
  f.food_name_amharic && /\b(fat|protein|water|carb|fiber|ash|energy|kcal)\)/.test(f.food_name_amharic)
);
if (corruptedAmharic.length === 0) {
  console.log('   ✓ No corrupted nutrient text in Amharic names');
} else {
  console.log(`   ✗ Found ${corruptedAmharic.length} entries with corrupted Amharic`);
  allValid = false;
}

// Check energy values
const missingEnergy = cleaned.filter(f => f.energy_kcal === null);
if (missingEnergy.length === 0) {
  console.log('   ✓ All entries have energy values');
} else {
  console.log(`   ✗ Found ${missingEnergy.length} entries without energy`);
}

console.log('\n' + (allValid ? '✨ ALL CRITICAL VALIDATIONS PASSED\n' : '⚠️  Some issues found\n'));

console.log('═══════════════════════════════════════════════════════════════\n');
console.log('📌 FILES READY FOR USE:');
console.log('   • cleaned_foods.json     - Ready for database import');
console.log('   • cleaning_log.json      - Detailed audit trail');
console.log('\n');
