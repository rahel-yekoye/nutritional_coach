import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethiopian_food_app/core/providers/dashboard_provider.dart';
import 'package:ethiopian_food_app/core/models/meal_plan.dart';

class MealPlannerScreen extends ConsumerWidget {
  const MealPlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealPlanAsync = ref.watch(dailyMealPlanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adaptive Meal Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(mealPlanProvider),
          ),
        ],
      ),
      body: mealPlanAsync.when(
        data: (plan) {
          if (plan == null) {
            return const Center(child: Text('Please create a profile first'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAdaptiveHeader(context),
                const SizedBox(height: 16),
                _buildPlanSummary(context, plan),
                const SizedBox(height: 24),
                _buildMealSection(context, 'Breakfast Suggestions', plan.breakfast),
                const SizedBox(height: 16),
                _buildMealSection(context, 'Lunch Suggestions', plan.lunch),
                const SizedBox(height: 16),
                _buildMealSection(context, 'Dinner Suggestions', plan.dinner),
                const SizedBox(height: 40),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => ref.invalidate(mealPlanProvider),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Shuffle Suggestions'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildAdaptiveHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Suggestions adapt in real-time based on your remaining daily allowance.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue[900],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSummary(BuildContext context, MealPlan plan) {
    return Card(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Daily Plan Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Calories', plan.totalCalories.toStringAsFixed(0), 'kcal'),
                _buildSummaryItem('Protein', plan.totalProtein.toStringAsFixed(0), 'g'),
                _buildSummaryItem('Carbs', plan.totalCarbs.toStringAsFixed(0), 'g'),
                _buildSummaryItem('Fat', plan.totalFat.toStringAsFixed(0), 'g'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text('$label ($unit)', style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMealSection(BuildContext context, String title, List<MealItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(item.food.foodName),
                subtitle: Text(
                  '${item.servings.toStringAsFixed(1)} servings • ${item.calories.toStringAsFixed(0)} kcal',
                ),
                trailing: Text(
                  '${item.protein.toStringAsFixed(1)}g P',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            )),
      ],
    );
  }
}
