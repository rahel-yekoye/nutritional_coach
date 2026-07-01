import 'dart:async';
import 'package:flutter/material.dart';

class NutritionTipsWidget extends StatefulWidget {
  final List<String> tips;

  const NutritionTipsWidget({
    super.key,
    required this.tips,
  });

  @override
  State<NutritionTipsWidget> createState() => _NutritionTipsWidgetState();
}

class _NutritionTipsWidgetState extends State<NutritionTipsWidget> {
  int _currentTipIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          _currentTipIndex = (_currentTipIndex + 1) % widget.tips.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tips.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Theme.of(context).primaryColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  widget.tips[_currentTipIndex],
                  key: ValueKey<int>(_currentTipIndex),
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
