import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:hospital_management/core/widgets/kpi_card.dart';
import 'package:hospital_management/core/providers/hms_providers.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportsDataProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Reports & Hospital Analytics'),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Monthly financial report exported to PDF.')),
              );
            },
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: const Text('Export PDF Report'),
          ),
          const Gap(16),
        ],
      ),
      body: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading reports: $e')),
        data: (data) {
          final revenuePaise = data['totalRevenuePaise'] as int;
          final duePaise = data['totalDuePaise'] as int;
          final opdCount = data['totalOpdVisits'] as int;
          final ipdCount = data['totalAdmissions'] as int;
          final departments = data['departments'] as List<Map<String, dynamic>>;

          final totalRevFormatted = '₹${(revenuePaise / 100).toStringAsFixed(0)}';
          final dueFormatted = '₹${(duePaise / 100).toStringAsFixed(0)}';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Revenue summary
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 1100
                        ? 4
                        : constraints.maxWidth > 650
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
                          label: 'This Month Total Revenue',
                          value: totalRevFormatted,
                          icon: Icons.payments_outlined,
                          color: Colors.green.shade700,
                        ),
                        KpiCard(
                          label: 'Total OPD Consultations',
                          value: '$opdCount Visits',
                          icon: Icons.people_outline,
                          color: Colors.blue.shade700,
                        ),
                        KpiCard(
                          label: 'Total IPD Admissions',
                          value: '$ipdCount Patients',
                          icon: Icons.hotel_outlined,
                          color: Colors.indigo.shade600,
                        ),
                        KpiCard(
                          label: 'Outstanding Patient Dues',
                          value: dueFormatted,
                          icon: Icons.warning_amber_rounded,
                          color: Colors.amber.shade900,
                        ),
                      ],
                    );
                  },
                ),
                const Gap(28),

                // Revenue breakdown card
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Revenue Breakdown by Department',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Gap(16),
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(3),
                            1: FlexColumnWidth(2),
                            2: FlexColumnWidth(2),
                            3: FlexColumnWidth(2),
                          },
                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                          children: [
                            const TableRow(
                              decoration: BoxDecoration(color: Color(0x10000000)),
                              children: [
                                Padding(padding: EdgeInsets.all(12), child: Text('Department / Head', style: TextStyle(fontWeight: FontWeight.bold))),
                                Padding(padding: EdgeInsets.all(12), child: Text('Transactions', style: TextStyle(fontWeight: FontWeight.bold))),
                                Padding(padding: EdgeInsets.all(12), child: Text('Revenue (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
                                Padding(padding: EdgeInsets.all(12), child: Text('% Share', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                            ),
                            if (departments.isEmpty)
                              const TableRow(
                                children: [
                                  Padding(padding: EdgeInsets.all(12), child: Text('No revenue transactions recorded')),
                                  Padding(padding: EdgeInsets.all(12), child: Text('0')),
                                  Padding(padding: EdgeInsets.all(12), child: Text('₹0.00')),
                                  Padding(padding: EdgeInsets.all(12), child: Text('0%')),
                                ],
                              )
                            else
                              ...departments.map((dept) {
                                final deptTotal = dept['totalPaise'] as int;
                                final pct = revenuePaise > 0
                                    ? ((deptTotal / revenuePaise) * 100).toStringAsFixed(1)
                                    : '0.0';
                                return TableRow(
                                  children: [
                                    Padding(padding: const EdgeInsets.all(12), child: Text(dept['name'] as String)),
                                    Padding(padding: const EdgeInsets.all(12), child: Text(dept['count'] as String)),
                                    Padding(padding: const EdgeInsets.all(12), child: Text('₹${(deptTotal / 100).toStringAsFixed(2)}')),
                                    Padding(padding: const EdgeInsets.all(12), child: Text('$pct%')),
                                  ],
                                );
                              }),
                          ],
                        ),
                      ],
                    ),
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
