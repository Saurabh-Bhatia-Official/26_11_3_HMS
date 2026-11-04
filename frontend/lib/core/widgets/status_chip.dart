import 'package:flutter/material.dart';

/// A compact, coloured status chip used for appointment, bed, invoice, etc.
///
/// If [color] is not provided, a colour is automatically derived from [label]
/// using a common status → colour mapping.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.color,
    this.textColor,
  });

  final String label;

  /// Background colour. Inferred from [label] when null.
  final Color? color;

  /// Foreground / text colour. Inferred when null.
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? _bgForLabel(label);
    final fg = textColor ?? _fgForBg(bg);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
      ),
    );
  }

  // ── Colour mapping ─────────────────────────────────────────────────────────

  static Color _bgForLabel(String label) {
    switch (label.toLowerCase().trim()) {
      // Appointment statuses
      case 'scheduled':
      case 'booked':
        return const Color(0xFFE3F2FD);
      case 'confirmed':
        return const Color(0xFFE8F5E9);
      case 'checked in':
      case 'in progress':
        return const Color(0xFFFFF3E0);
      case 'completed':
      case 'done':
        return const Color(0xFFE8F5E9);
      case 'cancelled':
      case 'no show':
        return const Color(0xFFFFEBEE);
      case 'waiting':
        return const Color(0xFFFFF9C4);

      // Bed statuses
      case 'available':
      case 'vacant':
        return const Color(0xFFE8F5E9);
      case 'occupied':
        return const Color(0xFFFFEBEE);
      case 'cleaning':
      case 'housekeeping':
        return const Color(0xFFFFF3E0);
      case 'maintenance':
        return const Color(0xFFF3E5F5);
      case 'reserved':
        return const Color(0xFFE3F2FD);

      // Invoice statuses
      case 'paid':
      case 'settled':
        return const Color(0xFFE8F5E9);
      case 'partial':
      case 'partially paid':
        return const Color(0xFFFFF9C4);
      case 'pending':
      case 'unpaid':
        return const Color(0xFFFFEBEE);
      case 'overdue':
        return const Color(0xFFFFCDD2);
      case 'draft':
        return const Color(0xFFF5F5F5);

      // Lab statuses
      case 'ordered':
        return const Color(0xFFE3F2FD);
      case 'sample collected':
        return const Color(0xFFFFF3E0);
      case 'processing':
        return const Color(0xFFFFF9C4);
      case 'resulted':
      case 'reported':
        return const Color(0xFFE8F5E9);
      case 'abnormal':
      case 'critical':
        return const Color(0xFFFFEBEE);

      // IPD statuses
      case 'admitted':
        return const Color(0xFFE3F2FD);
      case 'discharged':
        return const Color(0xFFE8F5E9);

      default:
        return const Color(0xFFF5F5F5);
    }
  }

  static Color _fgForBg(Color bg) {
    // Use luminance to decide whether to use dark or light text.
    return bg.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
  }
}
