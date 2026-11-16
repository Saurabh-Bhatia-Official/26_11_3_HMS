import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_management/core/router/app_routes.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/core/providers/hospital_name_provider.dart';
import 'package:hospital_management/core/providers/hms_providers.dart';
import 'package:hospital_management/data/models/hms_models.dart';
import 'package:hospital_management/features/patients/patients_provider.dart';

class PosCartItem {
  final int medicineId;
  final String medicineName;
  final String genericName;
  final String unit;
  final String form;
  final String batchNo;
  final double unitPrice;
  int quantity;
  final int maxStock;

  PosCartItem({
    required this.medicineId,
    required this.medicineName,
    required this.genericName,
    required this.unit,
    required this.form,
    required this.batchNo,
    required this.unitPrice,
    required this.quantity,
    required this.maxStock,
  });

  double get lineTotal => unitPrice * quantity;
}

class DispenseScreen extends ConsumerStatefulWidget {
  const DispenseScreen({super.key, required this.prescriptionId});

  final String prescriptionId;

  @override
  ConsumerState<DispenseScreen> createState() => _DispenseScreenState();
}

class _DispenseScreenState extends ConsumerState<DispenseScreen> {
  // Customer details
  bool _isWalkIn = true;
  String _customerName = 'Walk-in Customer';
  String _customerUhid = 'WALK-IN';
  String _customerPhone = '';
  String _doctorName = 'Self / Counter Sale';

  // Medicine selection
  int? _selectedMedicineId;
  final _qtyController = TextEditingController(text: '1');
  final _searchController = TextEditingController();

  // Cart
  final List<PosCartItem> _cart = [];

  // Billing configuration
  double _taxRatePct = 5.0; // 5% GST on standard medicines
  double _discountAmount = 0.0;
  String _paymentMode = 'Cash';
  bool _isProcessing = false;

