import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_management/core/auth/session_service.dart';
import 'package:hospital_management/core/providers/hospital_name_provider.dart';
import 'package:hospital_management/core/router/app_routes.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/data/models/hms_models.dart';

enum AuthTab { signIn, createHospital }

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

  // ── Create Hospital & Super Admin Form ──────────────────────────────────────
  final _createFormKey = GlobalKey<FormState>();
  final _hospNameController = TextEditingController();
  final _hospCodeController = TextEditingController();
  final _hospAddressController = TextEditingController();
  String _hospType = 'Multi-Specialty Hospital';

  final _adminFullNameController = TextEditingController();
  final _adminUsernameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _adminConfirmPasswordController = TextEditingController();
  bool _adminObscurePassword = true;
  bool _adminObscureConfirm = true;

  bool _isSubmitting = false;

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

    _hospNameController.dispose();
    _hospCodeController.dispose();
    _hospAddressController.dispose();

    _adminFullNameController.dispose();
    _adminUsernameController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    _adminConfirmPasswordController.dispose();
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

  // ── Create Hospital & Super Admin Submission ────────────────────────────────
  Future<void> _submitCreateHospitalAndSuperAdmin() async {
    if (_isSubmitting) return;
    if (!(_createFormKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final db = ref.read(appDatabaseProvider);
    final hospName = _hospNameController.text.trim();
    final hospCode = _hospCodeController.text.trim().toUpperCase();
    final hospAddress = _hospAddressController.text.trim();

    final adminUsername = _adminUsernameController.text.trim();
    final adminFullName = _adminFullNameController.text.trim();
    final adminEmail = _adminEmailController.text.trim();
    final adminPassword = _adminPasswordController.text;

    // 1. Verify username is available
    final isTaken = await db.isUsernameTaken(adminUsername);
    if (isTaken) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Username "$adminUsername" is already in use. Please select another.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      // 2. Insert new Hospital Entity
      final newHospital = HospitalModel(
        uuid: 'hosp-${DateTime.now().millisecondsSinceEpoch}',
        name: hospName,
        code: hospCode,
        type: _hospType,
        address: hospAddress,
        phone: '',
        email: adminEmail,
        status: 'Active',
      );
      final newHospId = await db.hmsDao.insertHospital(newHospital);
      final savedHospital = newHospital.copyWith(id: newHospId);

      // 3. Register Super Admin User
      final regError = await ref.read(sessionProvider.notifier).registerUser(
            fullName: adminFullName,
            username: adminUsername,
            email: adminEmail,
            password: adminPassword,
            role: 'Super Admin',
            hospitalId: newHospId,
            hospitalName: hospName,
          );

      if (regError != null) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(regError),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // 4. Set active hospital and refresh
      ref.invalidate(allHospitalsProvider);
      ref.read(activeHospitalProvider.notifier).switchHospital(savedHospital);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hospital "$hospName" created! Super Admin account "$adminUsername" is ready. You can now add other staff via Settings.'),
          backgroundColor: Colors.teal.shade800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );

      context.go(AppRoutes.dashboard);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to register hospital: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
    }

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
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

                    // ── Segmented Tab Switcher ───────────────────────────────
                    SegmentedButton<AuthTab>(
                      segments: const [
                        ButtonSegment(
                          value: AuthTab.signIn,
                          icon: Icon(Icons.login_rounded, size: 18),
                          label: Text('Sign In', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        ButtonSegment(
                          value: AuthTab.createHospital,
                          icon: Icon(Icons.domain_add_rounded, size: 18),
                          label: Text('Create Hospital', style: TextStyle(fontWeight: FontWeight.w600)),
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
                      _buildCreateHospitalForm(context, colorScheme, textTheme),
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
          const Gap(16),

          // ── Switch to Create Hospital Link ─────────────────────────────────
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _currentTab = AuthTab.createHospital),
              icon: const Icon(Icons.domain_add_rounded, size: 16),
              label: const Text('Register New Hospital (Super Admin)'),
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

  // ── Create Hospital & Super Admin View ──────────────────────────────────────
  Widget _buildCreateHospitalForm(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Form(
      key: _createFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Information Note ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: 20, color: colorScheme.primary),
                const Gap(8),
                Expanded(
                  child: Text(
                    'Creating a hospital registers the master Super Admin account. Other staff (Doctors, Nurses, Receptionists, Pharmacists) are provisioned securely through Super Admin Settings.',
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onPrimaryContainer),
                  ),
                ),
              ],
            ),
          ),
          const Gap(16),

          // ── Hospital Section Header ────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.domain_rounded, size: 18, color: colorScheme.primary),
              const Gap(6),
              Text(
                'Hospital Information',
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
            ],
          ),
          const Divider(height: 16),

          // ── Hospital Name ──────────────────────────────────────────────────
          TextFormField(
            controller: _hospNameController,
            decoration: const InputDecoration(
              labelText: 'Hospital / Facility Name *',
              hintText: 'e.g. St. Jude Memorial Hospital',
              prefixIcon: Icon(Icons.local_hospital_outlined),
            ),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Hospital name is required';
              return null;
            },
          ),
          const Gap(12),

          // ── Hospital Code & Facility Type ──────────────────────────────────
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _hospCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Branch Code *',
                    hintText: 'e.g. SJH-CENTRAL',
                    prefixIcon: Icon(Icons.tag),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Code required';
                    return null;
                  },
                ),
              ),
              const Gap(12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _hospType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Multi-Specialty Hospital', child: Text('Multi-Specialty')),
                    DropdownMenuItem(value: 'General Hospital', child: Text('General Hospital')),
                    DropdownMenuItem(value: 'Clinic / Outpatient', child: Text('Clinic')),
                    DropdownMenuItem(value: 'Trauma & Emergency', child: Text('Trauma Center')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _hospType = val);
                  },
                ),
              ),
            ],
          ),
          const Gap(12),

          // ── Hospital Address ───────────────────────────────────────────────
          TextFormField(
            controller: _hospAddressController,
            decoration: const InputDecoration(
              labelText: 'Address & City',
              hintText: 'e.g. 100 Medical Blvd, City Center',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            textInputAction: TextInputAction.next,
          ),
          const Gap(20),

          // ── Super Admin Section Header ─────────────────────────────────────
          Row(
            children: [
              Icon(Icons.admin_panel_settings_outlined, size: 18, color: colorScheme.primary),
              const Gap(6),
              Text(
                'Super Admin Account Credentials',
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
            ],
          ),
          const Divider(height: 16),

          // ── Super Admin Full Name ──────────────────────────────────────────
          TextFormField(
            controller: _adminFullNameController,
            decoration: const InputDecoration(
              labelText: 'Super Admin Full Name *',
              hintText: 'e.g. Dr. Arthur Vance',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Full name is required';
              return null;
            },
          ),
          const Gap(12),

          // ── Super Admin Username & Email ───────────────────────────────────
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _adminUsernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username *',
                    hintText: 'e.g. arthur_superadmin',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Username required';
                    if (value.trim().contains(' ')) return 'No spaces allowed';
                    if (value.trim().length < 3) return 'Min 3 chars';
                    return null;
                  },
                ),
              ),
              const Gap(12),
              Expanded(
                child: TextFormField(
                  controller: _adminEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Official Email *',
                    hintText: 'admin@stjude.org',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Email required';
                    if (!value.contains('@') || !value.contains('.')) return 'Invalid email';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const Gap(12),

          // ── Super Admin Password ───────────────────────────────────────────
          TextFormField(
            controller: _adminPasswordController,
            decoration: InputDecoration(
              labelText: 'Super Admin Password *',
              hintText: 'Min 6 characters',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(_adminObscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _adminObscurePassword = !_adminObscurePassword),
                tooltip: _adminObscurePassword ? 'Show password' : 'Hide password',
              ),
            ),
            obscureText: _adminObscurePassword,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password is required';
              if (value.length < 6) return 'At least 6 characters required';
              return null;
            },
          ),
          const Gap(12),

          // ── Confirm Password ───────────────────────────────────────────────
          TextFormField(
            controller: _adminConfirmPasswordController,
            decoration: InputDecoration(
              labelText: 'Confirm Password *',
              prefixIcon: const Icon(Icons.lock_reset_rounded),
              suffixIcon: IconButton(
                icon: Icon(_adminObscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _adminObscureConfirm = !_adminObscureConfirm),
                tooltip: _adminObscureConfirm ? 'Show password' : 'Hide password',
              ),
            ),
            obscureText: _adminObscureConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitCreateHospitalAndSuperAdmin(),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please confirm password';
              if (value != _adminPasswordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const Gap(22),

          // ── Submit Button ──────────────────────────────────────────────────
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submitCreateHospitalAndSuperAdmin,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.domain_add_rounded),
            label: Text(
              _isSubmitting ? 'Registering Hospital & Admin…' : 'Register Hospital & Super Admin',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const Gap(16),

          // ── Switch to Sign In Link ─────────────────────────────────────────
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _currentTab = AuthTab.signIn),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to Sign In'),
            ),
          ),
        ],
      ),
    );
  }
}
