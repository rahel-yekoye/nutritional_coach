const fs = require('fs');

const foods = JSON.parse(fs.readFileSync('cleaned_foods.json'));

console.log('RANDOM SAMPLES FROM cleaned_foods.json:\n');

const indices = [0, 50, 100, 150, 200, 300];

indices.forEach(i => {
  if (i >= foods.length) return;
  const f = foods[i];
  console.log(`[${i}] ${f.food_code}: ${f.food_name}`);
  console.log(`    Amharic: ${f.food_name_amharic}`);
  console.log(`    Energy: ${f.energy_kcal} kcal | Protein: ${f.protein_g}g | Carbs: ${f.carbs_g}g`);
  console.log();
});
