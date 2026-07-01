const fs = require('fs');
const path = require('path');

// Category mapping based on food_code prefix
const categoryMap = {
  '01': 'Cereals & Grains',
  '02': 'Tubers & Roots',
  '03': 'Legumes & Pulses',
  '04': 'Vegetables',
  '05': 'Fruits',
  '06': 'Seeds & Nuts',
  '07': 'Meat & Poultry',
  '08': 'Eggs',
  '09': 'Fish & Seafood',
  '10': 'Dairy & Milk',
  '11': 'Oils & Fats',
  '12': 'Beverages',
  '13': 'Sweets & Sugars',
  '14': 'Spices & Seasonings',
  '15': 'Condiments',
  '16': 'Sauces & Soups',
  '17': 'Prepared Dishes'
};

// Common ingredient keywords to extract
const ingredientKeywords = {
  'barley': ['barley', 'gebs'],
  'wheat': ['wheat', 'sinde', 'emmer'],
  'teff': ['teff'],
  'maize': ['maize', 'corn', 'bekolo'],
  'millet': ['millet', 'zengada', 'mashila'],
  'sorghum': ['sorghum', 'mashila'],
  'oats': ['oats', 'aja'],
  'rice': ['rice', 'ruz'],
  'lentil': ['lentil', 'misir'],
  'chickpea': ['chickpea', 'shimbra'],
  'bean': ['bean', 'boloke', 'kidney', 'haricot', 'broad bean', 'bakela'],
  'pea': ['pea', 'ater', 'field pea'],
  'soybean': ['soybean', 'akuriater'],
  'potato': ['potato', 'teleto'],
  'sweet potato': ['sweet potato', 'dinch'],
  'cassava': ['cassava'],
  'beef': ['beef', 'bere'],
  'chicken': ['chicken', 'doro'],
  'goat': ['goat', 'fiyel'],
  'sheep': ['sheep', 'mutton', 'begi'],
  'pork': ['pork', 'asama'],
  'fish': ['fish', 'asa', 'tilapia', 'carp', 'catfish'],
  'egg': ['egg', 'enqulal'],
  'milk': ['milk', 'wetet'],
  'cheese': ['cheese', 'ayib'],
  'bread': ['bread', 'qita', 'enjera'],
  'pasta': ['pasta'],
  'nut': ['nut', 'peanut', 'lewz'],
  'seed': ['seed', 'fire'],
  'oil': ['oil', 'zeyet'],
  'honey': ['honey', 'mar'],
  'spice': ['spice', 'berbere', 'mitmita'],
  'vegetable': ['vegetable', 'gomen', 'atikilt'],
  'fruit': ['fruit']
};

function getCategory(foodCode) {
  const prefix = foodCode.substring(0, 2);
  return categoryMap[prefix] || 'Other';
}

function normalizeEnglishName(foodName) {
  // Remove Amharic/transliteration parts (usually after common markers)
  // Markers: space followed by "Ye'", "ye'", comma, or similar patterns
  const markers = ['Ye\'', 'ye\'', 'Yaltefetege', 'Yetefetege', 'Yetekeka', 'Yatrefetege'];
  
  let normalized = foodName;
  
  // Find where Amharic starts (usually marked by "Ye'" or similar)
  for (let marker of markers) {
    const idx = normalized.indexOf(marker);
    if (idx > 0) {
      normalized = normalized.substring(0, idx).trim();
      break;
    }
  }
  
  // Also handle cases where there's a comma separating English from Amharic
  if (normalized.includes(',')) {
    // Keep only the first part, but be careful about descriptions
    const parts = normalized.split(',');
    // Return the longest continuous description
    normalized = parts[0].trim();
  }
  
  return normalized;
}

function normalizeAmharic(amharicName) {
  if (!amharicName) return '';
  // Remove common suffixes and clean up
  return amharicName.trim().toLowerCase();
}

