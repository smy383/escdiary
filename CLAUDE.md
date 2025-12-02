# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**방탈출 다이어리 (Escape Room Diary)** - A personal escape room game record keeper app built with Flutter. Users can record escape room experiences with 6 rating categories, search records, and toggle dark/light mode. All data is stored on-device using SQLite.

## Development Commands

```bash
# Run on iOS Simulator
flutter run -d <simulator_uuid>

# Run on Android Emulator
flutter run -d emulator-5554

# Run analyzer
flutter analyze

# Get dependencies
flutter pub get

# List available devices
flutter devices
```

## Architecture

### Tech Stack
- **Framework**: Flutter 3.9+, Dart
- **State Management**: Provider (ChangeNotifier pattern)
- **Local Storage**: SQLite via `sqflite` (mobile) / `sqflite_common_ffi_web` (web)
- **Theme**: Material Design 3 with light/dark mode support

### Directory Structure
```
lib/
├── main.dart              # App entry point with MultiProvider setup
├── config/
│   └── theme.dart         # Material 3 light/dark theme definitions
├── models/
│   └── escape_record.dart # Data model with ClearTimeType enum
├── providers/
│   ├── record_provider.dart  # CRUD operations & search state
│   └── theme_provider.dart   # Theme mode persistence
├── services/
│   └── database_service.dart # SQLite operations (singleton)
├── screens/
│   ├── home_screen.dart         # Main list with statistics header
│   ├── record_form_screen.dart  # Create/edit form with 6 rating bars
│   ├── record_detail_screen.dart
│   ├── search_screen.dart
│   └── settings_screen.dart
└── widgets/
    ├── rating_bar.dart    # Star rating input (0-5)
    ├── record_card.dart   # List item display
    └── empty_state.dart   # Empty placeholder
```

### Data Model (EscapeRecord)
Key fields:
- `themeName`, `storeName`, `branchName` - Location info
- `playDate`, `playTime`, `playerCount` - Play session info
- `isCleared`, `hintCount`, `clearTime`, `clearTimeType` - Result info
- 6 rating fields: `ratingInterior`, `ratingSatisfaction`, `ratingPuzzle`, `ratingStory`, `ratingProduction`, `ratingHorror` (0-5 scale)

### State Flow
```
Screen (UI)
    ↓ context.read<RecordProvider>()
Provider (State)
    ↓ DatabaseService()
SQLite (Persistence)
```

## Key Patterns

### Provider Usage
- Use `context.watch<T>()` for reactive rebuilds in build methods
- Use `context.read<T>()` for one-time access in callbacks
- RecordProvider maintains both `records` list and `statistics` map

### Database Service
- Singleton pattern with `DatabaseService()`
- Platform-aware initialization (mobile vs web SQLite)
- Indexed columns: `themeName`, `storeName`, `playDate`

### Theme
- `ThemeProvider` persists theme choice via SharedPreferences
- Uses `ColorScheme.fromSeed()` for Material 3 color generation
- Primary color: `#6750A4`

## Language
- UI text is in Korean (한국어)
- Code comments may be in Korean
