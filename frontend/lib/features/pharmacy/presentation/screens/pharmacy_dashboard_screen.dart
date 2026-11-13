import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_management/core/widgets/kpi_card.dart';
import 'package:hospital_management/core/widgets/section_header.dart';
import 'package:hospital_management/core/providers/hms_providers.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/data/models/hms_models.dart';

/// Professional Hospital Pharmacy & Medical Stock Inventory Management Screen.
/// Provides enterprise-level Formulary master, FEFO batch tracking, Stock Inward (GRN),
/// Stock Adjustments (Wastage / Audit write-off), and Distributor management.
class PharmacyDashboardScreen extends ConsumerStatefulWidget {
  const PharmacyDashboardScreen({super.key});

  @override
  ConsumerState<PharmacyDashboardScreen> createState() => _PharmacyDashboardScreenState();
}

class _PharmacyDashboardScreenState extends ConsumerState<PharmacyDashboardScreen> {
  // Search and filters for medicine formulary
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategoryFilter = 'All';
  String _stockStatusFilter = 'All'; // 'All', 'In Stock', 'Low Stock', 'Out of Stock'

  // Batch search and filter
  final _batchSearchController = TextEditingController();
  String _batchSearchQuery = '';
  String _batchFilter = 'All'; // 'All', 'Near Expiry', 'Expired', 'Active'

  @override
  void dispose() {
    _searchController.dispose();
    _batchSearchController.dispose();
    super.dispose();
  }

  void _invalidateAll() {
    ref.invalidate(medicinesListProvider);
    ref.invalidate(lowStockMedicinesProvider);
    ref.invalidate(nearExpiryBatchesProvider);
    ref.invalidate(allBatchesProvider);
    ref.invalidate(allSuppliersProvider);
    ref.invalidate(allPurchasesProvider);
    ref.invalidate(allStockAdjustmentsProvider);
    ref.invalidate(dashboardStatsProvider);
  }

