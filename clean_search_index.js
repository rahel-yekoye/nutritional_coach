const fs = require('fs');

// Keywords to remove - low-value descriptors
const noisyKeywords = new Set([
  "ti're",           // raw
  "yetefetege",      // wheat/grain variety descriptor
  "yetekeka",        // split descriptor
  "yaltefetege",     // whole grain descriptor
  "yetekekele",      // boiled descriptor
  "yetetebese",      // grilled descriptor
  "yedereke",        // dry descriptor
  "without",         // cooking preparation
  "with",            // cooking preparation
  "salt",            // ingredient modifier (too common)
  "raw",             // preparation state
  "boiled",          // preparation state
  "drained",         // preparation state
  "grilled",         // preparation state
  "roasted",         // preparation state
  "dried",           // preparation state
  "fresh",           // state descriptor
  "peeled",          // preparation state
  "tuber",           // generic descriptor
  "seed",            // too generic
  "flour",           // form descriptor (keep in name, remove from keywords)
  "kernel",          // generic
  "flesh",           // generic
  "leaves",          // part but also too generic
  "stems",           // generic
  "fruit",           // too generic
  "oil",             // too generic for base foods
  "whole",           // preparation state
  "split",           // preparation state
  "grain",           // too generic
  "meat",            // too generic in this context
  "part",            // generic
  "parts",           // generic
  "assorted",        // generic
  "and",             // connector
  "as",              // connector
  "of",              // connector
  "a",               // article
  "the",             // article
  "from",            // preposition
  "an",              // article
  "unfermented",     // preparation descriptor
  "fermented",       // preparation descriptor
  "canned",          // packaging
  "paste",           // form (too generic)
  "juice",           // form (too generic)
  "pulp",            // generic
  "white",           // color descriptor (too common)
  "red",             // color descriptor (too common)
  "green",           // color descriptor (too common)
  "black",           // color descriptor (too common)
  "brown",           // color descriptor (too common)
  "yellow",          // color descriptor (too common)
  "mixed",           // descriptor
  "refined",         // processing state
  "decorticated",    // processing state
  "sandwich",        // form descriptor
  "cracker",         // form descriptor
  "butter",          // product form (keep specific context)
  "soft",            // texture
  "hard",            // texture
  "sweet",           // taste
  "recipe",          // cooking reference
  "kenewuhaw",       // "as part of recipe" Amharic
  "dinch",           // alternate name descriptor
  "eshet",           // "fresh" Amharic
  "yedereke",        // "dry" Amharic duplicate
  "dilih",           // processing descriptor
  "yetashege",       // processing descriptor
  "ti",              // fragment
  "re",              // fragment
  "ye",              // fragment
]);

// Keep these keywords even if they contain removed words
const preserveKeywords = new Set([
  'tempeh',
  'tofu',
  'pasta',
  'enjera',
  'kocho',
  'bulla',
  'qualima',
  'butter',
  'homemade'
]);

// Keywords to rename/consolidate
const keywordAliases = {
  'yetelate': 'peeled',  // but we're removing peeled...actually keep ingredient
  'lomi': 'lemon',
  'birtu': 'orange',
  'temir': 'date',
  'babay': 'watermelon',
  'bekolo': 'maize',
  'keye': 'red',
  'nech': 'white',
  'tikur': 'black',
  'bicha': 'yellow',
  'dibilik': 'mixed',
  'sinde': 'wheat',
  'gebs': 'barley',
  'zengada': 'millet',
  'mashila': 'sorghum',
  'bere': 'beef',
  'doro': 'chicken',
  'fiyel': 'goat',
  'begi': 'sheep',
  'gimel': 'camel',
  'asa': 'fish',
  'shimbra': 'chickpea',
  'ater': 'field pea',
  'boloke': 'bean',
  'akuriater': 'soybean',
  'misir': 'lentil',
  'gomen': 'greens',
  'atikilt': 'vegetable',
  'timatim': 'tomato',
  'carot': 'carrot',
  'shinkurt': 'onion',
  'kariya': 'pepper',
  'dubba': 'pumpkin',
  'cabbage': 'cabbage',
  'lewz': 'peanut',
  'selit': 'sesame',
  'telba': 'linseed',
  'nug': 'niger',
  'suf': 'safflower',
};

