import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_management/core/router/app_routes.dart';
import 'package:hospital_management/core/widgets/status_chip.dart';
import 'package:hospital_management/core/providers/hms_providers.dart';

class OpdQueueScreen extends ConsumerStatefulWidget {
  const OpdQueueScreen({super.key});

  @override
  ConsumerState<OpdQueueScreen> createState() => _OpdQueueScreenState();
}

class _OpdQueueScreenState extends ConsumerState<OpdQueueScreen> {
  String _selectedDoctor = 'All Consultants';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final queueAsync = ref.watch(opdQueueProvider);
    final staffAsync = ref.watch(staffListProvider);

    final rawDoctors = (staffAsync.value ?? [])
        .where((s) => s.role.toLowerCase().contains('doctor'))
        .map((s) => '${s.name} (${s.department})')
        .toSet()
        .toList();
    final doctorOptions = ['All Consultants', ...rawDoctors];

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('OPD Consultation Queue'),
        actions: [
          FilledButton.icon(
            onPressed: () => context.go(AppRoutes.appointmentsNew),
            icon: const Icon(Icons.add),
            label: const Text('Add Walk-in Token'),
          ),
          const Gap(16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header Bar
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
                    const Icon(Icons.person_pin_outlined),
                    const Gap(8),
                    const Text('Consultant: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: doctorOptions.contains(_selectedDoctor) ? _selectedDoctor : doctorOptions.first,
                      underline: const SizedBox.shrink(),
                      items: doctorOptions.map((doc) => DropdownMenuItem(value: doc, child: Text(doc))).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedDoctor = v);
                      },
                    ),
                    const Spacer(),
                    queueAsync.when(
                      data: (list) {
                        final count = _selectedDoctor == 'All Consultants'
                            ? list.length
                            : list.where((item) => item.doctorName.toLowerCase().contains(_selectedDoctor.split('(').first.trim().toLowerCase())).length;
                        return Chip(
                          label: Text('$count Patients in Queue'),
                          backgroundColor: colorScheme.primaryContainer,
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

            // Queue List
            Expanded(
              child: queueAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading queue: $e')),
                data: (queue) {
                  final filtered = _selectedDoctor == 'All Consultants'
                      ? queue
                      : queue.where((item) => item.doctorName.toLowerCase().contains(_selectedDoctor.split('(').first.trim().toLowerCase())).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No patients in OPD consultation queue for selected doctor.'));
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Text(
                              '#${item.tokenNo}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(item.patientName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                              const Gap(8),
                              Text(item.uhid, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                              const Gap(8),
                              Text('(${item.ageGender})', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                              const Gap(12),
                              StatusChip(label: item.status),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Complaint: ${item.complaint}'),
                                const Gap(2),
                                Text('Vitals: ${item.vitalsSummary}', style: TextStyle(color: Colors.blue.shade800, fontSize: 12)),
                              ],
                            ),
                          ),
                          trailing: FilledButton.icon(
                            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                            label: const Text('Open EMR'),
                            onPressed: () => context.go('/opd/${item.id}'),
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
