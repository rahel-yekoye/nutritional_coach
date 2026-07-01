import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ethiopian_food_app/core/models/food_model.dart';

class CategoryExplorerWidget extends StatelessWidget {
  final List<CategoryModel> categories;

  const CategoryExplorerWidget({
    super.key,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    // Only show top 6 categories on dashboard
    final displayCategories = categories.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Category Explorer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/categories'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: displayCategories.length,
            itemBuilder: (context, index) {
              final category = displayCategories[index];
              return _CategoryCard(
                category: category,
                index: index,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final int index;

  const _CategoryCard({
    required this.category,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(index);
    final icon = _getCategoryIcon(category.name);

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(
            '/category/${Uri.encodeComponent(category.name)}',
            extra: category.foodCount,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
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

  Color _getCategoryColor(int index) {
    final colors = [
      Colors.orange,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.blue,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }
}
