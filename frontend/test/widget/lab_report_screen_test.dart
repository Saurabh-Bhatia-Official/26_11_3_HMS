import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_management/core/providers/hms_providers.dart';
import 'package:hospital_management/data/models/lab_models.dart';
import 'package:hospital_management/features/lab/presentation/screens/lab_order_detail_screen.dart';

void main() {
  const report = LabOrderModel(
    id: 1,
    orderNo: 'L-001',
    patientName: 'Test Patient',
    uhid: 'UHID-001',
    testName: 'Complete Blood Count',
    doctorName: 'Dr. Test',
    sampleType: 'Blood',
    priority: 'Routine',
    status: 'Completed',
    orderedAt: 'Today',
    parameters: [
      {
        'param': 'Hemoglobin',
        'val': '14.2',
        'unit': 'g/dL',
        'refLow': 13.0,
        'refHigh': 17.0,
      },
    ],
  );

  testWidgets('completed report view is read-only', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          labOrderDetailProvider(report.orderNo)
              .overrideWith((ref) async => report),
        ],
        child: const MaterialApp(
          home: LabOrderDetailScreen(orderId: 'L-001'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('14.2'), findsOneWidget);
    expect(find.text('Edit Report'), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('completed report can open directly in edit mode',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          labOrderDetailProvider(report.orderNo)
              .overrideWith((ref) async => report),
        ],
        child: const MaterialApp(
          home: LabOrderDetailScreen(
            orderId: 'L-001',
            startInEditMode: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Save Report Changes'), findsOneWidget);
  });
}
