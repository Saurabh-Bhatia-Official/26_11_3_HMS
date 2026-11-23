import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_management/core/auth/session_service.dart';
import 'package:hospital_management/core/auth/online_hospital_session.dart';
import 'package:hospital_management/core/providers/hospital_name_provider.dart';
import 'package:hospital_management/core/router/app_routes.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/data/models/hms_models.dart';
import 'package:hospital_management/data/remote/hospital_api_client.dart';
import 'package:hospital_management/core/providers/hms_providers.dart';

enum AuthTab { signIn, createHospital, centralReview }

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
  HospitalApiRecord? _selectedOnlineHospital;
  bool _onlineSignIn = false;
  bool _enterHospitalId = false;
  bool _loadingOnlineHospitals = false;
  bool _reviewingRegistrations = false;
  String? _onlineHospitalError;
  String? _onlineLoginMessage;
  List<HospitalApiRecord> _onlineHospitals = [];
  final _hospitalIdController = TextEditingController();

  // ── Create Hospital & Super Admin Form ──────────────────────────────────────
  final _createFormKey = GlobalKey<FormState>();
  final _hospNameController = TextEditingController();
  final _hospCodeController = TextEditingController();
  final _hospAddressController = TextEditingController();
  String _hospType = 'Multispeciality Hospital';

  final _adminFullNameController = TextEditingController();
  final _adminUsernameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _adminConfirmPasswordController = TextEditingController();
  bool _adminObscurePassword = true;
  bool _adminObscureConfirm = true;

  // ── Hospital Staff & Role Credentials ──────────────────────────────────────
  final _adminRoleUsernameController = TextEditingController();
  final _adminRolePasswordController =
      TextEditingController(text: 'Admin@1234');
  final _doctorUsernameController = TextEditingController();
  final _doctorPasswordController = TextEditingController(text: 'Doctor@1234');
  final _nurseUsernameController = TextEditingController();
  final _nursePasswordController = TextEditingController(text: 'Nurse@1234');
  final _staffUsernameController = TextEditingController();
  final _staffPasswordController = TextEditingController(text: 'Staff@1234');
  bool _customStaffExpanded = false;

  bool _isSubmitting = false;
  final _centralUsernameController = TextEditingController();
  final _centralPasswordController = TextEditingController();
  String? _centralAccessToken;
  List<Map<String, dynamic>> _pendingOnlineRegistrations = [];
  String? _reviewMessage;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    _hospCodeController.addListener(_onHospCodeChanged);
  }

  void _onHospCodeChanged() {
    final code = _hospCodeController.text.trim().toLowerCase();
    if (code.isNotEmpty) {
      if (_adminRoleUsernameController.text.isEmpty ||
          _adminRoleUsernameController.text.endsWith('_admin')) {
        _adminRoleUsernameController.text = '${code}_admin';
      }
      if (_doctorUsernameController.text.isEmpty ||
          _doctorUsernameController.text.endsWith('_doctor')) {
        _doctorUsernameController.text = '${code}_doctor';
      }
      if (_nurseUsernameController.text.isEmpty ||
          _nurseUsernameController.text.endsWith('_nurse')) {
        _nurseUsernameController.text = '${code}_nurse';
      }
      if (_staffUsernameController.text.isEmpty ||
          _staffUsernameController.text.endsWith('_staff')) {
        _staffUsernameController.text = '${code}_staff';
      }
    }
  }

  @override
  void dispose() {
    _hospCodeController.removeListener(_onHospCodeChanged);
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
    _hospitalIdController.dispose();
    _centralUsernameController.dispose();
    _centralPasswordController.dispose();

    _adminRoleUsernameController.dispose();
    _adminRolePasswordController.dispose();
    _doctorUsernameController.dispose();
    _doctorPasswordController.dispose();
    _nurseUsernameController.dispose();
    _nursePasswordController.dispose();
    _staffUsernameController.dispose();
    _staffPasswordController.dispose();
    super.dispose();
  }

  // ── Sign In Submission ──────────────────────────────────────────────────────
  Future<void> _submitSignIn() async {
    if (_isSubmitting) return;
    if (!(_signInFormKey.currentState?.validate() ?? false)) return;

    if (_onlineSignIn) {
      await _submitOnlineSignIn();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final selectedHospital =
          _selectedHospital ?? ref.read(activeHospitalProvider);

      final error = await ref.read(sessionProvider.notifier).login(
            _usernameController.text.trim(),
            _passwordController.text,
            selectedHospitalId: selectedHospital?.id,
            selectedHospitalName: selectedHospital?.name,
          );

      if (!mounted) return;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (selectedHospital != null) {
        ref
            .read(activeHospitalProvider.notifier)
            .switchHospital(selectedHospital);
      }

      context.go(AppRoutes.dashboard);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _loadOnlineHospitals() async {
    setState(() {
      _loadingOnlineHospitals = true;
      _onlineHospitalError = null;
    });
    try {
      final hospitals =
          await ref.read(hospitalApiClientProvider).listHospitals();
      if (!mounted) return;
      setState(() {
        _onlineHospitals = hospitals;
        _selectedOnlineHospital = hospitals.isEmpty ? null : hospitals.first;
        _loadingOnlineHospitals = false;
      });
    } on HospitalApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _onlineHospitalError = error.message;
        _loadingOnlineHospitals = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _onlineHospitalError = 'Cannot connect to the CareSync server.';
        _loadingOnlineHospitals = false;
      });
    }
  }

  Future<void> _lookupOnlineHospital() async {
    final id = _hospitalIdController.text.trim();
    if (!RegExp(r'^\d{12}$').hasMatch(id)) {
      setState(
          () => _onlineHospitalError = 'Enter a valid 12-digit Hospital ID.');
      return;
    }
    setState(() {
      _loadingOnlineHospitals = true;
      _onlineHospitalError = null;
      _selectedOnlineHospital = null;
    });
    try {
      final hospital =
          await ref.read(hospitalApiClientProvider).lookupHospital(id);
      if (!mounted) return;
      setState(() {
        _selectedOnlineHospital = hospital;
        _loadingOnlineHospitals = false;
      });
    } on HospitalApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _onlineHospitalError = error.message;
        _loadingOnlineHospitals = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _onlineHospitalError = 'Cannot connect to the CareSync server.';
        _loadingOnlineHospitals = false;
      });
    }
  }

  Future<void> _submitOnlineSignIn() async {
    if (_selectedOnlineHospital == null) {
      setState(() =>
          _onlineHospitalError = 'Select or find an approved hospital first.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _onlineLoginMessage = null;
    });
    try {
      final error =
          await ref.read(onlineHospitalSessionProvider.notifier).login(
                hospitalId: _selectedOnlineHospital!.hospitalId,
                username: _usernameController.text.trim(),
                password: _passwordController.text,
              );
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _onlineLoginMessage = error;
      });
      if (error == null) context.go(AppRoutes.onlineHospital);
    } on HospitalApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _onlineLoginMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _onlineLoginMessage = 'Cannot connect to the CareSync server.';
      });
    }
  }

  Future<void> _loginCentralAdministrator() async {
    if (_centralUsernameController.text.trim().isEmpty ||
        _centralPasswordController.text.isEmpty) {
      setState(() => _reviewMessage =
          'Enter the Central Super Admin username and password.');
      return;
    }
    setState(() {
      _reviewingRegistrations = true;
      _reviewMessage = null;
    });
    try {
      final login = await ref.read(hospitalApiClientProvider).centralAdminLogin(
            username: _centralUsernameController.text.trim(),
            password: _centralPasswordController.text,
          );
      final token = login['accessToken'] as String;
      final user = login['user'] as Map<String, dynamic>;
      if (user['role'] != 'SUPER_ADMIN' || user['hospitalId'] != null) {
        throw const HospitalApiException(
            'This account is not a Central Super Admin.');
      }
      final pending =
          await ref.read(hospitalApiClientProvider).pendingRegistrations(token);
      if (!mounted) return;
      setState(() {
        _centralAccessToken = token;
        _pendingOnlineRegistrations = pending;
        _reviewingRegistrations = false;
      });
    } on HospitalApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _reviewingRegistrations = false;
        _reviewMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _reviewingRegistrations = false;
        _reviewMessage =
            'Cannot connect or the server returned an invalid response.';
      });
    }
  }

  Future<void> _reviewRegistration(String registrationId,
      {required bool approve}) async {
    final token = _centralAccessToken;
    if (token == null) return;
    try {
      if (approve) {
        final result = await ref
            .read(hospitalApiClientProvider)
            .approveRegistration(registrationId, token);
        if (!mounted) return;
        setState(() {
          _pendingOnlineRegistrations
              .removeWhere((row) => row['registrationId'] == registrationId);
          _reviewMessage =
              'Approved ${result['name']}. Hospital ID: ${result['hospitalId']}';
        });
      } else {
        await ref
            .read(hospitalApiClientProvider)
            .rejectRegistration(registrationId, token);
        if (!mounted) return;
        setState(() {
          _pendingOnlineRegistrations
              .removeWhere((row) => row['registrationId'] == registrationId);
          _reviewMessage = 'Registration rejected.';
        });
      }
    } on HospitalApiException catch (error) {
      if (mounted) setState(() => _reviewMessage = error.message);
    } catch (_) {
      if (mounted)
        setState(() => _reviewMessage = 'Cannot complete the review request.');
    }
  }

  // ── Create Hospital & Super Admin Submission ────────────────────────────────
  Future<void> _submitCreateHospitalAndSuperAdmin() async {
    if (_isSubmitting) return;
    if (!(_createFormKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final hospName = _hospNameController.text.trim();
    final hospCode = _hospCodeController.text.trim().toUpperCase();
    final hospAddress = _hospAddressController.text.trim();

    final adminUsername = _adminUsernameController.text.trim();
    final adminFullName = _adminFullNameController.text.trim();
    final adminEmail = _adminEmailController.text.trim();
    final adminPassword = _adminPasswordController.text;

    try {
      final result = await ref.read(hospitalApiClientProvider).registerHospital(
            name: hospName,
            code: hospCode,
            type: _hospType,
            address: hospAddress,
            email: adminEmail,
            adminUsername: adminUsername,
            adminPassword: adminPassword,
            adminFullName: adminFullName,
          );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.hourglass_top_rounded),
          title: const Text('Registration submitted'),
          content: Text(
            'Registration ${result['registrationId']} is ${result['status']}. '
            'The Central Super Admin must approve it. Your 12-digit Hospital ID will be issued after approval.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
      );
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

  Future<void> _submitOfflineLocalHospitalSetup() async {
    if (_isSubmitting || !(_createFormKey.currentState?.validate() ?? false))
      return;
    setState(() => _isSubmitting = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final username = _adminUsernameController.text.trim();
      if (await db.isUsernameTaken(username)) {
        throw const HospitalApiException(
            'That local username is already in use.');
      }
      final hospital = HospitalModel(
        uuid: 'hosp-${DateTime.now().millisecondsSinceEpoch}',
        name: _hospNameController.text.trim(),
        code: _hospCodeController.text.trim().toUpperCase(),
        type: _hospType,
        address: _hospAddressController.text.trim(),
        email: _adminEmailController.text.trim(),
        status: 'Active',
      );
      final localId = await db.hmsDao.insertHospital(hospital);
      final error = await ref.read(sessionProvider.notifier).registerUser(
            fullName: _adminFullNameController.text.trim(),
            username: username,
            email: _adminEmailController.text.trim(),
            password: _adminPasswordController.text,
            role: 'Super Admin',
            hospitalId: localId,
            hospitalName: hospital.name,
          );
      if (error != null) throw HospitalApiException(error);
      ref.invalidate(allHospitalsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Saved on this device only; this is not an online hospital registration.'),
        ));
        setState(() => _isSubmitting = false);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  } //

  static Widget _buildCredentialRow(
      String role, String username, String password) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(role,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Expanded(
            flex: 4,
            child: Text(username,
                style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
          ),
          Expanded(
            flex: 4,
            child: Text(
              password,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
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
                          label: Text('Sign In',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        ButtonSegment(
                          value: AuthTab.createHospital,
                          icon: Icon(Icons.domain_add_rounded, size: 18),
                          label: Text('Create Hospital',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        ButtonSegment(
                          value: AuthTab.centralReview,
                          icon: Icon(Icons.fact_check_outlined, size: 18),
                          label: Text('Review',
                              style: TextStyle(fontWeight: FontWeight.w600)),
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
                      _buildSignInForm(
                          context, colorScheme, textTheme, hospitals)
                    else if (_currentTab == AuthTab.createHospital)
                      _buildCreateHospitalForm(context, colorScheme, textTheme)
                    else
                      _buildCentralReviewForm(context, colorScheme, textTheme),
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
    final onlineSession = ref.watch(onlineHospitalSessionProvider);

    return Form(
      key: _signInFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Online / Offline Login Switch ─────────────────────────────
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Online Hospital Login'),
            subtitle: Text(
              _onlineSignIn
                  ? 'Sign in using the CareSync server'
                  : 'Sign in using this device',
            ),
            value: _onlineSignIn,
            onChanged: _isSubmitting
                ? null
                : (enabled) {
                    setState(() {
                      _onlineSignIn = enabled;
                      _onlineHospitalError = null;
                      _onlineLoginMessage = null;
                      _selectedOnlineHospital = null;
                    });

                    if (enabled) {
                      _loadOnlineHospitals();
                    }
                  },
          ),
          const Gap(12),

          // ── Online Session Error ──────────────────────────────────────
          if (_onlineSignIn && onlineSession.error != null) ...[
            const Gap(8),
            Text(
              onlineSession.error!,
              style: TextStyle(color: colorScheme.error),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onlineSession.isLoading
                    ? null
                    : () => ref
                        .read(onlineHospitalSessionProvider.notifier)
                        .restore(),
                child: const Text('Retry session restore'),
              ),
            ),
          ],

          const Gap(14),

          // ── Hospital Selector ─────────────────────────────────────────
          if (_onlineSignIn) ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() {
                  _enterHospitalId = !_enterHospitalId;
                  _selectedOnlineHospital = null;
                  _onlineHospitalError = null;
                }),
                icon: Icon(
                  _enterHospitalId ? Icons.list_alt : Icons.pin_outlined,
                  size: 16,
                ),
                label: Text(
                  _enterHospitalId
                      ? 'Choose from hospital list'
                      : 'I have a Hospital ID',
                ),
              ),
            ),
            if (_enterHospitalId)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hospitalIdController,
                      keyboardType: TextInputType.number,
                      maxLength: 12,
                      decoration: const InputDecoration(
                        labelText: '12-digit Hospital ID',
                      ),
                      validator: (value) =>
                          RegExp(r'^\d{12}$').hasMatch(value?.trim() ?? '')
                              ? null
                              : 'Enter a valid 12-digit Hospital ID',
                    ),
                  ),
                  IconButton(
                    tooltip: 'Find hospital',
                    onPressed:
                        _loadingOnlineHospitals ? null : _lookupOnlineHospital,
                    icon: const Icon(Icons.search),
                  ),
                ],
              )
            else if (_loadingOnlineHospitals)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_onlineHospitals.isNotEmpty)
              DropdownButtonFormField<HospitalApiRecord>(
                initialValue: _onlineHospitals.any(
                  (hospital) =>
                      hospital.hospitalId ==
                      _selectedOnlineHospital?.hospitalId,
                )
                    ? _onlineHospitals.firstWhere(
                        (hospital) =>
                            hospital.hospitalId ==
                            _selectedOnlineHospital?.hospitalId,
                      )
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Hospital',
                  prefixIcon: Icon(
                    Icons.local_hospital_outlined,
                  ),
                ),
                items: _onlineHospitals.map((hospital) {
                  return DropdownMenuItem(
                    value: hospital,
                    child: Text(
                      '${hospital.name} · ${hospital.hospitalId}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (hospital) {
                  setState(() {
                    _selectedOnlineHospital = hospital;
                  });
                },
                validator: (hospital) =>
                    hospital == null ? 'Choose an approved hospital' : null,
              )
            else
              Text(
                _onlineHospitalError ?? 'No approved Hospitals are available.',
                style: TextStyle(color: colorScheme.error),
              ),
            if (_selectedOnlineHospital != null && _enterHospitalId)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Hospital: ${_selectedOnlineHospital!.name} '
                  '(${_selectedOnlineHospital!.hospitalId})',
                ),
              ),
            if (_onlineHospitalError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _onlineHospitalError!,
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
          ] else if (hospitals.isNotEmpty) ...[
            DropdownButtonFormField<HospitalModel>(
              initialValue: hospitals.any(
                (h) => h.id == _selectedHospital?.id,
              )
                  ? hospitals.firstWhere(
                      (h) => h.id == _selectedHospital?.id,
                    )
                  : hospitals.first,
              decoration: const InputDecoration(
                labelText: 'Select Hospital / Branch',
                prefixIcon: Icon(
                  Icons.local_hospital_outlined,
                ),
                helperText: 'Branch to access for this work session',
              ),
              items: hospitals.map((h) {
                return DropdownMenuItem(
                  value: h,
                  child: Text(
                    h.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedHospital = val);
                }
              },
            ),
            const Gap(16),
          ],

          // ── Username Field ────────────────────────────────────────────
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              hintText: 'e.g. admin or staff ID',
              prefixIcon: Icon(
                Icons.person_outline_rounded,
              ),
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

          // ── Password Field ────────────────────────────────────────────
          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
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

          // ── Online Login Message ──────────────────────────────────────
          if (_onlineLoginMessage != null) ...[
            Text(
              _onlineLoginMessage!,
              style: TextStyle(color: colorScheme.primary),
            ),
            const Gap(12),
          ],

          // ── Submit Button ─────────────────────────────────────────────
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submitSignIn,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.login_rounded),
            label: Text(
              _isSubmitting ? 'Signing in…' : 'Sign In',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const Gap(16),

          // ── Register Hospital Link ────────────────────────────────────
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _currentTab = AuthTab.createHospital;
                });
              },
              icon: const Icon(
                Icons.domain_add_rounded,
                size: 16,
              ),
              label: const Text('Register Hospital online'),
            ),
          ),

          // ── Central Super Admin Link ──────────────────────────────────
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _currentTab = AuthTab.centralReview;
                });
              },
              icon: const Icon(
                Icons.fact_check_outlined,
                size: 16,
              ),
              label: const Text(
                'Central Super Admin: review registrations',
              ),
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
              border:
                  Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined,
                    size: 20, color: colorScheme.primary),
                const Gap(8),
                Expanded(
                  child: Text(
                    'Creating a hospital registers the master Super Admin account. Other staff (Doctors, Nurses, Receptionists, Pharmacists) are provisioned securely through Super Admin Settings.',
                    style: textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onPrimaryContainer),
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
                style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold, color: colorScheme.primary),
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
              if (value == null || value.trim().isEmpty)
                return 'Hospital name is required';
              return null;
            },
          ),
          const Gap(12),

          // ── Hospital Code & Facility Type ─────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 520;

              final branchCodeField = TextFormField(
                controller: _hospCodeController,
                decoration: const InputDecoration(
                  labelText: 'Branch Code *',
                  hintText: 'e.g. SJH-CENTRAL',
                  prefixIcon: Icon(Icons.tag),
                ),
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Code required';
                  }
                  return null;
                },
              );

              final facilityTypeField = DropdownButtonFormField<String>(
                initialValue: _hospType,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Multispeciality Hospital',
                    child: Text('Multispeciality',
                        overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'General Hospital',
                    child: Text('General Hospital',
                        overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'Clinic / Outpatient',
                    child: Text('Clinic'),
                  ),
                  DropdownMenuItem(
                    value: 'Trauma & Emergency Center',
                    child: Text('Trauma Center'),
                  ),
                  DropdownMenuItem(
                    value: 'Diagnostic Clinic',
                    child: Text('Diagnostic Clinic',
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _hospType = val);
                  }
                },
              );

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: branchCodeField),
                    const Gap(12),
                    Expanded(child: facilityTypeField),
                  ],
                );
              }

              return Column(
                children: [
                  branchCodeField,
                  const Gap(12),
                  facilityTypeField,
                ],
              );
            },
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
              Icon(Icons.admin_panel_settings_outlined,
                  size: 18, color: colorScheme.primary),
              const Gap(6),
              Text(
                'Super Admin Account Credentials',
                style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold, color: colorScheme.primary),
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
              if (value == null || value.trim().isEmpty)
                return 'Full name is required';
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
                    if (value == null || value.trim().isEmpty)
                      return 'Username required';
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
                    if (value == null || value.trim().isEmpty)
                      return 'Email required';
                    if (!value.contains('@') || !value.contains('.'))
                      return 'Invalid email';
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
                icon: Icon(_adminObscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () => setState(
                    () => _adminObscurePassword = !_adminObscurePassword),
                tooltip:
                    _adminObscurePassword ? 'Show password' : 'Hide password',
              ),
            ),
            obscureText: _adminObscurePassword,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password is required';
              if (value.length < 12) return 'At least 12 characters required';
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
                icon: Icon(_adminObscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () => setState(
                    () => _adminObscureConfirm = !_adminObscureConfirm),
                tooltip:
                    _adminObscureConfirm ? 'Show password' : 'Hide password',
              ),
            ),
            obscureText: _adminObscureConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitCreateHospitalAndSuperAdmin(),
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Please confirm password';
              if (value != _adminPasswordController.text)
                return 'Passwords do not match';
              return null;
            },
          ),
          const Gap(20),

          // ── Branch Staff & Role Accounts Header ────────────────────────────
          Row(
            children: [
              Icon(Icons.badge_outlined, size: 18, color: colorScheme.primary),
              const Gap(6),
              Text(
                'Branch Staff & Role Accounts',
                style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
            ],
          ),
          const Divider(height: 16),
          Text(
            'Separate role accounts (Admin, Doctor, Nurse, Staff) are provisioned for this hospital with individual passwords:',
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const Gap(12),

          // Admin Credentials
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _adminRoleUsernameController,
                  decoration: const InputDecoration(
                    labelText: 'Admin Username',
                    prefixIcon: Icon(Icons.manage_accounts_outlined),
                    isDense: true,
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: TextFormField(
                  controller: _adminRolePasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Admin Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const Gap(12),

          // Doctor Credentials
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _doctorUsernameController,
                  decoration: const InputDecoration(
                    labelText: 'Doctor Username',
                    prefixIcon: Icon(Icons.medical_services_outlined),
                    isDense: true,
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: TextFormField(
                  controller: _doctorPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Doctor Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const Gap(12),

          // Nurse Credentials
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nurseUsernameController,
                  decoration: const InputDecoration(
                    labelText: 'Nurse Username',
                    prefixIcon: Icon(Icons.local_hospital_outlined),
                    isDense: true,
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: TextFormField(
                  controller: _nursePasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Nurse Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const Gap(12),

          // Staff / Reception Credentials
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _staffUsernameController,
                  decoration: const InputDecoration(
                    labelText: 'Staff / Receptionist Username',
                    prefixIcon: Icon(Icons.person_outline),
                    isDense: true,
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: TextFormField(
                  controller: _staffPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Staff Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const Gap(22),

          // ── Submit Button ──────────────────────────────────────────────────
          FilledButton.icon(
            onPressed:
                _isSubmitting ? null : _submitCreateHospitalAndSuperAdmin,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.domain_add_rounded),
            label: Text(
              _isSubmitting
                  ? 'Registering Hospital & Admin…'
                  : 'Register Hospital & Super Admin',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const Gap(16),

          // ── Switch to Sign In Link ─────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: _isSubmitting ? null : _submitOfflineLocalHospitalSetup,
            icon: const Icon(Icons.phone_android),
            label: const Text('Save to this device only (offline setup)'),
          ),
          const Gap(12),
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

  Widget _buildCentralReviewForm(
      BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Central Super Admin review', style: textTheme.titleMedium),
        const Gap(12),
        TextFormField(
          controller: _centralUsernameController,
          decoration:
              const InputDecoration(labelText: 'Central Super Admin username'),
          enabled: _centralAccessToken == null,
        ),
        const Gap(10),
        TextFormField(
          controller: _centralPasswordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
          enabled: _centralAccessToken == null,
        ),
        const Gap(12),
        if (_centralAccessToken == null)
          FilledButton(
            onPressed:
                _reviewingRegistrations ? null : _loginCentralAdministrator,
            child: Text(_reviewingRegistrations
                ? 'Connecting…'
                : 'Load pending registrations'),
          )
        else
          OutlinedButton(
            onPressed: () => setState(() {
              _centralAccessToken = null;
              _pendingOnlineRegistrations = [];
              _centralPasswordController.clear();
            }),
            child: const Text('End review session'),
          ),
        if (_reviewMessage != null) ...[
          const Gap(10),
          Text(_reviewMessage!, style: TextStyle(color: colorScheme.primary)),
        ],
        const Gap(12),
        if (_centralAccessToken != null && _pendingOnlineRegistrations.isEmpty)
          const Text('There are no pending registrations.'),
        for (final registration in _pendingOnlineRegistrations)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(registration['name'] as String? ?? 'Hospital',
                      style: textTheme.titleSmall),
                  Text('${registration['type']} · ${registration['code']}'),
                  Text(
                      'First admin: ${registration['firstAdminFullName']} (${registration['firstAdminUsername']})'),
                  if ((registration['address'] as String?)?.isNotEmpty == true)
                    Text(registration['address'] as String),
                  const Gap(8),
                  Wrap(spacing: 8, children: [
                    FilledButton.tonal(
                      onPressed: () => _reviewRegistration(
                          registration['registrationId'] as String,
                          approve: true),
                      child: const Text('Approve'),
                    ),
                    OutlinedButton(
                      onPressed: () => _reviewRegistration(
                          registration['registrationId'] as String,
                          approve: false),
                      child: const Text('Reject'),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _currentTab = AuthTab.signIn),
            child: const Text('Back to sign in'),
          ),
        ),
      ],
    );
  }
}
