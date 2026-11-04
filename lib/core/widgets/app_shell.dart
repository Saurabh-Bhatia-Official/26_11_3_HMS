import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_management/core/auth/auto_lock_service.dart';
import 'package:hospital_management/core/auth/session_service.dart';
import 'package:hospital_management/core/permissions/permission_service.dart';
import 'package:hospital_management/core/providers/hospital_name_provider.dart';
import 'package:hospital_management/core/router/app_routes.dart';
import 'package:hospital_management/core/theme/theme_provider.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/data/models/hms_models.dart';
import 'package:hospital_management/features/patients/patients_provider.dart';

class NavDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
  final String module;

  const NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    required this.module,
  });
}

const List<NavDestination> kNavDestinations = [
  NavDestination(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
    route: AppRoutes.dashboard,
    module: Modules.dashboard,
  ),
  NavDestination(
    label: 'Patients',
    icon: Icons.people_outline_rounded,
    selectedIcon: Icons.people_rounded,
    route: AppRoutes.patients,
    module: Modules.patients,
  ),
  NavDestination(
    label: 'Appointments',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month_rounded,
    route: AppRoutes.appointments,
    module: Modules.appointments,
  ),
  NavDestination(
    label: 'OPD Care',
    icon: Icons.local_hospital_outlined,
    selectedIcon: Icons.local_hospital_rounded,
    route: AppRoutes.opd,
    module: Modules.opd,
  ),
  NavDestination(
    label: 'IPD / Wards',
    icon: Icons.hotel_outlined,
    selectedIcon: Icons.hotel_rounded,
    route: AppRoutes.ipd,
    module: Modules.ipd,
  ),
  NavDestination(
    label: 'Bed Board',
    icon: Icons.single_bed_outlined,
    selectedIcon: Icons.single_bed_rounded,
    route: AppRoutes.beds,
    module: Modules.beds,
  ),
  NavDestination(
    label: 'Laboratory',
    icon: Icons.biotech_outlined,
    selectedIcon: Icons.biotech_rounded,
    route: AppRoutes.lab,
    module: Modules.lab,
  ),
  NavDestination(
    label: 'Pharmacy',
    icon: Icons.medication_outlined,
    selectedIcon: Icons.medication_rounded,
    route: AppRoutes.pharmacy,
    module: Modules.pharmacy,
  ),
  NavDestination(
    label: 'Billing',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long_rounded,
    route: AppRoutes.billing,
    module: Modules.billing,
  ),
  NavDestination(
    label: 'Staff',
    icon: Icons.badge_outlined,
    selectedIcon: Icons.badge_rounded,
    route: AppRoutes.staff,
    module: Modules.staff,
  ),
  NavDestination(
    label: 'Reports',
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart_rounded,
    route: AppRoutes.reports,
    module: Modules.reports,
  ),
  NavDestination(
    label: 'Audit Log',
    icon: Icons.history_outlined,
    selectedIcon: Icons.history_rounded,
    route: AppRoutes.audit,
    module: Modules.audit,
  ),
  NavDestination(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
    route: AppRoutes.settings,
    module: Modules.settings,
  ),
];

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _getSelectedIndex(String location, List<NavDestination> destinations) {
    for (int i = 0; i < destinations.length; i++) {
      if (location.startsWith(destinations[i].route)) {
        return i;
      }
    }
    return 0;
  }

  void _showQuickSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final repo = ref.read(patientRepositoryProvider);
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.search, size: 22),
                  Gap(8),
                  Text('Quick Patient Lookup'),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Enter patient name, UHID, or phone…',
                        prefixIcon: Icon(Icons.person_search),
                      ),
                      onChanged: (val) {
                        setDialogState(() => query = val.trim());
                      },
                    ),
                    const Gap(12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: FutureBuilder(
                        future: repo.search(query, limit: 10),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                          }
                          final list = snapshot.data ?? [];
                          if (list.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(query.isEmpty ? 'Type to search patient directory' : 'No patients found matching "$query"'),
                            );
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            itemCount: list.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final p = list[idx];
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text(p.name.isNotEmpty ? p.name[0] : 'P'),
                                ),
                                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${p.uhid} • ${p.gender ?? ""} ${p.age}y • ${p.phone ?? ""}'),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                                onTap: () {
                                  Navigator.pop(dialogContext);
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    context.go('/patients/${p.id}');
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    context.go(AppRoutes.patientsNew);
                  },
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('Register New Patient'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddHospitalDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final typeCtrl = TextEditingController(text: 'Multispeciality Hospital');
    final addressCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final taxCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_business_rounded, color: Colors.blue),
            Gap(10),
            Text('Register New Hospital / Branch'),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Hospital Name *', hintText: 'e.g. CareSync City Hospital'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Hospital name is required' : null,
                ),
                const Gap(10),
                TextFormField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(labelText: 'Branch Code *', hintText: 'e.g. CS-CITY, CS-NORTH'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Branch code is required' : null,
                ),
                const Gap(10),
                DropdownButtonFormField<String>(
                  value: typeCtrl.text,
                  decoration: const InputDecoration(labelText: 'Facility Type'),
                  items: const [
                    DropdownMenuItem(value: 'Multispeciality Hospital', child: Text('Multispeciality Hospital')),
                    DropdownMenuItem(value: 'Trauma & Emergency Center', child: Text('Trauma & Emergency Center')),
                    DropdownMenuItem(value: 'General Hospital', child: Text('General Hospital')),
                    DropdownMenuItem(value: 'Diagnostic Clinic', child: Text('Diagnostic Clinic')),
                    DropdownMenuItem(value: 'Day Surgery Center', child: Text('Day Surgery Center')),
                  ],
                  onChanged: (v) {
                    if (v != null) typeCtrl.text = v;
                  },
                ),
                const Gap(10),
                TextFormField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: 'Address', hintText: 'Street, City, State'),
                ),
                const Gap(10),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone', hintText: '+91 98765 43210'),
                ),
                const Gap(10),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email', hintText: 'branch@caresync.health'),
                ),
                const Gap(10),
                TextFormField(
                  controller: taxCtrl,
                  decoration: const InputDecoration(labelText: 'GSTIN / Tax ID', hintText: 'e.g. GSTIN27AABCT3518Q1Z5'),
                ),
              ],
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
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);

              final newHospital = HospitalModel(
                id: 0,
                uuid: 'hosp-${DateTime.now().millisecondsSinceEpoch}',
                name: nameCtrl.text.trim(),
                code: codeCtrl.text.trim().toUpperCase(),
                type: typeCtrl.text.trim(),
                address: addressCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                taxId: taxCtrl.text.trim(),
                status: 'Active',
              );

              final db = ref.read(appDatabaseProvider);
              await db.hmsDao.insertHospital(newHospital);
              ref.invalidate(allHospitalsProvider);

              // Automatically switch to the newly created hospital
              final all = await db.hmsDao.getAllHospitals();
              final created = all.lastWhere((h) => h.code == newHospital.code, orElse: () => newHospital);
              await ref.read(activeHospitalProvider.notifier).switchHospital(created);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Hospital "${newHospital.name}" added and activated!'),
                    backgroundColor: Colors.teal.shade800,
                  ),
                );
              }
            },
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Create & Activate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final checker = ref.watch(permissionCheckerProvider);
    final visibleDestinations = kNavDestinations.where((d) => checker.canAccessModule(d.module)).toList();
    final effectiveDestinations = visibleDestinations.isEmpty ? kNavDestinations : visibleDestinations;
    final selectedIndex = _getSelectedIndex(location, effectiveDestinations);
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final colorScheme = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider);
    final hospitalName = ref.watch(hospitalNameProvider).value ?? 'CareSync';
    final themeMode = ref.watch(themeModeProvider);

    return AutoLockActivityDetector(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0.5,
          titleSpacing: 16,
          title: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/caresync_logo.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.local_hospital_rounded,
                      size: 20,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const Gap(12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hospitalName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'CareSync • Connecting Care. Simplifying Healthcare.',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            // Super Admin Multi-Hospital Switcher
            if (user?.role.toLowerCase().contains('super') ?? false)
              Consumer(
                builder: (context, ref, _) {
                  final activeHosp = ref.watch(activeHospitalProvider);
                  final allHospAsync = ref.watch(allHospitalsProvider);
                  final hospitals = allHospAsync.value ?? [];

                  return PopupMenuButton<String>(
                    tooltip: 'Active Hospital (Super Admin Multi-Hospital)',
                    offset: const Offset(0, 48),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorScheme.secondary.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.domain_rounded, size: 16, color: colorScheme.onSecondaryContainer),
                          const Gap(6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Text(
                              activeHosp?.name ?? hospitalName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSecondaryContainer,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Gap(4),
                          Icon(Icons.arrow_drop_down, size: 18, color: colorScheme.onSecondaryContainer),
                        ],
                      ),
                    ),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem<String>(
                        enabled: false,
                        child: Text(
                          'SUPER ADMIN • MULTI-HOSPITAL',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ),
                      const PopupMenuDivider(),
                      for (final h in hospitals)
                        PopupMenuItem<String>(
                          value: 'switch_${h.id}',
                          child: Row(
                            children: [
                              Icon(
                                h.id == activeHosp?.id ? Icons.check_circle : Icons.business_outlined,
                                size: 16,
                                color: h.id == activeHosp?.id ? Colors.green : Colors.grey,
                              ),
                              const Gap(8),
                              Expanded(
                                child: Text(
                                  '${h.name} (${h.code})',
                                  style: TextStyle(
                                    fontWeight: h.id == activeHosp?.id ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'add_hospital',
                        child: Row(
                          children: [
                            Icon(Icons.add_business_outlined, size: 16, color: Colors.blue),
                            Gap(8),
                            Text('Add New Hospital / Branch', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (val) {
                      if (val == 'add_hospital') {
                        _showAddHospitalDialog(context);
                      } else if (val.startsWith('switch_')) {
                        final id = int.tryParse(val.replaceFirst('switch_', ''));
                        if (id != null) {
                          final target = hospitals.firstWhere((h) => h.id == id);
                          ref.read(activeHospitalProvider.notifier).switchHospital(target);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Switched to ${target.name} (${target.code})'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                  );
                },
              ),

            // Quick Search Dialog
            IconButton(
              icon: const Icon(Icons.search_rounded),
              tooltip: 'Quick Patient Search (UHID / Name)',
              onPressed: () => _showQuickSearchDialog(context),
            ),

            // Global Quick Actions Menu (Role-Based Enabled/Disabled)
            if (checker.can(Modules.patients, AppActions.create) ||
                checker.can(Modules.appointments, AppActions.create) ||
                checker.can(Modules.ipd, AppActions.create) ||
                checker.canAccessModule(Modules.opd) ||
                checker.canAccessModule(Modules.pharmacy) ||
                checker.can(Modules.staff, AppActions.create) ||
                checker.can(Modules.billing, AppActions.create))
              PopupMenuButton<String>(
                tooltip: 'Quick Actions',
                offset: const Offset(0, 48),
                icon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 16, color: colorScheme.onPrimary),
                      const Gap(4),
                      Text(
                        'Quick New',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  if (checker.can(Modules.patients, AppActions.create))
                    const PopupMenuItem(
                      value: 'patient',
                      child: Row(
                        children: [
                          Icon(Icons.person_add_outlined, size: 18),
                          Gap(10),
                          Text('Register Patient'),
                        ],
                      ),
                    ),
                  if (checker.can(Modules.appointments, AppActions.create))
                    const PopupMenuItem(
                      value: 'appointment',
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_outlined, size: 18),
                          Gap(10),
                          Text('Book Appointment'),
                        ],
                      ),
                    ),
                  if (checker.can(Modules.ipd, AppActions.create))
                    const PopupMenuItem(
                      value: 'ipd',
                      child: Row(
                        children: [
                          Icon(Icons.hotel_outlined, size: 18),
                          Gap(10),
                          Text('Admit to Ward / IPD'),
                        ],
                      ),
                    ),
                  if (checker.canAccessModule(Modules.opd))
                    const PopupMenuItem(
                      value: 'opd',
                      child: Row(
                        children: [
                          Icon(Icons.local_hospital_outlined, size: 18),
                          Gap(10),
                          Text('OPD Queue & Vitals'),
                        ],
                      ),
                    ),
                  if (checker.canAccessModule(Modules.pharmacy))
                    const PopupMenuItem(
                      value: 'pharmacy',
                      child: Row(
                        children: [
                          Icon(Icons.medication_outlined, size: 18),
                          Gap(10),
                          Text('Pharmacy & Add Medicine'),
                        ],
                      ),
                    ),
                  if (checker.can(Modules.staff, AppActions.create))
                    const PopupMenuItem(
                      value: 'staff',
                      child: Row(
                        children: [
                          Icon(Icons.person_add_alt_1_outlined, size: 18),
                          Gap(10),
                          Text('Add Staff / Doctor'),
                        ],
                      ),
                    ),
                  if (checker.canAccessModule(Modules.lab))
                    const PopupMenuItem(
                      value: 'lab',
                      child: Row(
                        children: [
                          Icon(Icons.biotech_outlined, size: 18),
                          Gap(10),
                          Text('Order Lab Test'),
                        ],
                      ),
                    ),
                  if (checker.can(Modules.billing, AppActions.create))
                    const PopupMenuItem(
                      value: 'billing',
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 18),
                          Gap(10),
                          Text('Generate Invoice / Bill'),
                        ],
                      ),
                    ),
                ],
                onSelected: (val) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    switch (val) {
                      case 'patient':
                        context.go(AppRoutes.patientsNew);
                        break;
                      case 'appointment':
                        context.go(AppRoutes.appointmentsNew);
                        break;
                      case 'ipd':
                        context.go(AppRoutes.ipdAdmit);
                        break;
                      case 'opd':
                        context.go(AppRoutes.opd);
                        break;
                      case 'lab':
                        context.go(AppRoutes.lab);
                        break;
                      case 'pharmacy':
                        context.go(AppRoutes.pharmacy);
                        break;
                      case 'staff':
                        context.go(AppRoutes.staffNew);
                        break;
                      case 'billing':
                        context.go(AppRoutes.billing);
                        break;
                    }
                  });
                },
              ),
            const Gap(4),

            // Dark / Light Mode Toggle
            IconButton(
              icon: Icon(
                themeMode == ThemeMode.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
              tooltip: themeMode == ThemeMode.dark ? 'Light mode' : 'Dark mode',
              onPressed: () {
                ref.read(themeModeProvider.notifier).setThemeMode(
                      themeMode == ThemeMode.dark
                          ? ThemeMode.light
                          : ThemeMode.dark,
                    );
              },
            ),

            // Quick Lock
            IconButton(
              icon: const Icon(Icons.lock_outline_rounded),
              tooltip: 'Lock Session',
              onPressed: () {
                ref.read(sessionProvider.notifier).lock();
                context.go(AppRoutes.lock);
              },
            ),

            // User Info & Menu
            PopupMenuButton<String>(
              tooltip: 'User menu',
              offset: const Offset(0, 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: colorScheme.primary,
                      child: Text(
                        (user?.username ?? 'U')[0].toUpperCase(),
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Gap(8),
                    if (isDesktop) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user?.fullName ?? user?.username ?? 'Staff',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            user?.role ?? 'Role',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const Gap(4),
                      const Icon(Icons.arrow_drop_down, size: 18),
                    ],
                  ],
                ),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      const Icon(Icons.badge_outlined, size: 18),
                      const Gap(10),
                      Text('Signed in as ${user?.username ?? ""} • ${user?.role ?? "Staff"}'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'lock',
                  child: const Row(
                    children: [
                      Icon(Icons.lock_clock_outlined, size: 18),
                      Gap(10),
                      Text('Lock Screen'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 18, color: colorScheme.error),
                      const Gap(10),
                      Text('Sign Out', style: TextStyle(color: colorScheme.error)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (value == 'logout') {
                    ref.read(sessionProvider.notifier).logout();
                    context.go(AppRoutes.login);
                  } else if (value == 'lock') {
                    ref.read(sessionProvider.notifier).lock();
                    context.go(AppRoutes.lock);
                  }
                });
              },
            ),
            const Gap(8),
          ],
        ),
        drawer: isDesktop
            ? null
            : Drawer(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    DrawerHeader(
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/caresync_logo.png',
                              width: 48,
                              height: 48,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.local_hospital_rounded,
                                size: 40,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const Gap(8),
                          Text(
                            hospitalName,
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'CareSync • Connecting Care. Simplifying Healthcare.',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (int i = 0; i < effectiveDestinations.length; i++)
                      ListTile(
                        leading: Icon(
                          i == selectedIndex
                              ? effectiveDestinations[i].selectedIcon
                              : effectiveDestinations[i].icon,
                          color: i == selectedIndex ? colorScheme.primary : null,
                        ),
                        title: Text(
                          effectiveDestinations[i].label,
                          style: TextStyle(
                            fontWeight: i == selectedIndex
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: i == selectedIndex ? colorScheme.primary : null,
                          ),
                        ),
                        selected: i == selectedIndex,
                        onTap: () {
                          Navigator.pop(context);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            context.go(effectiveDestinations[i].route);
                          });
                        },
                      ),
                  ],
                ),
              ),
        body: Row(
          children: [
            if (isDesktop)
              NavigationRail(
                selectedIndex: selectedIndex,
                extended: true,
                minExtendedWidth: 210,
                leading: const Gap(8),
                destinations: [
                  for (final item in effectiveDestinations)
                    NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: Text(item.label),
                    ),
                ],
                onDestinationSelected: (index) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.go(effectiveDestinations[index].route);
                  });
                },
              ),
            if (isDesktop)
              const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: widget.child),
          ],
        ),
      ),
    );
  }
}
