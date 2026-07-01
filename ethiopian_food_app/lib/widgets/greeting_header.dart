import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethiopian_food_app/core/models/user_profile.dart';
import 'package:ethiopian_food_app/core/providers/profile_provider.dart';

class GreetingHeader extends ConsumerWidget {
  final UserProfile profile;

  const GreetingHeader({
    super.key,
    required this.profile,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _getMotivation() {
    final goals = {
      NutritionGoal.loseWeight: 'Stay consistent with your weight loss journey! 💪',
      NutritionGoal.maintain: 'Keep up the great balance! ⚖️',
      NutritionGoal.gainWeight: 'Building strength takes time and nutrition! 🏋️',
      NutritionGoal.buildMuscle: 'Fuel those muscles with protein! 💪',
      NutritionGoal.healthyEating: 'Every healthy choice counts! 🥗',
    };
    return goals[profile.goal] ?? 'You\'ve got this!';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.goal.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getMotivation(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      profile.fastingMode ? Icons.restaurant_menu : Icons.restaurant,
                      size: 20,
                      color: profile.fastingMode ? Colors.green[700] : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Fasting Mode',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: profile.fastingMode ? Colors.green[700] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Switch.adaptive(
                  value: profile.fastingMode,
                  onChanged: (value) {
                    ref.read(profileProvider.notifier).toggleFastingMode();
                  },
                  activeColor: Colors.green[700],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
