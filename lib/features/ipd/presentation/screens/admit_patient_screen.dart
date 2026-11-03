import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_management/core/router/app_routes.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/core/providers/hms_providers.dart';
import 'package:hospital_management/data/models/hms_models.dart';
import 'package:hospital_management/features/patients/patients_provider.dart';

class AdmitPatientScreen extends ConsumerStatefulWidget {
  const AdmitPatientScreen({super.key});

  @override
  ConsumerState<AdmitPatientScreen> createState() => _AdmitPatientScreenState();
}

class _AdmitPatientScreenState extends ConsumerState<AdmitPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientController = TextEditingController();
  final _reasonController = TextEditingController();
  final _depositController = TextEditingController();

  String _ward = 'All';
  String _bed = '';
  String _doctor = '';
  String _paymentMode = 'Cash';

  Future<void> _admit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final db = ref.read(appDatabaseProvider);
    final nameText = _patientController.text.trim();
    String patientName = nameText;
    String uhid = 'WALK-IN';
    if (nameText.contains('(') && nameText.contains(')')) {
      patientName = nameText.split('(').first.trim();
      uhid = nameText.split('(').last.replaceAll(')', '').trim();
    }

    final deposit = (int.tryParse(_depositController.text.trim()) ?? 0) * 100;
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';

    final admission = IpdAdmissionModel(
      id: 0,
      patientName: patientName,
      uhid: uhid,
      ward: _ward,
      bedNo: _bed,
      doctorName: _doctor,
      admitDate: dateStr,
      days: 1,
      diagnosis: _reasonController.text.trim(),
      status: 'Admitted',
      depositPaise: deposit,
      notes: [],
      medications: [],
    );

    await db.hmsDao.insertIpdAdmission(admission);
    ref.invalidate(ipdAdmissionsListProvider);
    ref.invalidate(bedsListProvider);
    ref.invalidate(dashboardStatsProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$patientName admitted to $_ward Bed $_bed.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      context.go(AppRoutes.ipd);
    }
  }

  @override
  void dispose() {
    _patientController.dispose();
    _reasonController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final patientsAsync = ref.watch(patientListProvider);
    final bedsAsync = ref.watch(bedsListProvider);
    final staffAsync = ref.watch(staffListProvider);

    final patients = patientsAsync.value ?? [];
    final allBeds = bedsAsync.value ?? [];
    final availableBeds = allBeds.where((b) => b.status == 'Available').toList();
    final wards = ['All', ...availableBeds.map((b) => b.ward).toSet()];

    final filteredBeds = _ward == 'All'
        ? availableBeds
        : availableBeds.where((b) => b.ward == _ward).toList();

    if (_bed.isEmpty && filteredBeds.isNotEmpty) {
      _bed = filteredBeds.first.bedNo;
    } else if (filteredBeds.isNotEmpty && !filteredBeds.any((b) => b.bedNo == _bed)) {
      _bed = filteredBeds.first.bedNo;
    }

    final doctors = (staffAsync.value ?? [])
        .where((s) => s.role.toLowerCase().contains('doctor'))
        .map((s) => '${s.name} (${s.department})')
        .toSet()
        .toList();

    if (_doctor.isEmpty && doctors.isNotEmpty) {
      _doctor = doctors.first;
    } else if (doctors.isNotEmpty && !doctors.contains(_doctor)) {
      _doctor = doctors.first;
    }

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Inpatient Admission (ADT)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.ipd),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
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
                        'Patient Admission Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Gap(24),

                      // Patient Selector
                      if (patients.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Select Registered Patient *',
                            prefixIcon: Icon(Icons.person_search_outlined),
                          ),
                          items: patients.map((p) {
                            return DropdownMenuItem<String>(
                              value: '${p.name} (${p.uhid})',
                              child: Text('${p.name} (${p.uhid}) - ${p.phone ?? "-"}'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              _patientController.text = val;
                            }
                          },
                        ),
                        const Gap(12),
                      ],
                      TextFormField(
                        controller: _patientController,
                        decoration: const InputDecoration(
                          labelText: 'Patient Name & UHID *',
                          hintText: 'Select above or enter name (UHID)',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const Gap(16),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: wards.contains(_ward) ? _ward : wards.first,
                              decoration: const InputDecoration(
                                labelText: 'Ward *',
                                prefixIcon: Icon(Icons.apartment),
                              ),
                              items: wards.map((w) => DropdownMenuItem(value: w, child: Text(w == 'All' ? 'All Wards' : '$w Ward'))).toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _ward = v;
                                  });
                                }
                              },
                            ),
                          ),
                          const Gap(16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: filteredBeds.any((b) => b.bedNo == _bed) ? _bed : (filteredBeds.isNotEmpty ? filteredBeds.first.bedNo : null),
                              decoration: const InputDecoration(
                                labelText: 'Available Bed *',
                                prefixIcon: Icon(Icons.hotel),
                              ),
                              items: filteredBeds.isNotEmpty
                                  ? filteredBeds.map((b) => DropdownMenuItem(value: b.bedNo, child: Text('${b.bedNo} (${b.ward}) - ${b.tariffFormatted}/day'))).toList()
                                  : const [DropdownMenuItem(value: '', child: Text('No available beds'))],
                              onChanged: (v) {
                                if (v != null && v.isNotEmpty) setState(() => _bed = v);
                              },
                              validator: (v) => v == null || v.isEmpty ? 'Bed required' : null,
                            ),
                          ),
                        ],
                      ),
                      const Gap(16),

                      DropdownButtonFormField<String>(
                        value: doctors.contains(_doctor) ? _doctor : (doctors.isNotEmpty ? doctors.first : null),
                        decoration: const InputDecoration(
                          labelText: 'Admitting / Attending Doctor *',
                          prefixIcon: Icon(Icons.person_pin),
                        ),
                        items: doctors.isNotEmpty
                            ? doctors.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList()
                            : const [DropdownMenuItem(value: '', child: Text('No doctors registered'))],
                        onChanged: (v) {
                          if (v != null && v.isNotEmpty) setState(() => _doctor = v);
                        },
                        validator: (v) => v == null || v.isEmpty ? 'Doctor required' : null,
                      ),
                      const Gap(16),

                      TextFormField(
                        controller: _reasonController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Provisional Diagnosis / Admission Reason *',
                          hintText: 'Enter clinical reason for inpatient stay',
                          prefixIcon: Icon(Icons.notes),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const Gap(24),

                      Text(
                        'Financial Deposit & Advance',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Gap(16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _depositController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Advance Deposit Amount (₹) *',
                                prefixIcon: Icon(Icons.currency_rupee),
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const Gap(16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: const ['Cash', 'UPI / QR', 'Card (POS)', 'Bank Transfer (NEFT)'].contains(_paymentMode)
                                  ? _paymentMode
                                  : 'Cash',
                              decoration: const InputDecoration(
                                labelText: 'Payment Mode',
                                prefixIcon: Icon(Icons.payment),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                                DropdownMenuItem(value: 'UPI / QR', child: Text('UPI / QR')),
                                DropdownMenuItem(value: 'Card (POS)', child: Text('Card (POS)')),
                                DropdownMenuItem(value: 'Bank Transfer (NEFT)', child: Text('NEFT / RTGS')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _paymentMode = v);
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
                            onPressed: () => context.go(AppRoutes.ipd),
                            child: const Text('Cancel'),
                          ),
                          const Gap(12),
                          FilledButton.icon(
                            onPressed: _admit,
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Confirm Admission & Assign Bed'),
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
