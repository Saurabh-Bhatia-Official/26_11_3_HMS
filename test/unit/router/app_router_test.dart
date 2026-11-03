import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_management/core/auth/session_service.dart';
import 'package:hospital_management/core/router/app_router.dart';
import 'package:hospital_management/core/router/app_routes.dart';
import 'package:hospital_management/data/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.open();

    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
    );

    // Login as admin
    await container.read(sessionProvider.notifier).login('admin', 'Admin@1234');
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('GoRouter Route Matching & Location Tests', () {
    test('1. AppRoutes.labOrderDetailPath produces correct path', () {
      expect(AppRoutes.labOrderDetailPath('L-102'), equals('/lab/L-102'));
    });

    test('2. GoRouter matches /lab/L-102 successfully without throwing GoException', () {
      final router = container.read(appRouterProvider);
      final match = router.routeInformationParser.configuration.findMatch(Uri.parse('/lab/L-102'));
      expect(match.matches, isNotEmpty);
      expect(match.matches.last.matchedLocation, equals('/lab/L-102'));
    });

    test('3. GoRouter matches legacy nested /lab/orders/L-102 successfully', () {
      final router = container.read(appRouterProvider);
      final match = router.routeInformationParser.configuration.findMatch(Uri.parse('/lab/orders/L-102'));
      expect(match.matches, isNotEmpty);
      expect(match.matches.last.matchedLocation, equals('/lab/orders/L-102'));
    });

    test('4. GoRouter matches /opd/1 and /billing/INV-01 and /ipd/1', () {
      final router = container.read(appRouterProvider);

      final opdMatch = router.routeInformationParser.configuration.findMatch(Uri.parse('/opd/1'));
      expect(opdMatch.matches, isNotEmpty);

      final billingMatch = router.routeInformationParser.configuration.findMatch(Uri.parse('/billing/INV-01'));
      expect(billingMatch.matches, isNotEmpty);

      final ipdMatch = router.routeInformationParser.configuration.findMatch(Uri.parse('/ipd/1'));
      expect(ipdMatch.matches, isNotEmpty);
    });

    test('5. GoRouter matches /pharmacy/1 and /pharmacy/dispense/1', () {
      final router = container.read(appRouterProvider);

      final pharmMatch1 = router.routeInformationParser.configuration.findMatch(Uri.parse('/pharmacy/1'));
      expect(pharmMatch1.matches, isNotEmpty);

      final pharmMatch2 = router.routeInformationParser.configuration.findMatch(Uri.parse('/pharmacy/dispense/1'));
      expect(pharmMatch2.matches, isNotEmpty);
    });

    test('6. GoRouter matches /staff/new and /staff/1/edit', () {
      final router = container.read(appRouterProvider);

      final staffNewMatch = router.routeInformationParser.configuration.findMatch(Uri.parse('/staff/new'));
      expect(staffNewMatch.matches, isNotEmpty);
      expect(staffNewMatch.matches.last.matchedLocation, equals('/staff/new'));

      final staffEditMatch = router.routeInformationParser.configuration.findMatch(Uri.parse(AppRoutes.staffEdit(1)));
      expect(staffEditMatch.matches, isNotEmpty);
      expect(staffEditMatch.matches.last.matchedLocation, equals('/staff/1/edit'));
    });
  });
}
