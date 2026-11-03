/// Central registry of all named route paths.
///
/// Usage:
/// ```dart
/// context.go(AppRoutes.dashboard);
/// context.go('${AppRoutes.patients}/${patient.id}');
/// ```
abstract class AppRoutes {
  AppRoutes._();

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login = '/login';
  static const String lock = '/lock';

  // ── Root (redirects to dashboard) ─────────────────────────────────────────
  static const String root = '/';

  // ── Dashboard ─────────────────────────────────────────────────────────────
  static const String dashboard = '/dashboard';

  // ── Patients ─────────────────────────────────────────────────────────────
  static const String patients = '/patients';
  static const String patientNew = '/patients/new';
  static const String patientsNew = '/patients/new';
  static const String patientProfile = '/patients/:id';

  /// Build a concrete patient-profile path.
  static String patientProfilePath(int id) => '/patients/$id';

  // ── Appointments ─────────────────────────────────────────────────────────
  static const String appointments = '/appointments';
  static const String appointmentNew = '/appointments/new';
  static const String appointmentsNew = '/appointments/new';

  // ── OPD ──────────────────────────────────────────────────────────────────
  static const String opd = '/opd';
  static const String opdConsultation = '/opd/:visitId';

  static String opdConsultationPath(int visitId) => '/opd/$visitId';

  // ── IPD ──────────────────────────────────────────────────────────────────
  static const String ipd = '/ipd';
  static const String ipdAdmit = '/ipd/admit';
  static const String ipdAdmission = '/ipd/:admissionId';

  static String ipdAdmissionPath(int admissionId) => '/ipd/$admissionId';

  // ── Beds ─────────────────────────────────────────────────────────────────
  static const String beds = '/beds';

  // ── Staff ────────────────────────────────────────────────────────────────
  static const String staff = '/staff';
  static const String staffNew = '/staff/new';
  static const String staffEditPath = '/staff/:id/edit';

  static String staffEdit(dynamic id) => '/staff/$id/edit';

  // ── Lab ──────────────────────────────────────────────────────────────────
  static const String lab = '/lab';
  static const String labOrderDetail = '/lab/:orderId';

  static String labOrderDetailPath(dynamic orderId) => '/lab/$orderId';

  // ── Pharmacy ─────────────────────────────────────────────────────────────
  static const String pharmacy = '/pharmacy';
  static const String pharmacyDispense = '/pharmacy/dispense/:prescriptionId';

  static String pharmacyDispensePath(int prescriptionId) =>
      '/pharmacy/dispense/$prescriptionId';

  // ── Billing ──────────────────────────────────────────────────────────────
  static const String billing = '/billing';
  static const String invoiceDetail = '/billing/:invoiceId';

  static String invoiceDetailPath(int invoiceId) => '/billing/$invoiceId';

  // ── Reports ──────────────────────────────────────────────────────────────
  static const String reports = '/reports';

  // ── Settings ─────────────────────────────────────────────────────────────
  static const String settings = '/settings';

  // ── Audit ────────────────────────────────────────────────────────────────
  static const String audit = '/audit';
}
