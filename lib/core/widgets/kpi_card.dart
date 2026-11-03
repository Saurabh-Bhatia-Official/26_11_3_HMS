import 'package:flutter/material.dart';

/// Reusable KPI (Key Performance Indicator) card for the dashboard.
///
/// Displays an icon, a large [value], a descriptive [label], and optionally
/// a [subtitle] and a trend indicator.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
    this.trend,
    this.trendLabel,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;

  /// Background / accent colour for the icon container.  Defaults to the
  /// theme's primary colour when null.
  final Color? color;

  /// Optional secondary line shown below [label].
  final String? subtitle;

  /// Positive = up-trend, negative = down-trend, null = no indicator.
  final double? trend;

  /// Short text next to the trend arrow, e.g. "vs yesterday".
  final String? trendLabel;

  /// If provided, the card becomes tappable (ripple effect).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap != null
            ? () {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  onTap?.call();
                });
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon badge ────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: accent, size: 20),
                    ),
                    if (trend != null)
                      Flexible(
                        child: _TrendBadge(trend: trend!, label: trendLabel),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // ── Value ────────────────────────────────────────────────────
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // ── Label ────────────────────────────────────────────────────
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.75),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Private trend badge ──────────────────────────────────────────────────────

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.trend, this.label});

  final double trend;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final isUp = trend >= 0;
    final color = isUp ? const Color(0xFF2E7D32) : const Color(0xFFB00020);
    final icon = isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded;
    final sign = isUp ? '+' : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 2),
        Text(
          '$sign${trend.toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
        if (label != null) ...[
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}
