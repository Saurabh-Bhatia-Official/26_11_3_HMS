import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_management/core/auth/auto_lock_service.dart';
import 'package:hospital_management/core/auth/session_service.dart';
import 'package:hospital_management/core/router/app_routes.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _passwordController = TextEditingController();
  final _focusNode = FocusNode();
  bool _obscurePassword = true;
  bool _isUnlocking = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final password = _passwordController.text;
    if (password.isEmpty) return;

    setState(() {
      _isUnlocking = true;
      _errorMessage = null;
    });

    final error = await ref.read(sessionProvider.notifier).unlock(password);

    if (!mounted) return;
    setState(() => _isUnlocking = false);

    if (error != null) {
      setState(() => _errorMessage = error);
    } else {
      ref.read(autoLockProvider.notifier).unlock();
      context.go(AppRoutes.dashboard);
    }
  }

  void _switchUser() {
    ref.read(sessionProvider.notifier).logout();
    ref.read(autoLockProvider.notifier).unlock();
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_clock_outlined,
                      size: 56,
                      color: colorScheme.primary,
                    ),
                    const Gap(16),
                    Text(
                      'Session Locked',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      user?.fullName ?? 'User',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '(${user?.role ?? "Staff"})',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Gap(24),

                    // Password input
                    TextField(
                      controller: _passwordController,
                      focusNode: _focusNode,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Enter Password to Resume',
                        prefixIcon: const Icon(Icons.password_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        errorText: _errorMessage,
                      ),
                      onSubmitted: (_) => _unlock(),
                    ),
                    const Gap(20),

                    // Unlock button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isUnlocking ? null : _unlock,
                        child: Text(_isUnlocking ? 'Unlocking…' : 'Unlock'),
                      ),
                    ),
                    const Gap(12),

                    // Switch User
                    TextButton(
                      onPressed: _switchUser,
                      child: const Text('Switch User / Sign Out'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

