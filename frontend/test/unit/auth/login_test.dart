import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_management/core/auth/session_service.dart';
import 'package:hospital_management/data/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SessionNotifier sessionNotifier;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    sessionNotifier = SessionNotifier(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Authentication & Demo Login Verification', () {
    test('1. Admin demo login succeeds with Admin@1234', () async {
      final error = await sessionNotifier.login('admin', 'Admin@1234');
      expect(error, isNull);
      expect(sessionNotifier.state.isAuthenticated, isTrue);
      expect(sessionNotifier.state.user?.username, equals('admin'));
      expect(sessionNotifier.state.user?.role, equals('Admin'));
    });

    test('2. Doctor demo login succeeds with Doctor@1234', () async {
      final error = await sessionNotifier.login('doctor', 'Doctor@1234');
      expect(error, isNull);
      expect(sessionNotifier.state.isAuthenticated, isTrue);
      expect(sessionNotifier.state.user?.role, equals('Doctor'));
    });

    test('3. Nurse demo login succeeds with Nurse@1234', () async {
      final error = await sessionNotifier.login('nurse', 'Nurse@1234');
      expect(error, isNull);
      expect(sessionNotifier.state.isAuthenticated, isTrue);
      expect(sessionNotifier.state.user?.role, equals('Nurse'));
    });

    test('4. Reception demo login succeeds with Reception@1234', () async {
      final error = await sessionNotifier.login('reception', 'Reception@1234');
      expect(error, isNull);
      expect(sessionNotifier.state.isAuthenticated, isTrue);
      expect(sessionNotifier.state.user?.role, equals('Receptionist'));
    });

    test('5. Invalid password returns clear error without locking account', () async {
      final error = await sessionNotifier.login('admin', 'WrongPassword!');
      expect(error, equals('Invalid username or password.'));
      expect(sessionNotifier.state.isAuthenticated, isFalse);
    });

    test('6. Non-existent username returns clear error without locking account', () async {
      final error = await sessionNotifier.login('unknown_user', 'SomePassword123');
      expect(error, equals('Invalid username or password.'));
      expect(sessionNotifier.state.isAuthenticated, isFalse);
    });

    test('7. Multiple consecutive failed attempts DO NOT lock account (account locking disabled)', () async {
      // Attempt 10 failed logins in a row
      for (int i = 0; i < 10; i++) {
        final error = await sessionNotifier.login('admin', 'BadPassword_$i');
        expect(error, equals('Invalid username or password.'));
        expect(sessionNotifier.state.isAuthenticated, isFalse);
      }

      // 11th attempt with correct password succeeds immediately!
      final success = await sessionNotifier.login('admin', 'Admin@1234');
      expect(success, isNull);
      expect(sessionNotifier.state.isAuthenticated, isTrue);
      expect(sessionNotifier.state.user?.username, equals('admin'));
    });

    test('8. Regular user accounts can be registered and authenticate successfully', () async {
      const username = 'testdoctor';
      const plainPassword = 'CustomSecurePassword!2026';
      final salt = 'salt_${username}_reg';
      final hash = hashPassword(plainPassword, salt);

      await db.createRegularUser(
        username: username,
        passwordHash: hash,
        fullName: 'Dr. Test User',
        role: 'Doctor',
        email: 'testdoctor@hospital.local',
      );

      // Invalid password fails
      final badResult = await sessionNotifier.login(username, 'WrongPassword');
      expect(badResult, equals('Invalid username or password.'));

      // Correct password succeeds
      final goodResult = await sessionNotifier.login(username, plainPassword);
      expect(goodResult, isNull);
      expect(sessionNotifier.state.isAuthenticated, isTrue);
      expect(sessionNotifier.state.user?.username, equals('testdoctor'));
      expect(sessionNotifier.state.user?.fullName, equals('Dr. Test User'));
    });

    test('9. Repeated consecutive logins do not throw UNIQUE constraint or unexpected error', () async {
      for (int i = 0; i < 5; i++) {
        final error = await sessionNotifier.login('admin', 'Admin@1234');
        expect(error, isNull, reason: 'Failed on iteration $i');
        expect(sessionNotifier.state.isAuthenticated, isTrue);
        sessionNotifier.logout();
        expect(sessionNotifier.state.isAuthenticated, isFalse);
      }
    });

    test('10. All demo accounts authenticate cleanly without unexpected error', () async {
      final demoCredentials = {
        'admin': 'Admin@1234',
        'doctor': 'Doctor@1234',
        'nurse': 'Nurse@1234',
        'reception': 'Reception@1234',
        'pharmacy': 'Pharmacy@1234',
        'lab': 'Lab@1234',
        'accounts': 'Accounts@1234',
        'user': 'User@1234',
      };

      for (final entry in demoCredentials.entries) {
        final error = await sessionNotifier.login(entry.key, entry.value);
        expect(error, isNull, reason: 'Login failed for demo user ${entry.key}');
        expect(sessionNotifier.state.isAuthenticated, isTrue);
        sessionNotifier.logout();
      }
    });

    test('11. registerUser creates new account with hospital selection and logs in automatically', () async {
      final regError = await sessionNotifier.registerUser(
        fullName: 'Dr. Sarah Jenkins',
        username: 'sjenkins',
        email: 'sjenkins@caresync.health',
        password: 'Password@1234',
        role: 'Doctor',
        hospitalId: 1,
        hospitalName: 'CareSync Central Hospital',
      );

      expect(regError, isNull);
      expect(sessionNotifier.state.isAuthenticated, isTrue);
      expect(sessionNotifier.state.user?.username, equals('sjenkins'));
      expect(sessionNotifier.state.user?.fullName, equals('Dr. Sarah Jenkins'));
      expect(sessionNotifier.state.user?.role, equals('Doctor'));
      expect(sessionNotifier.state.user?.hospitalId, equals(1));
      expect(sessionNotifier.state.user?.hospitalName, equals('CareSync Central Hospital'));
    });

    test('12. registerUser rejects already taken usernames', () async {
      final regError = await sessionNotifier.registerUser(
        fullName: 'Duplicate Admin',
        username: 'admin',
        email: 'duplicate@test.com',
        password: 'Password@1234',
        role: 'Doctor',
      );

      expect(regError, contains('already taken'));
    });

    test('13. login allows selecting hospital entity and updates active session', () async {
      final error = await sessionNotifier.login(
        'doctor',
        'Doctor@1234',
        selectedHospitalId: 2,
        selectedHospitalName: 'CareSync North Clinic',
      );

      expect(error, isNull);
      expect(sessionNotifier.state.isAuthenticated, isTrue);
      expect(sessionNotifier.state.user?.hospitalId, equals(2));
      expect(sessionNotifier.state.user?.hospitalName, equals('CareSync North Clinic'));
    });
  });
}

