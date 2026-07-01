const fs = require('fs');

// Load parsed foods
const rawFoods = JSON.parse(fs.readFileSync('foods.json', 'utf8'));

// Tracking
const log = {
  totalProcessed: rawFoods.length,
  removed: [],
  corrected: [],
  warnings: []
};

// List of common English food descriptor words to remove from Amharic
const englishFoodWords = new Set([
  'seed', 'dry', 'raw', 'whole', 'grain', 'flour', 'boiled', 'drained', 'fried',
  'cooked', 'roasted', 'oven', 'salt', 'without', 'recipe', 'part', 'as', 'of', 'a',
  'and', 'or', 'in', 'to', 'the', 'with', 'for', 'oil', 'fat', 'water', 'sauce',
  'soup', 'stew', 'juice', 'powder', 'paste', 'fresh', 'canned', 'frozen', 'baked',
  'steamed', 'grilled', 'toasted', 'ground', 'sliced', 'chopped', 'peeled', 'cored',
  'seeded', 'skin', 'bone', 'meat', 'lean', 'fat', 'trimmed', 'untrimmed', 'home',
  'made', 'traditional', 'recipe', 'ethnic', 'variety', 'type', 'kind', 'cultivar'
]);

// Amharic name patterns - typically start with specific letters
const amharicStartPatterns = /^[YyTtGgKkFfDdBbHhSsWwLlMmNnCcZzPpAaEe][\w']+/i;

function isCorrupted(text) {
  if (!text) return false;
  
  // Check for fragments like "fat)", "water)", typical column breaks
  if (/\b(fat|protein|water|carb|fiber|ash|energy|kcal|cal|mg|g)\)/.test(text)) return true;
  
  // Check for line numbers or stray digits that shouldn't be there
  if (/^\d+\s+/.test(text)) return true;
  
  // Check for mixed formatting issues: contains multiple closing parens
  if ((text.match(/\)/g) || []).length > 1) return true;
  
  return false;
}

function isValidFoodCode(code) {
  return /^\d{6}$/.test(code);
}

function extractAmharicName(fullName) {
  if (!fullName || isCorrupted(fullName)) return null;
  
  const words = fullName.split(/\s+/);
  let amharicStart = -1;
  
  // Find where Amharic name likely starts
  for (let i = 0; i < words.length; i++) {
    const word = words[i];
    
    // Look for Amharic word patterns (starts with capital + lowercase typical of transliteration)
    if (word.match(/^[YyTtGgKkFfDdBbHhSsWwZz][aeiouəɛɔ]/i) && word.length > 2) {
      amharicStart = i;
      break;
    }
  }
  
  if (amharicStart === -1) return null;
  
  // Extract Amharic part
  let amharicPart = words.slice(amharicStart).join(' ');
  
  // Clean up: remove trailing English words
  const amharicWords = amharicPart.split(/\s+/);
  let cleanEnd = amharicWords.length;
  
  for (let i = amharicWords.length - 1; i >= 0; i--) {
    const word = amharicWords[i].toLowerCase().replace(/[,;.()]/g, '');
    if (englishFoodWords.has(word) || word.length < 2) {
      cleanEnd = i;
    } else {
      break;
    }
  }
  
  amharicPart = amharicWords.slice(0, cleanEnd).join(' ').trim();
  
  // Remove corruption markers
  amharicPart = amharicPart
    .replace(/\([^)]*\)/g, '') // Remove anything in parentheses
    .replace(/\d+/g, '')        // Remove numbers
    .trim();
  
  return amharicPart && amharicPart.length > 2 ? amharicPart : null;
}

function extractEnglishName(fullName) {
  if (!fullName) return null;
  
  const words = fullName.split(/\s+/);
  let englishEnd = words.length;
  
  // Find where English name ends (before Amharic starts)
  for (let i = 0; i < words.length; i++) {
    const word = words[i];
    if (word.match(/^[YyTtGgKkFfDdBbHhSsWwZz][aeiouəɛɔ]/i) && word.length > 2) {
      englishEnd = i;
      break;
    }
  }
  
  let englishPart = words.slice(0, englishEnd).join(' ').trim();
  
  // Clean trailing commas/spaces
  englishPart = englishPart
    .replace(/,\s*$/, '')
    .replace(/\s+/g, ' ')
    .trim();
  
  return englishPart || null;
}