function filterKeywords(keywordArray) {
  return keywordArray.filter(kw => {
    // Preserve explicitly listed keywords
    if (preserveKeywords.has(kw)) {
      return true;
    }
    
    // Remove noisy keywords
    if (noisyKeywords.has(kw)) {
      return false;
    }
    
    // Remove keywords that are only in aliases (they get remapped)
    if (keywordAliases[kw]) {
      return false;
    }
    
    // Keep everything else
    return true;
  });
}

function remapKeywords(keywordArray) {
  return keywordArray.map(kw => keywordAliases[kw] || kw);
}

function cleanIndices() {
  // Read search index
  const searchIndex = JSON.parse(fs.readFileSync('search_index.json', 'utf8'));
  
  let totalRemovedKeywords = 0;
  let removedNoisyCount = 0;
  
  // Clean search index keywords
  const cleanedSearchIndex = searchIndex.map(item => {
    const originalCount = item.keywords.length;
    
    // Filter out noisy keywords
    let cleaned = filterKeywords(item.keywords);
    
    // Remap aliases
    cleaned = remapKeywords(cleaned);
    
    // Remove duplicates after remapping
    cleaned = [...new Set(cleaned)].sort();
    
    removedNoisyCount += originalCount - cleaned.length;
    
    return {
      ...item,
      keywords: cleaned
    };
  });
  
  // Build new inverted index
  const newInvertedIndex = {};
  
  cleanedSearchIndex.forEach(item => {
    item.keywords.forEach(keyword => {
      if (!newInvertedIndex[keyword]) {
        newInvertedIndex[keyword] = [];
      }
      newInvertedIndex[keyword].push(item.food_code);
    });
  });
  
  // Write cleaned search index
  fs.writeFileSync('search_index.json', JSON.stringify(cleanedSearchIndex, null, 2), 'utf8');
  console.log(`✓ Updated search_index.json with cleaned keywords`);
  
  // Write new inverted index
  fs.writeFileSync('cleaned_inverted_index.json', JSON.stringify(newInvertedIndex, null, 2), 'utf8');
  console.log(`✓ Created cleaned_inverted_index.json`);
  
  // Calculate statistics
  const oldKeywordCount = searchIndex.reduce((sum, item) => sum + item.keywords.length, 0);
  const newKeywordCount = cleanedSearchIndex.reduce((sum, item) => sum + item.keywords.length, 0);
  const uniqueOldKeywords = new Set(searchIndex.flatMap(item => item.keywords)).size;
  const uniqueNewKeywords = new Set(cleanedSearchIndex.flatMap(item => item.keywords)).size;
  
  console.log('\n📊 Cleanup Statistics:');
  console.log(`   Total keyword instances removed: ${removedNoisyCount}`);
  console.log(`   Unique noisy keywords removed: ${uniqueOldKeywords - uniqueNewKeywords}`);
  console.log(`   Old keyword count (unique): ${uniqueOldKeywords}`);
  console.log(`   New keyword count (unique): ${uniqueNewKeywords}`);
  console.log(`   Old total keyword instances: ${oldKeywordCount}`);
  console.log(`   New total keyword instances: ${newKeywordCount}`);
  console.log(`   Avg keywords per food (before): ${(oldKeywordCount / searchIndex.length).toFixed(2)}`);
  console.log(`   Avg keywords per food (after): ${(newKeywordCount / cleanedSearchIndex.length).toFixed(2)}`);
  
  // Show top keywords after cleanup
  console.log('\n🔍 Top 15 keywords after cleanup:');
  Object.entries(newInvertedIndex)
    .sort((a, b) => b[1].length - a[1].length)
    .slice(0, 15)
    .forEach(([keyword, foods]) => {
      console.log(`   "${keyword}": ${foods.length} foods`);
    });
  
  // Show removed noisy keywords
  console.log('\n🗑️  Removed noisy keywords:');
  const removedKeywords = Array.from(noisyKeywords).filter(kw => uniqueOldKeywords > 0);
  console.log(`   ${removedKeywords.slice(0, 10).join(', ')}`);
  console.log(`   ... and ${Math.max(0, removedKeywords.length - 10)} more`);
}

cleanIndices();
