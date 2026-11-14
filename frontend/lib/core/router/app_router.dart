import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_management/core/auth/auto_lock_service.dart';
import 'package:hospital_management/data/models/hms_models.dart';
import 'package:hospital_management/core/auth/session_service.dart';
import 'package:hospital_management/core/permissions/permission_service.dart';
import 'package:hospital_management/core/router/app_routes.dart';
import 'package:hospital_management/core/widgets/app_shell.dart';
import 'package:hospital_management/features/appointments/presentation/screens/appointment_form_screen.dart';
import 'package:hospital_management/features/appointments/presentation/screens/appointment_list_screen.dart';
import 'package:hospital_management/features/audit/presentation/screens/audit_log_screen.dart';
import 'package:hospital_management/features/auth/presentation/screens/lock_screen.dart';
import 'package:hospital_management/features/auth/presentation/screens/login_screen.dart';
import 'package:hospital_management/features/beds/presentation/screens/bed_board_screen.dart';
import 'package:hospital_management/features/billing/presentation/screens/billing_list_screen.dart';
import 'package:hospital_management/features/billing/presentation/screens/invoice_detail_screen.dart';
import 'package:hospital_management/features/hospitals/presentation/screens/hospitals_screen.dart';
import 'package:hospital_management/features/ipd/presentation/screens/admit_patient_screen.dart';
import 'package:hospital_management/features/ipd/presentation/screens/ipd_admission_screen.dart';
import 'package:hospital_management/features/ipd/presentation/screens/ipd_list_screen.dart';
import 'package:hospital_management/features/lab/presentation/screens/lab_order_detail_screen.dart';
import 'package:hospital_management/features/lab/presentation/screens/lab_order_queue_screen.dart';
import 'package:hospital_management/features/opd/presentation/screens/opd_consultation_screen.dart';
import 'package:hospital_management/features/opd/presentation/screens/opd_queue_screen.dart';
import 'package:hospital_management/features/patients/presentation/screens/patient_form_screen.dart';
import 'package:hospital_management/features/patients/presentation/screens/patient_list_screen.dart';
import 'package:hospital_management/features/patients/presentation/screens/patient_profile_screen.dart';
import 'package:hospital_management/features/pharmacy/presentation/screens/dispense_screen.dart';
import 'package:hospital_management/features/pharmacy/presentation/screens/pharmacy_dashboard_screen.dart';
import 'package:hospital_management/features/reports/presentation/screens/dashboard_screen.dart';
import 'package:hospital_management/features/reports/presentation/screens/reports_screen.dart';
import 'package:hospital_management/features/settings/presentation/screens/settings_screen.dart';
import 'package:hospital_management/features/staff/presentation/screens/staff_form_screen.dart';
import 'package:hospital_management/features/staff/presentation/screens/staff_list_screen.dart';
import 'package:hospital_management/data/models/hms_models.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = _RouterNotifier(ref);

  return GoRouter(
    debugLogDiagnostics: false,
    initialLocation: AppRoutes.dashboard,
    refreshListenable: routerNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final session = ref.read(sessionProvider);
      final isLocked = ref.read(autoLockProvider);

      final goingToLogin = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;
      final goingToLock = state.matchedLocation == AppRoutes.lock;

      // 1. Not authenticated → /login
      if (!session.isAuthenticated) {
        return goingToLogin ? null : AppRoutes.login;
      }

      // 2. Session locked → /lock
      if (isLocked) {
        return goingToLock ? null : AppRoutes.lock;
      }

      // 3. Authenticated + unlocked: don't let them linger on auth screens.
      if (goingToLogin || goingToLock) {
        return AppRoutes.dashboard;
      }

      // 4. Root redirect
      if (state.matchedLocation == AppRoutes.root) {
        return AppRoutes.dashboard;
      }

      // 5. Role-based module access check
      final user = session.user;
      if (user != null) {
        final loc = state.matchedLocation;
        final module = _routeToModule(loc);
        if (module != null && module != Modules.dashboard) {
          final checker = ref.read(permissionCheckerProvider);
          // When permissions are loaded, ensure the user has access to this module
          if (checker.canAccessModule(Modules.dashboard) &&
              !checker.canAccessModule(module)) {
            return AppRoutes.dashboard;
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) =>
            const LoginScreen(initialTab: AuthTab.createHospital),
      ),
      GoRoute(
        path: AppRoutes.lock,
        name: 'lock',
        builder: (context, state) => const LockScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.root,
            redirect: (_, __) => AppRoutes.dashboard,
          ),
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),

          // Patients
          GoRoute(
            path: AppRoutes.patients,
            name: 'patients',
            builder: (context, state) => const PatientListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'patient-new',
                builder: (context, state) => const PatientFormScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'patient-profile',
                builder: (context, state) {
                  final id =
                      int.tryParse(state.pathParameters['id'] ?? '') ?? 1;
                  return PatientProfileScreen(patientId: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'patient-edit',
                    builder: (context, state) {
                      final id = int.tryParse(state.pathParameters['id'] ?? '');
                      return PatientFormScreen(patientId: id);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Appointments
          GoRoute(
            path: AppRoutes.appointments,
            name: 'appointments',
            builder: (context, state) => const AppointmentListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'appointment-new',
                builder: (context, state) => AppointmentFormScreen(
                  appointment: state.extra as AppointmentModel?,
                ),
              ),
            ],
          ),

          // OPD
          GoRoute(
            path: AppRoutes.opd,
            name: 'opd',
            builder: (context, state) => const OpdQueueScreen(),
            routes: [
              GoRoute(
                path: ':visitId',
                name: 'opd-consultation',
                builder: (context, state) {
                  final visitId = state.pathParameters['visitId'] ?? '1';
                  return OpdConsultationScreen(visitId: visitId);
                },
              ),
            ],
          ),

          // IPD
          GoRoute(
            path: AppRoutes.ipd,
            name: 'ipd',
            builder: (context, state) => const IpdListScreen(),
            routes: [
              GoRoute(
                path: 'admit',
                name: 'ipd-admit',
                builder: (context, state) => const AdmitPatientScreen(),
              ),
              GoRoute(
                path: ':admissionId',
                name: 'ipd-admission',
                builder: (context, state) {
                  final admissionId =
                      state.pathParameters['admissionId'] ?? '1';
                  return IpdAdmissionScreen(admissionId: admissionId);
                },
              ),
            ],
          ),

          // Beds
          GoRoute(
            path: AppRoutes.beds,
            name: 'beds',
            builder: (context, state) => const BedBoardScreen(),
          ),

          // Staff
          GoRoute(
            path: AppRoutes.staff,
            name: 'staff',
            builder: (context, state) => const StaffListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'staff-new',
                builder: (context, state) => const StaffFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                name: 'staff-edit',
                builder: (context, state) {
                  final idStr = state.pathParameters['id'];
                  final id = int.tryParse(idStr ?? '');
                  final staff = state.extra is StaffModel
                      ? state.extra as StaffModel
                      : null;
                  return StaffFormScreen(staffId: id, existingStaff: staff);
                },
              ),
            ],
          ),

          // Lab
          GoRoute(
            path: AppRoutes.lab,
            name: 'lab',
            builder: (context, state) => const LabOrderQueueScreen(),
            routes: [
              GoRoute(
                path: 'orders/:orderId',
                name: 'lab-order-detail-legacy',
                builder: (context, state) {
                  final orderId = state.pathParameters['orderId'] ?? '1';
                  return LabOrderDetailScreen(orderId: orderId);
                },
              ),
              GoRoute(
                path: ':orderId',
                name: 'lab-order-detail',
                builder: (context, state) {
                  final orderId = state.pathParameters['orderId'] ?? '1';
                  return LabOrderDetailScreen(orderId: orderId);
                },
              ),
            ],
          ),

          // Pharmacy
          GoRoute(
            path: AppRoutes.pharmacy,
            name: 'pharmacy',
            builder: (context, state) => const PharmacyDashboardScreen(),
            routes: [
              GoRoute(
                path: 'dispense/:prescriptionId',
                name: 'pharmacy-dispense',
                builder: (context, state) {
                  final prescriptionId =
                      state.pathParameters['prescriptionId'] ?? '1';
                  return DispenseScreen(prescriptionId: prescriptionId);
                },
              ),
              GoRoute(
                path: ':prescriptionId',
                name: 'pharmacy-detail',
                builder: (context, state) {
                  final prescriptionId =
                      state.pathParameters['prescriptionId'] ?? '1';
                  return DispenseScreen(prescriptionId: prescriptionId);
                },
              ),
            ],
          ),

          // Billing
          GoRoute(
            path: AppRoutes.billing,
            name: 'billing',
            builder: (context, state) => const BillingListScreen(),
            routes: [
              GoRoute(
                path: ':invoiceId',
                name: 'invoice-detail',
                builder: (context, state) {
                  final invoiceId = state.pathParameters['invoiceId'] ?? '1';
                  return InvoiceDetailScreen(invoiceId: invoiceId);
                },
              ),
            ],
          ),

          // Reports
          GoRoute(
            path: AppRoutes.reports,
            name: 'reports',
            builder: (context, state) => const ReportsScreen(),
          ),

          // Hospitals (Super Admin)
          GoRoute(
            path: AppRoutes.hospitals,
            name: 'hospitals',
            builder: (context, state) => const HospitalsScreen(),
          ),

          // Settings
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),

          // Audit Log
          GoRoute(
            path: AppRoutes.audit,
            name: 'audit',
            builder: (context, state) => const AuditLogScreen(),
          ),
        ],
      ),
    ],
  );
});

String? _routeToModule(String location) {
  if (location.startsWith('/patients')) return Modules.patients;
  if (location.startsWith('/appointments')) return Modules.appointments;
  if (location.startsWith('/opd')) return Modules.opd;
  if (location.startsWith('/ipd')) return Modules.ipd;
  if (location.startsWith('/beds')) return Modules.beds;
  if (location.startsWith('/lab')) return Modules.lab;
  if (location.startsWith('/pharmacy')) return Modules.pharmacy;
  if (location.startsWith('/billing')) return Modules.billing;
  if (location.startsWith('/staff')) return Modules.staff;
  if (location.startsWith('/reports')) return Modules.reports;
  if (location.startsWith('/audit')) return Modules.audit;
  if (location.startsWith('/settings')) return Modules.settings;
  if (location.startsWith('/hospitals')) return Modules.hospitals;
  if (location.startsWith('/dashboard')) return Modules.dashboard;
  return null;
}

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<SessionState>(sessionProvider, (_, __) => notifyListeners());
    _ref.listen<bool>(autoLockProvider, (_, __) => notifyListeners());
    _ref.listen<AsyncValue<PermissionMap>>(
        permissionsProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}
