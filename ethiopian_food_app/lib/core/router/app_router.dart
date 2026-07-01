import 'package:go_router/go_router.dart';
import 'package:ethiopian_food_app/features/dashboard/dashboard_screen.dart';
import 'package:ethiopian_food_app/features/onboarding/onboarding_screen.dart';
import 'package:ethiopian_food_app/features/categories/categories_screen.dart';
import 'package:ethiopian_food_app/features/categories/category_foods_screen.dart';
import 'package:ethiopian_food_app/features/compare/compare_screen.dart';
import 'package:ethiopian_food_app/features/food_detail/food_detail_screen.dart';
import 'package:ethiopian_food_app/features/search/search_screen.dart';
import 'package:ethiopian_food_app/features/tracking/tracking_screen.dart';
import 'package:ethiopian_food_app/features/meal_planner/meal_planner_screen.dart';
import 'package:ethiopian_food_app/features/dashboard/blood_group_details_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/blood-group-details',
      builder: (context, state) => const BloodGroupDetailsScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) {
        final isPicker = state.uri.queryParameters['picker'] == 'true';
        return SearchScreen(isPicker: isPicker);
      },
    ),
    GoRoute(
      path: '/food/:foodCode',
      builder: (context, state) {
        final foodCode = state.pathParameters['foodCode']!;
        return FoodDetailScreen(foodCode: foodCode);
      },
    ),
    GoRoute(
      path: '/categories',
      builder: (context, state) => const CategoriesScreen(),
    ),
    GoRoute(
      path: '/category/:categoryName',
      builder: (context, state) {
        final categoryName = Uri.decodeComponent(state.pathParameters['categoryName']!);
        final foodCount = state.extra as int? ?? 0;
        return CategoryFoodsScreen(
          categoryName: categoryName,
          foodCount: foodCount,
        );
      },
    ),
    GoRoute(
      path: '/compare',
      builder: (context, state) => const CompareScreen(foodCode1: '', foodCode2: ''),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/tracking',
      builder: (context, state) => const TrackingScreen(),
    ),
    GoRoute(
      path: '/meal-planner',
      builder: (context, state) => const MealPlannerScreen(),
    ),
  ],
);
