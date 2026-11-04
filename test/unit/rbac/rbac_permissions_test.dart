import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_management/core/permissions/permission_service.dart';
import 'package:hospital_management/data/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Role-Based Access Control (RBAC) Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('1. Admin role receives full permissions across all modules', () async {
      final rows = await db.getPermissionsForRole('Admin');
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
    });

    test('2. Doctor role has clinical access but restricted admin access', () async {
      final rows = await db.getPermissionsForRole('Doctor');
      final modules = rows.map((r) => r.module).toSet();

      expect(modules.contains(Modules.dashboard), isTrue);
      expect(modules.contains(Modules.patients), isTrue);
      expect(modules.contains(Modules.appointments), isTrue);
      expect(modules.contains(Modules.opd), isTrue);
      expect(modules.contains(Modules.ipd), isTrue);
      expect(modules.contains(Modules.prescriptions), isTrue);

      // Restricted
      expect(modules.contains(Modules.staff), isFalse);
      expect(modules.contains(Modules.settings), isFalse);
      expect(modules.contains(Modules.audit), isFalse);
    });

    test('3. Pharmacist role has pharmacy access but restricted clinical access', () async {
      final rows = await db.getPermissionsForRole('Pharmacist');
      final modules = rows.map((r) => r.module).toSet();

      expect(modules.contains(Modules.dashboard), isTrue);
      expect(modules.contains(Modules.pharmacy), isTrue);
      expect(modules.contains(Modules.prescriptions), isTrue);

      // Restricted
      expect(modules.contains(Modules.ipd), isFalse);
      expect(modules.contains(Modules.staff), isFalse);
      expect(modules.contains(Modules.settings), isFalse);
      expect(modules.contains(Modules.audit), isFalse);
    });

    test('4. PermissionChecker correctly validates permissions map', () async {
      final rows = await db.getPermissionsForRole('Pharmacist');
      final PermissionMap map = {};
      for (final row in rows) {
        map.putIfAbsent(row.module, () => {}).add(row.action);
      }
      final checker = PermissionChecker(map);

      expect(checker.canAccessModule(Modules.pharmacy), isTrue);
      expect(checker.can(Modules.pharmacy, Actions.create), isTrue);
      expect(checker.canAccessModule(Modules.staff), isFalse);
      expect(checker.can(Modules.staff, Actions.create), isFalse);
    });
  });
}
