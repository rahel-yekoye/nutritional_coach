import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ethiopian_food_app/core/models/food_model.dart';
import 'package:ethiopian_food_app/core/providers/providers.dart';

final categoriesProvider = FutureProvider<CategoryResponse>((ref) async {
  final foodService = ref.watch(foodServiceProvider);
  return await foodService.getCategories();
});

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Categories'),
        elevation: 0,
      ),
      body: categoriesAsync.when(
        data: (response) => _buildCategories(context, response.categories),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildError(context, ref),
      ),
    );
  }

  Widget _buildCategories(BuildContext context, List<CategoryModel> categories) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () {
              // Navigate to category foods screen
              context.push(
                '/category/${Uri.encodeComponent(category.name)}',
                extra: category.foodCount,
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(index).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getCategoryIcon(category.name),
                      color: _getCategoryColor(index),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${category.foodCount} foods',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          const Text('Failed to load categories'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(categoriesProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
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

  Color _getCategoryColor(int index) {
    final colors = [
      Colors.orange,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.blue,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
    ];
    return colors[index % colors.length];
  }
}
