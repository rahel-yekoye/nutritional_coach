import 'package:ethiopian_food_app/core/models/food_model.dart';
import 'package:ethiopian_food_app/core/api/api_client.dart';

class CategoryFoodsResponse {
  final String category;
  final int count;
  final List<FoodModel> foods;

  CategoryFoodsResponse({
    required this.category,
    required this.count,
    required this.foods,
  });

  factory CategoryFoodsResponse.fromJson(Map<String, dynamic> json) {
    return CategoryFoodsResponse(
      category: json['category'] as String,
      count: json['count'] as int,
      foods: (json['foods'] as List)
          .map((e) => FoodModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FoodService {
  final ApiClient _apiClient;

  FoodService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Search for foods by query
  Future<SearchResponse> searchFoods(String query, {int limit = 20}) async {
    final response = await _apiClient.get(
      '/search',
      queryParameters: {
        'q': query,
        'limit': limit.toString(),
      },
    );
    return SearchResponse.fromJson(response);
  }

  /// Get autocomplete suggestions
  Future<SuggestResponse> getSuggestions(String query) async {
    final response = await _apiClient.get(
      '/suggest',
      queryParameters: {'q': query},
    );
    return SuggestResponse.fromJson(response);
  }

  /// Get food details by code
  Future<FoodModel> getFoodDetails(String foodCode) async {
    final response = await _apiClient.get('/food/$foodCode');
    return FoodModel.fromJson(response);
  }

  /// Get all categories
  Future<CategoryResponse> getCategories() async {
    final response = await _apiClient.get('/suggest/categories');
    return CategoryResponse.fromJson(response);
  }

  /// Get foods by category
  Future<CategoryFoodsResponse> getCategoryFoods(String categoryName) async {
    final encodedCategory = Uri.encodeComponent(categoryName);
    final response = await _apiClient.get('/category/$encodedCategory');
    return CategoryFoodsResponse.fromJson(response);
  }

  /// Compare multiple foods
  Future<List<FoodModel>> compareFoods(List<String> foodCodes) async {
    if (foodCodes.isEmpty) return [];
    
    final response = await _apiClient.get(
      '/food/compare/list',
      queryParameters: {'codes': foodCodes.join(',')},
    );
    
    final results = response['results'] as List;
    return results
        .where((e) => e['error'] == null)
        .map((e) => FoodModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void dispose() {
    _apiClient.dispose();
  }
}
