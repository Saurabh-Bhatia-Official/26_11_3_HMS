import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          await settingsDao.upsertSetting('hospital_name', 'City Hospital & Medical Center');
          await settingsDao.upsertSetting('currency_symbol', '₹');
        },
        onUpgrade: (m, from, to) async {
          // Future migrations go here
        },
      );

  // ── Connection ────────────────────────────────────────────────────────────

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'hospital_hms.db');
  }

  late final HmsDao hmsDao = HmsDao(this);

  // ── Public Helpers ────────────────────────────────────────────────────────

  Future<void> open() async {
    await customSelect('SELECT 1').get();
    await hmsDao.initTablesAndSeed();
  }

  Future<String?> getSetting(String key) async {
    final row = await settingsDao.getSetting(key);
    return row?.value;
  }

  Future<void> saveSetting(String key, String value) =>
      settingsDao.upsertSetting(key, value);

  // ── User Authentication Storage ───────────────────────────────────────────

  /// Built-in demo accounts with verified SHA-256 salted hashes.
  static final Map<String, UserAuthRecord> _demoUsers = {
    'admin': UserAuthRecord(
      id: 1,
      uuid: '00000000-0000-0000-0000-000000000001',
      username: 'admin',
      fullName: 'Hospital Administrator',
      role: 'Admin',
      email: 'admin@hospital.local',
      passwordHash: 'salt_admin_secure:18efdf6a78016d99624c2352ff2a9671887f6fa810eab9d408e12214604cef10',
      isDeleted: false,
    ),
    'doctor': UserAuthRecord(
      id: 2,
      uuid: '00000000-0000-0000-0000-000000000002',
      username: 'doctor',
      fullName: 'Duty Doctor',
      role: 'Doctor',
      email: 'doctor@hospital.local',
      passwordHash: 'salt_doctor_secure:1fa1c23b7c09a5390480e9320e1e4af4324cfd92cf764fab187e8711dab456e3',
      isDeleted: false,
    ),
    'nurse': UserAuthRecord(
      id: 3,
      uuid: '00000000-0000-0000-0000-000000000003',
      username: 'nurse',
      fullName: 'Staff Nurse',
      role: 'Nurse',
      email: 'nurse@hospital.local',
      passwordHash: 'salt_nurse_secure:e3f44a61fc988df0f706af94a0435fae549f419ea0dc518b7b2c8a45db9dc740',
      isDeleted: false,
    ),
    'reception': UserAuthRecord(
      id: 4,
      uuid: '00000000-0000-0000-0000-000000000004',
      username: 'reception',
      fullName: 'Front Desk Receptionist',
      role: 'Receptionist',
      email: 'reception@hospital.local',
      passwordHash: 'salt_reception_secure:426b1f0e540915bc1ccc8d17e5523d1464840b39dee28bdb6a71066e1665b175',
      isDeleted: false,
    ),
    'pharmacy': UserAuthRecord(
      id: 5,
      uuid: '00000000-0000-0000-0000-000000000005',
      username: 'pharmacy',
      fullName: 'Chief Pharmacist',
      role: 'Pharmacist',
      email: 'pharmacy@hospital.local',
      passwordHash: 'salt_pharmacy_secure:1cb40934731e5ae5198eafd8e1d4b6fe354c39da7a62e6c602137de991a88635',
      isDeleted: false,
    ),
    'lab': UserAuthRecord(
      id: 6,
      uuid: '00000000-0000-0000-0000-000000000006',
      username: 'lab',
      fullName: 'Laboratory Technician',
      role: 'Lab Technician',
      email: 'lab@hospital.local',
      passwordHash: 'salt_lab_secure:bbd238ae3a6e1c2eab09256778e0bb7aef9bdae8cf20ee388ef1bddf16feb76a',
      isDeleted: false,
    ),
    'accounts': UserAuthRecord(
      id: 7,
      uuid: '00000000-0000-0000-0000-000000000007',
      username: 'accounts',
      fullName: 'Billing Officer',
      role: 'Accounts',
      email: 'accounts@hospital.local',
      passwordHash: 'salt_accounts_secure:14263c8df7b9ba1c1bbcb2515732f435245db246988ee2c8174bb37c7f5947e4',
      isDeleted: false,
    ),
    'user': UserAuthRecord(
      id: 8,
      uuid: '00000000-0000-0000-0000-000000000008',
      username: 'user',
      fullName: 'Hospital Staff Member',
      role: 'Staff',
      email: 'staff@hospital.local',
      passwordHash: 'salt_user_secure:b817a531b8746650926e46ad1c96e13d2fd1a5e9bcfeca070d4cf82f629989e0',
      isDeleted: false,
    ),
  };

  /// Register or create a regular user account in persistent storage.
  Future<void> createRegularUser({
    required String username,
    required String passwordHash,
    required String fullName,
    required String role,
    required String email,
  }) async {
    final key = 'custom_user_${username.trim().toLowerCase()}';
    final payload = jsonEncode({
      'username': username.trim(),
      'passwordHash': passwordHash,
      'fullName': fullName,
      'role': role,
      'email': email,
    });
    await saveSetting(key, payload);
  }

  /// Retrieve a user by username (checks database custom users first, then demo users).
  Future<UserAuthRecord?> getUserByUsername(String username) async {
    final lower = username.trim().toLowerCase();

    // 1. Check custom / regular users registered in database
    final customUserJson = await getSetting('custom_user_$lower');
    if (customUserJson != null) {
      try {
        final map = jsonDecode(customUserJson) as Map<String, dynamic>;
        return UserAuthRecord(
          id: 100 + (map['username'] as String).hashCode.abs() % 10000,
          uuid: '00000000-0000-0000-0001-${(map['username'] as String).hashCode.abs().toString().padLeft(12, '0')}',
          username: map['username'] as String,
          fullName: map['fullName'] as String,
          role: map['role'] as String,
          email: map['email'] as String,
          passwordHash: map['passwordHash'] as String,
          isDeleted: false,
        );
      } catch (_) {}
    }

    // 2. Check demo users
    if (_demoUsers.containsKey(lower)) {
      final user = _demoUsers[lower]!;
      // Allow overriding admin password if set in settings
      if (lower == 'admin') {
        final customHash = await getSetting('admin_password_hash');
        if (customHash != null) {
          return UserAuthRecord(
            id: user.id,
            uuid: user.uuid,
            username: user.username,
            fullName: user.fullName,
            role: user.role,
            email: user.email,
            passwordHash: customHash,
            isDeleted: false,
          );
        }
      }
      return user;
    }

    return null;
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
    const modules = [
      'dashboard', 'patients', 'appointments', 'opd', 'ipd', 'beds',
      'staff', 'lab', 'pharmacy', 'billing', 'reports', 'settings',
      'audit', 'prescriptions', 'emr',
    ];
    const actions = ['view', 'create', 'edit', 'delete', 'print', 'export', 'approve'];

    final list = <RolePermissionRow>[];
    for (final m in modules) {
      for (final a in actions) {
        list.add(RolePermissionRow(m, a));
      }
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
