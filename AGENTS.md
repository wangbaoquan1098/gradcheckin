# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project Overview

A Flutter application for graduate school exam countdown and daily study check-in (考研倒计时打卡应用).

**Key Features:**
- Countdown timer to the graduate exam (Dec 25, 2026)
- Calendar view with check-in status visualization
- Daily check-in with retroactive check-in support
- Statistics dashboard showing monthly and total check-in rates

## Common Commands

### Development

```bash
# Install dependencies
flutter pub get

# Run on available devices
flutter run

# Run on specific platforms
flutter run -d ios        # iOS simulator
flutter run -d android    # Android device
flutter run -d chrome     # Web
flutter run -d macos      # macOS

# List available devices
flutter devices
```

### Testing

```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

### Building

```bash
# Android APK
flutter build apk --release

# iOS (requires Xcode and valid signing)
flutter build ios --release

# Web
flutter build web --release

# macOS
flutter build macos --release
```

### Code Quality

```bash
# Analyze code
flutter analyze

# Format code
flutter format lib/
```

## Architecture

The app follows a layered architecture with Provider for state management:

```
Presentation Layer (Screens/Widgets)
         ↓
    Provider Layer (State Management)
         ↓
 Repository Layer (Data Logic)
         ↓
  Database Layer (SQLite via sqflite)
```

### Key Files and Responsibilities

**State Management (Providers):**
- `lib/providers/countdown_provider.dart` - Exam countdown timer with 1-second updates, calculates elapsed days and percentage
- `lib/providers/checkin_provider.dart` - Check-in state, statistics calculation (monthly/total rates), handles date range validation

**Data Layer:**
- `lib/data/database/database_helper.dart` - SQLite database initialization, table schema for checkin_records
- `lib/data/repositories/checkin_repository.dart` - CRUD operations for check-in records, tracks operation history
- `lib/data/models/checkin_record.dart` - Data model for check-in records

**UI Layer:**
- `lib/screens/home/home_screen.dart` - Main calendar interface using table_calendar, handles date selection and check-in toggling
- `lib/screens/home/widgets/countdown_banner.dart` - Displays countdown timer with progress indicator
- `lib/screens/home/widgets/checkin_history_sheet.dart` - Bottom sheet showing check-in operation history

**Configuration:**
- `lib/core/constants/app_dates.dart` - Central configuration for exam date (2026-12-25), check-in period (2026-03-01 to 2026-12-25)
- `lib/core/constants/app_colors.dart` - Color palette (primary: blue, checkedIn: green, notCheckedIn: red)
- `lib/core/constants/app_strings.dart` - Localized Chinese strings

### Data Flow for Check-in

1. User taps a date in the calendar (HomeScreen)
2. Dialog confirms the check-in action
3. CheckinProvider.toggleCheckin() validates date (not future, within range)
4. CheckinRepository inserts new record to SQLite with timestamp
5. Provider updates local state and recalculates statistics
6. UI rebuilds to show updated check-in status

### Database Schema

**checkin_records table:**
- `id` - Primary key
- `date_key` - Date string format "YYYY-MM-DD" (indexed)
- `is_checked_in` - Boolean (1 = checked in, 0 = cancelled)
- `operation_time` - ISO8601 timestamp of the operation

Records are append-only; the latest record per date determines current status.

## Key Dependencies

```yaml
provider: ^6.1.2           # State management
sqflite: ^2.3.3            # SQLite database
shared_preferences: ^2.2.3 # Simple local storage
table_calendar: ^3.1.2     # Calendar widget
intl: ^0.20.2              # Date formatting and localization
flutter_localizations:     # Chinese localization
```

## Date Handling Conventions

- Date keys use format: `"YYYY-MM-DD"` (zero-padded month/day)
- Date comparison logic uses `DateTime(year, month, day)` to strip time component
- Future dates are disabled in the calendar and cannot be checked in
- Date range is constrained by `AppDates.checkinStartDate` and `AppDates.checkinEndDate`

## Platform Considerations

- **iOS:** Requires iOS 12.0+ (configured in ios/Podfile)
- **Android:** Uses sqflite which handles Android SQLite automatically
- **Web:** sqflite has web support but may require IndexedDB configuration
- **macOS:** Sqflite supported, database stored in app documents directory
