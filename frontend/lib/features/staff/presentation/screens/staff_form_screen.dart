import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_management/core/router/app_routes.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/core/providers/hms_providers.dart';
import 'package:hospital_management/data/models/hms_models.dart';

class StaffFormScreen extends ConsumerStatefulWidget {
  const StaffFormScreen({
    super.key,
    this.staffId,
    this.existingStaff,
    this.doctorOnly = false,
  });

  final int? staffId;
  final StaffModel? existingStaff;
  final bool doctorOnly;

  @override
  ConsumerState<StaffFormScreen> createState() => _StaffFormScreenState();
}

class _StaffFormScreenState extends ConsumerState<StaffFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _regNoController = TextEditingController();
  final _feeController = TextEditingController();

  String _role = 'Doctor';
  String _department = 'General Medicine';
  String _status = 'Active';
  bool _isLoading = true;
  bool _isSaving = false;
  StaffModel? _loadedStaff;

  final List<String> _roles = [
    'Doctor',
    'Nurse',
    'Pharmacist',
    'Lab Technician',
    'Receptionist',
    'Accounts',
    'Administrator',
  ];

  final List<String> _departments = [
    'General Medicine',
    'Cardiology',
    'Orthopaedics',
    'Pediatrics',
    'Obstetrics & Gynaecology',
    'Emergency / Casualty',
    'Nursing',
    'Reception',
    'Laboratory Services',
    'Pharmacy',
    'Accounts',
    'Administration',
  ];

  final List<String> _statuses = ['Active', 'On Leave', 'Inactive'];

  bool get _isEditing => widget.staffId != null || widget.existingStaff != null;
  bool get _isDoctorRegistration =>
      widget.doctorOnly || _role.toLowerCase().startsWith('doctor');
  bool get _requiresRegistrationNumber =>
      const {'doctor', 'nurse', 'pharmacist'}.contains(_role.toLowerCase());
  String get _registrationLabel => switch (_role.toLowerCase()) {
        'doctor' => 'Medical Registration No.',
        'nurse' => 'Nursing Registration No.',
        'pharmacist' => 'Pharmacy License No.',
        _ => 'Employee / Registration No.',
      };
  String get _formTitle => widget.doctorOnly
      ? 'Doctor Registration'
      : _isEditing
          ? 'Edit ${_isDoctorRegistration ? 'Doctor' : 'Staff'} Profile'
          : 'Add Practitioner / Staff Member';

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    if (widget.existingStaff != null) {
      _applyStaff(widget.existingStaff!);
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (widget.staffId != null && widget.staffId! > 0) {
      final db = ref.read(appDatabaseProvider);
      final staff = await db.hmsDao.getStaffById(widget.staffId!);
      if (staff != null) {
        _applyStaff(staff);
      }
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _applyStaff(StaffModel s) {
    _loadedStaff = s;
    _nameController.text = s.name;
    _phoneController.text = s.phone;
    _emailController.text = s.email;
    _regNoController.text = s.regNo;
    _qualificationController.text = s.qualification;
    _feeController.text = (s.feePaise / 100).toStringAsFixed(0);
    _status = _statuses.contains(s.status) ? s.status : 'Active';

    // Find role match
    for (final r in _roles) {
      if (s.role.toLowerCase().startsWith(r.toLowerCase())) {
        _role = r;
        break;
      }
    }

    // Find department match
    if (_departments.contains(s.department)) {
      _department = s.department;
    } else {
      _departments.insert(0, s.department);
      _department = s.department;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _qualificationController.dispose();
    _regNoController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final fee = (int.tryParse(_feeController.text.trim()) ?? 0) * 100;
      final now = DateTime.now();
      final qual = _qualificationController.text.trim();
      final roleString = qual.isNotEmpty ? '$_role ($qual)' : _role;
      final enteredEmail = _emailController.text.trim();
      final email = enteredEmail.isNotEmpty
          ? enteredEmail
          : '${_nameController.text.trim().toLowerCase().replaceAll(' ', '.')}@hospital.local';

      if (_isEditing) {
        final existing = widget.existingStaff ?? _loadedStaff;
        final staffId = widget.staffId ?? existing?.id ?? 0;
        final updatedStaff = StaffModel(
          id: staffId,
          uuid: existing?.uuid ?? 'staff-${now.microsecondsSinceEpoch}',
          name: _nameController.text.trim(),
          role: roleString,
          regNo: _regNoController.text.trim(),
          department: _department,
          phone: _phoneController.text.trim(),
          email: email,
          feePaise: fee,
          status: _status,
          qualification: qual,
          updatedAt: now.toIso8601String(),
        );

        await db.hmsDao.updateStaff(updatedStaff);
        ref.invalidate(staffListProvider);
        ref.invalidate(dashboardStatsProvider);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_isDoctorRegistration ? 'Doctor' : 'Staff'} profile for ${updatedStaff.name} updated successfully.'),
            backgroundColor: Colors.teal.shade700,
          ),
        );
      } else {
        final staff = StaffModel(
          id: 0,
          uuid: 'staff-${now.microsecondsSinceEpoch}',
          name: _nameController.text.trim(),
          role: roleString,
          regNo: _regNoController.text.trim(),
          department: _department,
          phone: _phoneController.text.trim(),
          email: email,
          feePaise: fee,
          status: _status,
          qualification: qual,
          createdAt: now.toIso8601String(),
        );

        await db.hmsDao.insertStaff(staff);
        ref.invalidate(staffListProvider);
        ref.invalidate(dashboardStatsProvider);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_isDoctorRegistration ? 'Doctor' : 'Staff'} profile for ${staff.name} saved successfully.'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }

      if (mounted) context.go(AppRoutes.staff);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Error saving ${_isDoctorRegistration ? 'doctor' : 'staff'} profile: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_formTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(_formTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.staff),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750),
            child: Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Icon(
                              _isEditing
                                  ? Icons.manage_accounts
                                  : Icons.person_add,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const Gap(12),
                          Text(
                            _isEditing
                                ? 'Edit ${_isDoctorRegistration ? 'Doctor' : 'Staff'} Profile'
                                : _isDoctorRegistration
                                    ? 'Doctor Registration'
                                    : 'New Staff Profile',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Gap(24),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name with Title *',
                          hintText: 'e.g. Dr. Rajesh Kulkarni',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const Gap(16),
                      Row(
                        children: [
                          if (widget.doctorOnly)
                            const Expanded(
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Hospital Role',
                                  prefixIcon:
                                      Icon(Icons.medical_services_outlined),
                                ),
                                child: Text('Doctor'),
                              ),
                            )
                          else
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _roles.contains(_role)
                                    ? _role
                                    : _roles.first,
                                decoration: const InputDecoration(
                                  labelText: 'Hospital Role *',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                                items: _roles
                                    .map((r) => DropdownMenuItem(
                                        value: r, child: Text(r)))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => _role = v);
                                },
                              ),
                            ),
                          const Gap(16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _departments.contains(_department)
                                  ? _department
                                  : _departments.first,
                              decoration: const InputDecoration(
                                labelText: 'Specialization / Department *',
                                prefixIcon: Icon(Icons.apartment_outlined),
                              ),
                              items: _departments
                                  .map((d) => DropdownMenuItem(
                                      value: d, child: Text(d)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _department = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const Gap(16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _regNoController,
                              decoration: InputDecoration(
                                labelText:
                                    '$_registrationLabel${_requiresRegistrationNumber ? ' *' : ''}',
                                hintText: _requiresRegistrationNumber
                                    ? 'Enter the professional registration number'
                                    : 'Optional',
                                prefixIcon: const Icon(Icons.verified_outlined),
                              ),
                              validator: (value) {
                                if (_requiresRegistrationNumber &&
                                    (value == null || value.trim().isEmpty)) {
                                  return '$_registrationLabel is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const Gap(16),
                          Expanded(
                            child: TextFormField(
                              controller: _qualificationController,
                              decoration: const InputDecoration(
                                labelText: 'Degree / Qualification',
                                hintText: 'e.g. MBBS, MD (Cardiology)',
                                prefixIcon: Icon(Icons.school_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isNotEmpty &&
                              !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                  .hasMatch(email)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const Gap(16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Mobile Phone *',
                                hintText: '+91 98XXX XXXXX',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                          const Gap(16),
                          Expanded(
                            child: TextFormField(
                              controller: _feeController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'OPD Consultation Fee (₹)',
                                prefixIcon: Icon(Icons.currency_rupee),
                              ),
                            ),
                          ),
                          const Gap(16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _statuses.contains(_status)
                                  ? _status
                                  : _statuses.first,
                              decoration: const InputDecoration(
                                labelText: 'Employment Status *',
                                prefixIcon: Icon(Icons.toggle_on_outlined),
                              ),
                              items: _statuses
                                  .map((s) => DropdownMenuItem(
                                      value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _status = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const Gap(32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => context.go(AppRoutes.staff),
                            child: const Text('Cancel'),
                          ),
                          const Gap(12),
                          FilledButton.icon(
                            onPressed: _isSaving ? null : _save,
                            icon: Icon(_isEditing ? Icons.save : Icons.check,
                                size: 18),
                            label: Text(_isSaving
                                ? 'Saving…'
                                : _isEditing
                                    ? 'Update ${_isDoctorRegistration ? 'Doctor' : 'Staff'} Profile'
                                    : 'Register ${_isDoctorRegistration ? 'Doctor' : 'Staff Member'}'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
