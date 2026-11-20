import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hospital_management/core/auth/session_service.dart';
import 'package:hospital_management/core/providers/hospital_name_provider.dart';
import 'package:hospital_management/data/models/hms_models.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hospital_management/core/auth/session_service.dart';
import 'package:hospital_management/core/providers/hospital_name_provider.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/data/models/hms_models.dart';

Future<bool> authenticateAndSwitchHospital({
  required BuildContext context,
  required WidgetRef ref,
  required HospitalModel hospital,
}) async {
  final currentUser = ref.read(currentUserProvider);
  final formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  var isSubmitting = false;
  var obscurePassword = true;
  String? errorMessage;

  final db = ref.read(appDatabaseProvider);
  final hospitalUsers = await db.hmsDao.getAllUsers(hospitalId: hospital.id);

  try {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> submit() async {
                setDialogState(() {
                  isSubmitting = true;
                  errorMessage = null;
                });
                final error = await ref.read(sessionProvider.notifier).login(
                      usernameController.text.trim(),
                      passwordController.text,
                      selectedHospitalId: hospital.id,
                      selectedHospitalName: hospital.name,
                    );
                if (!dialogContext.mounted) return;
                if (error != null) {
                  setDialogState(() {
                    isSubmitting = false;
                    errorMessage = error;
                  });
                  return;
                }

                await ref
                    .read(activeHospitalProvider.notifier)
                    .switchHospital(hospital);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, true);
                }
              }

              return AlertDialog(
                title: Row(
                  children: [
                    const Icon(Icons.swap_horiz_rounded, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Switch to ${hospital.name}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
                content: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Enter verified credentials for ${hospital.name} (${hospital.code}):',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          if (hospitalUsers.isNotEmpty) ...[
                            Text(
                              'Available Accounts in this Branch:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: hospitalUsers.take(6).map((u) {
                                final un = u['username'] as String? ?? '';
                                final role = u['role'] as String? ?? 'User';
                                return ActionChip(
                                  label: Text('$un ($role)', style: const TextStyle(fontSize: 10)),
                                  onPressed: () {
                                    setDialogState(() {
                                      usernameController.text = un;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: usernameController,
                            autofocus: true,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.person_outline, size: 20),
                              isDense: true,
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Enter a username'
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: passwordController,
                            obscureText: obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline, size: 20),
                              isDense: true,
                              suffixIcon: IconButton(
                                onPressed: () => setDialogState(
                                    () => obscurePassword = !obscurePassword),
                                icon: Icon(obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Enter a password'
                                : null,
                            onFieldSubmitted: (_) async {
                              if (!isSubmitting &&
                                  (formKey.currentState?.validate() ?? false)) {
                                await submit();
                              }
                            },
                          ),
                          if (errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              errorMessage!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel'),
                  ),
                  if (currentUser?.role == 'Super Admin')
                    TextButton.icon(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              await ref
                                  .read(activeHospitalProvider.notifier)
                                  .switchHospital(hospital);
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext, true);
                              }
                            },
                      icon: const Icon(Icons.admin_panel_settings, size: 16),
                      label: const Text('Direct Switch (Super Admin)'),
                    ),
                  FilledButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (formKey.currentState?.validate() ?? false) {
                              await submit();
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Authenticate & Switch'),
                  ),
                ],
              );
            },
          ),
        ) ??
        false;
  } finally {
    usernameController.dispose();
    passwordController.dispose();
  }
}
