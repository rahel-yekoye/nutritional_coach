import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ethiopian_food_app/core/api/api_client.dart';
import 'package:ethiopian_food_app/core/api/food_service.dart';
import 'package:ethiopian_food_app/core/cache/search_cache.dart';

/// Shared Preferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

/// API Client provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Food Service provider
final foodServiceProvider = Provider<FoodService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FoodService(apiClient: apiClient);
});

/// Search Cache provider
final searchCacheProvider = Provider<SearchCache>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SearchCache(prefs);
});
