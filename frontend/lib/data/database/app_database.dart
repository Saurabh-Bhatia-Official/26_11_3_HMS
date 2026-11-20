import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hospital_management/core/auth/session_service.dart';

import 'tables/patients_table.dart';
import 'tables/patient_allergies_table.dart';
import 'tables/settings_table.dart';
import 'daos/patients_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/hms_dao.dart';

part 'app_database.g.dart';

/// User record returned for authentication
class UserAuthRecord {
  final int id;
  final String uuid;
  final String username;
  final String fullName;
  final String role;
  final String email;
  final String? avatarPath;
  final String passwordHash;
  final int? hospitalId;
  final String? hospitalName;
  final int? failedAttempts;
  final String? lockedUntil;
  final bool isDeleted;

  UserAuthRecord({
    required this.id,
    required this.uuid,
    required this.username,
    required this.fullName,
    required this.role,
    required this.email,
    this.avatarPath,
    required this.passwordHash,
    this.hospitalId,
    this.hospitalName,
    this.failedAttempts,
    this.lockedUntil,
    this.isDeleted = false,
  });
}

/// Singleton Drift database for the Hospital Management System.
///
/// Access via [AppDatabase.instance] or inject via Riverpod.
@DriftDatabase(
  tables: [
    Patients,
    PatientAllergies,
    Settings,
  ],
  daos: [
    PatientsDao,
    SettingsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  // ── Singleton ─────────────────────────────────────────────────────────────

  static AppDatabase? _instance;

  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  /// For testing: inject an in-memory executor.
  static AppDatabase forTesting(QueryExecutor executor) =>
      AppDatabase._(executor);

  // ── Schema ────────────────────────────────────────────────────────────────

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Seed default settings
          await settingsDao.upsertSetting('uhid_prefix', 'UHID');
          await settingsDao.upsertSetting('uhid_sequence', '0');
          await settingsDao.upsertSetting('hospital_name', 'CareSync');
          await settingsDao.upsertSetting('currency_symbol', '₹');
        },
        onUpgrade: (m, from, to) async {
          // Future migrations go here
        },
      );

  // ── Connection ────────────────────────────────────────────────────────────

 static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'hospital_hms',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.dart.js'),
      ),
    );
  }

  late final HmsDao hmsDao = HmsDao(this);

  // ── Public Helpers ────────────────────────────────────────────────────────

  Future<void> open() async {
    await customSelect('SELECT 1').get();
    await hmsDao.initTablesAndSeed();
    await _seedDemoUsers();
  }

  Future<String?> getSetting(String key) async {
    final row = await settingsDao.getSetting(key);
    return row?.value;
  }

  Future<void> saveSetting(String key, String value) =>
      settingsDao.upsertSetting(key, value);

  // ── User Authentication Storage ───────────────────────────────────────────

  /// Seed built-in demo accounts into the app_users table on first launch.
  Future<void> _seedDemoUsers() async {
    final existing = await customSelect('SELECT count(*) as count FROM app_users').getSingle();
    if ((existing.data['count'] as int) > 0) return;

    final now = DateTime.now().toIso8601String();
    final demoUsers = [
      {
        'uuid': 'user-demo-superadmin',
        'username': 'superadmin',
        'fullName': 'Super Administrator',
        'role': 'Super Admin',
        'email': 'superadmin@caresync.health',
        'passwordHash': hashPassword('superadmin@1234', 'salt_superadmin_secure'),
        'hospitalId': null,
        'hospitalName': null,
      },
      {
        'uuid': 'user-demo-admin',
        'username': 'admin',
        'fullName': 'Hospital Administrator',
        'role': 'Admin',
        'email': 'admin@hospital.local',
        'passwordHash': hashPassword('admin@1234', 'salt_admin_secure'),
        'hospitalId': 1,
        'hospitalName': 'CareSync Central Hospital',
      },
      {
        'uuid': 'user-demo-doctor',
        'username': 'doctor',
        'fullName': 'Duty Doctor',
        'role': 'Doctor',
        'email': 'doctor@hospital.local',
        'passwordHash': hashPassword('doctor@1234', 'salt_doctor_secure'),
        'hospitalId': 1,
        'hospitalName': 'CareSync Central Hospital',
      },
      {
        'uuid': 'user-demo-nurse',
        'username': 'nurse',
        'fullName': 'Staff Nurse',
        'role': 'Nurse',
        'email': 'nurse@hospital.local',
        'passwordHash': hashPassword('nurse@1234', 'salt_nurse_secure'),
        'hospitalId': 1,
        'hospitalName': 'CareSync Central Hospital',
      },
      {
        'uuid': 'user-demo-reception',
        'username': 'reception',
        'fullName': 'Front Desk Receptionist',
        'role': 'Receptionist',
        'email': 'reception@hospital.local',
        'passwordHash': hashPassword('reception@1234', 'salt_reception_secure'),
        'hospitalId': 1,
        'hospitalName': 'CareSync Central Hospital',
      },
      {
        'uuid': 'user-demo-staff',
        'username': 'staff',
        'fullName': 'General Staff Member',
        'role': 'Staff',
        'email': 'staff@hospital.local',
        'passwordHash': hashPassword('staff@1234', 'salt_staff_secure'),
        'hospitalId': 1,
        'hospitalName': 'CareSync Central Hospital',
      },
      {
        'uuid': 'user-demo-pharmacy',
        'username': 'pharmacy',
        'fullName': 'Chief Pharmacist',
        'role': 'Pharmacist',
        'email': 'pharmacy@hospital.local',
        'passwordHash': hashPassword('pharmacy@1234', 'salt_pharmacy_secure'),
        'hospitalId': 1,
        'hospitalName': 'CareSync Central Hospital',
      },
      {
        'uuid': 'user-demo-lab',
        'username': 'lab',
        'fullName': 'Laboratory Technician',
        'role': 'Lab Technician',
        'email': 'lab@hospital.local',
        'passwordHash': hashPassword('lab@1234', 'salt_lab_secure'),
        'hospitalId': 1,
        'hospitalName': 'CareSync Central Hospital',
      },
      {
        'uuid': 'user-demo-accounts',
        'username': 'accounts',
        'fullName': 'Billing & Accounts Officer',
        'role': 'Accounts',
        'email': 'accounts@hospital.local',
        'passwordHash': hashPassword('accounts@1234', 'salt_accounts_secure'),
        'hospitalId': 1,
        'hospitalName': 'CareSync Central Hospital',
      },
    ];

    String esc(String s) => s.replaceAll("'", "''");
    for (final u in demoUsers) {
      await customStatement('''
        INSERT INTO app_users (uuid, username, full_name, role, email, password_hash, hospital_id, hospital_name, is_deleted, created_at, updated_at)
        VALUES ('${esc(u['uuid'] as String)}', '${esc(u['username'] as String)}', '${esc(u['fullName'] as String)}', '${esc(u['role'] as String)}', '${esc(u['email'] as String)}', '${esc(u['passwordHash'] as String)}', ${u['hospitalId'] ?? 'NULL'}, '${esc(u['hospitalName'] as String? ?? '')}', 0, '$now', '$now')
      ''');
    }
  }

  /// Register or create a regular user account in the app_users table.
  Future<void> createRegularUser({
    required String username,
    required String passwordHash,
    required String fullName,
    required String role,
    required String email,
    int? hospitalId,
    String? hospitalName,
  }) async {
    await hmsDao.insertUser(
      uuid: 'user-${DateTime.now().millisecondsSinceEpoch}',
      username: username.trim(),
      fullName: fullName,
      role: role,
      passwordHash: passwordHash,
      email: email,
      hospitalId: hospitalId,
      hospitalName: hospitalName,
    );
  }

  /// Check whether a username is already taken (optionally scoped by hospital).
  Future<bool> isUsernameTaken(String username, {int? hospitalId}) async {
    return await hmsDao.isUsernameTaken(username, hospitalId: hospitalId);
  }

  /// List all registered users from the app_users table.
  Future<List<Map<String, dynamic>>> getAllUsers({int? hospitalId}) async {
    return await hmsDao.getAllUsers(hospitalId: hospitalId);
  }

  /// Delete a user from the app_users table.
  Future<void> deleteCustomUser(String username) async {
    // Look up by username then delete
    final user = await hmsDao.getUserByUsernameAndHospital(username);
    if (user != null) {
      await hmsDao.deleteUser(user['id'] as int, username);
    }
  }

  /// Retrieve a user by username from the app_users table (optionally scoped by hospital).
  Future<UserAuthRecord?> getUserByUsername(String username, {int? hospitalId}) async {
    final row = await hmsDao.getUserByUsernameAndHospital(username, hospitalId: hospitalId);
    if (row == null) return null;
    return UserAuthRecord(
      id: row['id'] as int,
      uuid: row['uuid'] as String,
      username: row['username'] as String,
      fullName: (row['full_name'] ?? row['fullName'] ?? row['username']) as String,
      role: row['role'] as String,
      email: (row['email'] as String?) ?? '',
      passwordHash: (row['password_hash'] ?? row['passwordHash']) as String,
      hospitalId: (row['hospital_id'] ?? row['hospitalId']) as int?,
      hospitalName: (row['hospital_name'] ?? row['hospitalName']) as String?,
      isDeleted: (row['is_deleted'] as int?) == 1,
    );
  }

  // Account locking is disabled per requirement
  Future<void> clearAccountLockout(int userId) async {}
  Future<void> lockAccount(int userId, String until) async {}
  Future<void> incrementFailedAttempts(int userId, int attempts) async {}

  Future<void> onLoginSuccess(int userId) async {
    try {
      await saveSetting('last_login', DateTime.now().toIso8601String());
    } catch (_) {}
  }

  // ── Permissions ───────────────────────────────────────────────────────────

  Future<List<RolePermissionRow>> getPermissionsForRole(String role) async {
    final lower = role.trim().toLowerCase();
    final list = <RolePermissionRow>[];

    void grant(String module, List<String> actions) {
      for (final a in actions) {
        list.add(RolePermissionRow(module, a));
      }
    }

    const allActions = ['view', 'create', 'edit', 'delete', 'print', 'export', 'approve'];
    const standardActions = ['view', 'create', 'edit', 'print'];
    const readOnlyActions = ['view', 'print'];

    if (lower.contains('super')) {
      const allModules = [
        'dashboard', 'patients', 'appointments', 'opd', 'ipd', 'beds',
        'staff', 'lab', 'pharmacy', 'billing', 'reports', 'settings',
        'audit', 'prescriptions', 'emr', 'hospitals',
      ];
      for (final m in allModules) {
        grant(m, allActions);
      }
    } else if (lower.contains('admin')) {
      const allModules = [
        'dashboard', 'patients', 'appointments', 'opd', 'ipd', 'beds',
        'staff', 'lab', 'pharmacy', 'billing', 'reports', 'settings',
        'audit', 'prescriptions', 'emr',
      ];
      for (final m in allModules) {
        grant(m, allActions);
      }
    } else if (lower.contains('doctor')) {
      grant('dashboard', readOnlyActions);
      grant('patients', standardActions);
      grant('appointments', standardActions);
      grant('opd', standardActions);
      grant('ipd', standardActions);
      grant('beds', standardActions);
      grant('prescriptions', standardActions);
      grant('emr', standardActions);
      grant('lab', readOnlyActions);
      grant('pharmacy', readOnlyActions);
    } else if (lower.contains('nurse')) {
      grant('dashboard', readOnlyActions);
      grant('patients', readOnlyActions);
      grant('appointments', standardActions);
      grant('opd', standardActions);
      grant('ipd', standardActions);
      grant('beds', standardActions);
      grant('prescriptions', readOnlyActions);
      grant('pharmacy', readOnlyActions);
    } else if (lower.contains('reception')) {
      grant('dashboard', readOnlyActions);
      grant('patients', standardActions);
      grant('appointments', allActions);
      grant('opd', readOnlyActions);
      grant('beds', readOnlyActions);
      grant('billing', standardActions);
    } else if (lower.contains('pharm')) {
      grant('dashboard', readOnlyActions);
      grant('pharmacy', allActions);
      grant('prescriptions', standardActions);
      grant('patients', readOnlyActions);
      grant('billing', standardActions);
    } else if (lower.contains('lab')) {
      grant('dashboard', readOnlyActions);
      grant('lab', allActions);
      grant('patients', readOnlyActions);
    } else if (lower.contains('account') || lower.contains('billing')) {
      grant('dashboard', readOnlyActions);
      grant('billing', allActions);
      grant('reports', allActions);
      grant('patients', readOnlyActions);
    } else {
      // Default Staff
      grant('dashboard', readOnlyActions);
      grant('appointments', readOnlyActions);
      grant('beds', readOnlyActions);
      grant('patients', readOnlyActions);
    }

    return list;
  }
}

class RolePermissionRow {
  final String module;
  final String action;
  const RolePermissionRow(this.module, this.action);
}

/// Riverpod provider for AppDatabase singleton
final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

/// Riverpod provider for all user accounts (Super Admin & Admin management)
final allUsersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.getAllUsers();
});
