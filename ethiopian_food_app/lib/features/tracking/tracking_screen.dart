import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ethiopian_food_app/core/providers/nutrition_provider.dart';
import 'package:ethiopian_food_app/core/providers/profile_provider.dart';
import 'package:ethiopian_food_app/widgets/nutrition_progress_card.dart';

class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(todayNutritionSummaryProvider);
    final targets = ref.watch(nutritionTargetsProvider);
    final logsAsync = ref.watch(nutritionLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _showClearConfirmDialog(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(nutritionLogsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Daily Summary Card
              _buildMacroSummary(context, summary, targets),
              const SizedBox(height: 24),

              // Today's Logs
              Text(
                'Today\'s Logs',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              logsAsync.when(
                data: (logs) {
                  if (logs.isEmpty) {
                    return _buildEmptyLogs(context);
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return _buildLogItem(context, ref, log);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroSummary(BuildContext context, dynamic summary, dynamic targets) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            NutritionProgressCard(
              label: 'Calories',
              current: summary.totalCalories,
              target: targets.calories,
              unit: 'kcal',
              color: Colors.orange,
              icon: Icons.local_fire_department,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSmallMacro('Protein', summary.totalProtein, targets.protein, 'g', Colors.red),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSmallMacro('Carbs', summary.totalCarbs, targets.carbs, 'g', Colors.amber),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSmallMacro('Fat', summary.totalFat, targets.fat, 'g', Colors.purple),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallMacro(String label, double current, double target, String unit, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: target > 0 ? (current / target).clamp(0.0, 1.0) : 0,
          backgroundColor: color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        const SizedBox(height: 4),
        Text(
          '${current.toStringAsFixed(0)}/$target$unit',
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildEmptyLogs(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            Icon(Icons.no_meals, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No food logged yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, WidgetRef ref, dynamic log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Text(
            log.foodName[0].toUpperCase(),
            style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(log.foodName),
        subtitle: Text(
          '${log.servings.toStringAsFixed(1)} servings • ${log.calories.toStringAsFixed(0)} kcal',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('HH:mm').format(log.timestamp),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => ref.read(nutritionLogsProvider.notifier).deleteLog(log.id),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Today\'s Logs?'),
        content: const Text('This will delete all food entries for today. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(nutritionLogsProvider.notifier).clearTodayLogs();
              Navigator.pop(context);
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
