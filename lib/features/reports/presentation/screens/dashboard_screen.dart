import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_management/core/router/app_routes.dart';
import 'package:hospital_management/core/widgets/kpi_card.dart';
import 'package:hospital_management/core/widgets/section_header.dart';
import 'package:hospital_management/core/widgets/status_chip.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/core/providers/hms_providers.dart';

class DashboardStats {
  final int todayOpdVisits;
  final int todayAppointments;
  final int currentAdmissions;
  final int todayRevenuePaise;
  final int availableBeds;
  final int totalBeds;
  final int pendingLabOrders;
  final int lowStockMedicines;

  const DashboardStats({
    required this.todayOpdVisits,
    required this.todayAppointments,
    required this.currentAdmissions,
    required this.todayRevenuePaise,
    required this.availableBeds,
    required this.totalBeds,
    required this.pendingLabOrders,
    required this.lowStockMedicines,
  });

  double get bedOccupancyRate =>
      totalBeds == 0 ? 0 : ((totalBeds - availableBeds) / totalBeds) * 100;
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final data = await db.hmsDao.getDashboardStats();

  return DashboardStats(
    todayOpdVisits: data['todayOpdVisits'] as int,
    todayAppointments: data['todayAppointments'] as int,
    currentAdmissions: data['currentAdmissions'] as int,
    todayRevenuePaise: data['todayRevenuePaise'] as int,
    availableBeds: data['availableBeds'] as int,
    totalBeds: data['totalBeds'] as int,
    pendingLabOrders: data['pendingLabOrders'] as int,
    lowStockMedicines: data['lowStockMedicines'] as int,
  );
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final lowStockAsync = ref.watch(lowStockMedicinesProvider);
    final nearExpiryAsync = ref.watch(nearExpiryBatchesProvider);
    final bedsAsync = ref.watch(bedsListProvider);
    final queueAsync = ref.watch(opdQueueProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading dashboard: $err')),
        data: (stats) {
          final revenueFormatted =
              '₹${(stats.todayRevenuePaise / 100).toStringAsFixed(0)}';

          return RefreshIndicator(
            onRefresh: () => ref.refresh(dashboardStatsProvider.future),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Welcome Banner ─────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hospital Operations Overview',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const Gap(4),
                          Text(
                            'Real-time status across OPD, IPD, Wards, Laboratory, and Billing',
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: () => context.go(AppRoutes.patientsNew),
                            icon: const Icon(Icons.person_add_rounded, size: 18),
                            label: const Text('Register Patient'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.go(AppRoutes.appointmentsNew),
                            icon: const Icon(Icons.add_task_rounded, size: 18),
                            label: const Text('Book Appointment'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Gap(24),

                  // ── KPI Cards Grid ─────────────────────────────────────────
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 1200
                          ? 4
                          : constraints.maxWidth > 700
                              ? 2
                              : 1;

                      return GridView(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 160,
                        ),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          KpiCard(
                            label: "Today's OPD Patients",
                            value: stats.todayOpdVisits.toString(),
                            icon: Icons.people_outline_rounded,
                            color: Colors.blue.shade700,
                            subtitle: (queueAsync.value?.length ?? 0) > 0
                                ? '${queueAsync.value!.length} in active queue'
                                : 'Queue completed',
                            onTap: () => context.go(AppRoutes.opd),
                          ),
                          KpiCard(
                            label: "Today's Revenue",
                            value: revenueFormatted,
                            icon: Icons.currency_rupee_rounded,
                            color: Colors.green.shade700,
                            subtitle: 'Billing & pharmacy combined',
                            onTap: () => context.go(AppRoutes.billing),
                          ),
                          KpiCard(
                            label: 'Bed Occupancy',
                            value: '${stats.bedOccupancyRate.toStringAsFixed(0)}%',
                            icon: Icons.hotel_rounded,
                            color: Colors.indigo.shade600,
                            subtitle:
                                '${stats.totalBeds - stats.availableBeds} of ${stats.totalBeds} beds occupied',
                            onTap: () => context.go(AppRoutes.beds),
                          ),
                          KpiCard(
                            label: 'Pending Lab Tests',
                            value: stats.pendingLabOrders.toString(),
                            icon: Icons.biotech_rounded,
                            color: Colors.amber.shade800,
                            subtitle: stats.pendingLabOrders > 0
                                ? '${stats.pendingLabOrders} tests awaiting results'
                                : 'All lab reports processed',
                            onTap: () => context.go(AppRoutes.lab),
                          ),
                        ],
                      );
                    },
                  ),
                  const Gap(32),

                  // ── Today's Queue & Activity ───────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Live Queue
                      Expanded(
                        flex: 3,
                        child: Card(
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SectionHeader(
                                  title: "Today's OPD Queue",
                                  trailing: TextButton(
                                    onPressed: () => context.go(AppRoutes.opd),
                                    child: const Text('View All Queue'),
                                  ),
                                ),
                                const Gap(12),
                                _buildQueueList(context, ref),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Gap(20),

                      // Right: Alerts & Shortcuts
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            Card(
                              elevation: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SectionHeader(title: 'Active Alerts'),
                                    const Gap(16),
                                    _buildAlertItem(
                                      icon: Icons.warning_amber_rounded,
                                      color: (lowStockAsync.value?.isNotEmpty ?? false)
                                          ? Colors.red.shade700
                                          : Colors.teal.shade700,
                                      title: (lowStockAsync.value?.isNotEmpty ?? false)
                                          ? '${lowStockAsync.value!.length} Medicines Low in Stock'
                                          : 'Formulary Stock Optimal',
                                      subtitle: (lowStockAsync.value?.isNotEmpty ?? false)
                                          ? lowStockAsync.value!.take(3).map((m) => m.name).join(', ')
                                          : 'All medicines above reorder threshold',
                                      actionLabel: 'Inventory',
                                      onTap: () => context.go(AppRoutes.pharmacy),
                                    ),
                                    const Divider(height: 24),
                                    _buildAlertItem(
                                      icon: Icons.access_time_rounded,
                                      color: (nearExpiryAsync.value?.isNotEmpty ?? false)
                                          ? Colors.orange.shade700
                                          : Colors.teal.shade700,
                                      title: (nearExpiryAsync.value?.isNotEmpty ?? false)
                                          ? '${nearExpiryAsync.value!.length} Batches Near Expiry (< 90 days)'
                                          : 'Zero Expired Batches',
                                      subtitle: (nearExpiryAsync.value?.isNotEmpty ?? false)
                                          ? nearExpiryAsync.value!.take(2).map((b) => '${b.medicineName} (${b.batchNo})').join(', ')
                                          : 'All batches within safe expiry threshold',
                                      actionLabel: 'Batches',
                                      onTap: () => context.go(AppRoutes.pharmacy),
                                    ),
                                    const Divider(height: 24),
                                    () {
                                      final cleaningBeds = (bedsAsync.value ?? []).where((b) => b.status == 'Cleaning').toList();
                                      return _buildAlertItem(
                                        icon: Icons.bed_outlined,
                                        color: cleaningBeds.isNotEmpty
                                            ? Colors.blue.shade700
                                            : Colors.green.shade700,
                                        title: cleaningBeds.isNotEmpty
                                            ? '${cleaningBeds.length} Inpatient Bed(s) Need Cleaning'
                                            : 'All Inpatient Beds Sanitized',
                                        subtitle: cleaningBeds.isNotEmpty
                                            ? 'Beds: ${cleaningBeds.map((b) => b.bedNo).join(", ")}'
                                            : 'Clean and ready for admissions',
                                        actionLabel: 'Beds',
                                        onTap: () => context.go(AppRoutes.beds),
                                      );
                                    }(),
                                  ],
                                ),
                              ),
                            ),
                            const Gap(20),
                            Card(
                              elevation: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SectionHeader(title: 'Quick Actions'),
                                    const Gap(16),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        ActionChip(
                                          avatar: const Icon(Icons.person_add, size: 16),
                                          label: const Text('New Patient'),
                                          onPressed: () => context.go(AppRoutes.patientsNew),
                                        ),
                                        ActionChip(
                                          avatar: const Icon(Icons.hotel, size: 16),
                                          label: const Text('Admit Patient'),
                                          onPressed: () => context.go(AppRoutes.ipdAdmit),
                                        ),
                                        ActionChip(
                                          avatar: const Icon(Icons.medication, size: 16),
                                          label: const Text('Dispense Rx'),
                                          onPressed: () => context.go(AppRoutes.pharmacy),
                                        ),
                                        ActionChip(
                                          avatar: const Icon(Icons.receipt, size: 16),
                                          label: const Text('New Invoice'),
                                          onPressed: () => context.go(AppRoutes.billing),
                                        ),
                                      ],
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQueueList(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(opdQueueProvider);

    return queueAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Center(child: Text('Error loading queue: $e')),
      data: (queue) {
        if (queue.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No active patients in OPD queue.'),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: queue.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = queue[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  '#${item.tokenNo}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              title: Text(item.patientName, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${item.doctorName} • ${item.department}'),
              trailing: StatusChip(label: item.status),
              onTap: () => context.go(AppRoutes.opd),
            );
          },
        );
      },
    );
  }

  Widget _buildAlertItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const Gap(2),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(actionLabel, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}

