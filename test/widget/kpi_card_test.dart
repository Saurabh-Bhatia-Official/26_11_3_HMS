import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_management/core/widgets/kpi_card.dart';

void main() {
  group('KpiCard Widget Tests', () {
    testWidgets('renders all details without overflow at desktop card size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                height: 160,
                child: KpiCard(
                  label: "Today's OPD Patients",
                  value: '42',
                  icon: Icons.people_outline_rounded,
                  subtitle: '+3 in waiting queue',
                  trend: 5.2,
                  trendLabel: 'vs yesterday',
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text("Today's OPD Patients"), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('+3 in waiting queue'), findsOneWidget);
      expect(find.text('+5.2%'), findsOneWidget);
    });

    testWidgets('renders in a 4-column grid at 1280x800 without overflow', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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
                    children: const [
                      KpiCard(
                        label: "Today's OPD Patients",
                        value: '42',
                        icon: Icons.people_outline_rounded,
                        subtitle: '+3 in waiting queue',
                      ),
                      KpiCard(
                        label: "Today's Revenue",
                        value: '₹1,24,500',
                        icon: Icons.currency_rupee_rounded,
                        subtitle: 'Billing & pharmacy combined',
                      ),
                      KpiCard(
                        label: 'Bed Occupancy',
                        value: '75%',
                        icon: Icons.hotel_rounded,
                        subtitle: '15 of 20 beds occupied',
                      ),
                      KpiCard(
                        label: 'Pending Lab Tests',
                        value: '8',
                        icon: Icons.biotech_rounded,
                        subtitle: '2 urgent (STAT) samples',
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
      expect(find.text('₹1,24,500'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
    });
  });
}

