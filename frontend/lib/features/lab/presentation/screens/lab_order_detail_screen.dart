import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_management/core/router/app_routes.dart';
import 'package:hospital_management/core/widgets/status_chip.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/core/providers/hms_providers.dart';
import 'package:hospital_management/data/models/lab_models.dart';

const _finalLabReportStatuses = {
  'completed',
  'verified',
  'resulted',
  'delivered',
};

class LabOrderDetailScreen extends ConsumerStatefulWidget {
  const LabOrderDetailScreen({
    super.key,
    required this.orderId,
    this.startInEditMode = false,
  });

  final String orderId;
  final bool startInEditMode;

  @override
  ConsumerState<LabOrderDetailScreen> createState() => _LabOrderDetailScreenState();
}

class _LabOrderDetailScreenState extends ConsumerState<LabOrderDetailScreen> {
  bool _initialized = false;
  bool _isSaving = false;
  bool _isEditingReport = false;
  final List<Map<String, dynamic>> _parameters = [];

  @override
  void didUpdateWidget(covariant LabOrderDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId ||
        oldWidget.startInEditMode != widget.startInEditMode) {
      _disposeParameters();
      _initialized = false;
      _isEditingReport = false;
    }
  }

  void _disposeParameters() {
    for (final parameter in _parameters) {
      (parameter['controller'] as TextEditingController?)?.dispose();
    }
    _parameters.clear();
  }

  void _initParameters(List<Map<String, dynamic>> source) {
    _disposeParameters();

    for (final item in source) {
      final name = item['param'] ?? item['name'] ?? 'Parameter';
      final val = (item['val'] ?? item['value'] ?? '').toString();
      final unit = item['unit'] ?? '';
      final refLow = (item['refLow'] as num?)?.toDouble() ?? 0.0;
      final refHigh = (item['refHigh'] as num?)?.toDouble() ?? 100.0;

      _parameters.add({
        'param': name,
        'controller': TextEditingController(text: val),
        'unit': unit,
        'refLow': refLow,
        'refHigh': refHigh,
      });
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _disposeParameters();
    super.dispose();
  }

  Future<void> _verifyAndSave(LabOrderModel order) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final isEditingReport =
        _finalLabReportStatuses.contains(order.status.toLowerCase());

    try {
      final params = _parameters
          .map((parameter) => {
                'param': parameter['param'],
                'val': (parameter['controller'] as TextEditingController)
                    .text
                    .trim(),
                'unit': parameter['unit'],
                'refLow': parameter['refLow'],
                'refHigh': parameter['refHigh'],
              })
          .toList();
      final db = ref.read(appDatabaseProvider);
      await db.hmsDao.updateLabOrderResults(
        widget.orderId,
        params,
        isEditingReport ? order.status : 'Completed',
      );
      ref.invalidate(labOrdersListProvider);
      ref.invalidate(dashboardStatsProvider);
      if (isEditingReport) {
        ref.invalidate(labOrderDetailProvider(widget.orderId));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditingReport
              ? 'Changes to lab report ${widget.orderId} saved.'
              : 'Lab results for ${widget.orderId} saved and marked completed.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      if (isEditingReport) {
        setState(() => _isEditingReport = false);
      } else {
        context.go(AppRoutes.lab);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save lab report ${widget.orderId}: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _cancelReportEdit(LabOrderModel order) {
    _initParameters(order.parameters);
    setState(() => _isEditingReport = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final orderAsync = ref.watch(labOrderDetailProvider(widget.orderId));

    return orderAsync.when(
      loading: () => Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: Text('Laboratory Order #${widget.orderId}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(AppRoutes.lab),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: Text('Laboratory Order #${widget.orderId}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(AppRoutes.lab),
          ),
        ),
        body: Center(child: Text('Error loading lab order: $err')),
      ),
      data: (order) {
        if (order == null) {
          return Scaffold(
            backgroundColor: colorScheme.surfaceContainerLowest,
            appBar: AppBar(
              title: Text('Laboratory Order #${widget.orderId}'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go(AppRoutes.lab),
              ),
            ),
            body: const Center(child: Text('Laboratory order not found.')),
          );
        }
        if (!_initialized) {
          _initParameters(order.parameters);
          _isEditingReport =
                  !_finalLabReportStatuses.contains(order.status.toLowerCase()) ||
              widget.startInEditMode;
        }

        final patientName = order.patientName;
        final uhid = order.uhid;
        final testName = order.testName;
        final doctorName = order.doctorName;
        final sampleType = order.sampleType;
        final status = order.status;
        final hasCompletedReport =
            _finalLabReportStatuses.contains(status.toLowerCase());
        final isViewingReport = hasCompletedReport && !_isEditingReport;

        return Scaffold(
          backgroundColor: colorScheme.surfaceContainerLowest,
          appBar: AppBar(
            title: Text('Laboratory Order #${widget.orderId}'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go(AppRoutes.lab),
            ),
            actions: [
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Laboratory report printed for $patientName (#${widget.orderId}).')),
                  );
                },
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text('Print Report'),
              ),
              if (hasCompletedReport && _isEditingReport) ...[
                const Gap(8),
                TextButton.icon(
                  onPressed: _isSaving ? null : () => _cancelReportEdit(order),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Cancel'),
                ),
                const Gap(8),
                FilledButton.icon(
                  onPressed: _isSaving ? null : () => _verifyAndSave(order),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(_isSaving ? 'Saving…' : 'Save Report Changes'),
                ),
              ] else if (!hasCompletedReport) ...[
                const Gap(12),
                FilledButton.icon(
                  onPressed: _isSaving ? null : () => _verifyAndSave(order),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified_outlined, size: 18),
                  label: Text(
                      _isSaving ? 'Saving…' : 'Save & Complete Report'),
                ),
              ],
              const Gap(16),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: colorScheme.primaryContainer,
                          child: const Icon(Icons.biotech, size: 24),
                        ),
                        const Gap(16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    testName,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const Gap(12),
                                  StatusChip(label: status),
                                ],
                              ),
                              const Gap(4),
                              Text(
                                'Patient: $patientName ($uhid) • Doctor: $doctorName • Sample: $sampleType',
                                style: TextStyle(color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(20),
                Card(
                  elevation: 0.5,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Parameter Results & Reference Ranges',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Gap(16),
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(3),
                            1: FlexColumnWidth(2),
                            2: FlexColumnWidth(1.5),
                            3: FlexColumnWidth(2),
                            4: FlexColumnWidth(1.5),
                          },
                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                          children: [
                            const TableRow(
                              decoration: BoxDecoration(color: Color(0x10000000)),
                              children: [
                                Padding(padding: EdgeInsets.all(12), child: Text('Investigation', style: TextStyle(fontWeight: FontWeight.bold))),
                                Padding(padding: EdgeInsets.all(12), child: Text('Observed Value', style: TextStyle(fontWeight: FontWeight.bold))),
                                Padding(padding: EdgeInsets.all(12), child: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold))),
                                Padding(padding: EdgeInsets.all(12), child: Text('Biological Ref Interval', style: TextStyle(fontWeight: FontWeight.bold))),
                                Padding(padding: EdgeInsets.all(12), child: Text('Flag', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                            ),
                            for (final p in _parameters)
                              TableRow(
                                children: [
                                  Padding(padding: const EdgeInsets.all(12), child: Text(p['param'] as String)),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: isViewingReport
                                        ? Text(
                                            (p['controller']
                                                        as TextEditingController)
                                                    .text
                                                    .trim()
                                                    .isEmpty
                                                ? '—'
                                                : (p['controller']
                                                            as TextEditingController)
                                                        .text
                                                        .trim(),
                                          )
                                        : TextFormField(
                                            controller: p['controller']
                                                as TextEditingController,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                                isDense: true),
                                            onChanged: (_) => setState(() {}),
                                          ),
                                  ),
                                  Padding(padding: const EdgeInsets.all(12), child: Text(p['unit'] as String)),
                                  Padding(padding: const EdgeInsets.all(12), child: Text('${p["refLow"]} - ${p["refHigh"]}')),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: double.tryParse(
                                                (p['controller']
                                                        as TextEditingController)
                                                    .text
                                                    .trim()) ==
                                            null
                                        ? const Text('—')
                                        : _buildFlag(
                                            double.parse(
                                                (p['controller']
                                                        as TextEditingController)
                                                    .text
                                                    .trim()),
                                            p['refLow'] as double,
                                            p['refHigh'] as double,
                                          ),
                                  ),
                                ],
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
        );
      },
    );
  }

  Widget _buildFlag(double val, double low, double high) {
    if (val < low) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(4)),
        child: Text('LOW', style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 11)),
      );
    } else if (val > high) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
        child: Text('HIGH', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 11)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
      child: Text('NORMAL', style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}
