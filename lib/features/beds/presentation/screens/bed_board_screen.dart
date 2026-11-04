import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_management/core/router/app_routes.dart';
import 'package:hospital_management/core/providers/hms_providers.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/data/models/hms_models.dart';

class BedBoardScreen extends ConsumerStatefulWidget {
  const BedBoardScreen({super.key});

  @override
  ConsumerState<BedBoardScreen> createState() => _BedBoardScreenState();
}

class _BedBoardScreenState extends ConsumerState<BedBoardScreen> {
  String _selectedWard = 'All Wards';

  Color _colorForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green.shade600;
      case 'occupied':
        return Colors.red.shade700;
      case 'cleaning':
        return Colors.orange.shade700;
      case 'maintenance':
        return Colors.grey.shade600;
      default:
        return Colors.blue.shade600;
    }
  }

  void _showBedActionsDialog(BedModel bed) {
    final statusColor = _colorForStatus(bed.status);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.hotel, color: statusColor),
            ),
            const Gap(12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bed ${bed.bedNo}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('${bed.ward} • ${bed.type}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Status: ${bed.status}', style: TextStyle(fontWeight: FontWeight.bold, color: statusColor)),
            Text('Tariff: ₹${(bed.tariffPaise / 100).toStringAsFixed(0)} / day', style: const TextStyle(fontSize: 12)),
            const Divider(height: 24),
            if (bed.status == 'Occupied') ...[
              Text('Occupied By: ${bed.patientName ?? "Patient"}', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('UHID: ${bed.uhid ?? "-"}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const Gap(16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go(AppRoutes.ipd);
                  },
                  icon: const Icon(Icons.medical_information_outlined, size: 18),
                  label: const Text('View Inpatient Chart'),
                ),
              ),
              const Gap(8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.orange.shade800),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final db = ref.read(appDatabaseProvider);
                    await db.hmsDao.updateBedStatus(bed.bedNo, 'Cleaning');
                    ref.invalidate(bedsListProvider);
                    ref.invalidate(dashboardStatsProvider);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Bed ${bed.bedNo} sent for cleaning.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.cleaning_services, size: 18),
                  label: const Text('Discharge & Send for Cleaning'),
                ),
              ),
            ] else if (bed.status == 'Available') ...[
              const Text('This bed is clean, sanitized, and ready for patient intake.'),
              const Gap(16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go(AppRoutes.ipdAdmit);
                  },
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('Admit Inpatient Here'),
                ),
              ),
              const Gap(8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final db = ref.read(appDatabaseProvider);
                    await db.hmsDao.updateBedStatus(bed.bedNo, 'Cleaning');
                    ref.invalidate(bedsListProvider);
                    ref.invalidate(dashboardStatsProvider);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Bed ${bed.bedNo} marked for cleaning.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.cleaning_services_outlined, size: 18),
                  label: const Text('Mark for Cleaning'),
                ),
              ),
              const Gap(8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final db = ref.read(appDatabaseProvider);
                    await db.hmsDao.updateBedStatus(bed.bedNo, 'Maintenance');
                    ref.invalidate(bedsListProvider);
                    ref.invalidate(dashboardStatsProvider);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Bed ${bed.bedNo} marked for maintenance.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.build_outlined, size: 18),
                  label: const Text('Mark for Maintenance'),
                ),
              ),
            ] else if (bed.status == 'Cleaning') ...[
              const Text('Housekeeping is currently cleaning and sanitizing this bed.'),
              const Gap(16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final db = ref.read(appDatabaseProvider);
                    await db.hmsDao.updateBedStatus(bed.bedNo, 'Available');
                    ref.invalidate(bedsListProvider);
                    ref.invalidate(dashboardStatsProvider);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Bed ${bed.bedNo} is now Available!')),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Sanitization Done — Mark Ready'),
                ),
              ),
            ] else ...[
              const Text('This bed is currently undergoing maintenance.'),
              const Gap(16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final db = ref.read(appDatabaseProvider);
                    await db.hmsDao.updateBedStatus(bed.bedNo, 'Available');
                    ref.invalidate(bedsListProvider);
                    ref.invalidate(dashboardStatsProvider);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Bed ${bed.bedNo} restored to Available!')),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Maintenance Complete — Mark Available'),
                ),
              ),
            ],
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showAddEditBedDialog(bed: bed);
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit Bed'),
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Delete Bed'),
                          content: Text('Are you sure you want to remove Bed ${bed.bedNo} from ${bed.ward} Ward?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        final db = ref.read(appDatabaseProvider);
                        await db.hmsDao.deleteBed(bed.id, bed.bedNo);
                        ref.invalidate(bedsListProvider);
                        ref.invalidate(dashboardStatsProvider);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Bed ${bed.bedNo} deleted.')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete Bed'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddEditBedDialog({BedModel? bed}) {
    final isEditing = bed != null;
    final bedNoController = TextEditingController(text: bed?.bedNo ?? '');
    final wardController = TextEditingController(text: bed?.ward ?? (_selectedWard != 'All Wards' ? _selectedWard : 'General Ward'));
    final typeController = TextEditingController(text: bed?.type ?? 'General');
    final tariffController = TextEditingController(text: bed != null ? (bed.tariffPaise / 100).toStringAsFixed(0) : '800');
    String status = bed?.status ?? 'Available';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: Text(isEditing ? 'Edit Bed ${bed.bedNo}' : 'Add New Hospital Bed'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: bedNoController,
                    decoration: const InputDecoration(labelText: 'Bed Identifier / Number *', hintText: 'e.g. ICU-01, B-101'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Bed number is required' : null,
                  ),
                  const Gap(12),
                  TextFormField(
                    controller: wardController,
                    decoration: const InputDecoration(labelText: 'Ward Name *', hintText: 'e.g. ICU, Male General, Deluxe'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Ward name is required' : null,
                  ),
                  const Gap(12),
                  DropdownButtonFormField<String>(
                    value: const ['General', 'ICU', 'Private AC', 'Semi-Private', 'Emergency', 'Pediatric'].contains(typeController.text)
                        ? typeController.text
                        : 'General',
                    decoration: const InputDecoration(labelText: 'Bed Type'),
                    items: const [
                      DropdownMenuItem(value: 'General', child: Text('General')),
                      DropdownMenuItem(value: 'ICU', child: Text('ICU / Critical Care')),
                      DropdownMenuItem(value: 'Private AC', child: Text('Private AC')),
                      DropdownMenuItem(value: 'Semi-Private', child: Text('Semi-Private')),
                      DropdownMenuItem(value: 'Emergency', child: Text('Emergency / Trauma')),
                      DropdownMenuItem(value: 'Pediatric', child: Text('Pediatric')),
                    ],
                    onChanged: (v) {
                      if (v != null) setModalState(() => typeController.text = v);
                    },
                  ),
                  const Gap(12),
                  TextFormField(
                    controller: tariffController,
                    decoration: const InputDecoration(labelText: 'Daily Tariff (₹) *', hintText: 'e.g. 1200'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Tariff is required';
                      if (double.tryParse(v.trim()) == null) return 'Must be a valid number';
                      return null;
                    },
                  ),
                  const Gap(12),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Initial Status'),
                    items: const [
                      DropdownMenuItem(value: 'Available', child: Text('Available')),
                      DropdownMenuItem(value: 'Cleaning', child: Text('Cleaning')),
                      DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance')),
                    ],
                    onChanged: (v) {
                      if (v != null) setModalState(() => status = v);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(dialogCtx);

                final db = ref.read(appDatabaseProvider);
                final tariffPaise = ((double.tryParse(tariffController.text.trim()) ?? 0) * 100).round();

                if (isEditing) {
                  final updatedBed = bed.copyWith(
                    bedNo: bedNoController.text.trim(),
                    ward: wardController.text.trim(),
                    type: typeController.text.trim(),
                    tariffPaise: tariffPaise,
                    status: status,
                  );
                  await db.hmsDao.updateBed(updatedBed);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Bed ${updatedBed.bedNo} updated.')),
                    );
                  }
                } else {
                  final newBed = BedModel(
                    id: 0,
                    bedNo: bedNoController.text.trim(),
                    ward: wardController.text.trim(),
                    type: typeController.text.trim(),
                    tariffPaise: tariffPaise,
                    status: status,
                  );
                  await db.hmsDao.insertBed(newBed);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Bed ${newBed.bedNo} added to ${newBed.ward} Ward.')),
                    );
                  }
                }

                ref.invalidate(bedsListProvider);
                ref.invalidate(dashboardStatsProvider);
              },
              icon: Icon(isEditing ? Icons.check : Icons.add, size: 16),
              label: Text(isEditing ? 'Save Changes' : 'Create Bed'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bedsAsync = ref.watch(bedsListProvider);
    final allBeds = bedsAsync.value ?? [];
    final wardOptions = [
      'All Wards',
      ...allBeds.map((b) => b.ward).toSet(),
    ];

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Bed & Ward Management (Bed Board)'),
        actions: [
          OutlinedButton.icon(
            onPressed: () => _showAddEditBedDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Bed'),
          ),
          const Gap(8),
          FilledButton.icon(
            onPressed: () => context.go(AppRoutes.ipdAdmit),
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Admit to Bed'),
          ),
          const Gap(16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter & Stats Card
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
                    const Icon(Icons.hotel_outlined),
                    const Gap(8),
                    const Text('Ward: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: wardOptions.contains(_selectedWard)
                          ? _selectedWard
                          : 'All Wards',
                      underline: const SizedBox.shrink(),
                      items: wardOptions
                          .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedWard = v);
                      },
                    ),
                    const Spacer(),
                    // Legend
                    _buildLegendItem('Available', Colors.green.shade600),
                    const Gap(12),
                    _buildLegendItem('Occupied', Colors.red.shade700),
                    const Gap(12),
                    _buildLegendItem('Cleaning', Colors.orange.shade700),
                    const Gap(12),
                    _buildLegendItem('Maintenance', Colors.grey.shade600),
                  ],
                ),
              ),
            ),
            const Gap(20),

            // Visual Grid of Beds
            Expanded(
              child: bedsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading beds: $e')),
                data: (beds) {
                  final filtered = _selectedWard == 'All Wards'
                      ? beds
                      : beds.where((b) => b.ward == _selectedWard).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.hotel_outlined, size: 64, color: colorScheme.outline),
                          const Gap(16),
                          Text(
                            _selectedWard == 'All Wards'
                                ? 'No beds configured yet'
                                : 'No beds in $_selectedWard',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Gap(8),
                          Text(
                            'Click "Add Bed" to create wards and assign hospital beds.',
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                          const Gap(16),
                          FilledButton.icon(
                            onPressed: () => _showAddEditBedDialog(),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Bed'),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 240,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 145,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final bed = filtered[index];
                      final statusColor = _colorForStatus(bed.status);

                      return Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: statusColor.withOpacity(0.4), width: 1.5),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showBedActionsDialog(bed),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        bed.bedNo,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          bed.status,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Gap(4),
                                  Text(
                                    '${bed.ward} • ${bed.type}',
                                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                  ),
                                  const Gap(12),
                                  if (bed.patientName != null) ...[
                                    Text(
                                      bed.patientName!,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      bed.uhid ?? '',
                                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                    ),
                                  ] else ...[
                                    Text(
                                      'Tariff: ₹${(bed.tariffPaise / 100).toStringAsFixed(0)}/day',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const Gap(4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