  final List<String> _paymentModes = [
    'Cash',
    'UPI / QR Code',
    'Debit / Credit Card',
    'Hospital Credit / Due'
  ];
  final List<double> _taxRates = [0.0, 5.0, 12.0, 18.0];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    // If opened from a prescription or visit ID, lookup details dynamically
    final pid = widget.prescriptionId;
    if (pid != 'new' && pid != 'pos' && pid != 'counter') {
      final idNum = int.tryParse(pid);
      if (idNum != null) {
        final db = ref.read(appDatabaseProvider);
        final visit = await db.hmsDao.getOpdVisitById(idNum);
        if (visit != null && mounted) {
          setState(() {
            _customerName = visit.patientName;
            _customerUhid = visit.uhid;
            _doctorName = visit.doctorName;
            _isWalkIn = false;
          });
          return;
        }
      }
      _isWalkIn = false;
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  double get _subtotal => _cart.fold(0.0, (sum, item) => sum + item.lineTotal);
  double get _taxAmount => (_subtotal * _taxRatePct) / 100.0;
  double get _grandTotal =>
      (_subtotal + _taxAmount - _discountAmount).clamp(0.0, double.infinity);

  void _addItemToCart() {
    if (_selectedMedicineId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a medicine first.')),
      );
      return;
    }

    final medicines = ref.read(medicinesListProvider).value ?? [];
    final selectedMed =
        medicines.where((m) => m.id == _selectedMedicineId).firstOrNull;
    if (selectedMed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selected medicine was not found in stock.')),
      );
      return;
    }

    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be at least 1.')),
      );
      return;
    }

    if (qty > selectedMed.stockQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Insufficient stock. Only ${selectedMed.stockQty} ${selectedMed.unit}s available.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final existingIndex =
        _cart.indexWhere((item) => item.medicineId == selectedMed.id);
    if (existingIndex >= 0) {
      final newQty = _cart[existingIndex].quantity + qty;
      if (newQty > selectedMed.stockQty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Cannot exceed available stock (${selectedMed.stockQty} ${selectedMed.unit}s).'),
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }
      setState(() {
        _cart[existingIndex].quantity = newQty;
      });
    } else {
      final unitPrice = selectedMed.mrpPaise > 0
          ? (selectedMed.mrpPaise / 100.0)
          : 35.0; // fallback reasonable price

      setState(() {
        _cart.add(
          PosCartItem(
            medicineId: selectedMed.id,
            medicineName: selectedMed.name,
            genericName: selectedMed.genericName,
            unit: selectedMed.unit,
            form: selectedMed.form,
            batchNo:
                'B${DateTime.now().year}-${selectedMed.id.toString().padLeft(3, '0')}',
            unitPrice: unitPrice,
            quantity: qty,
            maxStock: selectedMed.stockQty,
          ),
        );
        _qtyController.text = '1';
      });
    }
  }

  Future<void> _completePosSale() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Cart is empty. Please add medicines before checkout.')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final db = ref.read(appDatabaseProvider);
    final now = DateTime.now();
    final invNo = 'PINV-${now.millisecondsSinceEpoch % 1000000}';
    final totalPaise = (_grandTotal * 100).round();
    final subtotalPaise = (_subtotal * 100).round();
    final taxPaise = (_taxAmount * 100).round();

    try {
      // 1. Deduct stock for each medicine in SQLite
      for (final item in _cart) {
        await db.hmsDao
            .dispenseMedicine(item.medicineId, item.quantity, _customerName);
      }

      // 2. Insert Invoice record in SQLite
      final invoice = InvoiceModel(
        id: 0,
        invoiceNo: invNo,
        patientName: _customerName,
        uhid: _customerUhid,
        billType: 'Pharmacy POS Sale',
        subtotalPaise: subtotalPaise,
        taxPaise: taxPaise,
        totalPaise: totalPaise,
        paidPaise: totalPaise,
        duePaise: 0,
        paymentMode: _paymentMode,
        status: 'Paid',
        dateTime:
            'Today, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        items: _cart
            .map((item) => {
                  'desc':
                      '${item.medicineName} (${item.quantity} ${item.unit})',
                  'rate': item.unitPrice,
                  'qty': item.quantity,
                  'total': item.lineTotal,
                })
            .toList(),
      );

      await db.hmsDao.insertInvoice(invoice);

      // 3. Invalidate reactive providers
      ref.invalidate(medicinesListProvider);
      ref.invalidate(lowStockMedicinesProvider);
      ref.invalidate(invoicesListProvider);
      ref.invalidate(dashboardStatsProvider);

      if (!mounted) return;

      // 4. Show printed receipt dialog
      _showReceiptDialog(invoice, List.from(_cart));

      setState(() {
        _cart.clear();
        _discountAmount = 0.0;
        _isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error completing sale: $e'),
            backgroundColor: Colors.red.shade800),
      );
    }
  }

  void _showReceiptDialog(InvoiceModel inv, List<PosCartItem> items) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const Gap(10),
            const Text('Sale Complete - Receipt Printed'),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Column(
                    children: [
                      Text(
                        '${ref.read(hospitalNameNotifierProvider).toUpperCase()} PHARMACY',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Text(
                          'Main Hospital Campus • 24/7 Pharmacy Counter'),
                      Text('Invoice: ${inv.invoiceNo} • ${inv.dateTime}',
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Customer: ${inv.patientName} (${inv.uhid})',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Payment: ${inv.paymentMode}'),
                  ],
                ),
                Text('Prescribing Doctor: $_doctorName',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const Gap(12),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(4),
                    1: FlexColumnWidth(1.5),
                    2: FlexColumnWidth(2),
                    3: FlexColumnWidth(2),
                  },
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(color: Color(0x10000000)),
                      children: [
                        Padding(
                            padding: EdgeInsets.all(6),
                            child: Text('Item',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(
                            padding: EdgeInsets.all(6),
                            child: Text('Qty',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(
                            padding: EdgeInsets.all(6),
                            child: Text('Rate',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(
                            padding: EdgeInsets.all(6),
                            child: Text('Total',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                    for (final item in items)
                      TableRow(
                        children: [
                          Padding(
                              padding: const EdgeInsets.all(6),
                              child: Text(item.medicineName)),
                          Padding(
                              padding: const EdgeInsets.all(6),
                              child: Text('${item.quantity}')),
                          Padding(
                              padding: const EdgeInsets.all(6),
                              child: Text(
                                  '₹${item.unitPrice.toStringAsFixed(2)}')),
                          Padding(
                              padding: const EdgeInsets.all(6),
                              child: Text(
                                  '₹${item.lineTotal.toStringAsFixed(2)}')),
                        ],
                      ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:'),
                    Text('₹${(inv.subtotalPaise / 100).toStringAsFixed(2)}'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Healthcare GST ($_taxRatePct%):'),
                    Text('₹${(inv.taxPaise / 100).toStringAsFixed(2)}'),
                  ],
                ),
                const Gap(8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount Paid:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      '₹${(inv.totalPaise / 100).toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              context.go(AppRoutes.pharmacy);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Pharmacy'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Thermal receipt for ${inv.invoiceNo} sent to POS printer.'),
                  backgroundColor: Colors.teal.shade800,
                ),
              );
            },
            icon: const Icon(Icons.print),
            label: const Text('Print Receipt & Next Sale'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final medicinesAsync = ref.watch(medicinesListProvider);
    final patientsAsync = ref.watch(patientListProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Pharmacy Point of Sale (POS) & Counter Billing'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.pharmacy),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _cart.clear();
                _discountAmount = 0.0;
              });
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Clear Cart'),
          ),
          const Gap(16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── TOP SECTION: Customer & Medicine Selection ───────────────────
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(Icons.point_of_sale_rounded,
                              color: colorScheme.onPrimaryContainer),
                        ),
                        const Gap(12),
                        const Text(
                          'POS Checkout & Medicine Dispensation',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                                value: true,
                                label: Text('Walk-in / Counter Cash')),
                            ButtonSegment(
                                value: false,
                                label: Text('Registered Patient')),
                          ],
                          selected: {_isWalkIn},
                          onSelectionChanged: (set) {
                            setState(() {
                              _isWalkIn = set.first;
                              if (_isWalkIn) {
                                _customerName = 'Walk-in Customer';
                                _customerUhid = 'WALK-IN';
                                _doctorName = 'Self / Counter Sale';
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const Gap(16),
                    const Divider(),
                    const Gap(16),

                    // Customer input fields
                    Row(
                      children: [
                        if (!_isWalkIn) ...[
                          Expanded(
                            flex: 3,
                            child: patientsAsync.when(
                              loading: () => const LinearProgressIndicator(),
                              error: (e, _) =>
                                  Text('Error loading patients: $e'),
                              data: (patients) {
                                final uniquePatients = <String, dynamic>{};
                                for (final p in patients) {
                                  if (p.uhid.isNotEmpty)
                                    uniquePatients[p.uhid] = p;
                                }
                                final hasMatch =
                                    uniquePatients.containsKey(_customerUhid);
                                return DropdownButtonFormField<String>(
                                  value: hasMatch ? _customerUhid : null,
                                  decoration: const InputDecoration(
                                    labelText: 'Select Registered Patient *',
                                    prefixIcon: Icon(Icons.person_search),
                                  ),
                                  items: uniquePatients.values.map((p) {
                                    return DropdownMenuItem<String>(
                                      value: p.uhid as String,
                                      child: Text(
                                          '${p.name} (${p.uhid}) - Phone: ${p.phone ?? "-"}'),
                                    );
                                  }).toList(),
                                  onChanged: (uhid) {
                                    if (uhid != null &&
                                        uniquePatients.containsKey(uhid)) {
                                      final p = uniquePatients[uhid]!;
                                      setState(() {
                                        _customerName = p.name;
                                        _customerUhid = p.uhid;
                                        _customerPhone = p.phone ?? '';
                                      });
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              initialValue: _customerName,
                              decoration: const InputDecoration(
                                labelText: 'Customer / Buyer Name *',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              onChanged: (v) => _customerName = v.trim().isEmpty
                                  ? 'Walk-in Customer'
                                  : v.trim(),
                            ),
                          ),
                        ],
                        const Gap(16),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: _doctorName,
                            decoration: const InputDecoration(
                              labelText: 'Prescribing Doctor',
                              hintText: 'e.g. Prescribing Doctor',
                              prefixIcon: Icon(Icons.medical_services_outlined),
                            ),
                            onChanged: (v) => _doctorName = v.trim().isEmpty
                                ? 'Self / Counter Sale'
                                : v.trim(),
                          ),
                        ),
                      ],
                    ),
                    const Gap(20),

                    // Medicine Selector Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 4,
                          child: medicinesAsync.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (e, _) =>
                                Text('Error loading medicines: $e'),
                            data: (medicines) {
                              final hasSelected = medicines
                                  .any((m) => m.id == _selectedMedicineId);
                              return DropdownButtonFormField<int>(
                                isExpanded: true,
                                value: hasSelected ? _selectedMedicineId : null,
                                decoration: const InputDecoration(
                                  labelText: 'Select Medicine from Stock *',
                                  hintText:
                                      'Choose medicine from pharmacy inventory',
                                  prefixIcon: Icon(Icons.medication),
                                ),
                                items: medicines.map((m) {
                                  final isOut = m.stockQty <= 0;
                                  return DropdownMenuItem<int>(
                                    value: m.id,
                                    enabled: !isOut,
                                    child: Text(
                                      '${m.name} (${m.genericName}) • Stock: ${m.stockQty} ${m.unit}s • ${m.mrpFormatted}${isOut ? " [OUT OF STOCK]" : ""}',
                                      style: TextStyle(
                                        color: isOut ? Colors.grey : null,
                                        fontWeight: isOut
                                            ? FontWeight.normal
                                            : FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (medId) {
                                  setState(() {
                                    _selectedMedicineId = medId;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        const Gap(16),
                        SizedBox(
                          width: 140,
                          child: TextFormField(
                            controller: _qtyController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Quantity *',
                              prefixIcon: Icon(Icons.format_list_numbered),
                            ),
                          ),
                        ),
                        const Gap(16),
                        FilledButton.icon(
                          onPressed: _addItemToCart,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                          ),
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: const Text('Add to Bill'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Gap(24),

            // ── MIDDLE SECTION: Cart Table & Billing Breakdown ───────────────
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 950;

                final cartTable = Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shopping_cart_outlined),
                            const Gap(8),
                            Text(
                              'Sale Item Details (${_cart.length} items)',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const Gap(16),
                        if (_cart.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.remove_shopping_cart_outlined,
                                      size: 48, color: Colors.grey),
                                  Gap(12),
                                  Text(
                                    'No medicines in bill. Select a medicine above and click "Add to Bill".',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _cart.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _cart[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.teal.shade50,
                                  child: Text('${index + 1}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal.shade900)),
                                ),
                                title: Text(item.medicineName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  '${item.genericName} • ${item.form} • Batch #${item.batchNo} • Unit Rate: ₹${item.unitPrice.toStringAsFixed(2)}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline,
                                          size: 20),
                                      onPressed: item.quantity > 1
                                          ? () =>
                                              setState(() => item.quantity--)
                                          : null,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${item.quantity}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline,
                                          size: 20),
                                      onPressed: item.quantity < item.maxStock
                                          ? () =>
                                              setState(() => item.quantity++)
                                          : null,
                                    ),
                                    const Gap(16),
                                    SizedBox(
                                      width: 90,
                                      child: Text(
                                        '₹${item.lineTotal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    const Gap(12),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red, size: 20),
                                      tooltip: 'Remove',
                                      onPressed: () =>
                                          setState(() => _cart.removeAt(index)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                );

                final summaryCard = Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment & Invoice Summary',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const Gap(20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:',
                                style: TextStyle(fontSize: 15)),
                            Text('₹${_subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Gap(12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Healthcare GST Rate:'),
                            DropdownButton<double>(
                              value: _taxRates.contains(_taxRatePct)
                                  ? _taxRatePct
                                  : _taxRates.first,
                              underline: const SizedBox.shrink(),
                              items: _taxRates
                                  .map((r) => DropdownMenuItem(
                                      value: r, child: Text('$r% GST')))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _taxRatePct = v);
                              },
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tax Amount ($_taxRatePct%):',
                                style: const TextStyle(color: Colors.grey)),
                            Text('₹${_taxAmount.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        const Gap(12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Discount (₹):'),
                            SizedBox(
                              width: 100,
                              height: 36,
                              child: TextField(
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  prefixText: '₹',
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 8),
                                ),
                                onChanged: (v) {
                                  final disc = double.tryParse(v.trim()) ?? 0.0;
                                  setState(() => _discountAmount = disc);
                                },
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Net Payable Total:',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(
                              '₹${_grandTotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                        const Gap(24),
                        DropdownButtonFormField<String>(
                          value: _paymentModes.contains(_paymentMode)
                              ? _paymentMode
                              : _paymentModes.first,
                          decoration: const InputDecoration(
                            labelText: 'Select Payment Method *',
                            prefixIcon: Icon(Icons.payment),
                          ),
                          items: _paymentModes
                              .map((m) =>
                                  DropdownMenuItem(value: m, child: Text(m)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _paymentMode = v);
                          },
                        ),
                        const Gap(28),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: _cart.isNotEmpty && !_isProcessing
                                ? _completePosSale
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.teal.shade800,
                            ),
                            icon: _isProcessing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.check_circle_outline,
                                    size: 22),
                            label: Text(
                              _isProcessing
                                  ? 'Processing Sale…'
                                  : 'Complete Sale & Generate Bill (₹${_grandTotal.toStringAsFixed(2)})',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: cartTable),
                      const Gap(24),
                      Expanded(flex: 2, child: summaryCard),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      cartTable,
                      const Gap(24),
                      summaryCard,
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
