import 'package:hive_flutter/hive_flutter.dart';
import '../core/models/nutrition_log.dart';
import '../core/models/food_model.dart';
import '../core/hive_setup.dart';

class NutritionService {
  static const String _boxPrefix = 'nutritionLogs';

  Box<NutritionLog>? _box;
  String? _currentUserId;

  Future<void> init(String userId) async {
    if (_currentUserId == userId && _box != null && _box!.isOpen) {
      return; // Already initialized for this user
    }
    
    // Close previous box if open
    await close();
    
    _currentUserId = userId;
    _box = await HiveSetup.openUserBox<NutritionLog>(_boxPrefix, userId);
  }

  Future<void> logFood({
    required FoodModel food,
    required double servings,
  }) async {
    if (_box == null) {
      throw StateError('NutritionService not initialized. Call init() first.');
    }
    
    final log = NutritionLog.fromFood(
      food: food,
      servings: servings,
      timestamp: DateTime.now(),
    );
    await _box!.put(log.id, log);
  }

  List<NutritionLog> getTodayLogs() {
    if (_box == null) return [];
    
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _box!.values
        .where((log) =>
            log.timestamp.isAfter(startOfDay) &&
            log.timestamp.isBefore(endOfDay))
        .toList();
  }

  List<NutritionLog> getLogsForDate(DateTime date) {
    if (_box == null) return [];
    
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _box!.values
        .where((log) =>
            log.timestamp.isAfter(startOfDay) &&
            log.timestamp.isBefore(endOfDay))
        .toList();
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
    if (_box == null) return;
    await _box!.delete(id);
  }

  Future<void> clearTodayLogs() async {
    if (_box == null) return;
    final logs = getTodayLogs();
    for (final log in logs) {
      await deleteLog(log.id);
    }
  }

  Future<void> clearAllLogs() async {
    if (_box == null) return;
    await _box!.clear();
  }

  Stream<BoxEvent> watchLogs() {
    if (_box == null) return const Stream.empty();
    return _box!.watch();
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

  Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
      _box = null;
      _currentUserId = null;
    }
  }
}