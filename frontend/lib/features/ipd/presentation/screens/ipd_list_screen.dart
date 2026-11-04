import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_management/core/router/app_routes.dart';
import 'package:hospital_management/core/widgets/status_chip.dart';
import 'package:hospital_management/core/providers/hms_providers.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/data/models/hms_models.dart';

class IpdListScreen extends ConsumerStatefulWidget {
  const IpdListScreen({super.key});

  @override
  ConsumerState<IpdListScreen> createState() => _IpdListScreenState();
}

class _IpdListScreenState extends ConsumerState<IpdListScreen> {
  String _selectedWard = 'All Wards';

  Future<void> _dischargePatient(IpdAdmissionModel item) async {
    final db = ref.read(appDatabaseProvider);
    await db.hmsDao.quickDischargePatient(item.id, item.bedNo);
    ref.invalidate(ipdAdmissionsListProvider);
    ref.invalidate(bedsListProvider);
    ref.invalidate(dashboardStatsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.patientName} discharged. Bed ${item.bedNo} marked for cleaning.'),
          backgroundColor: Colors.teal.shade800,
        ),
      );
    }
  }

  void _confirmDeleteAdmission(IpdAdmissionModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Admission for ${item.patientName}?'),
        content: Text(
          'Are you sure you want to delete IPD admission record for ${item.patientName} (${item.uhid})?\n\nThis will remove the admission record and immediately release Bed ${item.bedNo} back to Available status.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Back')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async {
              Navigator.pop(ctx);
              final db = ref.read(appDatabaseProvider);
              await db.hmsDao.deleteIpdAdmission(item.id, item.bedNo, item.patientName);
              ref.invalidate(ipdAdmissionsListProvider);
              ref.invalidate(bedsListProvider);
              ref.invalidate(dashboardStatsProvider);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Admission for ${item.patientName} removed. Bed ${item.bedNo} is now Available.'),
                    backgroundColor: Colors.red.shade800,
                  ),
                );
              }
            },
            child: const Text('Delete Admission'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final admissionsAsync = ref.watch(ipdAdmissionsListProvider);
    final bedsAsync = ref.watch(bedsListProvider);

    final admissions = admissionsAsync.value ?? [];
    final beds = bedsAsync.value ?? [];
    final wardOptions = [
      'All Wards',
      ...admissions.map((a) => a.ward).toSet(),
      ...beds.map((b) => b.ward).toSet(),
    ];

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Inpatient (IPD) Admissions & Wards'),
        actions: [
          OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.beds),
            icon: const Icon(Icons.bed_outlined, size: 18),
            label: const Text('Bed Board'),
          ),
          const Gap(12),
          FilledButton.icon(
            onPressed: () => context.go(AppRoutes.ipdAdmit),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Admit Patient'),
          ),
          const Gap(16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
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
                    const Icon(Icons.apartment),
                    const Gap(8),
                    const Text('Ward: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: wardOptions.contains(_selectedWard)
                          ? _selectedWard
                          : 'All Wards',
                      underline: const SizedBox.shrink(),
                      items: wardOptions
                          .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedWard = v);
                      },
                    ),
                    const Spacer(),
                    admissionsAsync.when(
                      data: (list) => Text(
                        'Total Inpatients: ${list.length}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(16),
            Expanded(
              child: admissionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading IPD admissions: $e')),
                data: (admissions) {
                  final filtered = _selectedWard == 'All Wards'
                      ? admissions
                      : admissions.where((a) => a.ward.contains(_selectedWard.replaceAll(' Ward', ''))).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No active inpatient admissions.'));
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
                            child: Icon(Icons.hotel, color: colorScheme.onPrimaryContainer),
                          ),
                          title: Row(
                            children: [
                              Text(item.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const Gap(8),
                              Text(item.uhid, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                              const Gap(12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${item.ward} • Bed ${item.bedNo}',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                                ),
                              ),
                              const Gap(8),
                              StatusChip(label: item.status),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Admitted: ${item.admitDate} (${item.days} days) • Doctor: ${item.doctorName} • Advance: ${item.depositFormatted}',
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (item.status != 'Discharged') ...[
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.check_circle_outline, size: 16),
                                  label: const Text('Discharge'),
                                  onPressed: () => _dischargePatient(item),
                                ),
                                const Gap(8),
                              ],
                              FilledButton.tonal(
                                onPressed: () => context.go('/ipd/${item.id}'),
                                child: const Text('View Stay & MAR'),
                              ),
                              const Gap(4),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                tooltip: 'Delete Admission Record',
                                onPressed: () => _confirmDeleteAdmission(item),
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
