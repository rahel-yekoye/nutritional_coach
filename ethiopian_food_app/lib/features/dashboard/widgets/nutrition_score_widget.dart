import 'package:flutter/material.dart';
import 'package:ethiopian_food_app/core/models/nutrition_analysis.dart';

class NutritionScoreWidget extends StatelessWidget {
  final NutritionAnalysis analysis;

  const NutritionScoreWidget({
    super.key,
    required this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    final score = analysis.score;
    final overallStatus = analysis.overallStatus;
    
    Color statusColor;
    if (overallStatus == 'No meals yet') {
      statusColor = Colors.grey;
    } else if (overallStatus == 'Balanced' || overallStatus == 'Healthy') {
      statusColor = Colors.green;
    } else if (overallStatus == 'Needs Adjustment' || 
               overallStatus.contains('Surplus') || 
               overallStatus.contains('Deficit')) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
               //Stack(
               //  alignment: Alignment.center,
               //  children: [
               //    SizedBox(
               //      width: 100,
               //      height: 100,
               //      child: CircularProgressIndicator(
               //        value: score / 100,
               //        strokeWidth: 10,
               //        backgroundColor: statusColor.withValues(alpha: 0.1),
               //        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
               //      ),
               //    ),
               //    Column(
               //      mainAxisSize: MainAxisSize.min,
               //      children: [
               //        Text(
               //          '$score',
               //          style: TextStyle(
               //            fontSize: 28,
               //            fontWeight: FontWeight.bold,
               //            color: statusColor,
               //          ),
               //        ),
               //        Text(
               //          'Score',
               //          style: TextStyle(
               //            fontSize: 12,
               //            color: Colors.grey[600],
               //          ),
               //        ),
               //      ],
               //    ),
               //  ],
               //),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                     Text(
                       'Daily Nutrition',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                     ),
                     const SizedBox(height: 4),
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                       decoration: BoxDecoration(
                         color: statusColor.withValues(alpha: 0.1),
                         borderRadius: BorderRadius.circular(8),
                       ),
                       child: Text(
                         overallStatus,
                         style: TextStyle(
                           fontSize: 14,
                           color: statusColor,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                     ),
                     const SizedBox(height: 8),
                     Text(
                       _getAnalysisMessage(analysis),
                       style: TextStyle(
                         fontSize: 13,
                         color: Colors.grey[700],
                       ),
                     ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _buildMacroBreakdown(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroBreakdown(BuildContext context) {
    return Column(
      children: [
        _buildMacroRow(context, 'Calories', analysis.calories, 'kcal'),
        const SizedBox(height: 12),
        _buildMacroRow(context, 'Protein', analysis.protein, 'g'),
        const SizedBox(height: 12),
        _buildMacroRow(context, 'Fat', analysis.fat, 'g'),
        const SizedBox(height: 12),
        _buildMacroRow(context, 'Carbs', analysis.carbs, 'g'),
      ],
    );
  }

  Widget _buildMacroRow(BuildContext context, String label, MacroAnalysis macro, String unit) {
    Color statusColor;
    IconData statusIcon;
    switch (macro.status) {
      case MacroStatus.overLimit:
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        break;
      case MacroStatus.onTrack:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case MacroStatus.underTarget:
        statusColor = Colors.orange;
        statusIcon = Icons.info_outline;
        break;
    }

    final progress = macro.target > 0 ? (macro.actual / macro.target).clamp(0.0, 1.2) : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Spacer(),
            Text(
              '${macro.actual.toStringAsFixed(0)} / ${macro.target.toStringAsFixed(0)} $unit',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            const SizedBox(width: 8),
            Icon(statusIcon, color: statusColor, size: 16),
            const SizedBox(width: 4),
            Text(
              macro.status.displayName,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress > 1.0 ? 1.0 : progress,
            backgroundColor: statusColor.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  String _getAnalysisMessage(NutritionAnalysis analysis) {
    if (analysis.overallStatus == 'No meals yet') {
      return 'Log your first meal to start tracking your daily nutrition score.';
    }
    if (analysis.overallStatus == 'Balanced' || analysis.overallStatus == 'Healthy') {
      return 'Great job! You are hitting your nutritional targets.';
    }
    if (analysis.overallStatus == 'Unhealthy' || analysis.overallStatus.contains('Surplus')) {
      return 'You have exceeded some limits. Try to balance your next meals.';
    }
    return 'Focus on reaching your macro targets for better results.';
  }
}
