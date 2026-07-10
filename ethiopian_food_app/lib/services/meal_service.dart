import 'package:ethiopian_food_app/core/api/api_client.dart';
import 'package:ethiopian_food_app/core/models/nutrition_log.dart';
import 'package:ethiopian_food_app/services/auth_service.dart';

class MealService {
  final ApiClient apiClient;
  final AuthService authService;

  MealService({required this.apiClient, required this.authService});

  Map<String, String> get _authHeaders {
    final token = authService.currentToken;
    if (token == null) {
      throw StateError('Not authenticated');
    }
    return {'Authorization': 'Bearer $token'};
  }

  Future<List<NutritionLog>> fetchMealLogs({int limit = 100}) async {
    final token = authService.currentToken;
    if (token == null) return [];

    final response = await apiClient.get(
      '/api/v1/meals',
      queryParameters: {'limit': limit.toString()},
      headers: _authHeaders,
    );

    final data = response['data'] as Map<String, dynamic>;
    final meals = data['meals'] as List<dynamic>? ?? [];

    return meals
        .map((meal) => _mapServerMealToNutritionLog(meal as Map<String, dynamic>))
        .toList();
  }

  Future<void> createMealLog(NutritionLog log) async {
    await apiClient.post(
      '/api/v1/meals',
      headers: _authHeaders,
      body: {
        'foodCode': log.foodCode,
        'foodName': log.foodName,
        'mealType': 'snack',
        'calories': log.calories,
        'protein': log.protein,
        'fat': log.fat,
        'carbs': log.carbs,
        'consumedAt': log.timestamp.toIso8601String(),
      },
    );
  }

  NutritionLog _mapServerMealToNutritionLog(Map<String, dynamic> meal) {
    final consumedAtRaw = meal['consumedAt'];
    final timestamp = consumedAtRaw != null
        ? DateTime.parse(consumedAtRaw.toString())
        : DateTime.now();

    return NutritionLog(
      id: meal['_id']?.toString() ?? meal['id']?.toString() ?? '',
      foodCode: meal['foodCode']?.toString() ?? '',
      foodName: meal['foodName']?.toString() ?? '',
      category: meal['mealType']?.toString() ?? 'snack',
      servings: 1.0,
      calories: (meal['calories'] as num?)?.toDouble() ?? 0,
      protein: (meal['protein'] as num?)?.toDouble() ?? 0,
      carbs: (meal['carbs'] as num?)?.toDouble() ?? 0,
      fat: (meal['fat'] as num?)?.toDouble() ?? 0,
      fiber: 0,
      timestamp: timestamp,
    );
  }
}
