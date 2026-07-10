import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethiopian_food_app/core/models/nutrition_log.dart';
import 'package:ethiopian_food_app/core/models/food_model.dart';
import 'package:ethiopian_food_app/core/models/unified_nutrition_state.dart';
import 'package:ethiopian_food_app/core/models/user_profile.dart';
import 'package:ethiopian_food_app/services/nutrition_service.dart';
import 'package:ethiopian_food_app/services/meal_service.dart';
import 'package:ethiopian_food_app/services/auth_service.dart';
import 'package:ethiopian_food_app/core/providers/profile_provider.dart';
import 'package:ethiopian_food_app/core/providers/providers.dart';

final nutritionLogsProvider =
    StateNotifierProvider<NutritionLogsNotifier, AsyncValue<List<NutritionLog>>>(
        (ref) {
  return NutritionLogsNotifier(
    ref.watch(nutritionServiceProvider),
    ref.watch(mealServiceProvider),
    ref.watch(authServiceProvider),
  );
});

class NutritionLogsNotifier
    extends StateNotifier<AsyncValue<List<NutritionLog>>> {
  final NutritionService _service;
  final MealService _mealService;
  final AuthService _authService;
  bool _mounted = true;

  NutritionLogsNotifier(
    this._service,
    this._mealService,
    this._authService,
  ) : super(const AsyncValue.loading()) {
    _init();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void _setState(AsyncValue<List<NutritionLog>> value) {
    if (!_mounted) return;
    state = value;
  }

  Future<void> _init() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        _setState(const AsyncValue.data([]));
        return;
      }

      await _service.init(user.id);
      if (!_mounted) return;

      await _syncFromBackend();
      if (!_mounted) return;

      _loadTodayLogs();
    } catch (e, stack) {
      _setState(AsyncValue.error(e, stack));
    }
  }

  Future<void> _syncFromBackend() async {
    try {
      final serverLogs = await _mealService.fetchMealLogs();
      if (serverLogs.isNotEmpty) {
        await _service.importServerLogs(serverLogs);
        debugPrint('✅ Restored ${serverLogs.length} meal logs from server');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to sync meal logs from server: $e');
    }
  }

  void _loadTodayLogs() {
    try {
      final logs = _service.getTodayLogs();
      _setState(AsyncValue.data(logs));
    } catch (e, stack) {
      _setState(AsyncValue.error(e, stack));
    }
  }

  Future<void> logFood({
    required FoodModel food,
    required double servings,
  }) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw StateError('No authenticated user');
      }

      await _service.init(user.id);
      if (!_mounted) return;

      final log = await _service.logFood(food: food, servings: servings);
      if (!_mounted) return;

      try {
        await _mealService.createMealLog(log);
      } catch (e) {
        debugPrint('⚠️ Failed to persist meal log to server: $e');
      }

      if (!_mounted) return;
      _loadTodayLogs();
    } catch (e, stack) {
      _setState(AsyncValue.error(e, stack));
    }
  }

  Future<void> deleteLog(String id) async {
    try {
      await _service.deleteLog(id);
      if (!_mounted) return;
      _loadTodayLogs();
    } catch (e, stack) {
      _setState(AsyncValue.error(e, stack));
    }
  }

  Future<void> clearTodayLogs() async {
    try {
      await _service.clearTodayLogs();
      if (!_mounted) return;
      _loadTodayLogs();
    } catch (e, stack) {
      _setState(AsyncValue.error(e, stack));
    }
  }

  Future<void> clearAllData() async {
    try {
      await _service.clearAllLogs();
      if (!_mounted) return;
      _loadTodayLogs();
    } catch (e, stack) {
      _setState(AsyncValue.error(e, stack));
    }
  }

  void refresh() {
    _loadTodayLogs();
  }

  Future<void> syncFromBackend() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      await _service.init(user.id);
      if (!_mounted) return;

      await _syncFromBackend();
      if (!_mounted) return;

      _loadTodayLogs();
    } catch (e, stack) {
      _setState(AsyncValue.error(e, stack));
    }
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
