import 'package:flutter/material.dart';
import 'package:ethiopian_food_app/core/models/food_model.dart';
import 'package:ethiopian_food_app/widgets/match_badge.dart';

class FoodCard extends StatelessWidget {
  final FoodModel food;
  final VoidCallback? onTap;

  const FoodCard({
    super.key,
    required this.food,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with name and badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      food.foodName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (food.matchType != null)
                    MatchBadge(matchType: food.matchType!),
                ],
              ),
              
              // Amharic name
              if (food.foodNameAmharic != null) ...[
                const SizedBox(height: 4),
                Text(
                  food.foodNameAmharic!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Category
              Row(
                children: [
                  Icon(Icons.category, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    food.category,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              // Nutrition summary
              if (food.nutrition != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NutritionItem(
                      label: 'Energy',
                      value: '${food.nutrition!.energyKcal?.toStringAsFixed(0) ?? '-'} kcal',
                      icon: Icons.local_fire_department,
                    ),
                    _NutritionItem(
                      label: 'Protein',
                      value: '${food.nutrition!.proteinG?.toStringAsFixed(1) ?? '-'} g',
                      icon: Icons.egg,
                    ),
                    _NutritionItem(
                      label: 'Carbs',
                      value: '${food.nutrition!.carbsG?.toStringAsFixed(1) ?? '-'} g',
                      icon: Icons.grain,
                    ),
                  ],
                ),
              ],

              // Score (optional)
              if (food.score != null) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (food.score! / 30).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getScoreColor(food.score!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 20) return Colors.green;
    if (score >= 10) return Colors.orange;
    return Colors.grey;
  }
}

class _NutritionItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _NutritionItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
