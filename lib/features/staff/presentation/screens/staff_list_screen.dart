import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_management/core/router/app_routes.dart';
import 'package:hospital_management/core/widgets/status_chip.dart';
import 'package:hospital_management/core/providers/hms_providers.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/data/models/hms_models.dart';

class StaffListScreen extends ConsumerStatefulWidget {
  const StaffListScreen({super.key});

  @override
  ConsumerState<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends ConsumerState<StaffListScreen> {
  String _roleFilter = 'All Roles';

  void _confirmDeleteStaff(StaffModel staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${staff.name}?'),
        content: Text(
          'Are you sure you want to remove ${staff.name} (${staff.role}) from the hospital staff directory?\n\nThis will remove them from doctor appointments and duty rosters.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async {
              Navigator.pop(ctx);
              final db = ref.read(appDatabaseProvider);
              await db.hmsDao.deleteStaff(staff.id, staff.name);
              ref.invalidate(staffListProvider);
              ref.invalidate(dashboardStatsProvider);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Staff record for ${staff.name} deleted.'),
                    backgroundColor: Colors.red.shade800,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final staffAsync = ref.watch(staffListProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Doctors & Hospital Staff Directory'),
        actions: [
          FilledButton.icon(
            onPressed: () => context.go(AppRoutes.staffNew),
            icon: const Icon(Icons.person_add_alt_1, size: 18),
            label: const Text('Add Staff / Doctor'),
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
                    const Icon(Icons.badge_outlined),
                    const Gap(8),
                    const Text('Role: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: const ['All Roles', 'Doctor', 'Nurse', 'Pharmacist'].contains(_roleFilter)
                          ? _roleFilter
                          : 'All Roles',
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: 'All Roles', child: Text('All Roles')),
                        DropdownMenuItem(value: 'Doctor', child: Text('Doctors')),
                        DropdownMenuItem(value: 'Nurse', child: Text('Nurses')),
                        DropdownMenuItem(value: 'Pharmacist', child: Text('Pharmacists')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _roleFilter = v);
                      },
                    ),
                    const Spacer(),
                    staffAsync.when(
                      data: (list) => Text(
                        'Total Staff: ${list.length}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(16),
            Expanded(
              child: staffAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading staff: $e')),
                data: (staff) {
                  final filtered = _roleFilter == 'All Roles'
                      ? staff
                      : staff.where((s) => s.role.contains(_roleFilter)).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No staff members registered.'));
                  }

                  return Card(
                    elevation: 1,
                    clipBehavior: Clip.antiAlias,
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isDoctor = item.role.contains('Doctor');

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          onTap: () => context.go(AppRoutes.staffEdit(item.id), extra: item),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: isDoctor ? Colors.blue.shade100 : colorScheme.primaryContainer,
                            child: Icon(
                              isDoctor ? Icons.medical_services_rounded : Icons.person,
                              color: isDoctor ? Colors.blue.shade900 : colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const Gap(8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Text(item.role, style: TextStyle(fontSize: 12, color: Colors.blue.shade900)),
                              ),
                              const Gap(8),
                              Text('•  ${item.department}', style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                              const Gap(12),
                              StatusChip(label: item.status),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Text('Reg: ${item.regNo}'),
                                const Gap(16),
                                const Icon(Icons.phone, size: 14, color: Colors.grey),
                                const Gap(4),
                                Text(item.phone),
                                const Gap(16),
                                if (isDoctor) Text('Fee: ${item.feeFormatted}'),
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit Profile',
                                onPressed: () => context.go(AppRoutes.staffEdit(item.id), extra: item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.calendar_month_outlined),
                                tooltip: 'Schedules',
                                onPressed: () => context.go(AppRoutes.appointments),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                tooltip: 'Delete Staff Member',
                                onPressed: () => _confirmDeleteStaff(item),
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
