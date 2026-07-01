import 'package:flutter/material.dart';

class MatchBadge extends StatelessWidget {
  final String matchType;

  const MatchBadge({super.key, required this.matchType});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(matchType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.color.withOpacity(0.3)),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _BadgeConfig _getConfig(String type) {
    switch (type) {
      case 'exact_name':
        return _BadgeConfig(
          label: 'EXACT',
          color: Colors.green,
        );
      case 'name_match':
        return _BadgeConfig(
          label: 'NAME',
          color: Colors.blue,
        );
      case 'keyword_match':
        return _BadgeConfig(
          label: 'KEYWORD',
          color: Colors.orange,
        );
      case 'category_match':
        return _BadgeConfig(
          label: 'CATEGORY',
          color: Colors.grey,
        );
      default:
        return _BadgeConfig(
          label: 'MATCH',
          color: Colors.grey,
        );
    }
  }
}

class _BadgeConfig {
  final String label;
  final Color color;

  _BadgeConfig({required this.label, required this.color});
}