function validateFoodName(name) {
  if (!name) return false;
  
  // Should be readable English with common characters
  // Allow: letters, digits (for nutrition info), commas, spaces, apostrophes, hyphens
  if (!/^[a-zA-Z0-9\s,.'()-]+$/.test(name)) return false;
  
  // Should have at least 2 words or 8 characters
  if (name.split(/\s+/).length < 2 && name.length < 8) return false;
  
  return true;
}

// Process all foods
const cleanedFoods = [];
const codesSeen = new Set();

for (const food of rawFoods) {
  const originalFood = JSON.stringify(food);
  let isValid = true;
  let fixes = [];
  
  // Validate food code
  if (!isValidFoodCode(food.food_code)) {
    log.removed.push({
      reason: 'Invalid food_code',
      food_code: food.food_code,
      food_name: food.food_name
    });
    isValid = false;
  }
  
  // Check for duplicates
  if (codesSeen.has(food.food_code)) {
    log.removed.push({
      reason: 'Duplicate food_code',
      food_code: food.food_code,
      food_name: food.food_name
    });
    isValid = false;
  }
  
  if (!isValid) continue;
  codesSeen.add(food.food_code);
  
  // Clean and validate food_name
  let cleanName = food.food_name;
  if (!cleanName || !validateFoodName(cleanName)) {
    // Try to extract clean English name
    cleanName = extractEnglishName(food.food_name);
    if (!cleanName) {
      log.removed.push({
        reason: 'Invalid or unfixable food_name',
        food_code: food.food_code,
        food_name: food.food_name
      });
      continue;
    }
    fixes.push('food_name cleaned');
  }
  
  // Extract and validate Amharic name
  let amharicName = null;
  if (food.food_name_amharic) {
    if (isCorrupted(food.food_name_amharic)) {
      fixes.push('food_name_amharic was corrupted, extracted fresh');
      amharicName = extractAmharicName(food.food_name);
    } else {
      amharicName = food.food_name_amharic.trim();
      // Clean trailing English words
      const words = amharicName.split(/\s+/);
      let cleanEnd = words.length;
      for (let i = words.length - 1; i >= 0; i--) {
        const word = words[i].toLowerCase().replace(/[,;.()]/g, '');
        if (englishFoodWords.has(word)) {
          cleanEnd = i;
        } else {
          break;
        }
      }
      if (cleanEnd < words.length) {
        fixes.push('food_name_amharic trailing English removed');
      }
      amharicName = words.slice(0, cleanEnd).join(' ').trim() || null;
    }
  } else {
    // Try to extract from full name
    amharicName = extractAmharicName(food.food_name);
  }
  
  // Validate numeric fields
  const numericFields = ['energy_kcal', 'water_g', 'protein_g', 'fat_g', 'carbs_g', 'fiber_g', 'ash_g'];
  for (const field of numericFields) {
    if (food[field] !== null && food[field] !== undefined) {
      if (typeof food[field] !== 'number' || isNaN(food[field])) {
        food[field] = null;
        fixes.push(`${field} was invalid, set to null`);
      } else if (food[field] < 0) {
        food[field] = null;
        fixes.push(`${field} was negative, set to null`);
      }
    }
  }
  
  // Create cleaned entry
  const cleanedFood = {
    food_code: food.food_code,
    food_name: cleanName,
    food_name_amharic: amharicName,
    energy_kcal: food.energy_kcal,
    water_g: food.water_g,
    protein_g: food.protein_g,
    fat_g: food.fat_g,
    carbs_g: food.carbs_g,
    fiber_g: food.fiber_g,
    ash_g: food.ash_g
  };
  
  cleanedFoods.push(cleanedFood);
  
  if (fixes.length > 0) {
    log.corrected.push({
      food_code: food.food_code,
      food_name: cleanName,
      fixes: fixes
    });
  }
}

// Save cleaned data
fs.writeFileSync('cleaned_foods.json', JSON.stringify(cleanedFoods, null, 2));

// Save detailed log
const logSummary = {
  summary: {
    total_processed: log.totalProcessed,
    total_cleaned: cleanedFoods.length,
    total_removed: log.removed.length,
    total_corrected: log.corrected.length,
    total_fixes_applied: log.corrected.reduce((sum, item) => sum + item.fixes.length, 0)
  },
  removed_entries: log.removed,
  corrected_entries: log.corrected
};

fs.writeFileSync('cleaning_log.json', JSON.stringify(logSummary, null, 2));

// Print results
console.log('\n========================================');
console.log('✓ CLEANING COMPLETE');
console.log('========================================\n');

console.log('SUMMARY:');
console.log(`  Total foods processed:    ${log.totalProcessed}`);
console.log(`  Total foods cleaned:      ${cleanedFoods.length}`);
console.log(`  Total removed:            ${log.removed.length}`);
console.log(`  Total corrected:          ${log.corrected.length}`);
console.log(`  Total fixes applied:      ${logSummary.summary.total_fixes_applied}`);

console.log('\n\nREMOVAL REASONS:');
const removalReasons = {};
for (const item of log.removed) {
  removalReasons[item.reason] = (removalReasons[item.reason] || 0) + 1;
}
for (const [reason, count] of Object.entries(removalReasons)) {
  console.log(`  ${reason}: ${count}`);
}

console.log('\n\nFIXES APPLIED:');
const fixTypes = {};
for (const item of log.corrected) {
  for (const fix of item.fixes) {
    fixTypes[fix] = (fixTypes[fix] || 0) + 1;
  }
}
for (const [fixType, count] of Object.entries(fixTypes)) {
  console.log(`  ${fixType}: ${count}`);
}

console.log('\n\nSAMPLE CLEANED ENTRIES (first 3):');
for (let i = 0; i < Math.min(3, cleanedFoods.length); i++) {
  console.log(`\n  [${i + 1}] Code ${cleanedFoods[i].food_code}:`);
  console.log(`    English: ${cleanedFoods[i].food_name}`);
  console.log(`    Amharic: ${cleanedFoods[i].food_name_amharic || '(none)'}`);
  console.log(`    Energy: ${cleanedFoods[i].energy_kcal} kcal`);
}

console.log('\n\nOUTPUT FILES:');
console.log(`  ✓ cleaned_foods.json (${cleanedFoods.length} foods)`);
console.log(`  ✓ cleaning_log.json (detailed change log)`);
console.log('\n');
