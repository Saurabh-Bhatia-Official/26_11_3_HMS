import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_management/core/router/app_routes.dart';
import 'package:hospital_management/core/widgets/status_chip.dart';
import 'package:hospital_management/core/providers/hms_providers.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/data/models/hms_models.dart';

class IpdAdmissionScreen extends ConsumerStatefulWidget {
  const IpdAdmissionScreen({super.key, required this.admissionId});

  final String admissionId;

  @override
  ConsumerState<IpdAdmissionScreen> createState() => _IpdAdmissionScreenState();
}

class _IpdAdmissionScreenState extends ConsumerState<IpdAdmissionScreen> {
  final _newNoteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _newNoteController.dispose();
    super.dispose();
  }

  int get _parsedAdmissionId => int.tryParse(widget.admissionId) ?? 1;

  Future<void> _addNote(int admissionId) async {
    final text = _newNoteController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSaving = true);
    final db = ref.read(appDatabaseProvider);
    final now = TimeOfDay.now();
    final timeStr = 'Today, ${now.format(context)}';

    await db.hmsDao.addIpdNursingNote(admissionId, {
      'time': timeStr,
      'author': 'Duty Nurse',
      'note': text,
    });

    _newNoteController.clear();
    ref.invalidate(ipdAdmissionDetailProvider(_parsedAdmissionId));
    ref.invalidate(ipdAdmissionsListProvider);
    setState(() => _isSaving = false);
  }

  void _insertQuickNote(String snippet) {
    if (_newNoteController.text.isEmpty) {
      _newNoteController.text = snippet;
    } else {
      _newNoteController.text = '${_newNoteController.text}. $snippet';
    }
  }

  Future<void> _markMedicationGiven(int admissionId, int index, String medName) async {
    final db = ref.read(appDatabaseProvider);
    await db.hmsDao.updateIpdMedicationStatus(admissionId, index, 'Given', 'Duty Nurse');
    ref.invalidate(ipdAdmissionDetailProvider(_parsedAdmissionId));
    ref.invalidate(ipdAdmissionsListProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Administered: $medName')),
      );
    }
  }

  void _discharge(IpdAdmissionModel admission) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Initiate Patient Discharge?'),
        content: Text(
          'This will mark ${admission.patientName} as Discharged, free up Bed ${admission.bedNo} for sanitization, and redirect to Billing for final settlement.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final db = ref.read(appDatabaseProvider);
              await db.hmsDao.quickDischargePatient(admission.id, admission.bedNo);
              ref.invalidate(ipdAdmissionDetailProvider(_parsedAdmissionId));
              ref.invalidate(ipdAdmissionsListProvider);
              ref.invalidate(bedsListProvider);
              ref.invalidate(dashboardStatsProvider);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${admission.patientName} discharged. Bed ${admission.bedNo} sent for cleaning.'),
                  ),
                );
                context.go(AppRoutes.billing);
              }
            },
            child: const Text('Confirm Discharge'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final admissionAsync = ref.watch(ipdAdmissionDetailProvider(_parsedAdmissionId));

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Inpatient Record & Medication Chart (MAR)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.ipd),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Discharge summary generated & sent to printer.')),
              );
            },
            icon: const Icon(Icons.print_outlined, size: 18),
            label: const Text('Print Summary'),
          ),
          const Gap(12),
          admissionAsync.maybeWhen(
            data: (adm) {
              if (adm == null || adm.status == 'Discharged') return const SizedBox.shrink();
              return FilledButton.icon(
                onPressed: () => _discharge(adm),
                style: FilledButton.styleFrom(backgroundColor: Colors.teal.shade700),
                icon: const Icon(Icons.exit_to_app_rounded, size: 18),
                label: const Text('Discharge Patient'),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          const Gap(16),
        ],
      ),
      body: admissionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading inpatient record: $e')),
        data: (admission) {
          if (admission == null) {
            return const Center(child: Text('Inpatient record not found.'));
          }

          final medications = admission.medications;
          final nursingNotes = admission.notes;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Inpatient Header Card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(Icons.hotel, size: 28, color: colorScheme.onPrimaryContainer),
                        ),
                        const Gap(16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    admission.patientName,
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  Chip(
                                    label: Text(admission.uhid, style: const TextStyle(fontSize: 11)),
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: colorScheme.secondaryContainer,
                                  ),
                                  StatusChip(label: '${admission.ward} • Bed ${admission.bedNo}'),
                                  if (admission.status == 'Discharged')
                                    const StatusChip(label: 'Discharged'),
                                ],
                              ),
                              const Gap(6),
                              Text(
                                'Admitted: ${admission.admitDate} (${admission.days} days) • Doctor: ${admission.doctorName} • Diagnosis: ${admission.diagnosis} • Advance Deposit: ₹${(admission.depositPaise / 100).toStringAsFixed(0)}',
                                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(20),

                // Tabs for MAR and Nursing Notes
                DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: colorScheme.primary,
                        unselectedLabelColor: colorScheme.onSurfaceVariant,
                        indicatorColor: colorScheme.primary,
                        tabs: const [
                          Tab(icon: Icon(Icons.medication), text: 'Medication Administration Record (MAR)'),
                          Tab(icon: Icon(Icons.note_alt), text: 'Nursing & Doctor Round Notes'),
                        ],
                      ),
                      const Gap(16),
                      SizedBox(
                        height: 520,
                        child: TabBarView(
                          children: [
                            // ─── MAR Tab ───
                            Card(
                              elevation: 0.5,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: medications.isEmpty
                                  ? const Center(child: Text('No medications scheduled for this patient.'))
                                  : ListView.separated(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: medications.length,
                                      separatorBuilder: (_, __) => const Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        final item = medications[index];
                                        final isGiven = item['status'] == 'Given';
                                        return ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: isGiven
                                                ? Colors.green.shade100
                                                : Colors.orange.shade100,
                                            child: Icon(
                                              isGiven ? Icons.check : Icons.access_time,
                                              color: isGiven
                                                  ? Colors.green.shade900
                                                  : Colors.orange.shade900,
                                            ),
                                          ),
                                          title: Text(
                                            item['medicine'] ?? 'Medicine',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Text(
                                            '${item["frequency"] ?? ""} • Scheduled: ${item["scheduled"] ?? "Pending"} • Given By: ${item["givenBy"] ?? "-"}',
                                          ),
                                          trailing: isGiven
                                              ? const StatusChip(label: 'Administered')
                                              : FilledButton.tonalIcon(
                                                  onPressed: () => _markMedicationGiven(
                                                    admission.id,
                                                    index,
                                                    item['medicine'] ?? 'Medicine',
                                                  ),
                                                  icon: const Icon(Icons.check, size: 16),
                                                  label: const Text('Mark Given'),
                                                ),
                                        );
                                      },
                                    ),
                            ),

                            // ─── Nursing Notes Tab ───
                            Card(
                              elevation: 0.5,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Quick note chips
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        ActionChip(
                                          avatar: const Icon(Icons.flash_on, size: 14),
                                          label: const Text('Vitals stable, afebrile'),
                                          onPressed: () => _insertQuickNote('Vitals stable, afebrile, pulse normal'),
                                        ),
                                        ActionChip(
                                          avatar: const Icon(Icons.flash_on, size: 14),
                                          label: const Text('Wound clean & dressing dry'),
                                          onPressed: () => _insertQuickNote('Post-op surgical site clean and dressing dry, no soakage'),
                                        ),
                                        ActionChip(
                                          avatar: const Icon(Icons.flash_on, size: 14),
                                          label: const Text('Tolerating soft diet'),
                                          onPressed: () => _insertQuickNote('Patient tolerating oral fluids and soft diet comfortably'),
                                        ),
                                        ActionChip(
                                          avatar: const Icon(Icons.flash_on, size: 14),
                                          label: const Text('Doctor rounds completed'),
                                          onPressed: () => _insertQuickNote('Attending consultant rounds completed. Advised continuation of current plan'),
                                        ),
                                      ],
                                    ),
                                    const Gap(12),

                                    // Note text input
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _newNoteController,
                                            decoration: const InputDecoration(
                                              hintText: 'Add clinical observation / nursing note…',
                                              prefixIcon: Icon(Icons.edit_note),
                                            ),
                                            onSubmitted: (_) => _addNote(admission.id),
                                          ),
                                        ),
                                        const Gap(12),
                                        FilledButton.icon(
                                          onPressed: _isSaving ? null : () => _addNote(admission.id),
                                          icon: _isSaving
                                              ? const SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                )
                                              : const Icon(Icons.send, size: 16),
                                          label: const Text('Post Note'),
                                        ),
                                      ],
                                    ),
                                    const Gap(16),

                                    // List of Notes
                                    Expanded(
                                      child: nursingNotes.isEmpty
                                          ? const Center(child: Text('No nursing notes recorded yet.'))
                                          : ListView.separated(
                                              itemCount: nursingNotes.length,
                                              separatorBuilder: (_, __) => const Divider(height: 1),
                                              itemBuilder: (context, idx) {
                                                final note = nursingNotes[idx];
                                                return ListTile(
                                                  contentPadding: EdgeInsets.zero,
                                                  title: Row(
                                                    children: [
                                                      Text(
                                                        note['author'] ?? 'Staff',
                                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                                      ),
                                                      const Gap(12),
                                                      Text(
                                                        note['time'] ?? '',
                                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                      ),
                                                    ],
                                                  ),
                                                  subtitle: Padding(
                                                    padding: const EdgeInsets.only(top: 4),
                                                    child: Text(
                                                      note['note'] ?? '',
                                                      style: const TextStyle(fontSize: 13),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
