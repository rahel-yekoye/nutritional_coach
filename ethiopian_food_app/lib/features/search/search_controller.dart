import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethiopian_food_app/core/api/api_client.dart';
import 'package:ethiopian_food_app/core/api/food_service.dart';
import 'package:ethiopian_food_app/core/cache/search_cache.dart';
import 'package:ethiopian_food_app/core/models/food_model.dart';
import 'package:ethiopian_food_app/core/providers/providers.dart';

/// Search state
class SearchState {
  final List<FoodModel> results;
  final bool isLoading;
  final String? error;
  final String query;
  final bool isCached;

  const SearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.query = '',
    this.isCached = false,
  });

  SearchState copyWith({
    List<FoodModel>? results,
    bool? isLoading,
    String? error,
    String? query,
    bool? isCached,
  }) {
    return SearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      query: query ?? this.query,
      isCached: isCached ?? this.isCached,
    );
  }
}

/// Search Controller
class SearchController extends StateNotifier<SearchState> {
  final FoodService _foodService;
  final SearchCache _searchCache;
  Timer? _debounceTimer;

  SearchController(this._foodService, this._searchCache)
      : super(const SearchState());

  /// Search with debouncing
  void search(String query, {int limit = 20}) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Update query immediately
    state = state.copyWith(query: query, error: null);

    // If query is empty, clear results
    if (query.trim().isEmpty) {
      state = state.copyWith(results: [], isLoading: false);
      return;
    }

    // Debounce for 300ms
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query, limit);
    });
  }

  /// Perform actual search
  Future<void> _performSearch(String query, int limit) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check cache first
      final cached = _searchCache.get(query);
      if (cached != null) {
        state = state.copyWith(
          results: cached.results,
          isLoading: false,
          isCached: true,
        );
        return;
      }

      // Fetch from API
      final response = await _foodService.searchFoods(query, limit: limit);

      // Cache the results
      await _searchCache.put(query, response);

      state = state.copyWith(
        results: response.results,
        isLoading: false,
        isCached: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
        results: [],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
        results: [],
      );
    }
  }

  /// Clear search
  void clear() {
    _debounceTimer?.cancel();
    state = const SearchState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// Search Controller Provider
final searchControllerProvider =
    StateNotifierProvider<SearchController, SearchState>((ref) {
  final foodService = ref.watch(foodServiceProvider);
  final searchCache = ref.watch(searchCacheProvider);
  return SearchController(foodService, searchCache);
});

/// Suggestion state
class SuggestionState {
  final List<SuggestionModel> suggestions;
  final bool isLoading;

  const SuggestionState({
    this.suggestions = const [],
    this.isLoading = false,
  });
}

/// Suggestion Controller
class SuggestionController extends StateNotifier<SuggestionState> {
  final FoodService _foodService;
  Timer? _debounceTimer;
  String _lastQuery = '';

  SuggestionController(this._foodService) : super(const SuggestionState());

  /// Get suggestions with debouncing
  void getSuggestions(String query) {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      state = const SuggestionState();
      return;
    }

    // Don't fetch if same query
    if (query == _lastQuery) return;

    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      _fetchSuggestions(query);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    state = const SuggestionState(isLoading: true);
    _lastQuery = query;

    try {
      final response = await _foodService.getSuggestions(query);
      state = SuggestionState(suggestions: response.suggestions);
    } catch (e) {
      state = const SuggestionState();
    }
  }

  void clear() {
    _debounceTimer?.cancel();
    _lastQuery = '';
    state = const SuggestionState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// Suggestion Controller Provider
final suggestionControllerProvider =
    StateNotifierProvider<SuggestionController, SuggestionState>((ref) {
  final foodService = ref.watch(foodServiceProvider);
  return SuggestionController(foodService);
});
