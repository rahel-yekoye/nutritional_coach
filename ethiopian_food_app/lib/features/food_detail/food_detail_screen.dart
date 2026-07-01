import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethiopian_food_app/core/api/api_client.dart';
import 'package:ethiopian_food_app/core/models/food_model.dart';
import 'package:ethiopian_food_app/core/providers/providers.dart';
import 'package:ethiopian_food_app/core/providers/nutrition_provider.dart';
import 'package:ethiopian_food_app/widgets/loading_skeleton.dart';
import 'package:ethiopian_food_app/widgets/nutrition_card.dart';

final foodDetailProvider =
    FutureProvider.family<FoodModel, String>((ref, foodCode) async {
  final foodService = ref.watch(foodServiceProvider);
  return await foodService.getFoodDetails(foodCode);
});

class FoodDetailScreen extends ConsumerWidget {
  final String foodCode;

  const FoodDetailScreen({super.key, required this.foodCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodAsync = ref.watch(foodDetailProvider(foodCode));

    return foodAsync.when(
      data: (food) => Scaffold(
        body: _buildContent(context, food),
        bottomNavigationBar: _buildBottomBar(context, ref, food),
      ),
      loading: () => _buildLoading(),
      error: (error, stack) => _buildError(context, error, ref),
    );
  }

  Widget _buildContent(BuildContext context, FoodModel food) {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              food.foodName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black45,
                    offset: Offset(0, 1),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.restaurant,
                  size: 80,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ),

        // Content
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Amharic Name
              if (food.foodNameAmharic != null) ...[
                Text(
                  food.foodNameAmharic!,
                  style: TextStyle(
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],

              // Category Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.category, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              food.category,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Nutrition Header
              const Text(
                'Nutritional Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'per 100g',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),

              // Nutrition Cards Grid
              if (food.nutrition != null) ...[
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  children: [
                    NutritionCard(
                      label: 'Energy',
                      value: '${food.nutrition!.energyKcal?.toStringAsFixed(0) ?? '-'} kcal',
                      icon: Icons.local_fire_department,
                      color: Colors.orange,
                    ),
                    NutritionCard(
                      label: 'Protein',
                      value: '${food.nutrition!.proteinG?.toStringAsFixed(1) ?? '-'} g',
                      icon: Icons.egg,
                      color: Colors.red,
                    ),
                    NutritionCard(
                      label: 'Fat',
                      value: '${food.nutrition!.fatG?.toStringAsFixed(1) ?? '-'} g',
                      icon: Icons.water_drop,
                      color: Colors.amber,
                    ),
                    NutritionCard(
                      label: 'Carbs',
                      value: '${food.nutrition!.carbsG?.toStringAsFixed(1) ?? '-'} g',
                      icon: Icons.grain,
                      color: Colors.brown,
                    ),
                    NutritionCard(
                      label: 'Fiber',
                      value: '${food.nutrition!.fiberG?.toStringAsFixed(1) ?? '-'} g',
                      icon: Icons.eco,
                      color: Colors.green,
                    ),
                    NutritionCard(
                      label: 'Water',
                      value: '${food.nutrition!.waterG?.toStringAsFixed(1) ?? '-'} g',
                      icon: Icons.water,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Keywords
              if (food.keywords != null && food.keywords!.isNotEmpty) ...[
                const Text(
                  'Keywords',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: food.keywords!.map((keyword) {
                    return Chip(
                      label: Text(keyword),
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, WidgetRef ref, FoodModel food) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: () => _showServingsDialog(context, ref, food),
          icon: const Icon(Icons.add),
          label: const Text('Add to Today'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ),
    );
  }

  void _showServingsDialog(BuildContext context, WidgetRef ref, FoodModel food) {
    double servings = 1.0;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add to Today'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(food.foodName),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (servings > 0.5) {
                        setState(() {
                          servings -= 0.5;
                        });
                      }
                    },
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${servings.toStringAsFixed(1)} servings',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '(${(servings * 100).toStringAsFixed(0)}g)',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (servings < 10) {
                        setState(() {
                          servings += 0.5;
                        });
                      }
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (food.nutrition != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildNutrientRow(
                        'Calories',
                        '${((food.nutrition!.energyKcal ?? 0) * servings).toStringAsFixed(0)} kcal',
                      ),
                      _buildNutrientRow(
                        'Protein',
                        '${((food.nutrition!.proteinG ?? 0) * servings).toStringAsFixed(1)} g',
                      ),
                      _buildNutrientRow(
                        'Carbs',
                        '${((food.nutrition!.carbsG ?? 0) * servings).toStringAsFixed(1)} g',
                      ),
                      _buildNutrientRow(
                        'Fat',
                        '${((food.nutrition!.fatG ?? 0) * servings).toStringAsFixed(1)} g',
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await ref.read(nutritionLogsProvider.notifier).logFood(
                      food: food,
                      servings: servings,
                    );
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${food.foodName} added to today!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error, WidgetRef ref) {
    String message = 'Failed to load food details';
    if (error is ApiException) {
      message = error.message;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(foodDetailProvider(foodCode));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
