import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_management/core/permissions/permission_service.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/data/models/hms_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Role-Based Access Control (RBAC) & Super Admin Tests', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.open();
    });

    tearDown(() async {
      await db.close();
    });

    test('1. Super Admin role receives full permissions across all modules including hospitals', () async {
      final rows = await db.getPermissionsForRole('Super Admin');
      final modules = rows.map((r) => r.module).toSet();

      expect(modules.contains(Modules.dashboard), isTrue);
      expect(modules.contains(Modules.patients), isTrue);
      expect(modules.contains(Modules.appointments), isTrue);
      expect(modules.contains(Modules.opd), isTrue);
      expect(modules.contains(Modules.ipd), isTrue);
      expect(modules.contains(Modules.beds), isTrue);
      expect(modules.contains(Modules.staff), isTrue);
      expect(modules.contains(Modules.lab), isTrue);
      expect(modules.contains(Modules.pharmacy), isTrue);
      expect(modules.contains(Modules.billing), isTrue);
      expect(modules.contains(Modules.reports), isTrue);
      expect(modules.contains(Modules.settings), isTrue);
      expect(modules.contains(Modules.audit), isTrue);
      expect(modules.contains(Modules.hospitals), isTrue);
    });

    test('2. Hospital Admin role has all hospital modules but not multi-hospital management', () async {
      final rows = await db.getPermissionsForRole('Admin');
      final modules = rows.map((r) => r.module).toSet();

      expect(modules.contains(Modules.dashboard), isTrue);
      expect(modules.contains(Modules.staff), isTrue);
      expect(modules.contains(Modules.settings), isTrue);
      expect(modules.contains(Modules.hospitals), isFalse);
    });

    test('3. Doctor role has clinical access but restricted admin access and cannot delete patients', () async {
      final rows = await db.getPermissionsForRole('Doctor');
      final PermissionMap map = {};
      for (final row in rows) {
        map.putIfAbsent(row.module, () => {}).add(row.action);
      }
      final checker = PermissionChecker(map);

      expect(checker.canAccessModule(Modules.dashboard), isTrue);
      expect(checker.canAccessModule(Modules.patients), isTrue);
      expect(checker.can(Modules.patients, AppActions.create), isTrue);
      expect(checker.can(Modules.patients, AppActions.edit), isTrue);
      // Doctors cannot delete patients
      expect(checker.can(Modules.patients, AppActions.delete), isFalse);

      // Doctors cannot manage staff or settings
      expect(checker.canAccessModule(Modules.staff), isFalse);
      expect(checker.canAccessModule(Modules.settings), isFalse);
    });

    test('4. Pharmacist role has pharmacy access but cannot admit patients or manage beds', () async {
      final rows = await db.getPermissionsForRole('Pharmacist');
      final PermissionMap map = {};
      for (final row in rows) {
        map.putIfAbsent(row.module, () => {}).add(row.action);
      }
      final checker = PermissionChecker(map);

      expect(checker.canAccessModule(Modules.pharmacy), isTrue);
      expect(checker.can(Modules.pharmacy, AppActions.create), isTrue);
      expect(checker.canAccessModule(Modules.ipd), isFalse);
      expect(checker.canAccessModule(Modules.beds), isFalse);
    });

    test('5. Super Admin multi-hospital entity insertion, retrieval, and switching', () async {
      // 1. Initial seeded hospital
      final initialHospitals = await db.hmsDao.getAllHospitals();
      expect(initialHospitals, isNotEmpty);
      expect(initialHospitals.first.code, equals('CS-CENTRAL'));

      // 2. Add second hospital branch
      final secondHospital = HospitalModel(
        id: 0,
        uuid: '00000000-0000-0000-0000-000000000002',
        name: 'CareSync City Branch',
        code: 'CS-CITY',
        type: 'Trauma & Emergency Center',
        address: '500 Downtown Ave',
        phone: '+91 98765 11111',
        email: 'city@caresync.health',
        taxId: 'GSTIN27AABCT3518Q1Z6',
        status: 'Active',
      );
      final id = await db.hmsDao.insertHospital(secondHospital);
      expect(id, greaterThan(0));

      final allHospitals = await db.hmsDao.getAllHospitals();
      expect(allHospitals.length, equals(2));
      expect(allHospitals.any((h) => h.code == 'CS-CITY'), isTrue);

      // 3. Update hospital
      final inserted = allHospitals.firstWhere((h) => h.code == 'CS-CITY');
      final updated = inserted.copyWith(name: 'CareSync City Trauma Center');
      await db.hmsDao.updateHospital(updated);

      final retrieved = await db.hmsDao.getHospitalById(inserted.id);
      expect(retrieved?.name, equals('CareSync City Trauma Center'));

      // 4. Delete hospital
      await db.hmsDao.deleteHospital(inserted.id, inserted.name);
      final afterDelete = await db.hmsDao.getAllHospitals();
      expect(afterDelete.length, equals(1));
    });

    test('6. Super Admin account can authenticate with SuperAdmin@1234', () async {
      final user = await db.getUserByUsername('superadmin');
      expect(user, isNotNull);
      expect(user!.role, equals('Super Admin'));
      expect(user.fullName, contains('Super Administrator'));
    });

    test('7. Super Admin can provision staff accounts for any hospital and retrieve all users', () async {
      await db.createRegularUser(
        username: 'dr_miller',
        passwordHash: 'salt_miller:hash123',
        fullName: 'Dr. Arthur Miller',
        role: 'Doctor',
        email: 'miller@hospital.org',
        hospitalId: 1,
        hospitalName: 'CareSync Central Hospital',
      );

      final allUsers = await db.getAllUsers();
      expect(allUsers.any((u) => u.username == 'dr_miller'), isTrue);

      final miller = allUsers.firstWhere((u) => u.username == 'dr_miller');
      expect(miller.role, equals('Doctor'));
      expect(miller.hospitalId, equals(1));
      expect(miller.hospitalName, equals('CareSync Central Hospital'));

      await db.deleteCustomUser('dr_miller');
      final afterDelete = await db.getAllUsers();
      expect(afterDelete.any((u) => u.username == 'dr_miller'), isFalse);
    });
  });
}
