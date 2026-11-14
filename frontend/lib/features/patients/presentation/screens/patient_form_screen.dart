import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_management/core/router/app_routes.dart';
import 'package:hospital_management/domain/entities/patient.dart';
import 'package:hospital_management/features/patients/patients_provider.dart';

class PatientFormScreen extends ConsumerStatefulWidget {
  const PatientFormScreen({super.key, this.patientId});

  final int? patientId;

  @override
  ConsumerState<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends ConsumerState<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  String _gender = 'Male';
  String _bloodGroup = 'O+';
  bool _isVip = false;
  bool _isSaving = false;
  bool _isLoading = true;
  Patient? _loadedPatient;

  bool get _isEditing => widget.patientId != null && widget.patientId! > 0;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-'
  ];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    if (_isEditing) {
      final repo = ref.read(patientRepositoryProvider);
      final p = await repo.findById(widget.patientId!);
      if (p != null) {
        _loadedPatient = p;
        _nameController.text = p.name;
        _phoneController.text = p.phone ?? '';
        _ageController.text = p.ageYears?.toString() ?? '';
        _addressController.text = p.address ?? '';
        _cityController.text = p.city ?? '';
        _emergencyNameController.text = p.emergencyContactName ?? '';
        _emergencyPhoneController.text = p.emergencyContactPhone ?? '';
        _notesController.text = p.notes ?? '';
        if (_genders.contains(p.gender)) _gender = p.gender!;
        if (_bloodGroups.contains(p.bloodGroup)) _bloodGroup = p.bloodGroup!;
        _isVip = p.isVip;
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    final repo = ref.read(patientRepositoryProvider);

    try {
      final now = DateTime.now();
      final age = int.tryParse(_ageController.text.trim()) ?? 30;

      if (_isEditing && _loadedPatient != null) {
        final updated = _loadedPatient!.copyWith(
          name: _nameController.text.trim(),
          gender: _gender,
          ageYears: age,
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          bloodGroup: _bloodGroup,
          emergencyContactName: _emergencyNameController.text.trim(),
          emergencyContactPhone: _emergencyPhoneController.text.trim(),
          isVip: _isVip,
          notes: _notesController.text.trim(),
        );

        await repo.update(updated);
        ref.invalidate(patientListProvider);
        ref.invalidate(selectedPatientProvider(widget.patientId!));

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Patient records updated: ${updated.name} (${updated.uhid})'),
            backgroundColor: Colors.teal.shade700,
          ),
        );
        context.go('/patients/${updated.id}');
      } else {
        final uhid = await repo.generateUhid();
        final patient = Patient(
          id: 0,
          uuid: '',
          uhid: uhid,
          name: _nameController.text.trim(),
          gender: _gender,
          ageYears: age,
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          bloodGroup: _bloodGroup,
          emergencyContactName: _emergencyNameController.text.trim(),
          emergencyContactPhone: _emergencyPhoneController.text.trim(),
          isVip: _isVip,
          notes: _notesController.text.trim(),
          createdAt: now,
        );

        final created = await repo.create(patient);
        ref.invalidate(patientListProvider);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Patient registered successfully: ${created.name} (${created.uhid})'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        context.go('/patients/${created.id}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving patient: $e'),
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
        appBar: AppBar(
            title: Text(
                _isEditing ? 'Edit Patient Profile' : 'Patient Registration')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(_isEditing
            ? 'Edit Patient Profile (${_loadedPatient?.uhid ?? ""})'
            : 'Patient Registration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(_isEditing
              ? '/patients/${widget.patientId}'
              : AppRoutes.patients),
        ),
        actions: [
          FilledButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: Icon(_isEditing ? Icons.save : Icons.check, size: 18),
            label: Text(_isSaving
                ? 'Saving…'
                : (_isEditing ? 'Update Records' : 'Save Patient')),
          ),
          const Gap(16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Demographic & Contact Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Gap(24),

                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          hintText: 'e.g. Patient Full Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Patient name is required';
                          }

                          final name = v.trim();

                          if (!RegExp(
                            r"^[\p{L}\p{M}]+(?:[ .'-][\p{L}\p{M}]+)*$",
                            unicode: true,
                          ).hasMatch(name)) {
                            return 'Enter a valid name without numbers or symbols';
                          }

                          return null;
                        },
                      ),
                      const Gap(16),

                      // Gender & Age Row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _genders.contains(_gender)
                                  ? _gender
                                  : _genders.first,
                              decoration: const InputDecoration(
                                labelText: 'Gender *',
                                prefixIcon: Icon(Icons.wc_outlined),
                              ),
                              items: _genders
                                  .map((g) => DropdownMenuItem(
                                      value: g, child: Text(g)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _gender = v);
                              },
                            ),
                          ),
                          const Gap(16),
                          Expanded(
                            child: TextFormField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Age (Years) *',
                                prefixIcon: Icon(Icons.cake_outlined),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Age is required';
                                }

                                final age = int.tryParse(v.trim());

                                if (age == null) {
                                  return 'Enter a valid whole number';
                                }

                                if (age < 0 || age > 120) {
                                  return 'Age must be between 0 and 120';
                                }

                                return null;
                              },
                            ),
                          ),
                          const Gap(16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _bloodGroups.contains(_bloodGroup)
                                  ? _bloodGroup
                                  : _bloodGroups.first,
                              decoration: const InputDecoration(
                                labelText: 'Blood Group',
                                prefixIcon: Icon(Icons.bloodtype_outlined),
                              ),
                              items: _bloodGroups
                                  .map((b) => DropdownMenuItem(
                                      value: b, child: Text(b)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _bloodGroup = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const Gap(16),

                      // Phone & City
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number *',
                                hintText: '10-digit mobile number',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Phone number is required';
                                }

                                if (!RegExp(r'^[6-9]\d{9}$')
                                    .hasMatch(v.trim())) {
                                  return 'Enter a valid 10-digit Indian mobile number';
                                }

                                return null;
                              },
                            ),
                          ),
                          const Gap(16),
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: const InputDecoration(
                                labelText: 'City / District',
                                prefixIcon: Icon(Icons.location_city_outlined),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'City / District is required';
                                }

                                final city = v.trim();

                                if (!RegExp(
                                  r"^[\p{L}\p{M}]+(?:[ '\-][\p{L}\p{M}]+)*$",
                                  unicode: true,
                                ).hasMatch(city)) {
                                  return 'Enter a valid city or district name';
                                }

                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const Gap(16),

                      // Address
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Residential Address',
                          prefixIcon: Icon(Icons.home_outlined),
                        ),
                      ),
                      const Gap(24),
                      const Divider(),
                      const Gap(16),

                      Text(
                        'Emergency Contact',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const Gap(16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _emergencyNameController,
                              decoration: const InputDecoration(
                                labelText: 'Contact Person Name',
                                prefixIcon: Icon(Icons.contact_phone_outlined),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return null;
                                }

                                final name = v.trim();

                                if (!RegExp(
                                  r"^[\p{L}\p{M}]+(?:[ .'-][\p{L}\p{M}]+)*$",
                                  unicode: true,
                                ).hasMatch(name)) {
                                  return 'Enter a valid contact name';
                                }

                                return null;
                              },
                            ),
                          ),
                          const Gap(16),
                          Expanded(
                            child: TextFormField(
                              controller: _emergencyPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Contact Phone Number',
                                hintText: '10-digit mobile number',
                                prefixIcon: Icon(Icons.phone_in_talk_outlined),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Emergency contact number is required';
                                }

                                if (!RegExp(r'^[6-9]\d{9}$')
                                    .hasMatch(v.trim())) {
                                  return 'Enter a valid 10-digit Indian mobile number';
                                }

                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const Gap(16),

                      // VIP Switch
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Priority / VIP Patient Status'),
                        subtitle: const Text(
                            'Highlights record across queue and admissions'),
                        value: _isVip,
                        onChanged: (val) => setState(() => _isVip = val),
                      ),
                      const Gap(16),

                      // Clinical Notes
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Known Allergies / Clinical Notes',
                          hintText:
                              'e.g. Penicillin allergy, diabetic on insulin',
                          prefixIcon: Icon(Icons.medical_information_outlined),
                        ),
                      ),
                      const Gap(32),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _save,
                          icon: Icon(_isEditing
                              ? Icons.save_rounded
                              : Icons.person_add_rounded),
                          label: Text(
                            _isSaving
                                ? 'Saving…'
                                : (_isEditing
                                    ? 'Save Changes to Patient Record'
                                    : 'Register Patient & Open File'),
                          ),
                        ),
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
