import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_management/core/widgets/kpi_card.dart';
import 'package:hospital_management/data/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KpiCard Widget Tests (Database-driven)', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.open();
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('renders OPD metric dynamically fetched from SQLite database', (tester) async {
      // Fetch operational metrics directly from SQLite database
      final stats = await db.hmsDao.getDashboardStats();
      final opdVisitsCount = stats['todayOpdVisits'] as int;
      final opdValueStr = opdVisitsCount.toString();
      final subtitleStr = opdVisitsCount > 0 ? '$opdVisitsCount in active queue' : 'Queue completed';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                height: 160,
                child: KpiCard(
                  label: "Today's OPD Patients",
                  value: opdValueStr,
                  icon: Icons.people_outline_rounded,
                  subtitle: subtitleStr,
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text("Today's OPD Patients"), findsOneWidget);
      expect(find.text(opdValueStr), findsOneWidget);
      expect(find.text(subtitleStr), findsOneWidget);
    });

    testWidgets('renders all KPI metrics in grid fetched dynamically from SQLite database', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Fetch live operational metrics directly from SQLite database
      final stats = await db.hmsDao.getDashboardStats();
      final opdStr = (stats['todayOpdVisits'] as int).toString();
      final revenuePaise = stats['todayRevenuePaise'] as int;
      final revenueStr = '₹${(revenuePaise / 100).toStringAsFixed(0)}';
      final totalBeds = stats['totalBeds'] as int;
      final availBeds = stats['availableBeds'] as int;
      final occupancyRate = totalBeds == 0 ? 0 : (((totalBeds - availBeds) / totalBeds) * 100).round();
      final occupancyStr = '$occupancyRate%';
      final pendingLabStr = (stats['pendingLabOrders'] as int).toString();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GridView(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 160,
                    ),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      KpiCard(
                        label: "Today's OPD Patients",
                        value: opdStr,
                        icon: Icons.people_outline_rounded,
                        subtitle: 'Live SQLite count',
                      ),
                      KpiCard(
                        label: "Today's Revenue",
                        value: revenueStr,
                        icon: Icons.currency_rupee_rounded,
                        subtitle: 'Billing & pharmacy combined',
                      ),
                      KpiCard(
                        label: 'Bed Occupancy',
                        value: occupancyStr,
                        icon: Icons.hotel_rounded,
                        subtitle: '${totalBeds - availBeds} of $totalBeds beds occupied',
                      ),
                      KpiCard(
                        label: 'Pending Lab Tests',
                        value: pendingLabStr,
                        icon: Icons.biotech_rounded,
                        subtitle: 'Database pending orders',
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text("Today's OPD Patients"), findsOneWidget);
      expect(find.text("Today's Revenue"), findsOneWidget);
      expect(find.text('Bed Occupancy'), findsOneWidget);
      expect(find.text('Pending Lab Tests'), findsOneWidget);
      expect(find.text(revenueStr), findsOneWidget);
      expect(find.text(occupancyStr), findsOneWidget);
      if (opdStr == pendingLabStr) {
        expect(find.text(opdStr), findsNWidgets(2));
      } else {
        expect(find.text(opdStr), findsOneWidget);
        expect(find.text(pendingLabStr), findsOneWidget);
      }
    });
  });
}
