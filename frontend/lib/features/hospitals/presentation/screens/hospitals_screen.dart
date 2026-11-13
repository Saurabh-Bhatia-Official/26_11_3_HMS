import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:hospital_management/core/permissions/permission_service.dart';
import 'package:hospital_management/core/providers/hospital_name_provider.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/data/models/hms_models.dart';

class HospitalsScreen extends ConsumerStatefulWidget {
  const HospitalsScreen({super.key});

  @override
  ConsumerState<HospitalsScreen> createState() => _HospitalsScreenState();
}

class _HospitalsScreenState extends ConsumerState<HospitalsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<String> _facilityTypes = [
    'Multispeciality Hospital',
    'General Hospital',
    'Clinic / Outpatient',
    'Trauma & Emergency Center',
    'Diagnostic Clinic',
    'Day Surgery Center',
  ];

  static String _normalizeFacilityType(String? raw) {
    if (raw == null || raw.trim().isEmpty) return _facilityTypes.first;
    final clean = raw.trim();
    if (_facilityTypes.contains(clean)) return clean;
    final lower = clean.toLowerCase().replaceAll('-', '').replaceAll(' ', '');
    if (lower.contains('multi')) return 'Multispeciality Hospital';
    if (lower.contains('general')) return 'General Hospital';
    if (lower.contains('clinic') || lower.contains('outpatient')) return 'Clinic / Outpatient';
    if (lower.contains('trauma') || lower.contains('emergency')) return 'Trauma & Emergency Center';
    if (lower.contains('diagnos')) return 'Diagnostic Clinic';
    if (lower.contains('surgery')) return 'Day Surgery Center';
    return _facilityTypes.first;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditHospitalDialog({HospitalModel? hospital}) {
    final isEditing = hospital != null;
    final nameCtrl = TextEditingController(text: hospital?.name ?? '');
    final codeCtrl = TextEditingController(text: hospital?.code ?? '');
    final initialType = _normalizeFacilityType(hospital?.type);
    final typeCtrl = TextEditingController(text: initialType);
    final addressCtrl = TextEditingController(text: hospital?.address ?? '');
    final phoneCtrl = TextEditingController(text: hospital?.phone ?? '');
    final emailCtrl = TextEditingController(text: hospital?.email ?? '');
    final taxIdCtrl = TextEditingController(text: hospital?.taxId ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(isEditing ? Icons.edit_note : Icons.add_business_rounded, color: Theme.of(context).colorScheme.primary),
            const Gap(8),
            Text(isEditing ? 'Edit Hospital Entity' : 'Register New Hospital / Branch'),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Hospital Name *',
                      hintText: 'e.g. CareSync North Clinic',
                      prefixIcon: Icon(Icons.local_hospital_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const Gap(12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: codeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Hospital Code *',
                            hintText: 'e.g. CS-NORTH',
                            prefixIcon: Icon(Icons.tag),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _normalizeFacilityType(typeCtrl.text),
                          decoration: const InputDecoration(
                            labelText: 'Facility Type',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: _facilityTypes.map((t) {
                            return DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) typeCtrl.text = val;
                          },
                        ),
                      ),
                    ],
                  ),
                  const Gap(12),
                  TextFormField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Physical Address',
                      hintText: 'Street, City, Postal Code',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const Gap(12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: phoneCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: TextFormField(
                          controller: emailCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Official Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(12),
                  TextFormField(
                    controller: taxIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tax ID / License No.',
                      prefixIcon: Icon(Icons.receipt_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton.icon(
            icon: const Icon(Icons.save, size: 16),
            label: Text(isEditing ? 'Save Changes' : 'Register Hospital'),
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              final db = ref.read(appDatabaseProvider);
              if (isEditing) {
                final updated = hospital.copyWith(
                  name: nameCtrl.text.trim(),
                  code: codeCtrl.text.trim().toUpperCase(),
                  type: typeCtrl.text.trim(),
                  address: addressCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  taxId: taxIdCtrl.text.trim(),
                );
                await db.hmsDao.updateHospital(updated);
                ref.invalidate(allHospitalsProvider);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Updated hospital entity ${updated.name}')),
                  );
                }
              } else {
                final newHospital = HospitalModel(
                  uuid: 'hosp-${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text.trim(),
                  code: codeCtrl.text.trim().toUpperCase(),
                  type: typeCtrl.text.trim(),
                  address: addressCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  taxId: taxIdCtrl.text.trim(),
                  status: 'Active',
                );
                await db.hmsDao.insertHospital(newHospital);
                ref.invalidate(allHospitalsProvider);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Registered new hospital entity ${newHospital.name}!'),
                      backgroundColor: Colors.teal.shade800,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteHospital(HospitalModel hospital, int totalCount) {
    if (totalCount <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete the sole hospital entity in the network.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            Gap(8),
            Text('Delete Hospital Entity'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${hospital.name}" (${hospital.code})?\n\n'
          'This action removes the entity record from the system network.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade800),
            onPressed: () async {
              Navigator.pop(ctx);
              final db = ref.read(appDatabaseProvider);
              await db.hmsDao.deleteHospital(hospital.id, hospital.name);
              ref.invalidate(allHospitalsProvider);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Removed hospital entity ${hospital.name}')),
                );
              }
            },
            child: const Text('Confirm Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hospitalsAsync = ref.watch(allHospitalsProvider);
    final activeHospital = ref.watch(activeHospitalProvider);
    final checker = ref.watch(permissionCheckerProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Hospitals & Multi-Branch Network'),
        actions: [
          if (checker.can(Modules.hospitals, AppActions.create)) ...[
            FilledButton.icon(
              onPressed: () => _showAddEditHospitalDialog(),
              icon: const Icon(Icons.add_business_rounded, size: 18),
              label: const Text('Register New Hospital'),
            ),
            const Gap(16),
          ],
        ],
      ),
      body: hospitalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error loading hospitals: $err')),
        data: (hospitals) {
          final filtered = hospitals.where((h) {
            if (_searchQuery.isEmpty) return true;
            final q = _searchQuery.toLowerCase();
            return h.name.toLowerCase().contains(q) ||
                h.code.toLowerCase().contains(q) ||
                h.address.toLowerCase().contains(q) ||
                h.type.toLowerCase().contains(q);
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Active Context Highlight Banner ──────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.primaryContainer.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.domain_rounded, color: colorScheme.onPrimary, size: 32),
                      ),
                      const Gap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(
                                  'Current Operating Context:',
                                  style: textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade700,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const Gap(4),
                            Text(
                              activeHospital?.name ?? 'CareSync Central Hospital',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const Gap(2),
                            Text(
                              'Code: ${activeHospital?.code ?? "CS-CENTRAL"} • Type: ${activeHospital?.type ?? "Multi-Specialty Hospital"} • ${activeHospital?.address ?? "Main Medical Campus"}',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(16),
                      Text(
                        'Total Network Branches: ${hospitals.length}',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(24),

                // ── Section Title & Search ───────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All Hospital Entities (${filtered.length})',
                            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Select any hospital below to instantly switch the active operating context for clinical, ward, and financial records.',
                            style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                          ),
                        ],
                      ),
                    ),
                    const Gap(16),
                    SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search hospitals…',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      ),
                    ),
                  ],
                ),
                const Gap(16),

                // ── Hospital Cards List ──────────────────────────────────────
                if (filtered.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Text('No hospitals found matching "$_searchQuery".'),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Gap(12),
                    itemBuilder: (context, index) {
                      final h = filtered[index];
                      final isActive = h.id == activeHospital?.id;

                      return Card(
                        elevation: isActive ? 2 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isActive ? colorScheme.primary : colorScheme.outlineVariant,
                            width: isActive ? 1.8 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? colorScheme.primary
                                      : colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.local_hospital_rounded,
                                  color: isActive
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurfaceVariant,
                                  size: 24,
                                ),
                              ),
                              const Gap(16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          h.name,
                                          style: textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primaryContainer,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            h.code,
                                            style: TextStyle(
                                              color: colorScheme.onPrimaryContainer,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (isActive)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade700,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.check, size: 12, color: Colors.white),
                                                Gap(4),
                                                Text(
                                                  'CURRENTLY ACTIVE',
                                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const Gap(4),
                                    Wrap(
                                      spacing: 16,
                                      runSpacing: 4,
                                      children: [
                                        Text('Type: ${h.type}', style: textTheme.bodySmall),
                                        if (h.address.isNotEmpty)
                                          Text('Address: ${h.address}', style: textTheme.bodySmall),
                                        if (h.phone.isNotEmpty)
                                          Text('Phone: ${h.phone}', style: textTheme.bodySmall),
                                        if (h.email.isNotEmpty)
                                          Text('Email: ${h.email}', style: textTheme.bodySmall),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Gap(16),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isActive)
                                    FilledButton.icon(
                                      onPressed: () {
                                        ref.read(activeHospitalProvider.notifier).switchHospital(h);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Switched operating context to ${h.name} (${h.code})'),
                                            backgroundColor: Colors.teal.shade800,
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.check_circle_outline, size: 16),
                                      label: const Text('Select Hospital'),
                                    )
                                  else
                                    OutlinedButton.icon(
                                      onPressed: null,
                                      icon: const Icon(Icons.check, size: 16, color: Colors.green),
                                      label: const Text('Active Context', style: TextStyle(color: Colors.green)),
                                    ),
                                  const Gap(8),
                                  if (checker.can(Modules.hospitals, AppActions.edit))
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      tooltip: 'Edit Hospital Details',
                                      onPressed: () => _showAddEditHospitalDialog(hospital: h),
                                    ),
                                  if (checker.can(Modules.hospitals, AppActions.delete))
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      tooltip: 'Delete Hospital Entity',
                                      onPressed: () => _confirmDeleteHospital(h, hospitals.length),
                                    ),
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
        },
      ),
    );
  }
}

