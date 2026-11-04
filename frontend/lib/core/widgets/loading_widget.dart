import 'package:flutter/material.dart';

/// Centered loading indicator with an optional status [message].
///
/// Displays a skeleton placeholder when [useShimmer] is true, otherwise renders
/// a [CircularProgressIndicator].
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({
    super.key,
    this.message,
    this.useShimmer = false,
  });

  final String? message;

  /// When true, renders a placeholder block instead of a spinner.
  final bool useShimmer;

  @override
  Widget build(BuildContext context) {
    if (useShimmer) return const _SkeletonPlaceholder();

    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            color: theme.colorScheme.primary,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Skeleton placeholder ──────────────────────────────────────────────────────

class _SkeletonPlaceholder extends StatelessWidget {
  const _SkeletonPlaceholder();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          5,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 18,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
