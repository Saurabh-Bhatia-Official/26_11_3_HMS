import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_management/core/router/app_routes.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/core/providers/hms_providers.dart';
import 'package:hospital_management/data/models/hms_models.dart';
import 'package:hospital_management/features/patients/patients_provider.dart';

class AppointmentFormScreen extends ConsumerStatefulWidget {
  const AppointmentFormScreen({super.key});

  @override
  ConsumerState<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends ConsumerState<AppointmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientSearchController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedDoctor = '';
  String _selectedDepartment = '';
  String _selectedSlot = '10:00 AM';
  String _visitType = 'Scheduled Consultation';

  final List<String> _slots = [
    '09:00 AM', '09:20 AM', '09:40 AM',
    '10:00 AM', '10:20 AM', '10:40 AM',
    '11:00 AM', '11:20 AM', '11:40 AM',
    '02:00 PM', '02:20 PM', '02:40 PM',
  ];

  @override
  void dispose() {
    _patientSearchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _book() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final db = ref.read(appDatabaseProvider);
    final countRes = await db.customSelect('SELECT count(*) as count FROM appointments').getSingle();
    final token = ((countRes.data['count'] as int) + 1).toString().padLeft(2, '0');

    final nameText = _patientSearchController.text.trim();
    String patientName = nameText;
    String uhid = 'WALK-IN';
    if (nameText.contains('(') && nameText.contains(')')) {
      patientName = nameText.split('(').first.trim();
      uhid = nameText.split('(').last.replaceAll(')', '').trim();
    }

    final apt = AppointmentModel(
      id: 0,
      tokenNo: token,
      patientName: patientName,
      uhid: uhid,
      doctorName: _selectedDoctor,
      department: _selectedDepartment,
      date: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
      timeSlot: _selectedSlot,
      status: 'Scheduled',
      visitType: _visitType,
      notes: _notesController.text.trim(),
    );

    await db.hmsDao.insertAppointment(apt);
    ref.invalidate(appointmentsListProvider);
    ref.invalidate(dashboardStatsProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment confirmed for $patientName at $_selectedSlot (Token #$token)'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      context.go(AppRoutes.appointments);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final staffAsync = ref.watch(staffListProvider);
    final patientsAsync = ref.watch(patientListProvider);

    final staffList = staffAsync.value ?? [];
    final patients = patientsAsync.value ?? [];

    final doctors = staffList
        .where((s) => s.role.toLowerCase().contains('doctor'))
        .map((s) => '${s.name} (${s.department})')
        .toSet()
        .toList();
    if (doctors.isEmpty) {
      doctors.add('Duty Doctor (General)');
    }

    if (_selectedDoctor.isEmpty || !doctors.contains(_selectedDoctor)) {
      _selectedDoctor = doctors.first;
      if (_selectedDoctor.contains('(') && _selectedDoctor.contains(')')) {
        _selectedDepartment = _selectedDoctor.split('(').last.replaceAll(')', '').trim();
      }
    }

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Book Appointment / Token'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.appointments),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
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
                        'Appointment Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Gap(24),

                      // Patient Selection from Database
                      if (patients.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Select Registered Patient',
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
                              setState(() {
                                _patientSearchController.text = val;
                              });
                            }
                          },
                        ),
                        const Gap(12),
                      ],

                      // Patient Search / Name
                      TextFormField(
                        controller: _patientSearchController,
                        decoration: const InputDecoration(
                          labelText: 'Patient Name & UHID *',
                          hintText: 'Select above or enter Name (UHID)',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please specify a patient'
                            : null,
                      ),
                      const Gap(16),

                      // Doctor Selection
                      DropdownButtonFormField<String>(
                        value: doctors.contains(_selectedDoctor) ? _selectedDoctor : doctors.first,
                        decoration: const InputDecoration(
                          labelText: 'Consulting Doctor *',
                          prefixIcon: Icon(Icons.medical_services_outlined),
                        ),
                        items: doctors
                            .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              _selectedDoctor = v;
                              if (v.contains('(') && v.contains(')')) {
                                _selectedDepartment = v.split('(').last.replaceAll(')', '').trim();
                              }
                            });
                          }
                        },
                      ),
                      const Gap(16),

                      // Date Picker
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                alignment: Alignment.centerLeft,
                              ),
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              ),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 60)),
                                );
                                if (picked != null) {
                                  setState(() => _selectedDate = picked);
                                }
                              },
                            ),
                          ),
                          const Gap(16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: const [
                                'Scheduled Consultation',
                                'Walk-in Token',
                                'Follow-up Visit',
                              ].contains(_visitType)
                                  ? _visitType
                                  : 'Scheduled Consultation',
                              decoration: const InputDecoration(
                                labelText: 'Visit Type',
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Scheduled Consultation',
                                  child: Text('Scheduled Consultation'),
                                ),
                                DropdownMenuItem(
                                  value: 'Walk-in Token',
                                  child: Text('Walk-in Token'),
                                ),
                                DropdownMenuItem(
                                  value: 'Follow-up Visit',
                                  child: Text('Follow-up Visit'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _visitType = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const Gap(24),

                      Text(
                        'Available Time Slots',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Gap(12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _slots.map((slot) {
                          final isSelected = _selectedSlot == slot;
                          return ChoiceChip(
                            label: Text(slot),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) setState(() => _selectedSlot = slot);
                            },
                          );
                        }).toList(),
                      ),
                      const Gap(20),

                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Chief Complaint / Booking Notes',
                          hintText: 'e.g. Chest pain for 2 days, previous ECG normal',
                          prefixIcon: Icon(Icons.notes),
                        ),
                      ),
                      const Gap(32),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: _book,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Confirm Booking & Issue Token Slip'),
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

