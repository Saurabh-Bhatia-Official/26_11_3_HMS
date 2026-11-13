import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_management/core/widgets/section_header.dart';
import 'package:hospital_management/data/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SectionHeader Widget Tests (Database-driven)', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.open();
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('renders dynamic header fetched from database without throwing unbounded width exception', (tester) async {
      final hospitalName = (await db.settingsDao.getSetting('hospital_name'))?.value ?? 'CareSync';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                SectionHeader(title: '$hospitalName Operations'),
                IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('$hospitalName Operations'), findsOneWidget);
    });

    testWidgets('renders dynamic section from database with trailing action inside standard Column', (tester) async {
      final currency = (await db.settingsDao.getSetting('currency_symbol'))?.value ?? '₹';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SectionHeader(
                  title: 'Revenue ($currency)',
                  trailing: TextButton(onPressed: () {}, child: const Text('View All')),
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Revenue ($currency)'), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);
    });
  });
}
