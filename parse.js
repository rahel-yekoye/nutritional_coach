const fs = require('fs');

const text = fs.readFileSync('output.txt', 'utf8');

// Split by lines
const lines = text.split('\n');

// Store foods by code to handle duplicates
const foodsMap = new Map();

// Regex to detect a line starting with a food code
const codePattern = /^(\d{6})\s+(.+)$/;

let i = 0;
while (i < lines.length) {
  const line = lines[i];
  
  // Check if this line starts with a 6-digit code
  const match = line.match(codePattern);
  
  if (match) {
    const code = match[1];
    const restOfLine = match[2];
    
    // Skip if already processed (deduplication)
    if (foodsMap.has(code)) {
      i++;
      continue;
    }
    
    // Use regex to extract: names, edible portion, energy, and nutrients
    // Pattern: [names...] [edible_portion] [energy(kcal)] [water] [protein] [fat] [carbs] [fiber] [ash]
    // Energy is in format like "1510(357)"
    
    // Find energy value first - it's the anchor point
    const energyPattern = /\s(\d+)\((\d+(?:\.\d+)?)\)\s+([\d.]+)\s+([\d.]+)\s+([\[\d.]+\]?)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+?)(?:\s|$)/;
    const energyMatch = restOfLine.match(energyPattern);
    
    if (!energyMatch) {
      i++;
      continue; // Skip if we can't find complete numeric pattern
    }
    
    // Extract numeric values
    const energyKj = parseFloat(energyMatch[1]);
    const energyKcal = parseFloat(energyMatch[2]);
    const water = parseFloat(energyMatch[3]);
    const protein = parseFloat(energyMatch[4]);
    let fat = parseFloat(energyMatch[5].replace(/[\[\]]/g, ''));
    const carbs = parseFloat(energyMatch[6]);
    const fiber = parseFloat(energyMatch[7]);
    const ash = parseFloat(energyMatch[8]) || null;
    
    // Extract names (everything before the energy value)
    const beforeEnergy = restOfLine.substring(0, energyMatch.index).trim();
    
    // Split names by looking for edible portion (numeric value before energy)
    // Pattern: ...name edible_portion energy...
    const ediblePortionPattern = /\s(\d+(?:\.\d+)?)\s*$/;
    const edibleMatch = beforeEnergy.match(ediblePortionPattern);
    
    let fullName = beforeEnergy;
    const ediblePortion = edibleMatch ? parseFloat(edibleMatch[1]) : 1.0;
    
    if (edibleMatch) {
      // Remove edible portion from the end to get just names
      fullName = beforeEnergy.substring(0, edibleMatch.index).trim();
    }
    
    // Try to identify and separate Amharic portion (for reference)
    let amharicName = '';
    const words = fullName.split(/\s+/);
    
    // Amharic names typically start with capital + lowercase pattern: Ye, Ya, Ti, Ga, etc.
    for (let j = Math.max(1, words.length - 5); j < words.length; j++) {
      const word = words[j];
      if (word.match(/^[YyTtGgKkFfDd][aeiouəɛɔ]/i) && word.length > 2) {
        amharicName = words.slice(j).join(' ');
        break;
      }
    }
    
    // Store food item
    foodsMap.set(code, {
      food_code: code,
      food_name: fullName.trim() || null,
      food_name_amharic: amharicName.trim() || null,
      energy_kcal: energyKcal,
      water_g: water,
      protein_g: protein,
      fat_g: fat,
      carbs_g: carbs,
      fiber_g: fiber,
      ash_g: ash
    });
  }
  
  i++;
}

// Convert map to array
const foods = Array.from(foodsMap.values());

// Save to JSON
fs.writeFileSync('foods.json', JSON.stringify(foods, null, 2));

console.log(`\n✓ Parsing complete!`);
console.log(`Total unique foods extracted: ${foods.length}`);
console.log(`\nFirst 5 items:`);
console.log(JSON.stringify(foods.slice(0, 5), null, 2));
console.log(`\nSaved to: foods.json`);
