import 'package:hive_flutter/hive_flutter.dart';
import 'package:ethiopian_food_app/core/models/nutrition_log.dart';
import 'package:ethiopian_food_app/core/models/food_model.dart';

class NutritionService {
  static const String _boxName = 'nutritionLogs';

  Box<NutritionLog>? _box;

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<NutritionLog>(_boxName);
    } else {
      _box = Hive.box<NutritionLog>(_boxName);
    }
  }

  Future<void> logFood({
    required FoodModel food,
    required double servings,
  }) async {
    final log = NutritionLog.fromFood(
      food: food,
      servings: servings,
      timestamp: DateTime.now(),
    );
    await _box?.put(log.id, log);
  }

  List<NutritionLog> getTodayLogs() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      return _box?.values
              .whereType<NutritionLog>()
              .where((log) =>
                  log.timestamp.isAfter(startOfDay) &&
                  log.timestamp.isBefore(endOfDay))
              .toList() ??
          [];
    } catch (e) {
      print('Error reading logs from Hive: $e');
      return [];
    }
  }

  List<NutritionLog> getLogsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      return _box?.values
              .whereType<NutritionLog>()
              .where((log) =>
                  log.timestamp.isAfter(startOfDay) &&
                  log.timestamp.isBefore(endOfDay))
              .toList() ??
          [];
    } catch (e) {
      print('Error reading logs for date: $e');
      return [];
    }
  }

  DailyNutritionSummary getTodaySummary() {
    final logs = getTodayLogs();
    return DailyNutritionSummary.fromLogs(logs, DateTime.now());
  }

  DailyNutritionSummary getSummaryForDate(DateTime date) {
    final logs = getLogsForDate(date);
    return DailyNutritionSummary.fromLogs(logs, date);
  }

  Future<void> deleteLog(String id) async {
    await _box?.delete(id);
  }

  Future<void> clearTodayLogs() async {
    final logs = getTodayLogs();
    for (final log in logs) {
      await deleteLog(log.id);
    }
  }

  Future<void> clearAllLogs() async {
    await _box?.clear();
  }

  Stream<BoxEvent> watchLogs() {
    return _box?.watch() ?? const Stream.empty();
  }

  Map<String, int> getTopCategories({int limit = 5}) {
    final logs = getTodayLogs();
    final categoryCount = <String, int>{};

    for (final log in logs) {
      categoryCount[log.category] = (categoryCount[log.category] ?? 0) + 1;
    }

    final sorted = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sorted.take(limit));
  }
}
