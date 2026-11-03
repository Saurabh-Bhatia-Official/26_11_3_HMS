import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_management/core/widgets/status_chip.dart';
import 'package:hospital_management/core/providers/hms_providers.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/data/models/lab_models.dart';
import 'package:hospital_management/features/patients/patients_provider.dart';

class LabOrderQueueScreen extends ConsumerStatefulWidget {
  const LabOrderQueueScreen({super.key});

  @override
  ConsumerState<LabOrderQueueScreen> createState() => _LabOrderQueueScreenState();
}

class _LabOrderQueueScreenState extends ConsumerState<LabOrderQueueScreen> {
  String _selectedStatusFilter = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static const Map<String, List<Map<String, dynamic>>> _testTemplates = {
    'Complete Blood Count (CBC)': [
      {'param': 'Hemoglobin (Hb)', 'val': '', 'unit': 'g/dL', 'refLow': 13.0, 'refHigh': 17.0},
      {'param': 'Total Leukocyte Count (WBC)', 'val': '', 'unit': '/mcL', 'refLow': 4000.0, 'refHigh': 11000.0},
      {'param': 'Platelet Count', 'val': '', 'unit': '/mcL', 'refLow': 150000.0, 'refHigh': 450000.0},
      {'param': 'Packed Cell Volume (PCV)', 'val': '', 'unit': '%', 'refLow': 40.0, 'refHigh': 50.0},
      {'param': 'RBC Count', 'val': '', 'unit': 'mil/mcL', 'refLow': 4.5, 'refHigh': 5.5},
    ],
    'Liver Function Test (LFT)': [
      {'param': 'Total Bilirubin', 'val': '', 'unit': 'mg/dL', 'refLow': 0.2, 'refHigh': 1.2},
      {'param': 'Direct Bilirubin', 'val': '', 'unit': 'mg/dL', 'refLow': 0.0, 'refHigh': 0.3},
      {'param': 'SGOT / AST', 'val': '', 'unit': 'U/L', 'refLow': 10.0, 'refHigh': 40.0},
      {'param': 'SGPT / ALT', 'val': '', 'unit': 'U/L', 'refLow': 10.0, 'refHigh': 45.0},
      {'param': 'Alkaline Phosphatase (ALP)', 'val': '', 'unit': 'U/L', 'refLow': 44.0, 'refHigh': 147.0},
      {'param': 'Serum Albumin', 'val': '', 'unit': 'g/dL', 'refLow': 3.5, 'refHigh': 5.2},
    ],
    'Kidney Function Test (KFT / RFT)': [
      {'param': 'Serum Creatinine', 'val': '', 'unit': 'mg/dL', 'refLow': 0.7, 'refHigh': 1.3},
      {'param': 'Blood Urea Nitrogen (BUN)', 'val': '', 'unit': 'mg/dL', 'refLow': 7.0, 'refHigh': 20.0},
      {'param': 'Serum Uric Acid', 'val': '', 'unit': 'mg/dL', 'refLow': 3.5, 'refHigh': 7.2},
      {'param': 'Serum Sodium (Na+)', 'val': '', 'unit': 'mEq/L', 'refLow': 135.0, 'refHigh': 145.0},
      {'param': 'Serum Potassium (K+)', 'val': '', 'unit': 'mEq/L', 'refLow': 3.5, 'refHigh': 5.1},
    ],
    'Lipid Profile': [
      {'param': 'Total Cholesterol', 'val': '', 'unit': 'mg/dL', 'refLow': 125.0, 'refHigh': 200.0},
      {'param': 'HDL Cholesterol (Good)', 'val': '', 'unit': 'mg/dL', 'refLow': 40.0, 'refHigh': 60.0},
      {'param': 'LDL Cholesterol (Bad)', 'val': '', 'unit': 'mg/dL', 'refLow': 50.0, 'refHigh': 100.0},
      {'param': 'Triglycerides', 'val': '', 'unit': 'mg/dL', 'refLow': 50.0, 'refHigh': 150.0},
    ],
    'Diabetes & Glycemic Panel': [
      {'param': 'Fasting Blood Sugar (FBS)', 'val': '', 'unit': 'mg/dL', 'refLow': 70.0, 'refHigh': 100.0},
      {'param': 'Post-Prandial Blood Sugar (PPBS)', 'val': '', 'unit': 'mg/dL', 'refLow': 90.0, 'refHigh': 140.0},
      {'param': 'HbA1c (Glycated Hb)', 'val': '', 'unit': '%', 'refLow': 4.0, 'refHigh': 5.6},
    ],
    'Thyroid Profile (T3, T4, TSH)': [
      {'param': 'Total T3', 'val': '', 'unit': 'ng/dL', 'refLow': 80.0, 'refHigh': 200.0},
      {'param': 'Total T4', 'val': '', 'unit': 'ug/dL', 'refLow': 4.5, 'refHigh': 12.0},
      {'param': 'TSH (Thyroid Stimulating)', 'val': '', 'unit': 'uIU/mL', 'refLow': 0.35, 'refHigh': 4.94},
    ],
    'Urine Routine & Microscopy': [
      {'param': 'pH', 'val': '', 'unit': '', 'refLow': 4.5, 'refHigh': 8.0},
      {'param': 'Specific Gravity', 'val': '', 'unit': '', 'refLow': 1.005, 'refHigh': 1.030},
      {'param': 'Protein / Albumin', 'val': '', 'unit': '', 'refLow': 0.0, 'refHigh': 0.0},
      {'param': 'Urine Glucose / Sugar', 'val': '', 'unit': '', 'refLow': 0.0, 'refHigh': 0.0},
      {'param': 'Pus Cells / WBC', 'val': '', 'unit': '/hpf', 'refLow': 0.0, 'refHigh': 5.0},
    ],
  };

