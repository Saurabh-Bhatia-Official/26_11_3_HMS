import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_management/core/providers/hms_providers.dart';
import 'package:hospital_management/core/router/app_routes.dart';
import 'package:hospital_management/core/widgets/status_chip.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/domain/entities/patient.dart';
import 'package:hospital_management/features/patients/patients_provider.dart';

class PatientProfileScreen extends ConsumerWidget {
  const PatientProfileScreen({super.key, required this.patientId});

  final int patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(selectedPatientProvider(patientId));
    final allergiesAsync = ref.watch(patientAllergiesProvider(patientId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Patient Record (EMR 360)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.patients),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print Registration Card',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Registration card sent to printer.')),
              );
            },
          ),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit Profile'),
            onPressed: () => context.go('/patients/$patientId/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete / Archive Patient',
            onPressed: () {
              final patient = patientAsync.value;
              if (patient == null) return;
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
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Patient record for ${patient.name} archived.'),
                              backgroundColor: Colors.red.shade800,
                            ),
                          );
                          context.go(AppRoutes.patients);
                        }
                      },
                      child: const Text('Archive Patient'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Gap(8),
        ],
      ),
      body: patientAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading profile: $err')),
        data: (patient) {
          if (patient == null) {
            return const Center(child: Text('Patient not found.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Patient Banner Card ──────────────────────────────────────
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Text(
                            patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const Gap(20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    patient.name,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Gap(12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      patient.uhid,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: colorScheme.onSecondaryContainer,
                                      ),
                                    ),
                                  ),
                                  if (patient.isVip) ...[
                                    const Gap(8),
                                    const Chip(
                                      label: Text('VIP Patient', style: TextStyle(fontSize: 11)),
                                      avatar: Icon(Icons.star, color: Colors.amber, size: 16),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ],
                              ),
                              const Gap(8),
                              Wrap(
                                spacing: 20,
                                runSpacing: 6,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                                      const Gap(4),
                                      Text('${patient.gender} • ${patient.age} yrs'),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.bloodtype_outlined, size: 16, color: Colors.red),
                                      const Gap(4),
                                      Text('Blood Group: ${patient.bloodGroup ?? "N/A"}'),
                                    ],
                                  ),
                                  if (patient.phone != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                                        const Gap(4),
                                        Text(patient.phone!),
                                      ],
                                    ),
                                  if (patient.city != null && patient.city!.isNotEmpty)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                                        const Gap(4),
                                        Text(patient.city!),
                                      ],
                                    ),
                                ],
                              ),
                              if (patient.emergencyContactName != null &&
                                  patient.emergencyContactName!.isNotEmpty) ...[
                                const Gap(8),
                                Text(
                                  'Emergency Contact: ${patient.emergencyContactName} (${patient.emergencyContactPhone ?? "No phone"})',
                                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Quick Action Buttons
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            FilledButton.icon(
                              onPressed: () => context.go(AppRoutes.appointmentsNew),
                              icon: const Icon(Icons.calendar_month, size: 16),
                              label: const Text('Book OPD Visit'),
                            ),
                            const Gap(8),
                            OutlinedButton.icon(
                              onPressed: () => context.go(AppRoutes.ipdAdmit),
                              icon: const Icon(Icons.hotel, size: 16),
                              label: const Text('Admit to IPD'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(20),

                // ── Allergies Alert Banner ───────────────────────────────────
                allergiesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (allergies) {
                    if (allergies.isEmpty && (patient.notes == null || patient.notes!.isEmpty)) {
                      return const SizedBox.shrink();
                    }
                    return Card(
                      color: Colors.red.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.red.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.warning_rounded, color: Colors.red.shade700),
                            const Gap(12),
                            Expanded(
                              child: Text(
                                patient.notes != null && patient.notes!.isNotEmpty
                                    ? 'Clinical Alert / Allergies: ${patient.notes}'
                                    : 'Recorded allergies: ${allergies.map((a) => a.allergen).join(", ")}',
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const Gap(20),

                // ── Clinical Timeline / Modules Tabs ─────────────────────────
                DefaultTabController(
                  length: 4,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: colorScheme.primary,
                        unselectedLabelColor: colorScheme.onSurfaceVariant,
                        indicatorColor: colorScheme.primary,
                        tabs: const [
                          Tab(icon: Icon(Icons.history_edu), text: 'OPD Consultations'),
                          Tab(icon: Icon(Icons.hotel), text: 'IPD Admissions'),
                          Tab(icon: Icon(Icons.biotech), text: 'Lab Reports'),
                          Tab(icon: Icon(Icons.receipt_long), text: 'Bills & Invoices'),
                        ],
                      ),
                      const Gap(16),
                      SizedBox(
                        height: 380,
                        child: TabBarView(
                          children: [
                            _buildOpdHistory(context, ref, patient),
                            _buildIpdHistory(context, ref, patient),
                            _buildLabHistory(context, ref, patient),
                            _buildBillingHistory(context, ref, patient),
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

  Widget _buildOpdHistory(BuildContext context, WidgetRef ref, Patient patient) {
    final visitsAsync = ref.watch(opdQueueProvider);

    return Card(
      elevation: 0.5,
      child: visitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allVisits) {
          final visits = allVisits.where((v) =>
            v.uhid.toLowerCase() == patient.uhid.toLowerCase() ||
            v.patientName.toLowerCase() == patient.name.toLowerCase()
          ).toList();

          if (visits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.medical_services_outlined, size: 48, color: Colors.grey),
                  const Gap(8),
                  Text('No OPD consultations recorded yet for ${patient.name}.'),
                  const Gap(12),
                  OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.appointmentsNew),
                    icon: const Icon(Icons.add),
                    label: const Text('Book Consultation'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: visits.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final v = visits[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.medical_services_outlined)),
                title: Text('${v.department} Consultation', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Doctor: ${v.doctorName} • Token #${v.tokenNo}\nChief Complaint: ${v.complaint.isNotEmpty ? v.complaint : "Routine"}'),
                isThreeLine: true,
                trailing: StatusChip(label: v.status),
                onTap: () => context.go(AppRoutes.opd),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildIpdHistory(BuildContext context, WidgetRef ref, Patient patient) {
    final ipdAsync = ref.watch(ipdAdmissionsListProvider);

    return Card(
      elevation: 0.5,
      child: ipdAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allAdmissions) {
          final admissions = allAdmissions.where((a) =>
            a.uhid.toLowerCase() == patient.uhid.toLowerCase() ||
            a.patientName.toLowerCase() == patient.name.toLowerCase()
          ).toList();

          if (admissions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hotel_outlined, size: 48, color: Colors.grey),
                  const Gap(8),
                  Text('No prior inpatient admissions recorded for ${patient.name}.'),
                  const Gap(12),
                  OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.ipdAdmit),
                    icon: const Icon(Icons.add),
                    label: const Text('Admit Patient to Ward'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: admissions.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final a = admissions[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.hotel)),
                title: Text('Ward: ${a.ward} • Bed: ${a.bedNo}', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Doctor: ${a.doctorName} • Admitted: ${a.admitDate}\nDiagnosis: ${a.diagnosis}'),
                isThreeLine: true,
                trailing: StatusChip(label: a.status),
                onTap: () => context.go(AppRoutes.ipd),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLabHistory(BuildContext context, WidgetRef ref, Patient patient) {
    final labAsync = ref.watch(labOrdersListProvider);

    return Card(
      elevation: 0.5,
      child: labAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allOrders) {
          final orders = allOrders.where((o) =>
            o.uhid.toLowerCase() == patient.uhid.toLowerCase() ||
            o.patientName.toLowerCase() == patient.name.toLowerCase()
          ).toList();

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.biotech, size: 48, color: Colors.grey),
                  const Gap(8),
                  Text('No laboratory investigations ordered for ${patient.name}.'),
                  const Gap(12),
                  OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.lab),
                    icon: const Icon(Icons.add),
                    label: const Text('Go to Laboratory'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final o = orders[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.science_outlined)),
                title: Text(o.testName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Sample: ${o.sampleType} • Doctor: ${o.doctorName}\nOrdered: ${o.orderedAt} • Priority: ${o.priority}'),
                isThreeLine: true,
                trailing: StatusChip(label: o.status),
                onTap: () => context.go(AppRoutes.lab),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBillingHistory(BuildContext context, WidgetRef ref, Patient patient) {
    final invoicesAsync = ref.watch(invoicesListProvider);

    return Card(
      elevation: 0.5,
      child: invoicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allInvoices) {
          final invoices = allInvoices.where((i) =>
            i.uhid.toLowerCase() == patient.uhid.toLowerCase() ||
            i.patientName.toLowerCase() == patient.name.toLowerCase()
          ).toList();

          if (invoices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_outlined, size: 48, color: Colors.grey),
                  const Gap(8),
                  Text('No billing invoices generated yet for ${patient.name}.'),
                  const Gap(12),
                  OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.billing),
                    icon: const Icon(Icons.add),
                    label: const Text('Go to Billing'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: invoices.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final inv = invoices[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.receipt_outlined)),
                title: Text('Invoice #${inv.invoiceNo}', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${inv.billType} • Mode: ${inv.paymentMode}\nDate: ${inv.dateTime}'),
                isThreeLine: true,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${(inv.totalPaise / 100).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const Gap(4),
                    StatusChip(label: inv.status),
                  ],
                ),
                onTap: () => context.go(AppRoutes.billing),
              );
            },
          );
        },
      ),
    );
  }
}
