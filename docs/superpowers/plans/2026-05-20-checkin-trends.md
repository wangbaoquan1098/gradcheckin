# Checkin Trends Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a settings-menu trend screen that shows weekly and monthly check-in rate trends with checked-day counts.

**Architecture:** Keep trend aggregation in a pure Dart calculator so date edge cases are testable without Flutter or SQLite. The screen reads `CheckinProvider.checkedDates`, computes periods from `AppDates`, and renders a custom painted chart plus summary cards.

**Tech Stack:** Flutter, Provider, Material 3, CustomPainter, flutter_test.

---

## File Structure

- Create `lib/data/models/checkin_trend.dart`: immutable trend period model and trend grouping enum.
- Create `lib/core/utils/checkin_trend_calculator.dart`: pure weekly/monthly aggregation functions.
- Create `test/checkin_trend_calculator_test.dart`: calculator unit tests for week/month range handling.
- Create `lib/screens/trends/trend_screen.dart`: settings-menu destination with summaries, segment control, and period list.
- Create `lib/screens/trends/widgets/checkin_trend_chart.dart`: reusable custom painted chart.
- Modify `lib/screens/home/home_screen.dart`: add settings menu item and navigation.
- Modify `lib/core/constants/app_strings.dart`: add trend labels.

### Task 1: Trend Calculator Tests

**Files:**
- Create: `test/checkin_trend_calculator_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/checkin_trend_calculator_test.dart` with tests that import `package:gradcheckin/core/utils/checkin_trend_calculator.dart` and `package:gradcheckin/data/models/checkin_trend.dart`. Cover:

```dart
test('buildWeeklyTrends handles partial first week and current-date cutoff', () {
  final trends = CheckinTrendCalculator.buildWeeklyTrends(
    checkedDates: {'2026-03-01', '2026-03-02', '2026-03-04'},
    startDate: DateTime(2026, 3, 1),
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
});

test('buildMonthlyTrends aggregates natural months inside the valid range', () {
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
});

test('buildMonthlyTrends keeps empty periods visible at zero percent', () {
  final trends = CheckinTrendCalculator.buildMonthlyTrends(
    checkedDates: {},
    startDate: DateTime(2026, 3, 1),
    endDate: DateTime(2026, 12, 25),
    today: DateTime(2026, 3, 3),
  );

  expect(trends.single.checkedDays, 0);
  expect(trends.single.totalDays, 3);
  expect(trends.single.rate, 0);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/checkin_trend_calculator_test.dart`

Expected: fails because `CheckinTrendCalculator` and `CheckinTrendPeriod` do not exist.

### Task 2: Trend Calculator Implementation

**Files:**
- Create: `lib/data/models/checkin_trend.dart`
- Create: `lib/core/utils/checkin_trend_calculator.dart`

- [ ] **Step 1: Implement model**

Add `TrendGrouping { weekly, monthly }` and `CheckinTrendPeriod` with `label`, `startDate`, `endDate`, `checkedDays`, `totalDays`, and computed `rate`.

- [ ] **Step 2: Implement calculator**

Add `CheckinTrendCalculator.buildWeeklyTrends` and `buildMonthlyTrends`. Normalize all dates to date-only values, clamp the effective end to `min(today, endDate)`, skip output when effective end is before start, and count checked date keys only inside each period's actual range.

- [ ] **Step 3: Run calculator tests**

Run: `flutter test test/checkin_trend_calculator_test.dart`

Expected: all tests pass.

### Task 3: Trend Screen UI

**Files:**
- Create: `lib/screens/trends/trend_screen.dart`
- Create: `lib/screens/trends/widgets/checkin_trend_chart.dart`
- Modify: `lib/core/constants/app_strings.dart`

- [ ] **Step 1: Add trend strings**

Add Chinese labels for trend title, menu entry, weekly/monthly tabs, current period rate, current period days, and empty state.

- [ ] **Step 2: Build chart widget**

Create `CheckinTrendChart` that accepts `List<CheckinTrendPeriod>` and paints axis grid lines, green count bars, a blue rate line, and point markers. Use theme colors and keep labels compact.

- [ ] **Step 3: Build screen**

Create `TrendScreen` as a `StatefulWidget` with default `TrendGrouping.weekly`. Use `SegmentedButton<TrendGrouping>` for switching. Compute trends from `CheckinProvider.checkedDates`, `AppDates.checkinStartDate`, `AppDates.checkinEndDate`, and `DateTime.now()`. Show two summary cards, the chart, and a scrollable period detail list.

### Task 4: Settings Entry

**Files:**
- Modify: `lib/screens/home/home_screen.dart`

- [ ] **Step 1: Add import**

Import `../../screens/trends/trend_screen.dart`.

- [ ] **Step 2: Add menu action**

Handle the popup value `trends` by pushing `const TrendScreen()`.

- [ ] **Step 3: Add menu item**

Add a `PopupMenuItem` with an `Icons.show_chart` icon and the trend menu string near the history item.

### Task 5: Verification

**Files:**
- All modified Dart files.

- [ ] **Step 1: Format**

Run: `dart format lib test`

Expected: files formatted with no errors.

- [ ] **Step 2: Run tests**

Run: `flutter test`

Expected: all tests pass.

- [ ] **Step 3: Run analyzer**

Run: `flutter analyze`

Expected: no new errors.
