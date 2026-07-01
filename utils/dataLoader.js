/**
 * Data Loader Utility
 * Centralized data loading and preprocessing
 */

const fs = require('fs');
const path = require('path');
const { formatBytes } = require('../middleware/logger');

/**
 * Load and validate JSON file
 */
function loadJsonFile(filePath, description) {
  const fullPath = path.resolve(filePath);
  
  console.log(`📂 Loading ${description}...`);
  
  if (!fs.existsSync(fullPath)) {
    throw new Error(`File not found: ${fullPath}`);
  }

  const fileStats = fs.statSync(fullPath);
  const fileSize = formatBytes(fileStats.size);
  
  const startTime = Date.now();
  const data = JSON.parse(fs.readFileSync(fullPath, 'utf8'));
  const loadTime = Date.now() - startTime;
  
  console.log(`   ✓ Loaded ${description}: ${fileSize} in ${loadTime}ms`);
  
  return data;
}

/**
 * Preprocess inverted index
 * Convert arrays to Sets for O(1) lookup
 */
function preprocessInvertedIndex(invertedIndex) {
  console.log('🔄 Preprocessing inverted index...');
  
  const startTime = Date.now();
  const preprocessed = {};
  let totalMappings = 0;
  
  for (const [keyword, foodCodes] of Object.entries(invertedIndex)) {
    preprocessed[keyword] = new Set(foodCodes);
    totalMappings += foodCodes.length;
  }
  
  const processingTime = Date.now() - startTime;
  
  console.log(`   ✓ Preprocessed ${Object.keys(preprocessed).length} keywords`);
  console.log(`   ✓ Total mappings: ${totalMappings}`);
  console.log(`   ✓ Processing time: ${processingTime}ms`);
  
  return preprocessed;
}

/**
 * Build lookup maps for fast access
 */
function buildLookupMaps(searchIndex) {
  console.log('🔄 Building lookup maps...');
  
  const startTime = Date.now();
  
  // Food code map: O(1) lookup by food code
  const foodCodeMap = {};
  
  // Category map: foods grouped by category
  const categoryMap = {};
  
  // Keyword map: keywords to food codes
  const keywordToFoodsMap = {};
  
  searchIndex.forEach(food => {
    // Food code map
    foodCodeMap[food.food_code] = food;
    
    // Category map
    if (!categoryMap[food.category]) {
      categoryMap[food.category] = [];
    }
    categoryMap[food.category].push(food.food_code);
    
    // Keyword map
    food.keywords.forEach(keyword => {
      if (!keywordToFoodsMap[keyword]) {
        keywordToFoodsMap[keyword] = new Set();
      }
      keywordToFoodsMap[keyword].add(food.food_code);
    });
  });
  
  const processingTime = Date.now() - startTime;
  
  console.log(`   ✓ Food code map: ${Object.keys(foodCodeMap).length} entries`);
  console.log(`   ✓ Category map: ${Object.keys(categoryMap).length} categories`);
  console.log(`   ✓ Keyword map: ${Object.keys(keywordToFoodsMap).length} keywords`);
  console.log(`   ✓ Processing time: ${processingTime}ms`);
  
  return {
    foodCodeMap,
    categoryMap,
    keywordToFoodsMap,
  };
}

/**
 * Calculate and display statistics
 */
function calculateStatistics(searchIndex, invertedIndex) {
  console.log('\n📊 Data Statistics:');
  
  // Basic counts
  const totalFoods = searchIndex.length;
  const totalKeywords = Object.keys(invertedIndex).length;
  
  // Average keywords per food
  const totalFoodKeywords = searchIndex.reduce((sum, food) => sum + food.keywords.length, 0);
  const avgKeywordsPerFood = (totalFoodKeywords / totalFoods).toFixed(2);
  
  // Category breakdown
  const categoryBreakdown = {};
  searchIndex.forEach(food => {
    categoryBreakdown[food.category] = (categoryBreakdown[food.category] || 0) + 1;
  });
  
  // Keyword frequency
  const keywordFrequency = {};
  for (const [keyword, foodCodes] of Object.entries(invertedIndex)) {
    const count = Array.isArray(foodCodes) ? foodCodes.length : foodCodes.size;
    keywordFrequency[keyword] = count;
  }
  
  const topKeywords = Object.entries(keywordFrequency)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10);
  
  console.log(`   Total Foods: ${totalFoods}`);
  console.log(`   Total Keywords: ${totalKeywords}`);
  console.log(`   Avg Keywords/Food: ${avgKeywordsPerFood}`);
  
  console.log('\n📂 Top Categories:');
  Object.entries(categoryBreakdown)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 8)
    .forEach(([category, count]) => {
      const percentage = ((count / totalFoods) * 100).toFixed(1);
      console.log(`   ${category.padEnd(30)} ${count.toString().padStart(4)} (${percentage}%)`);
    });
  
  console.log('\n🔑 Top Keywords:');
  topKeywords.forEach(([keyword, count]) => {
    console.log(`   ${keyword.padEnd(20)} ${count.toString().padStart(4)} foods`);
  });
  
  return {
    totalFoods,
    totalKeywords,
    avgKeywordsPerFood: parseFloat(avgKeywordsPerFood),
    categoryBreakdown,
    topKeywords,
  };
}

/**
 * Calculate memory usage
 */
function calculateMemoryUsage() {
  const mem = process.memoryUsage();
  
  console.log('\n💾 Memory Usage:');
  console.log(`   Heap Used: ${formatBytes(mem.heapUsed)}`);
  console.log(`   Heap Total: ${formatBytes(mem.heapTotal)}`);
  console.log(`   RSS: ${formatBytes(mem.rss)}`);
  console.log(`   External: ${formatBytes(mem.external)}`);
  
  return mem;
}

/**
 * Main data loading function
 */
function loadAllData(searchIndexPath, invertedIndexPath) {
  console.log('\n🚀 Initializing Ethiopian Food Database API...\n');
  
  const startTime = Date.now();
  
  try {
    // Load data files
    const searchIndex = loadJsonFile(searchIndexPath, 'search_index.json');
    const invertedIndexRaw = loadJsonFile(invertedIndexPath, 'cleaned_inverted_index.json');
    
    // Preprocess data
    const invertedIndex = preprocessInvertedIndex(invertedIndexRaw);
    const lookupMaps = buildLookupMaps(searchIndex);
    
    // Calculate statistics
    const statistics = calculateStatistics(searchIndex, invertedIndex);
    
    // Memory usage
    const memoryUsage = calculateMemoryUsage();
    
    const totalTime = Date.now() - startTime;
    
    console.log(`\n✅ Initialization complete in ${totalTime}ms\n`);
    
    return {
      searchIndex,
      invertedIndex,
      ...lookupMaps,
      statistics,
      memoryUsage,
    };
    
  } catch (error) {
    console.error('\n❌ Initialization Error:', error.message);
    throw error;
  }
}

module.exports = {
  loadAllData,
  loadJsonFile,
  preprocessInvertedIndex,
  buildLookupMaps,
  calculateStatistics,
  calculateMemoryUsage,
};
