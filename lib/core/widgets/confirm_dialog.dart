import 'package:flutter/material.dart';

/// Shows a modal confirmation dialog and returns `true` if the user confirms,
/// `false` if they cancel, and `null` if the dialog is dismissed via barrier.
///
/// Example:
/// ```dart
/// final confirmed = await showConfirmDialog(
///   context,
///   title: 'Delete Patient',
///   message: 'This action cannot be undone. Are you sure?',
///   isDangerous: true,
/// );
/// if (confirmed == true) { ... }
/// ```
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDangerous = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDangerous: isDangerous,
    ),
  );
  return result ?? false;
}

// ── Private dialog widget ────────────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDangerous,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDangerous;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confirmColor = isDangerous
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: isDangerous
          ? Icon(Icons.warning_amber_rounded, color: confirmColor, size: 36)
          : null,
      title: Text(title),
      content: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        const SizedBox(width: 8),
        isDangerous
            ? FilledButton(
                style: FilledButton.styleFrom(backgroundColor: confirmColor),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(confirmLabel),
              )
            : FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(confirmLabel),
              ),
      ],
    );
  }
}
