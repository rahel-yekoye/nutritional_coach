import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethiopian_food_app/core/models/recommendation.dart';
import 'package:ethiopian_food_app/core/models/meal_plan.dart';
import 'package:ethiopian_food_app/core/models/food_model.dart';
import 'package:ethiopian_food_app/core/models/nutrition_analysis.dart';
import 'package:ethiopian_food_app/services/recommendation_engine.dart';
import 'package:ethiopian_food_app/services/meal_planner.dart';
import 'package:ethiopian_food_app/core/providers/providers.dart';
import 'package:ethiopian_food_app/core/providers/profile_provider.dart';
import 'package:ethiopian_food_app/core/providers/nutrition_provider.dart';

final recommendationServiceProvider = Provider<RecommendationEngine>((ref) {
  return RecommendationEngine();
});

final mealPlannerServiceProvider = Provider<MealPlannerService>((ref) {
  return MealPlannerService();
});

final allFoodsProvider = FutureProvider<List<FoodModel>>((ref) async {
  final foodService = ref.watch(foodServiceProvider);
  final categories = ['Cereals & Grains', 'Legumes & Pulses', 'Vegetables', 'Fruits', 'Meat & Poultry'];
  final allFoods = <FoodModel>[];
  
  for (final category in categories) {
    try {
      final response = await foodService.getCategoryFoods(category);
      allFoods.addAll(response.foods);
    } catch (e) {
      // Ignore errors for individual categories
    }
  }
  
  return allFoods;
});

