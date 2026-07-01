import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ethiopian_food_app/core/models/recommendation.dart';
import 'package:ethiopian_food_app/core/models/food_model.dart';

class RecommendationWidget extends StatelessWidget {
  final List<Recommendation> recommendations;

  const RecommendationWidget({
    super.key,
    required this.recommendations,
  });

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: recommendations.map((rec) => _buildRecommendationSection(context, rec)).toList(),
    );
  }

  Widget _buildRecommendationSection(BuildContext context, Recommendation rec) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Text(
                rec.type.icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                rec.reason,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        if (rec.description != null)
          Text(
            rec.description!,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: rec.foods.length,
            itemBuilder: (context, index) {
              final food = rec.foods[index];
              return _FoodRecommendationCard(food: food);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _FoodRecommendationCard extends StatelessWidget {
  final FoodModel food;

  const _FoodRecommendationCard({required this.food});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/food/${food.foodCode}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Center(
                    child: Icon(
                      Icons.restaurant,
                      color: Theme.of(context).primaryColor.withOpacity(0.5),
                      size: 40,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.foodName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      food.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (food.nutrition != null)
                      Text(
                        '${food.nutrition!.energyKcal?.toStringAsFixed(0) ?? '0'} kcal',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
