import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ethiopian_food_app/core/api/food_service.dart';
import 'package:ethiopian_food_app/core/providers/providers.dart';
import 'package:ethiopian_food_app/widgets/food_card.dart';
import 'package:ethiopian_food_app/widgets/loading_skeleton.dart';

final categoryFoodsProvider =
    FutureProvider.family<CategoryFoodsResponse, String>((ref, categoryName) async {
  final foodService = ref.watch(foodServiceProvider);
  final response = await foodService.getCategoryFoods(categoryName);
  return response;
});

class CategoryFoodsScreen extends ConsumerWidget {
  final String categoryName;
  final int foodCount;

  const CategoryFoodsScreen({
    super.key,
    required this.categoryName,
    required this.foodCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryFoodsAsync = ref.watch(categoryFoodsProvider(categoryName));

    return Scaffold(
      body: categoryFoodsAsync.when(
        data: (response) => _buildContent(context, response),
        loading: () => _buildLoading(context),
        error: (error, stack) => _buildError(context, error, ref),
      ),
    );
  }

  Widget _buildContent(BuildContext context, CategoryFoodsResponse response) {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              response.category,
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getCategoryIcon(response.category),
                      size: 60,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${response.count} foods',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Food Count Badge
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.restaurant_menu,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Showing all ${response.count} foods in ${response.category}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Foods List
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final food = response.foods[index];
              return FoodCard(
                food: food,
                onTap: () => context.push('/food/${food.foodCode}'),
              );
            },
            childCount: response.foods.length,
          ),
        ),

        // Bottom Padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 16),
        ),
      ],
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) => const FoodCardSkeleton(),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error, WidgetRef ref) {
    String message = 'Failed to load foods';
    if (error.toString().contains('404')) {
      message = 'Category not found';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
      ),
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
                ref.invalidate(categoryFoodsProvider(categoryName));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final name = category.toLowerCase();
    if (name.contains('cereal') || name.contains('grain')) return Icons.grain;
    if (name.contains('meat') || name.contains('poultry')) return Icons.restaurant;
    if (name.contains('vegetable')) return Icons.eco;
    if (name.contains('fruit')) return Icons.apple;
    if (name.contains('fish') || name.contains('seafood')) return Icons.set_meal;
    if (name.contains('legume') || name.contains('pulse')) return Icons.nature;
    if (name.contains('dairy')) return Icons.water_drop;
    if (name.contains('beverage')) return Icons.local_drink;
    if (name.contains('spice')) return Icons.spa;
    return Icons.restaurant_menu;
  }
}
