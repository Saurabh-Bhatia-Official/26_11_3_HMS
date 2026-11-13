import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/features/settings/presentation/screens/settings_screen.dart';

void main() {
  testWidgets('SettingsScreen builds cleanly without Dropdown assertion error', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.open();
    // Seed with raw 'UHID' prefix just like default migration
    await db.settingsDao.upsertSetting('uhid_prefix', 'UHID');
    await db.settingsDao.upsertSetting('hospital_name', 'CareSync');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    // Let any async load complete
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Hospital Administration & Settings'), findsOneWidget);
    expect(find.text('Hospital Identity'), findsOneWidget);
    expect(find.text('Clinical & OPD Tariffs'), findsOneWidget);

    await db.close();
  });
}

