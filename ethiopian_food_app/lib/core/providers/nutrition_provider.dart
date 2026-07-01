import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethiopian_food_app/core/models/nutrition_log.dart';
import 'package:ethiopian_food_app/core/models/food_model.dart';
import 'package:ethiopian_food_app/core/models/unified_nutrition_state.dart';
import 'package:ethiopian_food_app/core/models/user_profile.dart';
import 'package:ethiopian_food_app/services/nutrition_service.dart';
import 'package:ethiopian_food_app/core/providers/profile_provider.dart';

final nutritionServiceProvider = Provider<NutritionService>((ref) {
  return NutritionService();
});

final nutritionLogsProvider =
    StateNotifierProvider<NutritionLogsNotifier, AsyncValue<List<NutritionLog>>>(
        (ref) {
  return NutritionLogsNotifier(ref.watch(nutritionServiceProvider));
});

class NutritionLogsNotifier
    extends StateNotifier<AsyncValue<List<NutritionLog>>> {
  final NutritionService _service;

  NutritionLogsNotifier(this._service) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      await _service.init();
      _loadTodayLogs();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _loadTodayLogs() {
    try {
      final logs = _service.getTodayLogs();
      state = AsyncValue.data(logs);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> logFood({
    required FoodModel food,
    required double servings,
  }) async {
    try {
      await _service.logFood(food: food, servings: servings);
      _loadTodayLogs();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteLog(String id) async {
    try {
      await _service.deleteLog(id);
      _loadTodayLogs();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> clearTodayLogs() async {
    try {
      await _service.clearTodayLogs();
      _loadTodayLogs();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void refresh() {
    _loadTodayLogs();
  }
}

final todayNutritionSummaryProvider = Provider<DailyNutritionSummary>((ref) {
  final logsAsync = ref.watch(nutritionLogsProvider);

  return logsAsync.when(
    data: (logs) => DailyNutritionSummary.fromLogs(logs, DateTime.now()),
    loading: () => DailyNutritionSummary.fromLogs(const [], DateTime.now()),
    error: (_, __) => DailyNutritionSummary.fromLogs(const [], DateTime.now()),
  );
});

final unifiedNutritionProvider = Provider<UnifiedNutritionState>((ref) {
  final summary = ref.watch(todayNutritionSummaryProvider);
  final targets = ref.watch(nutritionTargetsProvider);
  final profileAsync = ref.watch(profileProvider);

  final intake = NutritionValues(
    calories: summary.totalCalories,
    protein: summary.totalProtein,
    fat: summary.totalFat,
    carbs: summary.totalCarbs,
    fiber: summary.totalFiber,
  );

  final targetValues = NutritionValues(
    calories: targets.calories,
    protein: targets.protein,
    fat: targets.fat,
    carbs: targets.carbs,
    fiber: targets.fiber,
  );

  return UnifiedNutritionState(
    dailyIntake: intake,
    dailyTargets: targetValues,
    remaining: targetValues - intake,
    goal: profileAsync.value?.goal ?? NutritionGoal.maintain,
    bloodGroup: profileAsync.value?.bloodGroup ?? BloodGroup.oPositive,
    isFasting: profileAsync.value?.fastingMode ?? false,
  );
});
