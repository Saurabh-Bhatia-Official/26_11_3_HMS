import 'package:flutter/material.dart';

/// Shown when a list or section has no items to display.
///
/// Example:
/// ```dart
/// EmptyState(
///   icon: Icons.calendar_today_outlined,
///   message: 'No appointments today',
///   action: ElevatedButton(
///     onPressed: _book,
///     child: const Text('Book Now'),
///   ),
/// )
/// ```
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon,
    this.action,
    this.subtitle,
  });

  final String message;
  final IconData? icon;

  /// Optional supplementary text shown below [message].
  final String? subtitle;

  /// Optional action widget (e.g. a button to create a new record).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(
                icon!,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
              ),
            if (icon != null) const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.75),
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
