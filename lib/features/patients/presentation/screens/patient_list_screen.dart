import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_management/core/router/app_routes.dart';
import 'package:hospital_management/core/widgets/empty_state.dart';
import 'package:hospital_management/features/patients/patients_provider.dart';
import 'package:hospital_management/domain/entities/patient.dart';

class PatientListScreen extends ConsumerStatefulWidget {
  const PatientListScreen({super.key});

  @override
  ConsumerState<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends ConsumerState<PatientListScreen> {
  final _searchController = TextEditingController();

  void _confirmDeletePatient(Patient patient) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Archive ${patient.name}?'),
        content: Text(
          'Are you sure you want to delete/archive patient record for ${patient.name} (${patient.uhid})?\n\nThis will remove them from the active patient registry.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = ref.read(patientRepositoryProvider);
              await repo.softDelete(patient.id);
              ref.invalidate(patientListProvider);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Patient record for ${patient.name} archived.'),
                    backgroundColor: Colors.red.shade800,
                  ),
                );
              }
            },
            child: const Text('Archive Patient'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(patientListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Patient Directory'),
        actions: [
          FilledButton.icon(
            onPressed: () => context.go(AppRoutes.patientsNew),
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: const Text('New Registration'),
          ),
          const Gap(16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Search Bar
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search patients by name, UHID, or phone number…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(patientSearchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onChanged: (value) {
                    ref.read(patientSearchQueryProvider.notifier).state = value.trim();
                  },
                ),
              ),
            ),
            const Gap(16),

            // Patient List
            Expanded(
              child: patientsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error loading patients: $err')),
                data: (patients) {
                  if (patients.isEmpty) {
                    return EmptyState(
                      icon: Icons.person_search_outlined,
                      message: 'No patients found. Register a new patient to get started.',
                      action: FilledButton.icon(
                        onPressed: () => context.go(AppRoutes.patientsNew),
                        icon: const Icon(Icons.add),
                        label: const Text('Register Patient'),
                      ),
                    );
                  }

                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListView.separated(
                      itemCount: patients.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final patient = patients[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Text(
                              patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                patient.name,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                              const Gap(8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  patient.uhid,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                              if (patient.isVip) ...[
                                const Gap(6),
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                              ],
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Text('${patient.gender ?? "Unspecified"} • Age: ${patient.age}'),
                                const Gap(16),
                                if (patient.bloodGroup != null) ...[
                                  Text('Blood: ${patient.bloodGroup}'),
                                  const Gap(16),
                                ],
                                if (patient.phone != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.phone, size: 14, color: Colors.grey),
                                      const Gap(4),
                                      Text(patient.phone!),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                tooltip: 'Edit Patient',
                                onPressed: () => context.go('/patients/${patient.id}/edit'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.calendar_month_outlined, size: 20),
                                tooltip: 'Book Appointment',
                                onPressed: () => context.go(AppRoutes.appointmentsNew),
                              ),
                              IconButton(
                                icon: const Icon(Icons.hotel_outlined, size: 20),
                                tooltip: 'Admit to Ward',
                                onPressed: () => context.go(AppRoutes.ipdAdmit),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                tooltip: 'Archive Patient',
                                onPressed: () => _confirmDeletePatient(patient),
                              ),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                          onTap: () => context.go('/patients/${patient.id}'),
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
