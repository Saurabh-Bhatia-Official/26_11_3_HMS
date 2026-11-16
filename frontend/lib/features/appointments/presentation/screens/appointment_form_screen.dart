import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_management/core/providers/hms_providers.dart';
import 'package:hospital_management/core/router/app_routes.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/data/models/hms_models.dart';

class AppointmentFormScreen extends ConsumerStatefulWidget {
  const AppointmentFormScreen({
    super.key,
    this.appointment,
  });

  final AppointmentModel? appointment;

  @override
  ConsumerState<AppointmentFormScreen> createState() =>
      _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends ConsumerState<AppointmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientSearchController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  int? _selectedDoctorId;
  String _selectedSlot = '10:00 AM';
  String _visitType = 'Scheduled Consultation';

  final List<String> _slots = [
    '09:00 AM',
    '09:20 AM',
    '09:40 AM',
    '10:00 AM',
    '10:20 AM',
    '10:40 AM',
    '11:00 AM',
    '11:20 AM',
    '11:40 AM',
    '02:00 PM',
    '02:20 PM',
    '02:40 PM',
  ];

  @override
  void initState() {
    super.initState();
    final appointment = widget.appointment;
    if (appointment == null) return;

    _patientSearchController.text =
        appointment.uhid.trim().toUpperCase() == 'WALK-IN'
            ? appointment.patientName
            : '${appointment.patientName} (${appointment.uhid})';
    _notesController.text = appointment.notes;
    _selectedDate = _parseAppointmentDate(appointment.date) ?? DateTime.now();
    _selectedSlot = appointment.timeSlot;
    _visitType = appointment.visitType;
  }

  DateTime? _parseAppointmentDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;

    final parts = value.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;

