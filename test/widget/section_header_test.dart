import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_management/core/widgets/section_header.dart';

void main() {
  group('SectionHeader Widget Tests', () {
    testWidgets('renders inside a Row without throwing unbounded width exception', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                const SectionHeader(title: 'Unbounded Test Header'),
                IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Unbounded Test Header'), findsOneWidget);
    });

    testWidgets('renders with trailing action inside standard Column', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SectionHeader(
                  title: 'Header with Trailing',
                  trailing: TextButton(onPressed: () {}, child: const Text('View All')),
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Header with Trailing'), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);
    });
  });
}