final recommendationsProvider = Provider<AsyncValue<List<Recommendation>>>((ref) {
  final allFoodsAsync = ref.watch(allFoodsProvider);
  final profileAsync = ref.watch(profileProvider);
  final targets = ref.watch(nutritionTargetsProvider);
  final summary = ref.watch(todayNutritionSummaryProvider);
  final engine = ref.watch(recommendationServiceProvider);

  return allFoodsAsync.when(
    data: (allFoods) {
      return profileAsync.when(
        data: (profile) {
          if (profile == null) return const AsyncValue.data([]);
          final recommendations = engine.generateRecommendations(
            allFoods: allFoods,
            profile: profile,
            targets: targets,
            todaySummary: summary,
          );
          return AsyncValue.data(recommendations);
        },
        loading: () => const AsyncValue.loading(),
        error: (e, s) => AsyncValue.error(e, s),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

final mealPlanProvider = Provider<AsyncValue<MealPlan?>>((ref) {
  final allFoodsAsync = ref.watch(allFoodsProvider);
  final nutritionState = ref.watch(unifiedNutritionProvider);
  final planner = ref.watch(mealPlannerServiceProvider);

  return allFoodsAsync.when(
    data: (allFoods) {
      if (allFoods.isEmpty) return const AsyncValue.data(null);
      
      final plan = planner.generateMealPlan(
        allFoods: allFoods,
        state: nutritionState,
      );
      return AsyncValue.data(plan);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

final dailyMealPlanProvider = Provider<AsyncValue<MealPlan?>>((ref) {
  return ref.watch(mealPlanProvider);
});

final nutrientFocusProvider = Provider<String>((ref) {
  final profileAsync = ref.watch(profileProvider);
  final engine = ref.watch(recommendationServiceProvider);
  return profileAsync.maybeWhen(
    data: (profile) => profile != null
        ? engine.getDailyNutrientFocus(profile.bloodGroup)
        : 'Balanced Nutrition',
    orElse: () => 'Balanced Nutrition',
  );
});

final bloodGroupAdviceProvider = Provider<String>((ref) {
  final profileAsync = ref.watch(profileProvider);
  final engine = ref.watch(recommendationServiceProvider);
  return profileAsync.maybeWhen(
    data: (profile) => profile != null
        ? engine.getBloodGroupAdvice(profile.bloodGroup)
        : '',
    orElse: () => '',
  );
});

final nutritionAnalysisProvider = Provider<NutritionAnalysis>((ref) {
  final state = ref.watch(unifiedNutritionProvider);
  final intake = state.dailyIntake;
  final targets = state.dailyTargets;
  final hasLoggedNutrition =
      intake.calories > 0 ||
      intake.protein > 0 ||
      intake.fat > 0 ||
      intake.carbs > 0;

  MacroStatus getStatus(double actual, double target) {
    if (target == 0) return MacroStatus.onTrack;
    final ratio = actual / target;
    if (ratio > 1.1) return MacroStatus.overLimit;
    if (ratio >= 0.9) return MacroStatus.onTrack;
    return MacroStatus.underTarget;
  }

  final calAnalysis = MacroAnalysis(
    target: targets.calories,
    actual: intake.calories,
    status: getStatus(intake.calories, targets.calories),
  );

  final proteinAnalysis = MacroAnalysis(
    target: targets.protein,
    actual: intake.protein,
    status: getStatus(intake.protein, targets.protein),
  );

  final fatAnalysis = MacroAnalysis(
    target: targets.fat,
    actual: intake.fat,
    status: getStatus(intake.fat, targets.fat),
  );

  final carbsAnalysis = MacroAnalysis(
    target: targets.carbs,
    actual: intake.carbs,
    status: getStatus(intake.carbs, targets.carbs),
  );

  if (!hasLoggedNutrition) {
    return NutritionAnalysis(
      calories: calAnalysis,
      protein: proteinAnalysis,
      fat: fatAnalysis,
      carbs: carbsAnalysis,
      overallStatus: 'No meals yet',
      score: 0,
    );
  }

  final overLimitCount = [
    calAnalysis.status,
    proteinAnalysis.status,
    fatAnalysis.status,
    carbsAnalysis.status,
  ].where((s) => s == MacroStatus.overLimit).length;

  final onTrackCount = [
    calAnalysis.status,
    proteinAnalysis.status,
    fatAnalysis.status,
    carbsAnalysis.status,
  ].where((s) => s == MacroStatus.onTrack).length;
String overallStatus = '';
int score = 0;

// penalty system instead of fixed scoring
int penalty = 0;

// over limit is heavy penalty
penalty += overLimitCount * 20;

// under target is light penalty (normal when user just ate 1 meal)
final underCount = [
  calAnalysis.status,
  proteinAnalysis.status,
  fatAnalysis.status,
  carbsAnalysis.status,
].where((s) => s == MacroStatus.underTarget).length;

penalty += underCount * 8;

// convert to score
score = 100 - penalty;

// clamp
if (score < 0) score = 0;
if (score > 100) score = 100;

  // Refine overallStatus with specific labels if possible
  if (calAnalysis.status == MacroStatus.overLimit) overallStatus = 'Calorie Surplus';
  if (calAnalysis.status == MacroStatus.underTarget) overallStatus = 'Calorie Deficit';
  if (fatAnalysis.status == MacroStatus.overLimit) overallStatus = 'High Fat Intake';
  if (proteinAnalysis.status == MacroStatus.overLimit) overallStatus = 'High Protein Excess';
  
  if (overLimitCount >= 2) overallStatus = 'Unhealthy';
  if (onTrackCount == 4) overallStatus = 'Balanced';

  return NutritionAnalysis(
    calories: calAnalysis,
    protein: proteinAnalysis,
    fat: fatAnalysis,
    carbs: carbsAnalysis,
    overallStatus: overallStatus,
    score: score,
  );
});

final nutritionTipsProvider = Provider<List<String>>((ref) {
  return [
    'Pair lentils with vitamin C foods (like peppers or tomatoes) to improve iron absorption.',
    'Drink water throughout the day for better digestion.',
    'Fiber helps digestion and keeps you full for longer.',
    'Teff is naturally gluten-free and high in iron and calcium.',
    'Berbere spice mix contains antioxidants from various peppers and spices.',
    'Injera is a fermented food, which is great for your gut health.',
    'Try to include a variety of colors in your vegetable dishes.',
    'Fasting dishes like Misir Wot are excellent plant-based protein sources.',
  ];
});
