import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_management/core/providers/hms_providers.dart';
import 'package:hospital_management/core/providers/hospital_name_provider.dart';
import 'package:hospital_management/core/router/app_routes.dart';
import 'package:hospital_management/core/widgets/status_chip.dart';
import 'package:hospital_management/data/database/app_database.dart';
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
  final TextEditingController _notesController = TextEditingController();

  @override
  void didUpdateWidget(covariant LabOrderDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId ||
        oldWidget.startInEditMode != widget.startInEditMode) {
      _disposeParameters();
      _initialized = false;
      _isEditingReport = widget.startInEditMode;
    }
  }

  void _disposeParameters() {
    for (final parameter in _parameters) {
      (parameter['controller'] as TextEditingController?)?.dispose();
    }
    _parameters.clear();
  }

  void _initParameters(List<Map<String, dynamic>> source, {String? notes}) {
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
    if (notes != null && notes.isNotEmpty) {
      _notesController.text = notes;
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _disposeParameters();
    _notesController.dispose();
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
      final notesText = _notesController.text.trim();
      await db.hmsDao.updateLabOrderResults(
        widget.orderId,
        params,
        isEditingReport ? order.status : 'Completed',
        notes: notesText,
      );
      
      _initParameters(params, notes: notesText);
      ref.invalidate(labOrdersListProvider);
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(labOrderDetailProvider(widget.orderId));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditingReport
              ? 'Changes to lab report ${widget.orderId} saved successfully.'
              : 'Lab results for ${widget.orderId} saved and marked completed.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      setState(() => _isEditingReport = false);
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
    _initParameters(order.parameters, notes: order.technicianNotes);
    setState(() => _isEditingReport = false);
  }

  void _showPrintReportDialog(BuildContext context, LabOrderModel order, String hospitalName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.print_rounded, color: Colors.blue),
            const Gap(10),
            Text('Laboratory Report Preview - #${order.orderNo}'),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        hospitalName.toUpperCase(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const Text(
                        'CENTRAL DIAGNOSTIC LABORATORY & PATHOLOGY DIVISION',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                      ),
                      const Gap(4),
                      Text(
                        'Accredited Clinical Diagnostic Centre • Official Patient Investigation Report',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                const Gap(16),
                // Patient Details Grid
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Patient Name: ${order.patientName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('UHID: ${order.uhid}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Referring Doctor: ${order.doctorName}', style: const TextStyle(fontSize: 12)),
                          Text('Sample: ${order.sampleType}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      const Gap(4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Test: ${order.testName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text('Status: ${order.status}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Gap(16),
                // Table of results
                Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade100),
                      children: const [
                        Padding(padding: EdgeInsets.all(8), child: Text('Investigation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Observed Value', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Reference Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      ],
                    ),
                    for (final p in _parameters)
                      TableRow(
                        children: [
                          Padding(padding: const EdgeInsets.all(8), child: Text(p['param'] as String, style: const TextStyle(fontSize: 12))),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              (p['controller'] as TextEditingController).text.trim().isEmpty
                                  ? '—'
                                  : (p['controller'] as TextEditingController).text.trim(),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(padding: const EdgeInsets.all(8), child: Text(p['unit'] as String, style: const TextStyle(fontSize: 12))),
                          Padding(padding: const EdgeInsets.all(8), child: Text('${p["refLow"]} - ${p["refHigh"]}', style: const TextStyle(fontSize: 12))),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: double.tryParse((p['controller'] as TextEditingController).text.trim()) == null
                                ? const Text('—', style: TextStyle(fontSize: 11))
                                : _buildFlag(
                                    double.parse((p['controller'] as TextEditingController).text.trim()),
                                    (p['refLow'] as num).toDouble(),
                                    (p['refHigh'] as num).toDouble(),
                                  ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (_notesController.text.trim().isNotEmpty) ...[
                  const Gap(16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Technician Remarks & Clinical Notes:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const Gap(4),
                        Text(_notesController.text.trim(), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
                const Gap(24),
                // Signature block
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Reported on: ${DateTime.now().toLocal().toString().split(".")[0]}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                    Column(
                      children: [
                        const Text('___________________________', style: TextStyle(fontSize: 10)),
                        const Gap(2),
                        const Text('Verified Pathologist / Technologist', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Report for ${order.patientName} (#${order.orderNo}) sent to print queue!'),
                  backgroundColor: Colors.green.shade800,
                ),
              );
            },
            icon: const Icon(Icons.print, size: 16),
            label: const Text('Print Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final orderAsync = ref.watch(labOrderDetailProvider(widget.orderId));
    final hospitalName = ref.watch(hospitalNameProvider).value ?? 'CareSync Hospital';

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
          _initParameters(order.parameters, notes: order.technicianNotes);
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
                onPressed: () => _showPrintReportDialog(context, order, hospitalName),
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text('Print / Preview'),
              ),
              if (hasCompletedReport && !isViewingReport) ...[
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
              ] else if (hasCompletedReport && isViewingReport) ...[
                const Gap(8),
                FilledButton.tonalIcon(
                  onPressed: () => setState(() => _isEditingReport = true),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Report'),
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
                // Top Clinical Header
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: colorScheme.primaryContainer,
                              child: const Icon(Icons.biotech, size: 28),
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
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                      ),
                                      const Gap(12),
                                      StatusChip(label: status),
                                    ],
                                  ),
                                  const Gap(4),
                                  Text(
                                    '$hospitalName • Diagnostic Laboratory Department',
                                    style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        // Demographics grid
                        Wrap(
                          spacing: 24,
                          runSpacing: 12,
                          children: [
                            _buildInfoItem(Icons.person_outline, 'Patient Name', patientName),
                            _buildInfoItem(Icons.tag, 'UHID', uhid),
                            _buildInfoItem(Icons.medical_services_outlined, 'Referring Doctor', doctorName),
                            _buildInfoItem(Icons.water_drop_outlined, 'Sample Type', sampleType),
                            _buildInfoItem(Icons.flag_outlined, 'Priority', order.priority),
                            _buildInfoItem(Icons.calendar_today_outlined, 'Ordered At', order.orderedAt),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(20),

                // Table of Results
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Parameter Results & Reference Ranges',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (isViewingReport)
                              OutlinedButton.icon(
                                onPressed: () => setState(() => _isEditingReport = true),
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                label: const Text('Edit Results'),
                              ),
                          ],
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
                                  Padding(padding: const EdgeInsets.all(12), child: Text(p['param'] as String, style: const TextStyle(fontWeight: FontWeight.w500))),
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
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          )
                                        : TextFormField(
                                            controller: p['controller']
                                                as TextEditingController,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              isDense: true,
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                              hintText: 'Enter value',
                                            ),
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
                                            (p['refLow'] as num).toDouble(),
                                            (p['refHigh'] as num).toDouble(),
                                          ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const Gap(24),

                        // Technician & Pathologist Remarks
                        Text(
                          'Technician Remarks & Clinical Notes',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Gap(8),
                        if (isViewingReport)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: colorScheme.outlineVariant),
                            ),
                            child: Text(
                              _notesController.text.trim().isEmpty
                                  ? 'No remarks entered. Specimen within regular observational standards.'
                                  : _notesController.text.trim(),
                              style: TextStyle(
                                fontStyle: _notesController.text.trim().isEmpty ? FontStyle.italic : FontStyle.normal,
                                color: _notesController.text.trim().isEmpty ? Colors.grey : colorScheme.onSurface,
                              ),
                            ),
                          )
                        else
                          TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'Enter clinical impressions, sample quality notes, or pathologist remarks...',
                              border: OutlineInputBorder(),
                            ),
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

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const Gap(6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildFlag(double val, double low, double high) {
    if (val < low) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(4)),
        child: Text('LOW', style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 11)),
      );
    } else if (val > high) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
        child: Text('HIGH', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 11)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
      child: Text('NORMAL', style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}
