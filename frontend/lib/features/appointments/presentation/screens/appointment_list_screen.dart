import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_management/core/router/app_routes.dart';
import 'package:hospital_management/core/widgets/status_chip.dart';
import 'package:hospital_management/core/providers/hms_providers.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/data/models/hms_models.dart';

class AppointmentListScreen extends ConsumerStatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  ConsumerState<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends ConsumerState<AppointmentListScreen> {
  DateTime _selectedDate = DateTime.now();
  String _doctorFilter = 'All Doctors';

  String _doctorLabel(AppointmentModel item) {
    final doctorName = item.doctorName.trim();
    final department = item.department.trim();
    if (department.isEmpty ||
        doctorName.endsWith('($department)') ||
        doctorName.endsWith('— $department')) {
      return doctorName;
    }
    return '$doctorName — $department';
  }

  Future<void> _updateStatus(AppointmentModel item, String newStatus) async {
    final db = ref.read(appDatabaseProvider);
    await db.hmsDao.updateAppointmentStatus(item.id, newStatus);
    ref.invalidate(appointmentsListProvider);
    ref.invalidate(dashboardStatsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment #${item.tokenNo} status set to $newStatus.'),
          backgroundColor: Colors.teal.shade800,
        ),
      );
    }
  }

  void _confirmDeleteAppointment(AppointmentModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel Appointment #${item.tokenNo}?'),
        content: Text(
          'Are you sure you want to cancel and remove appointment #${item.tokenNo} for ${item.patientName} (${item.uhid}) with ${item.doctorName}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Back')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async {
              Navigator.pop(ctx);
              final db = ref.read(appDatabaseProvider);
              await db.hmsDao.deleteAppointment(item.id, item.patientName);
              ref.invalidate(appointmentsListProvider);
              ref.invalidate(dashboardStatsProvider);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Appointment #${item.tokenNo} for ${item.patientName} cancelled and deleted.'),
                    backgroundColor: Colors.red.shade800,
                  ),
                );
              }
            },
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appointmentsAsync = ref.watch(appointmentsListProvider);
    final staffAsync = ref.watch(staffListProvider);

    final staffList = staffAsync.value ?? [];
    final doctorOptions = [
      'All Doctors',
      ...staffList
          .where((s) => s.role.toLowerCase().contains('doctor'))
          .map((s) => s.name)
          .toSet(),
    ];

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Appointments & Doctor Queues'),
        actions: [
          FilledButton.icon(
            onPressed: () => context.go(AppRoutes.appointmentsNew),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Book Appointment'),
          ),
          const Gap(16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Filter Bar
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Date selector
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                    ),
                    const Gap(16),

                    // Doctor dropdown
                    DropdownButton<String>(
                      value: doctorOptions.contains(_doctorFilter)
                          ? _doctorFilter
                          : 'All Doctors',
                      underline: const SizedBox.shrink(),
                      items: doctorOptions
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _doctorFilter = v);
                      },
                    ),
                    const Spacer(),

                    // Summary counts
                    appointmentsAsync.when(
                      data: (list) {
                        final filtered = _doctorFilter == 'All Doctors'
                            ? list
                            : list.where((a) => a.doctorName.contains(_doctorFilter)).toList();
                        return Text(
                          'Total: ${filtered.length} Slots Booked',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(16),

            // Appointments Table
            Expanded(
              child: appointmentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading appointments: $e')),
                data: (appointments) {
                  final filtered = _doctorFilter == 'All Doctors'
                      ? appointments
                      : appointments.where((a) => a.doctorName.contains(_doctorFilter)).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No appointments booked for this filter.'));
                  }

                  return Card(
                    elevation: 1,
                    clipBehavior: Clip.antiAlias,
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Text(
                              '#${item.tokenNo}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(item.patientName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              const Gap(8),
                              Text(
                                item.uhid,
                                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                              ),
                              const Gap(12),
                              StatusChip(label: item.status),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                const Gap(4),
                                Text(item.timeSlot),
                                const Gap(16),
                                const Icon(Icons.person_pin, size: 14, color: Colors.grey),
                                const Gap(4),
                                Text(_doctorLabel(item)),
                                const Gap(16),
                                Text('Type: ${item.visitType}'),
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PopupMenuButton<String>(
                                tooltip: 'Update Appointment Status',
                                icon: const Icon(Icons.edit_note, size: 20),
                                onSelected: (status) => _updateStatus(item, status),
                                itemBuilder: (ctx) => [
                                  'Scheduled',
                                  'Checked In',
                                  'In Consultation',
                                  'Completed',
                                  'Cancelled',
                                ].map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
                              ),
                              IconButton(
                                icon: const Icon(Icons.print_outlined),
                                tooltip: 'Print Token Slip',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Token #${item.tokenNo} printed.')),
                                  );
                                },
                              ),
                              const Gap(4),
                              FilledButton.tonal(
                                onPressed: () => context.go(AppRoutes.opd),
                                child: const Text('Start OPD'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                tooltip: 'Cancel / Delete Appointment',
                                onPressed: () => _confirmDeleteAppointment(item),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
