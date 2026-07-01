import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ethiopian_food_app/core/models/food_model.dart';

class SearchCache {
  static const String _cacheKey = 'search_cache';
  static const int _maxCacheSize = 20;

  final SharedPreferences _prefs;

  SearchCache(this._prefs);

  /// Get cached search results
  SearchResponse? get(String query) {
    final cache = _getCache();
    final cached = cache[query];
    if (cached == null) return null;

    try {
      return SearchResponse.fromJson(jsonDecode(cached) as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Cache search results (LRU style)
  Future<void> put(String query, SearchResponse response) async {
    final cache = _getCache();

    // Remove oldest if at capacity
    if (cache.length >= _maxCacheSize && !cache.containsKey(query)) {
      final oldestKey = cache.keys.first;
      cache.remove(oldestKey);
    }

    // Add or update
    cache[query] = jsonEncode(response.toJson());
    await _saveCache(cache);
  }

  /// Clear all cache
  Future<void> clear() async {
    await _prefs.remove(_cacheKey);
  }

  /// Get cache as map
  Map<String, String> _getCache() {
    final cacheJson = _prefs.getString(_cacheKey);
    if (cacheJson == null) return {};

    try {
      final decoded = jsonDecode(cacheJson) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value as String));
    } catch (e) {
      return {};
    }
  }

  /// Save cache to preferences
  Future<void> _saveCache(Map<String, String> cache) async {
    await _prefs.setString(_cacheKey, jsonEncode(cache));
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final cache = _getCache();
    return {
      'size': cache.length,
      'maxSize': _maxCacheSize,
      'utilization': '${(cache.length / _maxCacheSize * 100).toStringAsFixed(1)}%',
    };
  }
}

extension SearchResponseExtension on SearchResponse {
  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'result_count': resultCount,
      'limit': limit,
      'results': results.map((e) => e.toJson()).toList(),
      'cached': cached,
    };
  }
}
