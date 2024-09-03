import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/main.dart';

void main() {
  testWidgets('Dashboard initial state test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify the title
    expect(find.text('水温ダッシュボード'), findsOneWidget);

    // Verify system status
    expect(find.text('システム状態'), findsOneWidget);
    expect(find.text('正常に稼働中'), findsOneWidget);

    // Verify current water temperature
    expect(find.text('現在の水温'), findsOneWidget);
    expect(find.textContaining('°C'), findsOneWidget);

    // Verify current air temperature and humidity
    expect(find.text('現在の気温・湿度'), findsOneWidget);
    expect(find.textContaining('°C'), findsNWidgets(2)); // 水温と気温の2箇所
    expect(find.textContaining('%'), findsOneWidget);

    // Verify 24-hour history section
    expect(find.text('24時間の推移'), findsOneWidget);

    // Verify date navigation
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);

    // Verify charts existence (this is a basic check, you might want to add more specific tests)
    expect(find.byType(Container),
        findsWidgets); // Assuming charts are in Containers

    // Verify manual update button
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });

  testWidgets('Manual update button test', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    // Tap the refresh button
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();

    // Here you would typically verify that the data has been updated
    // This might involve mocking the data fetch and checking that new values are displayed
    // For now, we'll just check that the button is still there after tapping
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
}
