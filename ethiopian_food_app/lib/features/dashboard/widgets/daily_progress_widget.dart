import 'package:flutter/material.dart';
import 'package:ethiopian_food_app/widgets/nutrition_progress_card.dart';
import 'package:ethiopian_food_app/core/models/nutrition_log.dart';
import 'package:ethiopian_food_app/core/models/nutrition_targets.dart';

class DailyProgressWidget extends StatelessWidget {
  final DailyNutritionSummary summary;
  final NutritionTargets targets;

  const DailyProgressWidget({
    super.key,
    required this.summary,
    required this.targets,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        // Large screen (Desktop/Tablet): 4 cards in a row
        if (width > 768) {
          return Row(
            children: [
              _buildExpandedCard('Calories', summary.totalCalories, targets.calories, 'kcal', Colors.orange, Icons.local_fire_department),
              const SizedBox(width: 12),
              _buildExpandedCard('Protein', summary.totalProtein, targets.protein, 'g', Colors.red, Icons.egg),
              const SizedBox(width: 12),
              _buildExpandedCard('Carbs', summary.totalCarbs, targets.carbs, 'g', Colors.amber, Icons.bakery_dining),
              const SizedBox(width: 12),
              _buildExpandedCard('Fat', summary.totalFat, targets.fat, 'g', Colors.purple, Icons.water_drop),
            ],
          );
        }
        
        // Medium screen (Large Phones/Small Tablets): 2x2 grid
        if (width > 360) {
          return Column(
            children: [
              NutritionProgressCard(
                label: 'Calories',
                current: summary.totalCalories,
                target: targets.calories,
                unit: 'kcal',
                color: Colors.orange,
                icon: Icons.local_fire_department,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildCard('Protein', summary.totalProtein, targets.protein, 'g', Colors.red, Icons.egg)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildCard('Carbs', summary.totalCarbs, targets.carbs, 'g', Colors.amber, Icons.bakery_dining)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildCard('Fat', summary.totalFat, targets.fat, 'g', Colors.purple, Icons.water_drop)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildCard('Fiber', summary.totalFiber, targets.fiber, 'g', Colors.green, Icons.grass)),
                ],
              ),
            ],
          );
        }

        // Small screen: Single column with horizontal scroll for smaller cards
        return Column(
          children: [
            NutritionProgressCard(
              label: 'Calories',
              current: summary.totalCalories,
              target: targets.calories,
              unit: 'kcal',
              color: Colors.orange,
              icon: Icons.local_fire_department,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140, // Fixed height for horizontal scroll
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFixedCard('Protein', summary.totalProtein, targets.protein, 'g', Colors.red, Icons.egg),
                  const SizedBox(width: 12),
                  _buildFixedCard('Carbs', summary.totalCarbs, targets.carbs, 'g', Colors.amber, Icons.bakery_dining),
                  const SizedBox(width: 12),
                  _buildFixedCard('Fat', summary.totalFat, targets.fat, 'g', Colors.purple, Icons.water_drop),
                  const SizedBox(width: 12),
                  _buildFixedCard('Fiber', summary.totalFiber, targets.fiber, 'g', Colors.green, Icons.grass),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExpandedCard(String label, double current, double target, String unit, Color color, IconData icon) {
    return Expanded(
      child: NutritionProgressCard(
        label: label,
        current: current,
        target: target,
        unit: unit,
        color: color,
        icon: icon,
      ),
    );
  }

  Widget _buildCard(String label, double current, double target, String unit, Color color, IconData icon) {
    return NutritionProgressCard(
      label: label,
      current: current,
      target: target,
      unit: unit,
      color: color,
      icon: icon,
    );
  }

  Widget _buildFixedCard(String label, double current, double target, String unit, Color color, IconData icon) {
    return SizedBox(
      width: 150,
      child: NutritionProgressCard(
        label: label,
        current: current,
        target: target,
        unit: unit,
        color: color,
        icon: icon,
      ),
    );
  }
}
