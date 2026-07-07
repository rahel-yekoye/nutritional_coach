import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ethiopian_food_app/core/providers/nutrition_provider.dart';
import 'package:ethiopian_food_app/core/providers/dashboard_provider.dart';
import 'package:ethiopian_food_app/core/providers/profile_provider.dart';
import 'package:ethiopian_food_app/widgets/greeting_header.dart';
import 'package:ethiopian_food_app/features/dashboard/widgets/recommendation_widget.dart';
import 'package:ethiopian_food_app/features/dashboard/widgets/nutrition_score_widget.dart';
import 'package:ethiopian_food_app/features/dashboard/widgets/quick_actions_widget.dart';
import 'package:ethiopian_food_app/features/dashboard/widgets/blood_group_insights_widget.dart';
import 'package:ethiopian_food_app/features/dashboard/widgets/recent_activity_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final recommendationsAsync = ref.watch(recommendationsProvider);
    final analysis = ref.watch(nutritionAnalysisProvider);
    final nutrientFocus = ref.watch(nutrientFocusProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Nutrition Coach',
          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle_outlined, color: Theme.of(context).iconTheme.color),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(todayNutritionSummaryProvider);
              ref.invalidate(allFoodsProvider);
              ref.invalidate(mealPlanProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Greeting Card (contains Goal & Fasting Toggle)
                  GreetingHeader(profile: profile),
                  const SizedBox(height: 16),

                  // 2. Nutrition Analysis (Score, Calories, Macro Status)
                  NutritionScoreWidget(analysis: analysis),
                  const SizedBox(height: 16),

                  // 3. Blood Type Focus
                  BloodGroupInsightsWidget(
                    bloodGroup: profile.bloodGroup,
                    nutrientFocus: nutrientFocus,
                  ),
                  const SizedBox(height: 24),

                  // 4. Quick Actions
                  const QuickActionsWidget(),
                  const SizedBox(height: 24),

                  

                  // AI Recommendation (Optional/Secondary on Home)
                  _buildSectionHeader(context, 'Coach Recommendation'),
                  const SizedBox(height: 8),
                  recommendationsAsync.when(
                    data: (recs) => RecommendationWidget(recommendations: recs),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => const Text('Failed to load recommendations'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_ind_outlined,
              size: 100,
              color: Theme.of(context).primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              "Let's build your nutrition plan",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create a profile to get personalized Ethiopian food recommendations and track your nutrition.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.push('/profile'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Create Profile',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      onTap: (index) {
        switch (index) {
          case 0:
            break;
          case 1:
            context.push('/search');
            break;
          case 2:
            context.push('/categories');
            break;
          case 3:
            context.push('/tracking');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.category),
          label: 'Categories',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'Logs',
        ),
      ],
    );
  }
}
