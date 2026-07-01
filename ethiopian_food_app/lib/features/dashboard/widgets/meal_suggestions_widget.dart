import 'package:flutter/material.dart';
import 'package:ethiopian_food_app/core/models/meal_plan.dart';

class MealSuggestionsWidget extends StatelessWidget {
  final MealPlan? mealPlan;

  const MealSuggestionsWidget({
    super.key,
    this.mealPlan,
  });

  @override
  Widget build(BuildContext context) {
    if (mealPlan == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What Can I Eat Today?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildMealCard(context, 'Breakfast', mealPlan!.breakfast),
        const SizedBox(height: 8),
        _buildMealCard(context, 'Lunch', mealPlan!.lunch),
        const SizedBox(height: 8),
        _buildMealCard(context, 'Dinner', mealPlan!.dinner),
      ],
    );
  }

  Widget _buildMealCard(BuildContext context, String title, List<MealItem> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.food.foodName,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        '${item.calories.toStringAsFixed(0)} kcal',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
