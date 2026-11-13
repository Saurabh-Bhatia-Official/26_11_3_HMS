import 'package:flutter/material.dart';

/// A styled section header used in dashboard panels and list screens.
///
/// Example:
/// ```dart
/// SectionHeader(
///   title: 'Appointment Queue',
///   trailing: TextButton(onPressed: _viewAll, child: const Text('View All')),
/// )
/// ```
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding,
  });

  final String title;

  /// Optional widget shown right-aligned (e.g. a "View All" button).
  final Widget? trailing;

  /// Outer padding. Defaults to `EdgeInsets.symmetric(vertical: 12)`.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Accent bar
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );

    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 12),
      child: trailing != null
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                titleWidget,
                const SizedBox(width: 12),
                trailing!,
              ],
            )
          : titleWidget,
    );
  }
}
