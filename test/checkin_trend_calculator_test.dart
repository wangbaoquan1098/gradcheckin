import 'package:flutter_test/flutter_test.dart';
import 'package:gradcheckin/core/utils/checkin_trend_calculator.dart';

void main() {
  group('CheckinTrendCalculator', () {
    test(
      'buildWeeklyTrends handles partial first week and current-date cutoff',
      () {
        final trends = CheckinTrendCalculator.buildWeeklyTrends(
          checkedDates: {'2026-03-01', '2026-03-02', '2026-03-04'},
          startDate: DateTime(2026, 3),
          endDate: DateTime(2026, 12, 25),
          today: DateTime(2026, 3, 4),
        );

        expect(trends, hasLength(2));
        expect(trends.first.label, '第1周');
        expect(trends.first.checkedDays, 1);
        expect(trends.first.totalDays, 1);
        expect(trends.first.rate, 1);
        expect(trends.last.label, '第2周');
        expect(trends.last.checkedDays, 2);
        expect(trends.last.totalDays, 3);
        expect(trends.last.rate, closeTo(2 / 3, 0.0001));
      },
    );

    test(
      'buildMonthlyTrends aggregates natural months inside the valid range',
      () {
        final trends = CheckinTrendCalculator.buildMonthlyTrends(
          checkedDates: {'2026-03-01', '2026-03-15', '2026-04-01'},
          startDate: DateTime(2026, 3, 10),
          endDate: DateTime(2026, 4, 30),
          today: DateTime(2026, 4, 2),
        );

        expect(trends, hasLength(2));
        expect(trends.first.label, '3月');
        expect(trends.first.checkedDays, 1);
        expect(trends.first.totalDays, 22);
        expect(trends.last.label, '4月');
        expect(trends.last.checkedDays, 1);
        expect(trends.last.totalDays, 2);
      },
    );

    test('buildMonthlyTrends keeps empty periods visible at zero percent', () {
      final trends = CheckinTrendCalculator.buildMonthlyTrends(
        checkedDates: {},
        startDate: DateTime(2026, 3),
        endDate: DateTime(2026, 12, 25),
        today: DateTime(2026, 3, 3),
      );

      expect(trends.single.checkedDays, 0);
      expect(trends.single.totalDays, 3);
      expect(trends.single.rate, 0);
    });

    test(
      'buildWeeklyTrends ignores checked dates outside the effective range',
      () {
        final trends = CheckinTrendCalculator.buildWeeklyTrends(
          checkedDates: {'2026-02-28', '2026-03-01', '2026-03-08'},
          startDate: DateTime(2026, 3),
          endDate: DateTime(2026, 3, 7),
          today: DateTime(2026, 3, 10),
        );

        expect(trends, hasLength(2));
        expect(trends.first.checkedDays, 1);
        expect(trends.first.totalDays, 1);
        expect(trends.last.checkedDays, 0);
        expect(trends.last.totalDays, 6);
        expect(trends.last.rate, 0);
      },
    );
  });
}
