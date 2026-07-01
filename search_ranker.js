/**
 * Search Ranker for Food Search Index
 * Implements multi-factor scoring for search results
 */

const fs = require('fs');

class FoodSearchRanker {
  constructor(searchIndex = null, invertedIndex = null, foodCodeMap = null) {
    // Accept preloaded data or load from files
    if (searchIndex && invertedIndex) {
      this.searchIndex = searchIndex;
      this.invertedIndex = invertedIndex;
      this.foodCodeMap = foodCodeMap || this.buildFastLookup();
    } else {
      // Fallback: load from files (for standalone usage)
      this.searchIndex = JSON.parse(fs.readFileSync('search_index.json', 'utf8'));
      this.invertedIndex = JSON.parse(fs.readFileSync('cleaned_inverted_index.json', 'utf8'));
      this.foodCodeMap = this.buildFastLookup();
    }
  }

  buildFastLookup() {
    // Build lookup maps for O(1) access
    const foodCodeMap = {};
    this.searchIndex.forEach(item => {
      foodCodeMap[item.food_code] = item;
    });
    return foodCodeMap;
  }

  /**
   * Score based on name match quality
   * Returns 0-5 points
   * 5 = exact match
   * 4 = starts with query
   * 3 = contains whole query
   * 2 = partial match
   * 0 = no match
   */
  scoreNameMatch(foodName, query) {
    const name = foodName.toLowerCase();
    const q = query.toLowerCase();

    // Exact match
    if (name === q) {
      return 5;
    }

    // Starts with query
    if (name.startsWith(q)) {
      return 4;
    }

    // Query is a whole word in the name
    const words = name.split(/[\s\-,]/);
    if (words.some(word => word === q)) {
      return 4;
    }

    // Contains query as substring
    if (name.includes(q)) {
      return 3;
    }

    // Check if all query words are in name (order doesn't matter)
    const queryWords = q.split(/[\s\-,]/);
    if (queryWords.every(qw => name.includes(qw))) {
      return 2;
    }

    return 0;
  }

  /**
   * Score based on keyword overlap
   * Returns 0-2 points
   * Penalizes very generic results
   */
  scoreKeywordMatch(food, queryKeywords, matchedKeywords) {
    if (matchedKeywords.length === 0) {
      return 0;
    }

    const overlapRatio = matchedKeywords.length / queryKeywords.length;

    // Full overlap
    if (overlapRatio >= 0.9) {
      return 2;
    }

    // Partial overlap
    if (overlapRatio >= 0.5) {
      return 1;
    }

    // Minimal overlap
    if (overlapRatio >= 0.2) {
      return 0.5;
    }

    return 0;
  }

  /**
   * Score based on category match
   * Returns 0-1 points
   */
  scoreCategoryMatch(food, queryCategory) {
    if (!queryCategory) {
      return 0;
    }

    return food.category.toLowerCase() === queryCategory.toLowerCase() ? 1 : 0;
  }

  /**
   * Main scoring function
   * score = (name_match * 5) + (keyword_match * 2) + (category_match * 1)
   */
  calculateScore(food, query, queryKeywords, queryCategory) {
    const nameScore = this.scoreNameMatch(food.food_name, query);
    const keywordMatches = food.keywords.filter(kw =>
      queryKeywords.some(qkw => this.similarityScore(kw, qkw) > 0.7)
    );
    const keywordScore = this.scoreKeywordMatch(food, queryKeywords, keywordMatches);
    const categoryScore = this.scoreCategoryMatch(food, queryCategory);

    // Weighted scoring: name is most important, then keywords, then category
    const totalScore =
      nameScore * 5 +           // Name match: 0-25 points
      keywordScore * 2 +        // Keyword match: 0-4 points
      categoryScore * 1;        // Category match: 0-1 point

    return {
      score: totalScore,
      nameScore,
      keywordScore,
      categoryScore,
      matchedKeywords: keywordMatches
    };
  }

  /**
   * Simple string similarity (Levenshtein-like)
   * Returns 0-1 score
   */
  similarityScore(str1, str2) {
    const s1 = str1.toLowerCase();
    const s2 = str2.toLowerCase();

    // Exact match
    if (s1 === s2) return 1;

    // Prefix match
    if (s1.startsWith(s2) || s2.startsWith(s1)) return 0.9;

    // Substring match
    if (s1.includes(s2) || s2.includes(s1)) return 0.7;

    // Levenshtein distance
    const distance = this.levenshteinDistance(s1, s2);
    const maxLen = Math.max(s1.length, s2.length);
    return Math.max(0, 1 - distance / maxLen);
  }

  /**
   * Calculate Levenshtein distance between two strings
   */
  levenshteinDistance(str1, str2) {
    const m = str1.length;
    const n = str2.length;
    const dp = Array(m + 1)
      .fill(null)
      .map(() => Array(n + 1).fill(0));

    for (let i = 0; i <= m; i++) dp[i][0] = i;
    for (let j = 0; j <= n; j++) dp[0][j] = j;

    for (let i = 1; i <= m; i++) {
      for (let j = 1; j <= n; j++) {
        if (str1[i - 1] === str2[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = 1 + Math.min(dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]);
        }
      }
    }

    return dp[m][n];
  }

