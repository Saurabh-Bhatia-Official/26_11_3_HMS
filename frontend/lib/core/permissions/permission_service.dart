import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hospital_management/core/auth/session_service.dart';
import 'package:hospital_management/data/database/app_database.dart';

// ---------------------------------------------------------------------------
// Module & Action constants
// ---------------------------------------------------------------------------

/// Predefined module identifiers.  These must match the `module` column
/// values in the `role_permissions` table.
abstract class Modules {
  Modules._();

  static const String dashboard = 'dashboard';
  static const String patients = 'patients';
  static const String appointments = 'appointments';
  static const String opd = 'opd';
  static const String ipd = 'ipd';
  static const String beds = 'beds';
  static const String staff = 'staff';
  static const String lab = 'lab';
  static const String pharmacy = 'pharmacy';
  static const String billing = 'billing';
  static const String reports = 'reports';
  static const String settings = 'settings';
  static const String audit = 'audit';
  static const String prescriptions = 'prescriptions';
  static const String emr = 'emr';
  static const String hospitals = 'hospitals';
}

/// Predefined action identifiers.  These must match the `action` column
/// values in the `role_permissions` table.
abstract class AppActions {
  AppActions._();

  static const String view = 'view';
  static const String create = 'create';
  static const String edit = 'edit';
  static const String delete = 'delete';
  static const String print = 'print';
  static const String export = 'export';
  static const String approve = 'approve';
}

// ---------------------------------------------------------------------------
// Permission map type alias
// ---------------------------------------------------------------------------

/// `{ module → Set<action> }`
typedef PermissionMap = Map<String, Set<String>>;

// ---------------------------------------------------------------------------
// PermissionChecker
// ---------------------------------------------------------------------------

/// Synchronous helper that wraps a loaded [PermissionMap].
///
/// Usage:
/// ```dart
/// final checker = ref.watch(permissionCheckerProvider);
/// if (checker.can(Modules.patients, Actions.delete)) { ... }
/// ```
class PermissionChecker {
  const PermissionChecker(this._permissions);

  /// Empty checker — denies everything.  Used before permissions are loaded.
  const PermissionChecker.empty() : _permissions = const {};

  final PermissionMap _permissions;

  /// Returns `true` if the current role has [action] permission on [module].
  bool can(String module, String action) {
    return _permissions[module]?.contains(action) ?? false;
  }

  /// Returns `true` if the current role has *any* permission on [module].
  bool canAccessModule(String module) {
    final actions = _permissions[module];
    return actions != null && actions.isNotEmpty;
  }

  /// Returns all permitted actions for [module].
  Set<String> actionsFor(String module) => _permissions[module] ?? const {};

  @override
  String toString() => 'PermissionChecker($_permissions)';
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Loads all permissions for the current user's role from the DB.
///
/// Returns an empty map when no user is logged in.
final permissionsProvider = FutureProvider<PermissionMap>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const {};

  final db = ref.read(appDatabaseProvider);
  final rows = await db.getPermissionsForRole(user.role);

  final PermissionMap map = {};
  for (final row in rows) {
    map.putIfAbsent(row.module, () => {}).add(row.action);
  }
  return map;
});

/// Synchronous [PermissionChecker] built from [permissionsProvider].
///
/// Returns [PermissionChecker.empty] while permissions are loading or on error.
final permissionCheckerProvider = Provider<PermissionChecker>((ref) {
  final asyncPermissions = ref.watch(permissionsProvider);
  return asyncPermissions.when(
    data: (map) => PermissionChecker(map),
    loading: () => const PermissionChecker.empty(),
    error: (_, __) => const PermissionChecker.empty(),
  );
});
