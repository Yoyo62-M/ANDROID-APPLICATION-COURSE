# Grade Calculator — Flutter (Dart)

A full mobile conversion of the Kotlin/Compose Grade Calculator desktop app.

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   └── models.dart              # StudentRecord, GradingScale, ProcessedFile, etc.
├── state/
│   └── app_state.dart           # ChangeNotifier-based state management
├── theme/
│   └── app_theme.dart           # Light/dark themes + color helpers
├── services/
│   ├── file_parser_service.dart # CSV parsing
│   └── vault_manager.dart       # SharedPreferences persistence
└── views/
    ├── main_scaffold.dart        # Bottom nav + notification banner
    ├── home_view.dart            # Import, process grades, student table
    ├── vault_view.dart           # Saved files (grid/list + preview)
    └── settings_view.dart        # Grading scales, export prefs, theme
```

## Features

| Original (Kotlin/Compose) | Flutter (Dart) |
|---------------------------|----------------|
| AppState (mutableStateOf) | ChangeNotifier + Provider |
| StudentRecord data class  | StudentRecord class w/ toJson/fromJson |
| GradingScale + ranges     | Same logic, Dart classes |
| FileParserService (CSV)   | file_parser_service.dart |
| VaultManager (local file) | vault_manager.dart (SharedPreferences) |
| HomeView                  | home_view.dart |
| VaultView                 | vault_view.dart |
| SettingsView              | settings_view.dart |
| MainWindow + sidebar      | MainScaffold + BottomNavigationBar |
| AppTheme (Compose)        | app_theme.dart (Material 3) |
| Dark/light toggle         | ✅ |
| Grade color coding        | ✅ gradeColor() helper |
| Search & filter           | ✅ |
| Sort by column            | ✅ |
| Pagination (15/page)      | ✅ |
| Class statistics row      | ✅ avg, high, low, pass% |
| Custom grading scales     | ✅ create/edit in Settings |
| Process Grades button     | ✅ |
| Save to Vault             | ✅ |
| Vault grid/list view      | ✅ |
| File preview in vault     | ✅ |

## Setup & Run

```bash
flutter pub get
flutter run
```

## CSV Format

```
Student ID,Student Name,CA Score,Exam Score
STU001,Alice Johnson,28,65
STU002,Bob Smith,22,58
...
```

- **CA Score**: max 30
- **Exam Score**: max 70
- **Final Score**: CA + Exam (max 100)
- Pass threshold: 40

## Default Grading Scales

**Standard (A–F)**
- A: 70–100
- B: 60–69.99
- C: 50–59.99
- D: 40–49.99
- F: 0–39.99

**Distinction Scale**
- Distinction: 80–100
- Credit: 65–79.99
- Merit: 50–64.99
- Pass: 40–49.99
- Fail: 0–39.99