function extractKeywords(foodName, amharicName, category) {
  const keywords = new Set();
  
  // Add category
  keywords.add(category.toLowerCase());
  
  // Split English name into tokens
  const englishTokens = foodName.toLowerCase().split(/[\s,\-()\/]+/).filter(t => t.length > 0);
  englishTokens.forEach(token => {
    if (token.length > 2) {  // Ignore very short tokens
      keywords.add(token);
    }
  });
  
  // Extract main ingredients
  const nameLower = foodName.toLowerCase();
  for (const [ingredientName, ingredientMarkers] of Object.entries(ingredientKeywords)) {
    for (const marker of ingredientMarkers) {
      if (nameLower.includes(marker.toLowerCase())) {
        keywords.add(ingredientName);
        break;
      }
    }
  }
  
  // Add Amharic name tokens
  if (amharicName) {
    const amharicTokens = amharicName.toLowerCase().split(/[\s,\-()\/]+/).filter(t => t.length > 0);
    amharicTokens.forEach(token => {
      if (token.length > 1) {
        keywords.add(token);
      }
    });
  }
  
  return Array.from(keywords).sort();
}

function buildIndices() {
  // Read the cleaned foods data
  const foodsData = JSON.parse(fs.readFileSync('cleaned_foods.json', 'utf8'));
  
  const searchIndex = [];
  const invertedIndex = {};
  const keywordStats = [];
  
  // Process each food item
  foodsData.forEach(food => {
    const englishName = normalizeEnglishName(food.food_name);
    const category = getCategory(food.food_code);
    const normalizedAmharic = normalizeAmharic(food.food_name_amharic);
    const keywords = extractKeywords(englishName, food.food_name_amharic, category);
    
    // Add to search index
    searchIndex.push({
      food_code: food.food_code,
      food_name: englishName,
      food_name_original: food.food_name,
      food_name_amharic: food.food_name_amharic,
      normalized_amharic: normalizedAmharic,
      category: category,
      keywords: keywords,
      energy_kcal: food.energy_kcal,
      protein_g: food.protein_g,
      fat_g: food.fat_g,
      carbs_g: food.carbs_g,
      fiber_g: food.fiber_g
    });
    
    keywordStats.push(keywords.length);
    
    // Build inverted index
    keywords.forEach(keyword => {
      if (!invertedIndex[keyword]) {
        invertedIndex[keyword] = [];
      }
      invertedIndex[keyword].push(food.food_code);
    });
  });
  
  // Write search index
  fs.writeFileSync('search_index.json', JSON.stringify(searchIndex, null, 2), 'utf8');
  console.log(`✓ Created search_index.json with ${searchIndex.length} foods`);
  
  // Write inverted index
  fs.writeFileSync('inverted_index.json', JSON.stringify(invertedIndex, null, 2), 'utf8');
  console.log(`✓ Created inverted_index.json`);
  
  // Calculate statistics
  const totalKeywords = Object.keys(invertedIndex).length;
  const averageKeywords = (keywordStats.reduce((a, b) => a + b, 0) / keywordStats.length).toFixed(2);
  const minKeywords = Math.min(...keywordStats);
  const maxKeywords = Math.max(...keywordStats);
  
  // Print statistics
  console.log('\n📊 Index Statistics:');
  console.log(`   Total indexed keywords: ${totalKeywords}`);
  console.log(`   Average keywords per food: ${averageKeywords}`);
  console.log(`   Min keywords per food: ${minKeywords}`);
  console.log(`   Max keywords per food: ${maxKeywords}`);
  console.log(`   Total foods indexed: ${searchIndex.length}`);
  
  // Show sample keywords
  console.log('\n🔍 Sample keywords:');
  const sampleKeywords = Object.keys(invertedIndex)
    .sort((a, b) => invertedIndex[b].length - invertedIndex[a].length)
    .slice(0, 10);
  
  sampleKeywords.forEach(keyword => {
    console.log(`   "${keyword}": ${invertedIndex[keyword].length} foods`);
  });
  
  // Show category breakdown
  console.log('\n📂 Foods by category:');
  const categoryBreakdown = {};
  searchIndex.forEach(item => {
    if (!categoryBreakdown[item.category]) {
      categoryBreakdown[item.category] = 0;
    }
    categoryBreakdown[item.category]++;
  });
  
  Object.entries(categoryBreakdown)
    .sort((a, b) => b[1] - a[1])
    .forEach(([cat, count]) => {
      console.log(`   ${cat}: ${count}`);
    });
}

buildIndices();