  void _showNewLabOrderDialog() {
    final patientsAsync = ref.read(patientListProvider);
    final staffAsync = ref.read(staffListProvider);

    final patients = patientsAsync.value ?? [];
    final uniquePatients = <String, dynamic>{};
    for (final p in patients) {
      if (p.uhid.isNotEmpty) uniquePatients[p.uhid] = p;
    }

    final rawDoctors = (staffAsync.value ?? [])
        .where((s) => s.role.toLowerCase().contains('doctor'))
        .toList();
    final doctorList = rawDoctors.isNotEmpty
        ? rawDoctors.map((d) => d.name).toSet().toList()
        : ['Duty Doctor'];

    String selectedPatientName = uniquePatients.isNotEmpty ? (uniquePatients.values.first.name as String) : 'Walk-in Patient';
    String selectedUhid = uniquePatients.isNotEmpty ? uniquePatients.keys.first : 'WALK-IN';
    String selectedDoctor = doctorList.first;
    String selectedTest = _testTemplates.keys.first;
    String sampleType = 'Blood / Serum';
    String priority = 'Routine';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.biotech, color: Colors.indigo),
                Gap(8),
                Text('Order New Laboratory Investigation'),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient Selection
                    const Text('Select Patient', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Gap(8),
                    if (uniquePatients.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: uniquePatients.containsKey(selectedUhid) ? selectedUhid : uniquePatients.keys.first,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: uniquePatients.values.map((p) {
                          return DropdownMenuItem<String>(
                            value: p.uhid as String,
                            child: Text('${p.name} (${p.uhid}) - ${p.phone ?? ""}'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null && uniquePatients.containsKey(val)) {
                            final match = uniquePatients[val]!;
                            setModalState(() {
                              selectedUhid = match.uhid;
                              selectedPatientName = match.name;
                            });
                          }
                        },
                      )
                    else
                      TextFormField(
                        initialValue: selectedPatientName,
                        decoration: const InputDecoration(
                          labelText: 'Patient Name',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => selectedPatientName = v,
                      ),
                    const Gap(16),

                    // Consulting Doctor Selection
                    const Text('Referring / Consulting Doctor', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Gap(8),
                    DropdownButtonFormField<String>(
                      value: doctorList.contains(selectedDoctor) ? selectedDoctor : doctorList.first,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.medical_services_outlined),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: doctorList.map((doc) {
                        return DropdownMenuItem<String>(
                          value: doc,
                          child: Text(doc),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedDoctor = val);
                      },
                    ),
                    const Gap(16),

                    // Test Selection
                    const Text('Investigation / Test Catalog', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Gap(8),
                    DropdownButtonFormField<String>(
                      value: _testTemplates.containsKey(selectedTest) ? selectedTest : _testTemplates.keys.first,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.biotech),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _testTemplates.keys.map((test) {
                        return DropdownMenuItem<String>(
                          value: test,
                          child: Text(test),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedTest = val;
                            if (val.contains('Urine')) {
                              sampleType = 'Urine (Midstream)';
                            } else {
                              sampleType = 'Blood / Serum';
                            }
                          });
                        }
                      },
                    ),
                    const Gap(16),

                    // Sample Type & Priority
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Sample Type', style: TextStyle(fontWeight: FontWeight.bold)),
                              const Gap(8),
                              DropdownButtonFormField<String>(
                                value: const [
                                  'Blood / Serum',
                                  'Whole Blood (EDTA)',
                                  'Urine (Midstream)',
                                  'Plasma',
                                  'Throat / Nasal Swab',
                                ].contains(sampleType)
                                    ? sampleType
                                    : 'Blood / Serum',
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'Blood / Serum', child: Text('Blood / Serum')),
                                  DropdownMenuItem(value: 'Whole Blood (EDTA)', child: Text('Whole Blood (EDTA)')),
                                  DropdownMenuItem(value: 'Urine (Midstream)', child: Text('Urine (Midstream)')),
                                  DropdownMenuItem(value: 'Plasma', child: Text('Plasma')),
                                  DropdownMenuItem(value: 'Throat / Nasal Swab', child: Text('Swab')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => sampleType = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const Gap(16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Priority Level', style: TextStyle(fontWeight: FontWeight.bold)),
                              const Gap(8),
                              DropdownButtonFormField<String>(
                                value: const ['Routine', 'Urgent', 'STAT (Emergency)'].contains(priority)
                                    ? priority
                                    : 'Routine',
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'Routine', child: Text('Routine')),
                                  DropdownMenuItem(value: 'Urgent', child: Text('Urgent')),
                                  DropdownMenuItem(value: 'STAT (Emergency)', child: Text('STAT (Emergency)')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => priority = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),

                    // Parameters Preview
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, size: 16, color: Colors.indigo),
                              const Gap(6),
                              Text(
                                'Parameters Included (${_testTemplates[selectedTest]?.length ?? 0}):',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                          const Gap(6),
                          Text(
                            (_testTemplates[selectedTest] ?? []).map((p) => p['param']).join(' • '),
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final db = ref.read(appDatabaseProvider);
                  final timeStr = 'Today, ${TimeOfDay.now().format(context)}';
                  final orderNum = 'L-${100 + DateTime.now().millisecond + DateTime.now().second * 3}';

                  final templateParams = _testTemplates[selectedTest] ?? [];
                  final clonedParams = templateParams.map((p) => Map<String, dynamic>.from(p)).toList();

                  final newOrder = LabOrderModel(
                    id: 0,
                    orderNo: orderNum,
                    patientName: selectedPatientName,
                    uhid: selectedUhid,
                    testName: selectedTest,
                    doctorName: selectedDoctor,
                    sampleType: sampleType,
                    priority: priority,
                    status: 'Pending Collection',
                    orderedAt: timeStr,
                    parameters: clonedParams,
                  );

                  await db.hmsDao.insertLabOrder(newOrder);
                  ref.invalidate(labOrdersListProvider);
                  ref.invalidate(dashboardStatsProvider);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lab Order $orderNum ($selectedTest) placed for $selectedPatientName!'),
                        backgroundColor: Colors.teal.shade800,
                        action: SnackBarAction(
                          label: 'View Order',
                          textColor: Colors.white,
                          onPressed: () => context.go('/lab/$orderNum'),
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Place Lab Order'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateOrderStatus(LabOrderModel item, String newStatus) async {
    final db = ref.read(appDatabaseProvider);
    await db.hmsDao.updateLabOrderResults(item.orderNo, item.parameters, newStatus);
    ref.invalidate(labOrdersListProvider);
    ref.invalidate(labOrderDetailProvider(item.orderNo));
    ref.invalidate(dashboardStatsProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order ${item.orderNo} updated to "$newStatus"')),
      );
    }
  }

  void _confirmDeleteLabOrder(LabOrderModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel Lab Order #${item.orderNo}?'),
        content: Text(
          'Are you sure you want to cancel and delete lab investigation order #${item.orderNo} (${item.testName}) for ${item.patientName}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Back')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async {
              Navigator.pop(ctx);
              final db = ref.read(appDatabaseProvider);
              await db.hmsDao.deleteLabOrder(item.orderNo, item.testName);
              ref.invalidate(labOrdersListProvider);
              ref.invalidate(dashboardStatsProvider);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lab Order #${item.orderNo} cancelled and removed.'),
                    backgroundColor: Colors.red.shade800,
                  ),
                );
              }
            },
            child: const Text('Delete Order'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ordersAsync = ref.watch(labOrdersListProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Laboratory Worklist & Sample Tracking'),
        actions: [
          FilledButton.icon(
            onPressed: _showNewLabOrderDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Order Lab Investigation'),
          ),
          const Gap(16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Filter & Search Header Card
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
                    const Icon(Icons.biotech_outlined),
                    const Gap(8),
                    const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: const [
                        'All',
                        'Pending Collection',
                        'Sample Collected',
                        'Processing',
                        'Completed',
                      ].contains(_selectedStatusFilter)
                          ? _selectedStatusFilter
                          : 'All',
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All Lab Orders')),
                        DropdownMenuItem(value: 'Pending Collection', child: Text('Pending Sample Collection')),
                        DropdownMenuItem(value: 'Sample Collected', child: Text('Sample Collected')),
                        DropdownMenuItem(value: 'Processing', child: Text('Processing In Lab')),
                        DropdownMenuItem(value: 'Completed', child: Text('Completed & Verified')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedStatusFilter = v);
                      },
                    ),
                    const Gap(16),
                    SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search order #, patient, test…',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                      ),
                    ),
                    const Spacer(),
                    ordersAsync.when(
                      data: (orders) => Text(
                        'Total: ${orders.length} orders',
                        style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(16),

            // Lab Orders Queue List
            Expanded(
              child: ordersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading lab orders: $e')),
                data: (orders) {
                  var filtered = orders;
                  if (_selectedStatusFilter != 'All') {
                    filtered = filtered.where((o) => o.status.toLowerCase() == _selectedStatusFilter.toLowerCase()).toList();
                  }
                  if (_searchQuery.isNotEmpty) {
                    filtered = filtered.where((o) {
                      return o.orderNo.toLowerCase().contains(_searchQuery) ||
                          o.patientName.toLowerCase().contains(_searchQuery) ||
                          o.uhid.toLowerCase().contains(_searchQuery) ||
                          o.testName.toLowerCase().contains(_searchQuery);
                    }).toList();
                  }

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No laboratory orders matching criteria.'));
                  }

                  return Card(
                    elevation: 1,
                    clipBehavior: Clip.antiAlias,
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isUrgent = item.priority.contains('STAT') || item.priority.contains('Urgent');

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: isUrgent ? Colors.red.shade100 : colorScheme.primaryContainer,
                            child: Icon(
                              Icons.biotech,
                              color: isUrgent ? Colors.red.shade900 : colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(item.orderNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const Gap(8),
                              Text(
                                '${item.patientName} (${item.uhid})',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const Gap(12),
                              if (isUrgent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.priority.toUpperCase(),
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                                  ),
                                ),
                              StatusChip(label: item.status),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Test: ${item.testName} • Sample: ${item.sampleType} • Doctor: ${item.doctorName} • Ordered: ${item.orderedAt}',
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (item.status == 'Pending Collection') ...[
                                OutlinedButton.icon(
                                  onPressed: () => _updateOrderStatus(item, 'Sample Collected'),
                                  icon: const Icon(Icons.colorize, size: 16),
                                  label: const Text('Collect Sample'),
                                ),
                                const Gap(8),
                              ],
                              FilledButton.tonal(
                                onPressed: () => context.go('/lab/${item.orderNo}'),
                                child: Text(item.status == 'Completed' ? 'View Report' : 'Enter Results'),
                              ),
                              const Gap(4),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                tooltip: 'Cancel / Delete Order',
                                onPressed: () => _confirmDeleteLabOrder(item),
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