  Future<void> _restockMedicine(int id, String name, int addQty) async {
    final db = ref.read(appDatabaseProvider);
    await db.hmsDao.restockMedicine(id, addQty);
    _invalidateAll();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restocked $name: +$addQty units added to inventory.'),
          backgroundColor: Colors.teal.shade800,
        ),
      );
    }
  }

  void _showRestockDialog(MedicineModel item) {
    int qtyToAdd = 50;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('Restock ${item.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Stock: ${item.stockQty} ${item.unit}s'),
              Text('Reorder Level: ${item.reorderLevel} ${item.unit}s', style: const TextStyle(color: Colors.grey)),
              const Gap(16),
              const Text('Select Quantity to Add:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Gap(8),
              Wrap(
                spacing: 8,
                children: [20, 50, 100, 200].map((qty) {
                  return ChoiceChip(
                    label: Text('+$qty ${item.unit}s'),
                    selected: qtyToAdd == qty,
                    onSelected: (selected) {
                      if (selected) {
                        setModalState(() => qtyToAdd = qty);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _restockMedicine(item.id, item.name, qtyToAdd);
              },
              icon: const Icon(Icons.add_shopping_cart, size: 16),
              label: const Text('Confirm Restock'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Medicine CRUD Dialog ───────────────────────────────────────────────────

  void _showMedicineFormDialog([MedicineModel? existing]) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final genericCtrl = TextEditingController(text: existing?.genericName ?? '');
    final strengthCtrl = TextEditingController(text: existing?.strength ?? '');
    final supplierCtrl = TextEditingController(
      text: existing != null && existing.supplier.isNotEmpty
          ? existing.supplier
          : (existing?.manufacturer ?? ''),
    );
    final stockCtrl = TextEditingController(text: existing != null ? existing.stockQty.toString() : '');
    final reorderCtrl = TextEditingController(text: existing != null ? existing.reorderLevel.toString() : '');
    final mrpCtrl = TextEditingController(
      text: existing != null && existing.mrpPaise > 0
          ? (existing.mrpPaise / 100).toStringAsFixed(2)
          : '',
    );
    final batchCtrl = TextEditingController();
    final expCtrl = TextEditingController();
    final rackCtrl = TextEditingController(text: existing?.rackLocation ?? '');

    String category = existing?.category ?? 'Analgesic';
    String form = existing?.form ?? 'Tablet';
    String unit = existing?.unit ?? 'Strip (10 tabs)';

    final categories = [
      'Analgesic',
      'Antibiotic',
      'Antidiabetic',
      'Cardiology',
      'Gastrointestinal',
      'Respiratory',
      'Ophthalmic',
      'Dermatology',
      'Neurology',
      'Vitamins & Supplements',
      'Surgical & Consumables',
      'Other',
    ];
    if (!categories.contains(category)) categories.insert(0, category);

    final forms = [
      'Tablet',
      'Capsule',
      'Syrup',
      'Injection',
      'Ointment',
      'Cream',
      'Eye / Ear Drops',
      'Inhaler',
      'IV Infusion',
      'Powder',
    ];
    if (!forms.contains(form)) forms.insert(0, form);

    final units = [
      'Strip (10 tabs)',
      'Strip (14 tabs)',
      'Strip (10 caps)',
      'Bottle (100ml)',
      'Bottle (200ml)',
      'Vial',
      'Ampoule',
      'Tube (30g)',
      'Box',
      'Piece',
    ];
    if (!units.contains(unit)) units.insert(0, unit);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.teal.shade100,
                child: Icon(Icons.medication, color: Colors.teal.shade900),
              ),
              const Gap(12),
              Expanded(
                child: Text(
                  existing == null ? 'Add New Medicine to Stock' : 'Edit Medicine: ${existing.name}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Brand / Trade Name *',
                              hintText: 'e.g. Tab. Paracetamol 650mg',
                              prefixIcon: Icon(Icons.label_outline),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: genericCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Generic Chemical *',
                              hintText: 'e.g. Paracetamol',
                              prefixIcon: Icon(Icons.science_outlined),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: categories.contains(category) ? category : categories.first,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Therapeutic Category *',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (v) {
                              if (v != null) setModalState(() => category = v);
                            },
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: forms.contains(form) ? form : forms.first,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Dosage Form *',
                              prefixIcon: Icon(Icons.grain_outlined),
                            ),
                            items: forms.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                            onChanged: (v) {
                              if (v != null) setModalState(() => form = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: strengthCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Strength',
                              hintText: 'e.g. 650mg, 1g, 5ml',
                              prefixIcon: Icon(Icons.straighten_outlined),
                            ),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: units.contains(unit) ? unit : units.first,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Packaging Unit *',
                              prefixIcon: Icon(Icons.inventory_2_outlined),
                            ),
                            items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                            onChanged: (v) {
                              if (v != null) setModalState(() => unit = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: supplierCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Manufacturer / Brand Company',
                              hintText: 'e.g. Cipla Ltd, Sun Pharma',
                              prefixIcon: Icon(Icons.business_outlined),
                            ),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: TextFormField(
                            controller: rackCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Storage Rack / Shelf Location',
                              hintText: 'e.g. Rack A-12, Bin 3',
                              prefixIcon: Icon(Icons.shelves),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: stockCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Current Stock Quantity *',
                              prefixIcon: Icon(Icons.inventory_outlined),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (int.tryParse(v.trim()) == null) return 'Must be integer';
                              return null;
                            },
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: TextFormField(
                            controller: reorderCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Reorder Threshold Level *',
                              prefixIcon: Icon(Icons.warning_amber_outlined),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (int.tryParse(v.trim()) == null) return 'Must be integer';
                              return null;
                            },
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: TextFormField(
                            controller: mrpCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'MRP per Unit (₹) *',
                              prefixIcon: Icon(Icons.currency_rupee),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (double.tryParse(v.trim()) == null) return 'Valid price';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    if (existing == null) ...[
                      const Gap(12),
                      const Divider(),
                      const Gap(4),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: batchCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Initial Batch Number *',
                                hintText: 'e.g. B2026-08',
                                prefixIcon: Icon(Icons.tag),
                              ),
                            ),
                          ),
                          const Gap(12),
                          Expanded(
                            child: TextFormField(
                              controller: expCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Expiry Date (YYYY-MM-DD)',
                                hintText: 'e.g. 2028-12-31',
                                prefixIcon: Icon(Icons.calendar_month_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;

                final db = ref.read(appDatabaseProvider);
                final stock = int.tryParse(stockCtrl.text.trim()) ?? 0;
                final reorder = int.tryParse(reorderCtrl.text.trim()) ?? 15;
                final mrp = ((double.tryParse(mrpCtrl.text.trim()) ?? 0.0) * 100).round();
                final supp = supplierCtrl.text.trim().isEmpty ? 'General Supplier' : supplierCtrl.text.trim();

                if (existing != null) {
                  final updated = existing.copyWith(
                    name: nameCtrl.text.trim(),
                    genericName: genericCtrl.text.trim(),
                    category: category,
                    form: form,
                    strength: strengthCtrl.text.trim(),
                    unit: unit,
                    supplier: supp,
                    manufacturer: supp,
                    rackLocation: rackCtrl.text.trim(),
                    stockQty: stock,
                    reorderLevel: reorder,
                    mrpPaise: mrp,
                  );
                  await db.hmsDao.updateMedicine(updated);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Updated ${updated.name} in inventory.'), backgroundColor: Colors.teal.shade800),
                    );
                  }
                } else {
                  final newMed = MedicineModel(
                    id: 0,
                    name: nameCtrl.text.trim(),
                    genericName: genericCtrl.text.trim(),
                    category: category,
                    form: form,
                    strength: strengthCtrl.text.trim(),
                    unit: unit,
                    supplier: supp,
                    manufacturer: supp,
                    rackLocation: rackCtrl.text.trim(),
                    stockQty: stock,
                    reorderLevel: reorder,
                    mrpPaise: mrp,
                  );
                  await db.hmsDao.insertMedicine(
                    newMed,
                    batchNo: batchCtrl.text.trim(),
                    expiryDate: expCtrl.text.trim(),
                    mrpPaise: mrp,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Saved ${newMed.name} to pharmacy master.'), backgroundColor: Colors.green.shade800),
                    );
                  }
                }

                _invalidateAll();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              icon: const Icon(Icons.check, size: 16),
              label: Text(existing == null ? 'Save Medicine' : 'Update Medicine'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteMedicine(MedicineModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const Gap(8),
            Text('Delete ${item.name}?'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${item.name}" and all its recorded batches from the pharmacy inventory?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async {
              final db = ref.read(appDatabaseProvider);
              await db.hmsDao.deleteMedicine(item.id, item.name);
              _invalidateAll();
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted ${item.name} from inventory.')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Batch CRUD Dialog ──────────────────────────────────────────────────────

  void _showAddBatchDialog([MedicineModel? preselectedMed]) {
    final medicines = ref.read(medicinesListProvider).value ?? [];
    if (medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one medicine first.')),
      );
      return;
    }

    int selectedMedId = preselectedMed?.id ?? medicines.first.id;
    final batchCtrl = TextEditingController();
    final expCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final mrpCtrl = TextEditingController(
      text: preselectedMed != null && preselectedMed.mrpPaise > 0
          ? (preselectedMed.mrpPaise / 100).toStringAsFixed(2)
          : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final currentMed = medicines.firstWhere((m) => m.id == selectedMedId, orElse: () => medicines.first);
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.qr_code_2_outlined, color: Colors.indigo),
                Gap(8),
                Text('Add New Medicine Batch (FEFO Tracking)'),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedMedId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select Medicine *',
                        prefixIcon: Icon(Icons.medication),
                      ),
                      items: medicines.map((m) => DropdownMenuItem(value: m.id, child: Text('${m.name} (${m.unit})'))).toList(),
                      onChanged: (id) {
                        if (id != null) {
                          setModalState(() {
                            selectedMedId = id;
                            final m = medicines.firstWhere((item) => item.id == id);
                            if (m.mrpPaise > 0) {
                              mrpCtrl.text = (m.mrpPaise / 100).toStringAsFixed(2);
                            }
                          });
                        }
                      },
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: batchCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Batch Number *',
                              hintText: 'e.g. PCM-2026',
                              prefixIcon: Icon(Icons.tag),
                            ),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: TextFormField(
                            controller: expCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Expiry Date (YYYY-MM-DD) *',
                              hintText: 'e.g. 2028-12-31',
                              prefixIcon: Icon(Icons.event_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Batch Quantity *',
                              prefixIcon: Icon(Icons.format_list_numbered),
                            ),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: TextFormField(
                            controller: costCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Purchase Rate (₹) *',
                              prefixIcon: Icon(Icons.currency_rupee),
                            ),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: TextFormField(
                            controller: mrpCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'MRP (₹) *',
                              prefixIcon: Icon(Icons.sell_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton.icon(
                onPressed: () async {
                  final batchNo = batchCtrl.text.trim();
                  final exp = expCtrl.text.trim();
                  final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                  final cost = ((double.tryParse(costCtrl.text.trim()) ?? 0.0) * 100).round();
                  final mrp = ((double.tryParse(mrpCtrl.text.trim()) ?? 0.0) * 100).round();

                  if (batchNo.isEmpty || exp.isEmpty || qty <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill valid batch details and quantity.')),
                    );
                    return;
                  }

                  final db = ref.read(appDatabaseProvider);
                  final batch = MedicineBatchModel(
                    id: 0,
                    medicineId: currentMed.id,
                    medicineName: currentMed.name,
                    batchNo: batchNo,
                    expiryDate: exp,
                    stockQty: qty,
                    mrpPaise: mrp,
                    costPaise: cost,
                  );
                  await db.hmsDao.insertBatch(batch);
                  _invalidateAll();
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Batch $batchNo added to ${currentMed.name}'), backgroundColor: Colors.teal.shade800),
                    );
                  }
                },
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Save Batch'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Stock Inward (GRN / Purchases) Dialog ──────────────────────────────────

  void _showStockInwardDialog() {
    final medicines = ref.read(medicinesListProvider).value ?? [];
    final suppliers = ref.read(allSuppliersProvider).value ?? [];

    if (medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add medicines before recording stock inward shipments.')),
      );
      return;
    }

    String selectedSupplier = suppliers.isNotEmpty ? suppliers.first.name : 'General Supplier';
    int selectedMedId = medicines.first.id;
    final invoiceCtrl = TextEditingController();
    final batchCtrl = TextEditingController();
    final expCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final mrpCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final med = medicines.firstWhere((m) => m.id == selectedMedId, orElse: () => medicines.first);
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.inventory, color: Colors.teal),
                Gap(8),
                Text('Record Stock Inward / GRN (Goods Received Note)'),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Vendor & Consignment Details', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Gap(8),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: suppliers.any((s) => s.name == selectedSupplier) ? selectedSupplier : (suppliers.isNotEmpty ? suppliers.first.name : selectedSupplier),
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Distributor / Supplier *',
                              prefixIcon: Icon(Icons.local_shipping_outlined),
                            ),
                            items: (suppliers.isNotEmpty
                                    ? suppliers.map((s) => s.name).toSet().toList()
                                    : [selectedSupplier])
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setModalState(() => selectedSupplier = v);
                            },
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: invoiceCtrl,
                            decoration: const InputDecoration(
                              labelText: 'GRN / Invoice # *',
                              prefixIcon: Icon(Icons.receipt),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                    const Divider(),
                    const Gap(8),
                    const Text('Received Medicine & Batch Details', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Gap(8),
                    DropdownButtonFormField<int>(
                      value: selectedMedId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select Received Medicine *',
                        prefixIcon: Icon(Icons.medication),
                      ),
                      items: medicines.map((m) => DropdownMenuItem(value: m.id, child: Text('${m.name} (${m.unit}) - Curr: ${m.stockQty}'))).toList(),
                      onChanged: (id) {
                        if (id != null) {
                          setModalState(() {
                            selectedMedId = id;
                            final m = medicines.firstWhere((item) => item.id == id);
                            if (m.mrpPaise > 0) mrpCtrl.text = (m.mrpPaise / 100).toStringAsFixed(2);
                          });
                        }
                      },
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: batchCtrl,
                            decoration: const InputDecoration(labelText: 'Batch Number *', prefixIcon: Icon(Icons.tag)),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: TextFormField(
                            controller: expCtrl,
                            decoration: const InputDecoration(labelText: 'Expiry (YYYY-MM-DD) *', prefixIcon: Icon(Icons.calendar_month)),
                          ),
                        ),
                      ],
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Received Qty *', prefixIcon: Icon(Icons.add_box_outlined)),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: TextFormField(
                            controller: costCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Purchase Rate (₹) *', prefixIcon: Icon(Icons.currency_rupee)),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: TextFormField(
                            controller: mrpCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'MRP (₹) *', prefixIcon: Icon(Icons.sell_outlined)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton.icon(
                onPressed: () async {
                  final invNo = invoiceCtrl.text.trim();
                  final batchNo = batchCtrl.text.trim();
                  final exp = expCtrl.text.trim();
                  final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                  final cost = ((double.tryParse(costCtrl.text.trim()) ?? 0.0) * 100).round();
                  final mrp = ((double.tryParse(mrpCtrl.text.trim()) ?? 0.0) * 100).round();

                  if (invNo.isEmpty || batchNo.isEmpty || exp.isEmpty || qty <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all inward fields.')),
                    );
                    return;
                  }

                  final db = ref.read(appDatabaseProvider);
                  final item = PurchaseItemModel(
                    id: 0,
                    medicineId: med.id,
                    medicineName: med.name,
                    batchNo: batchNo,
                    expiryDate: exp,
                    qty: qty,
                    unitPricePaise: cost,
                    mrpPaise: mrp,
                    totalPaise: cost * qty,
                  );

                  final po = PurchaseOrderModel(
                    id: 0,
                    uuid: 'grn-${DateTime.now().millisecondsSinceEpoch}',
                    supplierId: 1,
                    supplierName: selectedSupplier,
                    invoiceNo: invNo,
                    invoiceDate: DateTime.now().toIso8601String().substring(0, 10),
                    totalAmountPaise: cost * qty,
                    status: 'received',
                    items: [item],
                  );

                  await db.hmsDao.recordStockInward(po);
                  _invalidateAll();
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Recorded Inward GRN #$invNo: +$qty units added to ${med.name}'), backgroundColor: Colors.teal.shade800),
                    );
                  }
                },
                icon: const Icon(Icons.archive_outlined, size: 16),
                label: const Text('Receive Stock (GRN)'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Stock Adjustment (Wastage / Audit) Dialog ──────────────────────────────

  void _showStockAdjustmentDialog() {
    final medicines = ref.read(medicinesListProvider).value ?? [];
    if (medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No medicines available for adjustment.')),
      );
      return;
    }

    int selectedMedId = medicines.first.id;
    String reason = 'Damaged / Broken in handling';
    final qtyCtrl = TextEditingController();
    final batchCtrl = TextEditingController();
    final reasonNotesCtrl = TextEditingController();

    final reasons = [
      'Damaged / Broken in handling',
      'Expired Stock Written Off',
      'Physical Inventory Discrepancy (Shortage)',
      'Physical Inventory Discrepancy (Surplus)',
      'Return to Distributor / Vendor',
      'Sample / Clinical Quality Audit',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final med = medicines.firstWhere((m) => m.id == selectedMedId, orElse: () => medicines.first);
          final isDeduction = !reason.contains('Surplus');

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.tune_outlined, color: Colors.orange),
                Gap(8),
                Text('Record Stock Adjustment & Wastage'),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedMedId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Select Medicine *', prefixIcon: Icon(Icons.medication)),
                      items: medicines.map((m) => DropdownMenuItem(value: m.id, child: Text('${m.name} • Stock: ${m.stockQty} ${m.unit}s'))).toList(),
                      onChanged: (id) {
                        if (id != null) setModalState(() => selectedMedId = id);
                      },
                    ),
                    const Gap(12),
                    DropdownButtonFormField<String>(
                      value: reasons.contains(reason) ? reason : reasons.first,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Adjustment Reason *', prefixIcon: Icon(Icons.report_problem_outlined)),
                      items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (r) {
                        if (r != null) setModalState(() => reason = r);
                      },
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: batchCtrl,
                            decoration: const InputDecoration(labelText: 'Batch Number', prefixIcon: Icon(Icons.tag)),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: TextFormField(
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: isDeduction ? 'Units to Deduct (-)' : 'Units to Add (+)',
                              prefixIcon: Icon(isDeduction ? Icons.remove_circle_outline : Icons.add_circle_outline),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(12),
                    TextFormField(
                      controller: reasonNotesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Pharmacist Remarks / Notes',
                        hintText: 'e.g. Dropped during ward transfer',
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: isDeduction ? Colors.orange.shade900 : Colors.teal.shade800),
                onPressed: () async {
                  final rawQty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                  if (rawQty <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quantity must be > 0.')));
                    return;
                  }
                  final finalQty = isDeduction ? -rawQty : rawQty;
                  final fullReason = reasonNotesCtrl.text.trim().isNotEmpty
                      ? '$reason (${reasonNotesCtrl.text.trim()})'
                      : reason;

                  final db = ref.read(appDatabaseProvider);
                  await db.hmsDao.recordStockAdjustment(
                    medicineId: med.id,
                    medicineName: med.name,
                    batchNo: batchCtrl.text.trim(),
                    adjustmentQty: finalQty,
                    reason: fullReason,
                  );
                  _invalidateAll();
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Adjusted ${med.name}: $finalQty units ($fullReason)')),
                    );
                  }
                },
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Apply Adjustment'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Add Supplier Dialog ───────────────────────────────────────────────────

  void _showAddSupplierDialog() {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final gstCtrl = TextEditingController();
    final addrCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.local_shipping_outlined, color: Colors.teal),
            Gap(8),
            Text('Add Pharmaceutical Distributor / Supplier'),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Distributor / Company Name *', prefixIcon: Icon(Icons.business)),
                ),
                const Gap(12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: contactCtrl,
                        decoration: const InputDecoration(labelText: 'Contact Person', prefixIcon: Icon(Icons.person_outline)),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: TextFormField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Mobile / Phone *', prefixIcon: Icon(Icons.phone_outlined)),
                      ),
                    ),
                  ],
                ),
                const Gap(12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: TextFormField(
                        controller: gstCtrl,
                        decoration: const InputDecoration(labelText: 'GSTIN Number', prefixIcon: Icon(Icons.receipt_long)),
                      ),
                    ),
                  ],
                ),
                const Gap(12),
                TextFormField(
                  controller: addrCtrl,
                  decoration: const InputDecoration(labelText: 'Warehouse / Supply Address', prefixIcon: Icon(Icons.location_on_outlined)),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton.icon(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final phone = phoneCtrl.text.trim();
              if (name.isEmpty || phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and phone are required.')));
                return;
              }
              final db = ref.read(appDatabaseProvider);
              final sup = SupplierModel(
                id: 0,
                uuid: 'sup-${DateTime.now().millisecondsSinceEpoch}',
                name: name,
                contactPerson: contactCtrl.text.trim(),
                phone: phone,
                email: emailCtrl.text.trim(),
                address: addrCtrl.text.trim(),
                gstNo: gstCtrl.text.trim(),
              );
              await db.hmsDao.insertSupplier(sup);
              _invalidateAll();
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Registered distributor $name'), backgroundColor: Colors.teal.shade800),
                );
              }
            },
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Save Supplier'),
          ),
        ],
      ),
    );
  }

  // ── Main Build Method ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final medicinesAsync = ref.watch(medicinesListProvider);
    final lowStockAsync = ref.watch(lowStockMedicinesProvider);
    final nearExpiryAsync = ref.watch(nearExpiryBatchesProvider);
    final batchesAsync = ref.watch(allBatchesProvider);
    final purchasesAsync = ref.watch(allPurchasesProvider);
    final adjustmentsAsync = ref.watch(allStockAdjustmentsProvider);
    final suppliersAsync = ref.watch(allSuppliersProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

    // Compute valuation
    final allMeds = medicinesAsync.value ?? [];
    final totalInventoryValuationPaise = allMeds.fold<int>(0, (sum, m) => sum + (m.stockQty * m.mrpPaise));
    final totalInventoryValuationFormatted = '₹${(totalInventoryValuationPaise / 100).toStringAsFixed(0)}';

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: const Text('Pharmacy & Medical Stock Inventory Management'),
          actions: [
            FilledButton.icon(
              onPressed: () => context.go('/pharmacy/dispense/pos'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.teal.shade800,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              icon: const Icon(Icons.point_of_sale, size: 18),
              label: const Text('Counter POS Billing', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const Gap(12),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Pharmacy & Batches',
              onPressed: _invalidateAll,
            ),
            const Gap(8),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(icon: Icon(Icons.dashboard_outlined), text: 'Control Center'),
              Tab(icon: Icon(Icons.medication_outlined), text: 'Medicine Master'),
              Tab(icon: Icon(Icons.qr_code_2_outlined), text: 'Batches & FEFO'),
              Tab(icon: Icon(Icons.archive_outlined), text: 'Stock Inward (GRN)'),
              Tab(icon: Icon(Icons.tune_outlined), text: 'Stock Audit & Waste'),
              Tab(icon: Icon(Icons.local_shipping_outlined), text: 'Suppliers & Vendors'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: CONTROL CENTER & ALERTS
            _buildControlCenterTab(
              colorScheme,
              medicinesAsync,
              lowStockAsync,
              nearExpiryAsync,
              statsAsync,
              totalInventoryValuationFormatted,
            ),

            // TAB 2: MEDICINE MASTER FORMULARY
            _buildMedicineMasterTab(colorScheme, medicinesAsync),

            // TAB 3: BATCHES & FEFO TRACKER
            _buildBatchesTab(colorScheme, batchesAsync, medicinesAsync),

            // TAB 4: STOCK INWARD (GRN)
            _buildStockInwardTab(colorScheme, purchasesAsync),

            // TAB 5: STOCK AUDIT & ADJUSTMENTS
            _buildStockAuditTab(colorScheme, adjustmentsAsync),

            // TAB 6: SUPPLIERS & VENDORS
            _buildSuppliersTab(colorScheme, suppliersAsync),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: Control Center ──────────────────────────────────────────────────

  Widget _buildControlCenterTab(
    ColorScheme colorScheme,
    AsyncValue<List<MedicineModel>> medicinesAsync,
    AsyncValue<List<MedicineModel>> lowStockAsync,
    AsyncValue<List<MedicineBatchModel>> nearExpiryAsync,
    AsyncValue<Map<String, dynamic>> statsAsync,
    String totalValuation,
  ) {
    final stats = statsAsync.value ?? {};
    final salesFormatted = stats['pharmacy_sales_formatted'] as String? ?? '₹0.00';
    final totalMeds = medicinesAsync.value?.length ?? 0;
    final lowStockCount = lowStockAsync.value?.length ?? 0;
    final nearExpiryCount = nearExpiryAsync.value?.length ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action Command Bar
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: Colors.teal, size: 28),
                  const Gap(12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pharmacy Fast Action Center', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Direct shortcuts for dispensing, stock inward receipts, inventory adjustments, and catalog updates.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => context.go('/pharmacy/dispense/pos'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.teal.shade800),
                    icon: const Icon(Icons.point_of_sale, size: 16),
                    label: const Text('Open POS Counter'),
                  ),
                  const Gap(8),
                  OutlinedButton.icon(
                    onPressed: _showStockInwardDialog,
                    icon: const Icon(Icons.archive_outlined, size: 16),
                    label: const Text('New GRN Inward'),
                  ),
                  const Gap(8),
                  OutlinedButton.icon(
                    onPressed: () => _showMedicineFormDialog(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Medicine'),
                  ),
                  const Gap(8),
                  OutlinedButton.icon(
                    onPressed: _showStockAdjustmentDialog,
                    icon: const Icon(Icons.tune_outlined, size: 16),
                    label: const Text('Stock Wastage'),
                  ),
                ],
              ),
            ),
          ),
          const Gap(24),

          // KPIs
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1150
                  ? 5
                  : constraints.maxWidth > 750
                      ? 3
                      : 2;
              return GridView(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 145,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  KpiCard(
                    label: "Today's Pharmacy Sales",
                    value: salesFormatted,
                    icon: Icons.currency_rupee,
                    color: Colors.green.shade700,
                  ),
                  KpiCard(
                    label: 'Total Stock Valuation',
                    value: totalValuation,
                    icon: Icons.account_balance_wallet_outlined,
                    color: Colors.indigo.shade700,
                  ),
                  KpiCard(
                    label: 'Formulary Medicines',
                    value: totalMeds.toString(),
                    icon: Icons.medication_liquid_rounded,
                    color: Colors.blue.shade700,
                  ),
                  KpiCard(
                    label: 'Low Stock Alerts',
                    value: lowStockCount.toString(),
                    icon: Icons.warning_amber_rounded,
                    color: Colors.red.shade700,
                  ),
                  KpiCard(
                    label: 'Near Expiry Batches (< 90d)',
                    value: nearExpiryCount.toString(),
                    icon: Icons.timer_outlined,
                    color: Colors.orange.shade800,
                  ),
                ],
              );
            },
          ),
          const Gap(28),

          // Low Stock Alerts & Near Expiry Split View
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Low Stock Panel
              Expanded(
                child: Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SectionHeader(title: 'Low Stock Alerts (Reorder Level Reached)'),
                            TextButton.icon(
                              onPressed: () => _showAddBatchDialog(),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Batch'),
                            ),
                          ],
                        ),
                        const Gap(12),
                        lowStockAsync.when(
                          loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
                          error: (e, _) => Text('Error: $e'),
                          data: (items) {
                            if (items.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.check_circle_outline, color: Colors.green, size: 36),
                                      Gap(8),
                                      Text('All medicines are well-stocked above reorder threshold.', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: items.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final item = items[idx];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.red.shade100,
                                    child: Icon(Icons.inventory_2_outlined, color: Colors.red.shade900),
                                  ),
                                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${item.category} • Rack: ${item.rackLocation.isNotEmpty ? item.rackLocation : "A-1"} • Reorder: ${item.reorderLevel} ${item.unit}s'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.red.shade200),
                                        ),
                                        child: Text(
                                          '${item.stockQty} ${item.unit}s left',
                                          style: TextStyle(
                                            color: Colors.red.shade900,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const Gap(8),
                                      FilledButton.tonalIcon(
                                        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                                        onPressed: () => _showRestockDialog(item),
                                        icon: const Icon(Icons.add_shopping_cart, size: 14),
                                        label: const Text('Reorder'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Gap(24),

              // Near Expiry FEFO Panel
              Expanded(
                child: Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Near Expiry Batches (FEFO Dispense Priority)'),
                        const Gap(12),
                        nearExpiryAsync.when(
                          loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
                          error: (e, _) => Text('Error: $e'),
                          data: (batches) {
                            if (batches.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.verified_outlined, color: Colors.teal, size: 36),
                                      Gap(8),
                                      Text('Zero near-expiry alerts. All active batches are compliant.', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: batches.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final b = batches[idx];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.orange.shade100,
                                    child: Icon(Icons.alarm, color: Colors.orange.shade900),
                                  ),
                                  title: Text(b.medicineName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Batch: ${b.batchNo} • Stock: ${b.stockQty} • Rate: ${b.mrpFormatted}'),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.orange.shade300),
                                    ),
                                    child: Text(
                                      'Exp: ${b.expiryDate}',
                                      style: TextStyle(
                                        color: Colors.orange.shade900,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Medicine Master Formulary ───────────────────────────────────────

  Widget _buildMedicineMasterTab(ColorScheme colorScheme, AsyncValue<List<MedicineModel>> medicinesAsync) {
    final categories = [
      'All',
      'Analgesic',
      'Antibiotic',
      'Antidiabetic',
      'Cardiology',
      'Gastrointestinal',
      'Respiratory',
      'Ophthalmic',
      'Surgical & Consumables',
      'Other',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter & Search Controls
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search formulary by brand name, generic chemical, manufacturer, or rack bin…',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                        ),
                      ),
                      const Gap(16),
                      FilledButton.icon(
                        onPressed: () => _showMedicineFormDialog(),
                        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Medicine'),
                      ),
                      const Gap(12),
                      OutlinedButton.icon(
                        onPressed: () => _showAddBatchDialog(),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16)),
                        icon: const Icon(Icons.qr_code, size: 18),
                        label: const Text('Add Batch'),
                      ),
                    ],
                  ),
                  const Gap(16),

                  // Category Pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((cat) {
                        final isSel = _selectedCategoryFilter == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSel,
                            onSelected: (val) {
                              if (val) setState(() => _selectedCategoryFilter = cat);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Gap(20),

          // Medicines Master List
          medicinesAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (medicines) {
              final filtered = medicines.where((m) {
                final matchQuery = _searchQuery.isEmpty ||
                    m.name.toLowerCase().contains(_searchQuery) ||
                    m.genericName.toLowerCase().contains(_searchQuery) ||
                    m.manufacturer.toLowerCase().contains(_searchQuery) ||
                    m.rackLocation.toLowerCase().contains(_searchQuery);

                final matchCategory = _selectedCategoryFilter == 'All' || m.category == _selectedCategoryFilter;
                return matchQuery && matchCategory;
              }).toList();

              if (filtered.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No medicines found matching the current search & category filter.')),
                  ),
                );
              }

              return Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Formulary Directory (${filtered.length} Medicines)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Click any medicine to edit details or restock', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                        ],
                      ),
                      const Gap(12),
                      const Divider(),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final m = filtered[idx];
                          final isLow = m.stockQty <= m.reorderLevel;
                          final isOut = m.stockQty <= 0;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            onTap: () => _showMedicineFormDialog(m),
                            leading: CircleAvatar(
                              backgroundColor: isOut
                                  ? Colors.grey.shade300
                                  : isLow
                                      ? Colors.red.shade100
                                      : Colors.teal.shade100,
                              child: Icon(
                                Icons.medication,
                                color: isOut
                                    ? Colors.grey.shade700
                                    : isLow
                                        ? Colors.red.shade900
                                        : Colors.teal.shade900,
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const Gap(8),
                                Text('(${m.genericName})', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                const Gap(12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Text(
                                    'MRP ${m.mrpFormatted}',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                                  ),
                                ),
                                if (isOut) ...[
                                  const Gap(8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                                    child: const Text('OUT OF STOCK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                                  ),
                                ] else if (isLow) ...[
                                  const Gap(8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)),
                                    child: const Text('LOW STOCK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Form: ${m.form} • Category: ${m.category} • Rack: ${m.rackLocation.isNotEmpty ? m.rackLocation : "A-1"} • Manufacturer: ${m.supplier}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${m.stockQty} ${m.unit}s',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isOut ? Colors.red : (isLow ? Colors.deepOrange : Colors.green.shade800),
                                  ),
                                ),
                                const Gap(16),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: Colors.teal),
                                  tooltip: 'Add Batch to ${m.name}',
                                  onPressed: () => _showAddBatchDialog(m),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                  tooltip: 'Edit Medicine Details',
                                  onPressed: () => _showMedicineFormDialog(m),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  tooltip: 'Delete Medicine',
                                  onPressed: () => _confirmDeleteMedicine(m),
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
            },
          ),
        ],
      ),
    );
  }

  // ── Tab 3: Batches & FEFO Tracker ──────────────────────────────────────────

  Widget _buildBatchesTab(
    ColorScheme colorScheme,
    AsyncValue<List<MedicineBatchModel>> batchesAsync,
    AsyncValue<List<MedicineModel>> medicinesAsync,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _batchSearchController,
                      decoration: InputDecoration(
                        hintText: 'Search by batch number or medicine name…',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _batchSearchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _batchSearchController.clear();
                                  setState(() => _batchSearchQuery = '');
                                },
                              )
                            : null,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (v) => setState(() => _batchSearchQuery = v.trim().toLowerCase()),
                    ),
                  ),
                  const Gap(16),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'All', label: Text('All Batches')),
                      ButtonSegment(value: 'Near Expiry', label: Text('Near Expiry (<90d)')),
                      ButtonSegment(value: 'Active', label: Text('Active')),
                    ],
                    selected: {_batchFilter},
                    onSelectionChanged: (set) => setState(() => _batchFilter = set.first),
                  ),
                  const Gap(16),
                  FilledButton.icon(
                    onPressed: () => _showAddBatchDialog(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Batch'),
                  ),
                ],
              ),
            ),
          ),
          const Gap(20),

          batchesAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (batches) {
              final filtered = batches.where((b) {
                final matchQuery = _batchSearchQuery.isEmpty ||
                    b.batchNo.toLowerCase().contains(_batchSearchQuery) ||
                    b.medicineName.toLowerCase().contains(_batchSearchQuery);

                if (!matchQuery) return false;
                if (_batchFilter == 'Near Expiry') return b.isNearExpiry;
                if (_batchFilter == 'Active') return !b.isExpired && !b.isNearExpiry;
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No batches matching search filter.')),
                  ),
                );
              }

              return Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FEFO Batch Ledger (${filtered.length} Batches)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Gap(12),
                      const Divider(),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1.8),
                          1: FlexColumnWidth(3),
                          2: FlexColumnWidth(2),
                          3: FlexColumnWidth(1.5),
                          4: FlexColumnWidth(1.8),
                          5: FlexColumnWidth(1.8),
                          6: FlexColumnWidth(1.2),
                        },
                        children: [
                          const TableRow(
                            decoration: BoxDecoration(color: Color(0x0C000000)),
                            children: [
                              Padding(padding: EdgeInsets.all(10), child: Text('Batch #', style: TextStyle(fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.all(10), child: Text('Medicine Name', style: TextStyle(fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.all(10), child: Text('Expiry Date', style: TextStyle(fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.all(10), child: Text('Stock Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.all(10), child: Text('Cost Price', style: TextStyle(fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.all(10), child: Text('MRP', style: TextStyle(fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.all(10), child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                          ),
                          ...filtered.map((b) {
                            final isNear = b.isNearExpiry;
                            final isExp = b.isExpired;

                            return TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.qr_code, size: 16, color: Colors.grey),
                                      const Gap(6),
                                      Text(b.batchNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                Padding(padding: const EdgeInsets.all(10), child: Text(b.medicineName)),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Row(
                                    children: [
                                      Text(b.expiryDate),
                                      if (isExp) ...[
                                        const Gap(6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                                          child: const Text('EXPIRED', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                      ] else if (isNear) ...[
                                        const Gap(6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)),
                                          child: const Text('<90 DAYS', style: TextStyle(color: Colors.deepOrange, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text('${b.stockQty} units', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                Padding(padding: const EdgeInsets.all(10), child: Text(b.costFormatted)),
                                Padding(padding: const EdgeInsets.all(10), child: Text(b.mrpFormatted, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                                Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                    tooltip: 'Delete Batch',
                                    onPressed: () async {
                                      final db = ref.read(appDatabaseProvider);
                                      await db.hmsDao.deleteBatch(b.id, b.batchNo, b.medicineId);
                                      _invalidateAll();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Removed batch ${b.batchNo}')),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Tab 4: Stock Inward (GRN) ──────────────────────────────────────────────

  Widget _buildStockInwardTab(ColorScheme colorScheme, AsyncValue<List<PurchaseOrderModel>> purchasesAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Goods Received Notes (GRN) & Vendor Inward Consignments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('Track incoming stock consignments received from pharmaceutical distributors.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              FilledButton.icon(
                onPressed: _showStockInwardDialog,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                icon: const Icon(Icons.archive_outlined, size: 18),
                label: const Text('Receive New Consignment (GRN)'),
              ),
            ],
          ),
          const Gap(20),

          purchasesAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (purchases) {
              if (purchases.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No inward consignments recorded yet. Click "Receive New Consignment (GRN)" to log shipments.')),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: purchases.length,
                separatorBuilder: (_, __) => const Gap(12),
                itemBuilder: (context, idx) {
                  final po = purchases[idx];
                  return Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.teal.shade50,
                                    child: Icon(Icons.receipt_long, color: Colors.teal.shade800),
                                  ),
                                  const Gap(12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Invoice / GRN: ${po.invoiceNo}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      Text('Supplier: ${po.supplierName} • Date: ${po.invoiceDate}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    po.totalFormatted,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green.shade800),
                                  ),
                                  const Gap(12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.green.shade300),
                                    ),
                                    child: Text(
                                      po.status.toUpperCase(),
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (po.items.isNotEmpty) ...[
                            const Gap(12),
                            const Divider(height: 1),
                            const Gap(8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: po.items.map((i) {
                                return Chip(
                                  label: Text('${i.medicineName} (Batch: ${i.batchNo}) • Qty: ${i.qty} • Rate: ₹${(i.unitPricePaise / 100).toStringAsFixed(2)}'),
                                  backgroundColor: colorScheme.surfaceContainerHigh,
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Tab 5: Stock Audit & Adjustments ───────────────────────────────────────

  Widget _buildStockAuditTab(ColorScheme colorScheme, AsyncValue<List<StockAdjustmentModel>> adjustmentsAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Stock Adjustments & Breakage / Wastage Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('Physical audit reconciliation, write-offs for broken ampoules, expired stock, and vendor returns.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              FilledButton.icon(
                onPressed: _showStockAdjustmentDialog,
                style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade800, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                icon: const Icon(Icons.tune_outlined, size: 18),
                label: const Text('Record Stock Adjustment'),
              ),
            ],
          ),
          const Gap(20),

          adjustmentsAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (adjustments) {
              if (adjustments.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No stock adjustments recorded. All inventory matches physical count.')),
                  ),
                );
              }

              return Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Adjustment Ledger (${adjustments.length} Records)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Gap(12),
                      const Divider(),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2.5),
                          1: FlexColumnWidth(1.5),
                          2: FlexColumnWidth(1.5),
                          3: FlexColumnWidth(3.5),
                          4: FlexColumnWidth(1.5),
                        },
                        children: [
                          const TableRow(
                            decoration: BoxDecoration(color: Color(0x0C000000)),
                            children: [
                              Padding(padding: EdgeInsets.all(10), child: Text('Medicine', style: TextStyle(fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.all(10), child: Text('Batch', style: TextStyle(fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.all(10), child: Text('Qty Adjusted', style: TextStyle(fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.all(10), child: Text('Reason & Remarks', style: TextStyle(fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.all(10), child: Text('Recorded By', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                          ),
                          ...adjustments.map((a) {
                            final isNeg = a.adjustmentQty < 0;
                            return TableRow(
                              children: [
                                Padding(padding: const EdgeInsets.all(10), child: Text(a.medicineName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                Padding(padding: const EdgeInsets.all(10), child: Text(a.batchNo.isNotEmpty ? a.batchNo : '-')),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(
                                    '${a.adjustmentQty > 0 ? "+" : ""}${a.adjustmentQty} units',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isNeg ? Colors.red.shade800 : Colors.green.shade800,
                                    ),
                                  ),
                                ),
                                Padding(padding: const EdgeInsets.all(10), child: Text(a.reason)),
                                Padding(padding: const EdgeInsets.all(10), child: Text(a.adjustedBy, style: const TextStyle(color: Colors.grey))),
                              ],
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Tab 6: Suppliers & Vendors ─────────────────────────────────────────────

  Widget _buildSuppliersTab(ColorScheme colorScheme, AsyncValue<List<SupplierModel>> suppliersAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pharmaceutical Suppliers & Wholesalers Directory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('Authorized medicine distributors, contact persons, GSTIN and supply warehouses.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              FilledButton.icon(
                onPressed: _showAddSupplierDialog,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                icon: const Icon(Icons.add_business_outlined, size: 18),
                label: const Text('Add Distributor'),
              ),
            ],
          ),
          const Gap(20),

          suppliersAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (suppliers) {
              if (suppliers.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No suppliers listed. Click "Add Distributor" to register suppliers.')),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 950 ? 2 : 1;
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 180,
                    ),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: suppliers.length,
                    itemBuilder: (context, idx) {
                      final s = suppliers[idx];
                      return Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.blue.shade100,
                                    child: Icon(Icons.business, color: Colors.blue.shade900),
                                  ),
                                  const Gap(12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        if (s.contactPerson.isNotEmpty)
                                          Text('Contact: ${s.contactPerson}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(12),
                              const Divider(height: 1),
                              const Gap(10),
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                                  const Gap(6),
                                  Text(s.phone, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  const Gap(16),
                                  if (s.email.isNotEmpty) ...[
                                    const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                                    const Gap(6),
                                    Expanded(child: Text(s.email, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
                                  ],
                                ],
                              ),
                              const Gap(6),
                              Row(
                                children: [
                                  const Icon(Icons.receipt_long, size: 16, color: Colors.grey),
                                  const Gap(6),
                                  Text('GSTIN: ${s.gstNo.isNotEmpty ? s.gstNo : "Pending verification"}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  const Spacer(),
                                  if (s.address.isNotEmpty)
                                    Text(s.address, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