  /**
   * Search and rank results
   * @param {string} query - Search query
   * @param {number} limit - Max results to return
   * @returns {Array} Ranked results
   */
  search(query, limit = 20) {
    if (!query || query.trim().length === 0) {
      return [];
    }

    const trimmedQuery = query.trim();
    const queryWords = trimmedQuery.split(/[\s,\-]+/).filter(w => w.length > 0);
    const queryCategory = this.extractCategoryFromQuery(trimmedQuery);

    // Find candidate foods
    const candidates = new Set();

    // 1. Direct name matches
    this.searchIndex.forEach(food => {
      if (
        food.food_name.toLowerCase().includes(trimmedQuery.toLowerCase()) ||
        food.normalized_amharic.includes(trimmedQuery.toLowerCase())
      ) {
        candidates.add(food.food_code);
      }
    });

    // 2. Keyword matches - OPTIMIZED: O(1) lookup instead of O(n) loop
    queryWords.forEach(word => {
      // Direct lookup for exact match
      if (this.invertedIndex[word]) {
        const foodCodes = this.invertedIndex[word];
        if (foodCodes instanceof Set) {
          foodCodes.forEach(code => candidates.add(code));
        } else if (Array.isArray(foodCodes)) {
          foodCodes.forEach(code => candidates.add(code));
        }
      }
      
      // Fuzzy matching only for keywords that start with the word (prefix search)
      Object.keys(this.invertedIndex).forEach(keyword => {
        if (keyword.startsWith(word) || this.similarityScore(keyword, word) > 0.75) {
          const foodCodes = this.invertedIndex[keyword];
          if (foodCodes instanceof Set) {
            foodCodes.forEach(code => candidates.add(code));
          } else if (Array.isArray(foodCodes)) {
            foodCodes.forEach(code => candidates.add(code));
          }
        }
      });
    });

    // Score and rank candidates
    const scored = Array.from(candidates)
      .map(foodCode => {
        const food = this.foodCodeMap[foodCode];
        const scores = this.calculateScore(food, trimmedQuery, queryWords, queryCategory);
        return {
          ...food,
          ...scores,
          matchType: this.determineMatchType(scores)
        };
      })
      .filter(result => result.score > 0)
      .sort((a, b) => b.score - a.score)
      .slice(0, limit);

    return scored;
  }

  /**
   * Determine the type of match for display
   */
  determineMatchType(scores) {
    if (scores.nameScore >= 4) return 'exact_name';
    if (scores.nameScore >= 2) return 'name_match';
    if (scores.keywordScore >= 1.5) return 'keyword_match';
    return 'category_match';
  }

  /**
   * Try to extract category from query
   */
  extractCategoryFromQuery(query) {
    const q = query.toLowerCase();
    const categories = [
      'cereals',
      'grains',
      'legumes',
      'vegetables',
      'fruits',
      'meat',
      'fish',
      'dairy',
      'eggs'
    ];

    for (const cat of categories) {
      if (q.includes(cat)) {
        return cat;
      }
    }

    return null;
  }

  /**
   * Format results for display
   */
  formatResults(results) {
    return results.map(result => ({
      food_code: result.food_code,
      food_name: result.food_name,
      food_name_amharic: result.food_name_amharic,
      category: result.category,
      score: result.score.toFixed(2),
      scoreBreakdown: {
        name: result.nameScore.toFixed(1),
        keyword: result.keywordScore.toFixed(1),
        category: result.categoryScore.toFixed(1)
      },
      matchType: result.matchType,
      keywords: result.keywords.slice(0, 5),
      nutrition: {
        energy_kcal: result.energy_kcal,
        protein_g: result.protein_g,
        fat_g: result.fat_g,
        carbs_g: result.carbs_g
      }
    }));
  }
}

// Export for use as module
module.exports = FoodSearchRanker;

// Test if run directly
if (require.main === module) {
  const ranker = new FoodSearchRanker();

  // Test queries
  const testQueries = [
    'barley',
    'wheat bread',
    'lentil soup',
    'chicken meat',
    'teff enjera',
    'vegetables',
    'fish tilapia'
  ];

  console.log('🔍 Search Ranking Test\n');

  testQueries.forEach(query => {
    console.log(`\n📍 Query: "${query}"`);
    console.log('─'.repeat(60));

    const results = ranker.search(query, 5);

    if (results.length === 0) {
      console.log('No results found');
      return;
    }

    ranker.formatResults(results).forEach((result, idx) => {
      console.log(`\n${idx + 1}. ${result.food_name}`);
      console.log(`   Code: ${result.food_code} | Category: ${result.category}`);
      console.log(`   Score: ${result.score} (name:${result.scoreBreakdown.name} keyword:${result.scoreBreakdown.keyword} cat:${result.scoreBreakdown.category})`);
      console.log(`   Match: ${result.matchType} | Keywords: ${result.keywords.join(', ')}`);
    });
  });
}
