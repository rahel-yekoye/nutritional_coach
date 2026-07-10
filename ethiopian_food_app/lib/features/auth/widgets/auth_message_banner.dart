import 'package:flutter/material.dart';

/// Inline auth feedback banner styled to match the app's Material 3 theme.
class AuthMessageBanner extends StatelessWidget {
  const AuthMessageBanner({
    super.key,
    required this.message,
    this.isError = true,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final backgroundColor = isError ? scheme.errorContainer : scheme.primaryContainer;
    final foregroundColor = isError ? scheme.onErrorContainer : scheme.onPrimaryContainer;
    final accentColor = isError ? scheme.error : scheme.primary;
    final icon = isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: theme.brightness == Brightness.dark ? 0.85 : 1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: foregroundColor,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
