import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_management/core/auth/session_service.dart';
import 'package:hospital_management/core/providers/hospital_name_provider.dart';
import 'package:hospital_management/core/router/app_routes.dart';
import 'package:hospital_management/data/models/hms_models.dart';

enum AuthTab { signIn, createAccount }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    super.key,
    this.initialTab = AuthTab.signIn,
  });

  final AuthTab initialTab;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late AuthTab _currentTab;

  // ── Sign In Form ────────────────────────────────────────────────────────────
  final _signInFormKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  HospitalModel? _selectedHospital;

  // ── Create Account Form ─────────────────────────────────────────────────────
  final _createFormKey = GlobalKey<FormState>();
  final _regFullNameController = TextEditingController();
  final _regUsernameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();
  String _regRole = 'Doctor';
  HospitalModel? _regHospital;
  bool _regObscurePassword = true;
  bool _regObscureConfirm = true;

  bool _isSubmitting = false;

  final List<String> _availableRoles = const [
    'Doctor',
    'Nurse',
    'Receptionist',
    'Pharmacist',
    'Lab Technician',
    'Accounts',
    'Staff',
    'Admin',
  ];

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();

    _regFullNameController.dispose();
    _regUsernameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    super.dispose();
  }

  // ── Sign In Submission ──────────────────────────────────────────────────────
  Future<void> _submitSignIn() async {
    if (_isSubmitting) return;
    if (!(_signInFormKey.currentState?.validate() ?? false)) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    setState(() => _isSubmitting = true);

    final error = await ref.read(sessionProvider.notifier).login(
          username,
          password,
          selectedHospitalId: _selectedHospital?.id,
          selectedHospitalName: _selectedHospital?.name,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      if (_selectedHospital != null) {
        ref.read(activeHospitalProvider.notifier).switchHospital(_selectedHospital!);
      }
      if (mounted) context.go(AppRoutes.dashboard);
    }
  }

  // ── Create Account Submission ───────────────────────────────────────────────
  Future<void> _submitCreateAccount() async {
    if (_isSubmitting) return;
    if (!(_createFormKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final error = await ref.read(sessionProvider.notifier).registerUser(
          fullName: _regFullNameController.text.trim(),
          username: _regUsernameController.text.trim(),
          email: _regEmailController.text.trim(),
          password: _regPasswordController.text,
          role: _regRole,
          hospitalId: _regHospital?.id,
          hospitalName: _regHospital?.name,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      if (_regHospital != null) {
        ref.read(activeHospitalProvider.notifier).switchHospital(_regHospital!);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account created successfully for ${_regFullNameController.text.trim()}! Logged in as $_regRole.'),
          backgroundColor: Colors.teal.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (mounted) context.go(AppRoutes.dashboard);
    }
  }

  void _prefill(String username, String password) {
    setState(() {
      _usernameController.text = username;
      _passwordController.text = password;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hospitalsAsync = ref.watch(allHospitalsProvider);
    final activeHospital = ref.watch(activeHospitalProvider);

    final hospitals = hospitalsAsync.valueOrNull ?? [];

    // Ensure default selected hospital
    if (hospitals.isNotEmpty) {
      _selectedHospital ??= activeHospital ?? hospitals.first;
      _regHospital ??= _selectedHospital ?? hospitals.first;
    }

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── CareSync Brand Logo ──────────────────────────────────
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/caresync_logo.png',
                          height: 88,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.local_hospital_rounded,
                              size: 40,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Gap(12),

                    // ── App Header ───────────────────────────────────────────
                    Text(
                      'CareSync',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Gap(2),
                    Text(
                      'Connecting Care. Simplifying Healthcare.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Gap(22),

                    // ── Segmented Tab Switcher (Sign In vs Create Account) ───
                    SegmentedButton<AuthTab>(
                      segments: const [
                        ButtonSegment(
                          value: AuthTab.signIn,
                          icon: Icon(Icons.login_rounded, size: 18),
                          label: Text('Sign In', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        ButtonSegment(
                          value: AuthTab.createAccount,
                          icon: Icon(Icons.person_add_rounded, size: 18),
                          label: Text('Create Account', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                      selected: {_currentTab},
                      onSelectionChanged: (newSelection) {
                        setState(() => _currentTab = newSelection.first);
                      },
                    ),
                    const Gap(22),

                    // ── Tab View Content ─────────────────────────────────────
                    if (_currentTab == AuthTab.signIn)
                      _buildSignInForm(context, colorScheme, textTheme, hospitals)
                    else
                      _buildCreateAccountForm(context, colorScheme, textTheme, hospitals),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Sign In View ────────────────────────────────────────────────────────────
  Widget _buildSignInForm(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    List<HospitalModel> hospitals,
  ) {
    return Form(
      key: _signInFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hospital Selector ──────────────────────────────────────────────
          if (hospitals.isNotEmpty) ...[
            DropdownButtonFormField<HospitalModel>(
              value: hospitals.any((h) => h.id == _selectedHospital?.id)
                  ? hospitals.firstWhere((h) => h.id == _selectedHospital?.id)
                  : hospitals.first,
              decoration: const InputDecoration(
                labelText: 'Select Hospital / Branch',
                prefixIcon: Icon(Icons.local_hospital_outlined),
                helperText: 'Branch to access for this work session',
              ),
              items: hospitals.map((h) {
                return DropdownMenuItem(
                  value: h,
                  child: Text(
                    h.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedHospital = val);
              },
            ),
            const Gap(16),
          ],

          // ── Username Field ─────────────────────────────────────────────────
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              hintText: 'e.g. admin or staff ID',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            textInputAction: TextInputAction.next,
            autocorrect: false,
            onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Username is required';
              }
              return null;
            },
          ),
          const Gap(16),

          // ── Password Field ─────────────────────────────────────────────────
          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              ),
            ),
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitSignIn(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              return null;
            },
          ),
          const Gap(22),

          // ── Submit Button ──────────────────────────────────────────────────
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submitSignIn,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.login_rounded),
            label: Text(
              _isSubmitting ? 'Signing in…' : 'Sign In',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const Gap(20),

          // ── Switch to Create Account Link ──────────────────────────────────
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _currentTab = AuthTab.createAccount),
              icon: const Icon(Icons.person_add_alt_1, size: 16),
              label: const Text("Don't have an account? Create an Account"),
            ),
          ),
          const Gap(16),

          // ── Demo credentials selector ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.badge_outlined, size: 16, color: colorScheme.primary),
                    const Gap(6),
                    Text(
                      'Demo Staff Credentials (Click to prefill):',
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('Super Admin', style: TextStyle(fontSize: 11)),
                      onPressed: () => _prefill('superadmin', 'SuperAdmin@1234'),
                    ),
                    ActionChip(
                      label: const Text('Admin', style: TextStyle(fontSize: 11)),
                      onPressed: () => _prefill('admin', 'Admin@1234'),
                    ),
                    ActionChip(
                      label: const Text('Doctor', style: TextStyle(fontSize: 11)),
                      onPressed: () => _prefill('doctor', 'Doctor@1234'),
                    ),
                    ActionChip(
                      label: const Text('Nurse', style: TextStyle(fontSize: 11)),
                      onPressed: () => _prefill('nurse', 'Nurse@1234'),
                    ),
                    ActionChip(
                      label: const Text('Reception', style: TextStyle(fontSize: 11)),
                      onPressed: () => _prefill('reception', 'Reception@1234'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Create Account View ─────────────────────────────────────────────────────
  Widget _buildCreateAccountForm(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    List<HospitalModel> hospitals,
  ) {
    return Form(
      key: _createFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hospital Selector ──────────────────────────────────────────────
          if (hospitals.isNotEmpty) ...[
            DropdownButtonFormField<HospitalModel>(
              value: hospitals.any((h) => h.id == _regHospital?.id)
                  ? hospitals.firstWhere((h) => h.id == _regHospital?.id)
                  : hospitals.first,
              decoration: const InputDecoration(
                labelText: 'Select Hospital / Branch *',
                prefixIcon: Icon(Icons.domain_rounded),
                helperText: 'Your account will be registered under this hospital entity',
              ),
              items: hospitals.map((h) {
                return DropdownMenuItem(
                  value: h,
                  child: Text(
                    h.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                );
              }).toList(),
              validator: (val) => val == null ? 'Please select a hospital' : null,
              onChanged: (val) {
                if (val != null) setState(() => _regHospital = val);
              },
            ),
            const Gap(14),
          ],

          // ── Full Name Field ────────────────────────────────────────────────
          TextFormField(
            controller: _regFullNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name *',
              hintText: 'e.g. Dr. Sarah Jenkins',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Full name is required';
              }
              return null;
            },
          ),
          const Gap(14),

          // ── Username Field ─────────────────────────────────────────────────
          TextFormField(
            controller: _regUsernameController,
            decoration: const InputDecoration(
              labelText: 'Username *',
              hintText: 'e.g. sjenkins',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            textInputAction: TextInputAction.next,
            autocorrect: false,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Username is required';
              }
              if (value.trim().contains(' ')) {
                return 'Username cannot contain spaces';
              }
              if (value.trim().length < 3) {
                return 'Username must be at least 3 characters';
              }
              return null;
            },
          ),
          const Gap(14),

          // ── Email Field ────────────────────────────────────────────────────
          TextFormField(
            controller: _regEmailController,
            decoration: const InputDecoration(
              labelText: 'Email Address *',
              hintText: 'e.g. sjenkins@caresync.health',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email address is required';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const Gap(14),

          // ── Role Selector Dropdown ─────────────────────────────────────────
          DropdownButtonFormField<String>(
            value: _regRole,
            decoration: const InputDecoration(
              labelText: 'Assigned Role *',
              prefixIcon: Icon(Icons.security_outlined),
            ),
            items: _availableRoles.map((role) {
              return DropdownMenuItem(
                value: role,
                child: Text(role, style: const TextStyle(fontWeight: FontWeight.w500)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _regRole = val);
            },
          ),
          const Gap(14),

          // ── Password Field ─────────────────────────────────────────────────
          TextFormField(
            controller: _regPasswordController,
            decoration: InputDecoration(
              labelText: 'Password *',
              hintText: 'At least 6 characters',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(_regObscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _regObscurePassword = !_regObscurePassword),
                tooltip: _regObscurePassword ? 'Show password' : 'Hide password',
              ),
            ),
            obscureText: _regObscurePassword,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const Gap(14),

          // ── Confirm Password Field ─────────────────────────────────────────
          TextFormField(
            controller: _regConfirmPasswordController,
            decoration: InputDecoration(
              labelText: 'Confirm Password *',
              prefixIcon: const Icon(Icons.lock_reset_rounded),
              suffixIcon: IconButton(
                icon: Icon(_regObscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _regObscureConfirm = !_regObscureConfirm),
                tooltip: _regObscureConfirm ? 'Show password' : 'Hide password',
              ),
            ),
            obscureText: _regObscureConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitCreateAccount(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _regPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const Gap(22),

          // ── Create Account Button ──────────────────────────────────────────
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submitCreateAccount,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.person_add_rounded),
            label: Text(
              _isSubmitting ? 'Creating Account…' : 'Create Account & Sign In',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const Gap(18),

          // ── Switch to Sign In Link ─────────────────────────────────────────
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _currentTab = AuthTab.signIn),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Already have an account? Sign In'),
            ),
          ),
        ],
      ),
    );
  }
}
