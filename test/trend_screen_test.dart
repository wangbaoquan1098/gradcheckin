import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gradcheckin/screens/trends/trend_screen.dart';

void main() {
  testWidgets('TrendContent shows summaries without repeating the page title', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrendContent(
            checkedDates: {'2026-03-02', '2026-03-04'},
            startDate: DateTime(2026, 3),
            endDate: DateTime(2026, 12, 25),
            today: DateTime(2026, 3, 4),
          ),
        ),
      ),
    );

    expect(find.text('打卡趋势'), findsNothing);
    expect(find.text('按周'), findsOneWidget);
    expect(find.text('按月'), findsOneWidget);
    expect(find.text('66.7%'), findsOneWidget);
    expect(find.text('2/3 天'), findsOneWidget);

    await tester.tap(find.text('按月'));
    await tester.pumpAndSettle();

    expect(find.text('50.0%'), findsOneWidget);
    expect(find.text('2/4 天'), findsOneWidget);
  });
}
