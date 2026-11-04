import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_management/core/widgets/status_chip.dart';
import 'package:hospital_management/core/providers/hms_providers.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/features/patients/patients_provider.dart';
import 'package:hospital_management/data/models/billing_models.dart';

class BillingListScreen extends ConsumerStatefulWidget {
  const BillingListScreen({super.key});

  @override
  ConsumerState<BillingListScreen> createState() => _BillingListScreenState();
}

class _BillingListScreenState extends ConsumerState<BillingListScreen> {
  String _filterType = 'All Invoices';

  Future<void> _markAsPaid(InvoiceModel item) async {
    final db = ref.read(appDatabaseProvider);
    await db.hmsDao.updateInvoiceStatus(item.invoiceNo, 'Paid', item.totalPaise);
    ref.invalidate(invoicesListProvider);
    ref.invalidate(dashboardStatsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invoice ${item.invoiceNo} marked as Paid & Settled.'),
          backgroundColor: Colors.teal.shade800,
        ),
      );
    }
  }

  void _confirmDeleteInvoice(InvoiceModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Void / Delete ${item.invoiceNo}?'),
        content: Text(
          'Are you sure you want to void and delete invoice ${item.invoiceNo} for ${item.patientName} (Total: ${item.totalFormatted})?\n\nThis will remove it from accounts ledger.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async {
              Navigator.pop(ctx);
              final db = ref.read(appDatabaseProvider);
              await db.hmsDao.deleteInvoice(item.id, item.invoiceNo);
              ref.invalidate(invoicesListProvider);
              ref.invalidate(dashboardStatsProvider);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invoice ${item.invoiceNo} voided and removed.'),
                    backgroundColor: Colors.red.shade800,
                  ),
                );
              }
            },
            child: const Text('Delete Invoice'),
          ),
        ],
      ),
    );
  }

  void _showQuickInvoiceDialog() {
    final patientsAsync = ref.read(patientListProvider);
    final patients = patientsAsync.value ?? [];
    final uniquePatients = <String, dynamic>{};
    for (final p in patients) {
      if (p.uhid.isNotEmpty) uniquePatients[p.uhid] = p;
    }

    String selectedPatientName = uniquePatients.isNotEmpty ? (uniquePatients.values.first.name as String) : 'Walk-in Patient';
    String selectedUhid = uniquePatients.isNotEmpty ? uniquePatients.keys.first : 'WALK-IN';
    String billType = 'OPD Consultation';
    int amountPaise = 0;
    String paymentMode = 'Cash';
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.teal),
                Gap(8),
                Text('Generate Instant OPD Receipt'),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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

                    const Text('Bill Type / Category', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Gap(8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'OPD Consultation',
                        'Specialist Review',
                        'Emergency Triage',
                        'Pharmacy Dispensing',
                        'Lab Investigation',
                      ].map((type) {
                        return ChoiceChip(
                          label: Text(type),
                          selected: billType == type,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() {
                                billType = type;
                                if (type == 'OPD Consultation') {
                                  amountPaise = 50000;
                                  amountController.text = '500';
                                } else if (type == 'Specialist Review') {
                                  amountPaise = 80000;
                                  amountController.text = '800';
                                } else if (type == 'Emergency Triage') {
                                  amountPaise = 150000;
                                  amountController.text = '1500';
                                } else if (type == 'Lab Investigation') {
                                  amountPaise = 65000;
                                  amountController.text = '650';
                                } else if (type == 'Pharmacy Dispensing') {
                                  amountPaise = 32000;
                                  amountController.text = '320';
                                }
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const Gap(16),

                    const Text('Amount (₹)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Gap(8),
                    Wrap(
                      spacing: 8,
                      children: [300, 500, 800, 1500].map((amt) {
                        return ActionChip(
                          label: Text('₹$amt'),
                          onPressed: () {
                            setModalState(() {
                              amountPaise = amt * 100;
                              amountController.text = amt.toString();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const Gap(8),
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Custom Total Amount (₹)',
                        prefixIcon: Icon(Icons.currency_rupee),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        final val = int.tryParse(v) ?? 0;
                        amountPaise = val * 100;
                      },
                    ),
                    const Gap(16),

                    const Text('Payment Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Gap(8),
                    Wrap(
                      spacing: 8,
                      children: ['Cash', 'UPI', 'Card'].map((mode) {
                        return ChoiceChip(
                          avatar: Icon(
                            mode == 'Cash'
                                ? Icons.money
                                : mode == 'UPI'
                                    ? Icons.qr_code
                                    : Icons.credit_card,
                            size: 16,
                          ),
                          label: Text(mode),
                          selected: paymentMode == mode,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => paymentMode = mode);
                            }
                          },
                        );
                      }).toList(),
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
                  final invNo = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

                  final invoice = InvoiceModel(
                    id: 0,
                    invoiceNo: invNo,
                    patientName: selectedPatientName,
                    uhid: selectedUhid,
                    billType: billType,
                    subtotalPaise: amountPaise,
                    taxPaise: 0,
                    totalPaise: amountPaise,
                    paidPaise: amountPaise,
                    duePaise: 0,
                    paymentMode: paymentMode,
                    status: 'Paid',
                    dateTime: timeStr,
                    items: [
                      {
                        'description': '$billType Fee',
                        'quantity': 1,
                        'ratePaise': amountPaise,
                        'amountPaise': amountPaise,
                      }
                    ],
                  );

                  await db.hmsDao.insertInvoice(invoice);
                  ref.invalidate(invoicesListProvider);
                  ref.invalidate(dashboardStatsProvider);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Receipt $invNo created for $selectedPatientName!'),
                        backgroundColor: Colors.teal.shade800,
                        action: SnackBarAction(
                          label: 'View',
                          textColor: Colors.white,
                          onPressed: () => context.go('/billing/$invNo'),
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Create & Save Receipt'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final invoicesAsync = ref.watch(invoicesListProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Billing, Invoices & Revenue'),
        actions: [
          FilledButton.icon(
            onPressed: _showQuickInvoiceDialog,
            icon: const Icon(Icons.receipt_long, size: 18),
            label: const Text('New OPD Receipt'),
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
                    const Icon(Icons.receipt_outlined),
                    const Gap(8),
                    const Text('Type: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: const [
                        'All Invoices',
                        'OPD Consultation',
                        'Pharmacy Dispensing',
                        'IPD Interim Bill',
                      ].contains(_filterType)
                          ? _filterType
                          : 'All Invoices',
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: 'All Invoices', child: Text('All Invoices')),
                        DropdownMenuItem(value: 'OPD Consultation', child: Text('OPD Consultations')),
                        DropdownMenuItem(value: 'Pharmacy Dispensing', child: Text('Pharmacy Dispensing')),
                        DropdownMenuItem(value: 'IPD Interim Bill', child: Text('IPD Interim Bills')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _filterType = v);
                      },
                    ),
                    const Spacer(),
                    invoicesAsync.when(
                      data: (list) {
                        final totalPaise = list.fold<int>(0, (sum, i) => sum + i.paidPaise);
                        return Text(
                          'Total Collected: ₹${(totalPaise / 100).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
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
            Expanded(
              child: invoicesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading invoices: $e')),
                data: (invoices) {
                  final filtered = _filterType == 'All Invoices'
                      ? invoices
                      : invoices.where((i) => i.billType == _filterType).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No invoices recorded.'));
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
                            child: Icon(Icons.receipt, color: colorScheme.onPrimaryContainer),
                          ),
                          title: Row(
                            children: [
                              Text(item.invoiceNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const Gap(8),
                              Text(item.patientName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              const Gap(8),
                              Text(item.uhid, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                              const Gap(12),
                              StatusChip(label: item.status),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Type: ${item.billType} • Mode: ${item.paymentMode} • ${item.dateTime}',
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(item.totalFormatted, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  if (item.duePaise > 0)
                                    Text('Due: ${item.dueFormatted}', style: TextStyle(color: Colors.red.shade700, fontSize: 12))
                                  else
                                    Text('Settled', style: TextStyle(color: Colors.green.shade700, fontSize: 12)),
                                ],
                              ),
                              const Gap(12),
                              if (item.status != 'Paid') ...[
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.check, size: 14),
                                  label: const Text('Mark Paid'),
                                  onPressed: () => _markAsPaid(item),
                                ),
                                const Gap(8),
                              ],
                              FilledButton.tonal(
                                onPressed: () => context.go('/billing/${item.id}'),
                                child: const Text('View Bill'),
                              ),
                              const Gap(4),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                tooltip: 'Void / Delete Invoice',
                                onPressed: () => _confirmDeleteInvoice(item),
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
