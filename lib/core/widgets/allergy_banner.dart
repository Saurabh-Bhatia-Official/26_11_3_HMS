import 'package:flutter/material.dart';

/// A prominent red banner listing a patient's known allergies.
///
/// Always rendered even when [allergies] is empty so callers can
/// unconditionally include it — it hides itself when the list is empty.
///
/// Example:
/// ```dart
/// AllergyBanner(allergies: patient.allergies)
/// ```
class AllergyBanner extends StatelessWidget {
  const AllergyBanner({
    super.key,
    required this.allergies,
  });

  /// List of allergy strings to display.  The widget hides itself when empty.
  final List<String> allergies;

  @override
  Widget build(BuildContext context) {
    if (allergies.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        border: Border.all(color: const Color(0xFFEF9A9A)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFB71C1C),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KNOWN ALLERGIES',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFFB71C1C),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: allergies.map((a) => _AllergyChip(label: a)).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AllergyChip extends StatelessWidget {
  const _AllergyChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFCDD2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEF9A9A)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFFB71C1C),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
