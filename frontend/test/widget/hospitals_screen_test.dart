import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_management/core/permissions/permission_service.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/data/models/hms_models.dart';
import 'package:hospital_management/features/hospitals/presentation/screens/hospitals_screen.dart';

void main() {
  testWidgets('HospitalsScreen builds cleanly and Add/Edit hospital dialog handles Multispeciality Hospital without Dropdown assertion', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.open();

    await tester.binding.setSurfaceSize(const Size(1200, 900));

    final superAdminChecker = PermissionChecker({
      Modules.hospitals: {
        AppActions.view,
        AppActions.create,
        AppActions.edit,
        AppActions.delete,
      },
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          permissionCheckerProvider.overrideWithValue(superAdminChecker),
        ],
        child: const MaterialApp(
          home: HospitalsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify HospitalsScreen renders
    expect(tester.takeException(), isNull);
    expect(find.text('Hospitals & Multi-Branch Network'), findsOneWidget);

    // Tap Register New Hospital button
    final addButton = find.text('Register New Hospital');
    expect(addButton, findsOneWidget);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Register New Hospital / Branch'), findsOneWidget);
    expect(find.text('Multispeciality Hospital'), findsWidgets);

    // Close dialog
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await db.close();
  });
}