    return DateTime(year, month, day);
  }

  @override
  void dispose() {
    _patientSearchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<StaffModel> _availableDoctors(List<StaffModel> staff) => staff
      .where((member) =>
          member.role.toLowerCase().contains('doctor') && member.isActive)
      .toList();

  bool _isPastAppointmentSlot(DateTime date, String slot) {
    final now = DateTime.now();
    final selectedDay = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    if (selectedDay.isBefore(today)) return true;

    final parts = slot.split(' ');
    if (parts.length != 2) return false;
    final timeParts = parts[0].split(':');
    if (timeParts.length != 2) return false;
    var hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    if (hour == null ||
        minute == null ||
        hour < 1 ||
        hour > 12 ||
        minute < 0 ||
        minute > 59) {
      return false;
    }

    final period = parts[1].toUpperCase();
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    if (period != 'AM' && period != 'PM') return false;

    final selectedDateTime =
        DateTime(date.year, date.month, date.day, hour, minute);
    return !selectedDateTime.isAfter(now);
  }

  Future<void> _book() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final existing = widget.appointment;
    final existingDate =
        existing == null ? null : _parseAppointmentDate(existing.date);
    final isUnchangedPastSlot = existingDate != null &&
        DateUtils.isSameDay(existingDate, _selectedDate) &&
        existing?.timeSlot == _selectedSlot;
    if (!isUnchangedPastSlot &&
        _isPastAppointmentSlot(_selectedDate, _selectedSlot)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot book an appointment for a past date or time slot.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final doctors = _availableDoctors(ref.read(staffListProvider).value ?? []);
    final doctor = _selectedDoctorId == null
        ? doctors
                .where(
                  (member) => member.name == widget.appointment?.doctorName,
                )
                .firstOrNull ??
            doctors.firstOrNull
        : doctors.where((member) => member.id == _selectedDoctorId).firstOrNull;
    if (doctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Select an active doctor before booking.')),
      );
      return;
    }

    final db = ref.read(appDatabaseProvider);
    final appointment = widget.appointment;
    final countRes = await db
        .customSelect('SELECT count(*) as count FROM appointments')
        .getSingle();
    final token = appointment?.tokenNo ??
        ((countRes.data['count'] as int) + 1).toString().padLeft(2, '0');

    final nameText = _patientSearchController.text.trim();
    String patientName = nameText;
    String uhid = 'WALK-IN';
    if (nameText.contains('(') && nameText.contains(')')) {
      patientName = nameText.split('(').first.trim();
      uhid = nameText.split('(').last.replaceAll(')', '').trim();
    }

    final apt = AppointmentModel(
      id: appointment?.id ?? 0,
      tokenNo: token,
      patientName: patientName,
      uhid: uhid,
      doctorName: doctor.name,
      department: doctor.department,
      date: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
      timeSlot: _selectedSlot,
      status: appointment?.status ?? 'Scheduled',
      visitType: _visitType,
      notes: _notesController.text.trim(),
    );

    try {
      if (appointment == null) {
        await db.hmsDao.insertAppointment(apt);
      } else {
        await db.hmsDao.updateAppointment(apt);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save appointment: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    ref.invalidate(appointmentsListProvider);
    ref.invalidate(dashboardStatsProvider);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          appointment != null
              ? 'Appointment #$token updated successfully.'
              : 'Appointment confirmed for $patientName at $_selectedSlot (Token #$token)',
        ),
        backgroundColor: Colors.green.shade700,
      ),
    );
    context.go(AppRoutes.appointments);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final staffAsync = ref.watch(staffListProvider);
    final patientsAsync = ref.watch(patientListProvider);

    final staffList = staffAsync.value ?? [];
    final patients = patientsAsync.value ?? [];

    final doctors = _availableDoctors(staffList);
    final selectedDoctor = _selectedDoctorId == null
        ? doctors
                .where(
                  (member) => member.name == widget.appointment?.doctorName,
                )
                .firstOrNull ??
            doctors.firstOrNull
        : doctors.where((member) => member.id == _selectedDoctorId).firstOrNull;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          widget.appointment == null
              ? 'Book Appointment / Token'
              : 'Edit Appointment #${widget.appointment!.tokenNo}',
        ),
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
                              child: Text(
                                  '${p.name} (${p.uhid}) - ${p.phone ?? "-"}'),
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
                      if (staffAsync.isLoading)
                        const LinearProgressIndicator()
                      else if (staffAsync.hasError)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                  'Unable to load doctors: ${staffAsync.error}'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  ref.invalidate(staffListProvider),
                              child: const Text('Retry'),
                            ),
                          ],
                        )
                      else if (doctors.isEmpty)
                        Text(
                          'No active doctors registered. Add an active doctor in the Staff Directory before booking.',
                          style: TextStyle(color: colorScheme.error),
                        )
                      else
                        DropdownButtonFormField<int>(
                          initialValue: selectedDoctor?.id,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Consulting Doctor *',
                            prefixIcon: Icon(Icons.medical_services_outlined),
                          ),
                          validator: (value) => value == null
                              ? 'Select a consulting doctor'
                              : null,
                          items: doctors
                              .map((doctor) => DropdownMenuItem(
                                    value: doctor.id,
                                    child: Text(
                                      '${doctor.name} — ${doctor.department.isEmpty ? 'Specialty not set' : doctor.department}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: (id) {
                            if (id != null) {
                              setState(() => _selectedDoctorId = id);
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                alignment: Alignment.centerLeft,
                              ),
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              ),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate.isBefore(
                                    DateUtils.dateOnly(DateTime.now()),
                                  )
                                      ? DateUtils.dateOnly(DateTime.now())
                                      : _selectedDate,
                                  firstDate: DateUtils.dateOnly(DateTime.now()),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 60)),
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
                              initialValue: const [
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
                          final isPast =
                              _isPastAppointmentSlot(_selectedDate, slot);
                          return ChoiceChip(
                            label: Text(slot),
                            selected: isSelected,
                            onSelected: isPast
                                ? null
                                : (val) {
                                    if (val) {
                                      setState(() => _selectedSlot = slot);
                                    }
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
                          hintText:
                              'e.g. Chest pain for 2 days, previous ECG normal',
                          prefixIcon: Icon(Icons.notes),
                        ),
                      ),
                      const Gap(32),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: doctors.isNotEmpty &&
                                  !staffAsync.isLoading &&
                                  !staffAsync.hasError
                              ? _book
                              : null,
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text(
                            widget.appointment == null
                                ? 'Confirm Booking & Issue Token Slip'
                                : 'Save Appointment Changes',
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
