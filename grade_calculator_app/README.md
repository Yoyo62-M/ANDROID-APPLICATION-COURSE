# 🎓 Student Grade Calculator — Flutter Desktop App

A professional desktop application built with **Flutter (Dart)** for calculating and reporting student grades from Excel files.

---

## 📋 Requirements Before You Start

| Tool | Version | Download |
|------|---------|----------|
| Flutter SDK | 3.16+ | https://docs.flutter.dev/get-started/install |
| Dart SDK | 3.0+ | Included with Flutter |
| Visual Studio Code | Latest | https://code.visualstudio.com |
| VS Code Flutter Extension | Latest | VS Code Marketplace |
| Git | Any | https://git-scm.com |
| **Windows only:** Visual Studio 2022 (C++ workload) | 2022 | https://visualstudio.microsoft.com |

---

## 🚀 STEP-BY-STEP SETUP GUIDE

### STEP 1 — Install Flutter SDK

1. Go to https://docs.flutter.dev/get-started/install
2. Choose your OS (Windows / macOS / Linux)
3. Download and extract the Flutter SDK
4. Add `flutter/bin` to your **PATH** environment variable
5. Open a terminal and run:
   ```
   flutter --version
   ```
   You should see Flutter version info.

---

### STEP 2 — Enable Desktop Support

Open a terminal and run:
```bash
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop
```

Verify with:
```bash
flutter devices
```
You should see "Windows (desktop)" or your OS listed.

---

### STEP 3 — Windows Only: Install Visual Studio 2022

> **Skip this step on macOS or Linux**

1. Download Visual Studio 2022 Community (free): https://visualstudio.microsoft.com/downloads/
2. During install, select the **"Desktop development with C++"** workload
3. Complete installation and restart your computer

---

### STEP 4 — Install VS Code Extensions

Open VS Code → Extensions (Ctrl+Shift+X) → Search and install:
- ✅ **Flutter** (by Dart Code)
- ✅ **Dart** (by Dart Code)

---

### STEP 5 — Open This Project

1. Extract the ZIP file to a folder (e.g., `C:\Projects\grade_calculator_app`)
2. Open VS Code
3. Go to **File → Open Folder** → Select `grade_calculator_app`
4. VS Code will detect it as a Flutter project

---

### STEP 6 — Initialize Flutter Desktop Platform Files

Open the VS Code terminal (**Terminal → New Terminal**) and run:

```bash
flutter create . --platforms=windows,macos,linux
```

> This generates the native platform runner files (CMakeLists, etc.)
> Say **yes** if asked to overwrite `pubspec.yaml` — actually DON'T overwrite it, press N

**Better approach — run this instead:**
```bash
flutter create --platforms=windows temp_init && xcopy temp_init\windows windows /E /I /Y && rmdir /S /Q temp_init
```

Or simply on macOS/Linux:
```bash
flutter create --platforms=macos,linux .
```

---

### STEP 7 — Get Dependencies

In the VS Code terminal, run:
```bash
flutter pub get
```

Wait for all packages to download. You should see:
```
Got dependencies!
```

---

### STEP 8 — Run the App

```bash
flutter run -d windows
```

Or on macOS:
```bash
flutter run -d macos
```

The app will compile and launch. First build may take 2–5 minutes. Subsequent builds are fast.

---

## 📁 Excel File Format

Your input Excel file **must** have these columns in this exact order:

| Column A | Column B | Column C | Column D | Column E |
|----------|----------|----------|----------|----------|
| Student ID | Student Name | Assignment Mark (0-100) | Test Mark (0-100) | Exam Mark (0-100) |

**Row 1** = Headers (skipped automatically)  
**Row 2+** = Student data

> 💡 Click **"GET TEMPLATE"** in the app to download a ready-made template!

---

## 🧮 Grading System

| Grade | Mark Range | Remark |
|-------|-----------|--------|
| A | 75 – 100 | Distinction |
| AB | 70 – 74 | Merit |
| B | 60 – 69 | Credit |
| C | 50 – 59 | Pass |
| D | 40 – 49 | Supplementary |
| F | 0 – 39 | Fail |

**Final Mark Formula:**
```
Final = (Assignment × 20%) + (Test × 30%) + (Exam × 50%)
```

---

## 🏗️ Project Structure

```
grade_calculator_app/
├── lib/
│   ├── main.dart                    ← App entry point
│   ├── theme/
│   │   └── app_theme.dart           ← Dark blue theme & colors
│   ├── models/
│   │   └── calculator.dart          ← OOP: abstract Calculator + GradeCalculator
│   ├── utils/
│   │   └── excel_handler.dart       ← Import & export Excel
│   ├── screens/
│   │   ├── home_screen.dart         ← Upload screen
│   │   └── results_screen.dart      ← Results + download screen
│   └── widgets/
│       └── glass_card.dart          ← Reusable UI components
├── pubspec.yaml                     ← Dependencies
└── README.md
```

---

## 🎓 OOP Concepts Used (For Lecturer)

| Concept | Where Used |
|---------|-----------|
| **Abstract Class** | `Calculator` in `models/calculator.dart` |
| **Inheritance** | `GradeCalculator extends Calculator` |
| **Polymorphism** | `calculate()` overridden in `GradeCalculator` |
| **Lambdas** | Throughout — `map`, `where`, `fold`, `=>` arrow functions |
| **Late / Delayed Init** | `late final` in `StudentGrade`, `GradeCalculator` |
| **Classes** | `Calculator`, `GradeCalculator`, `StudentGrade`, `GradeRange`, `ExcelHandler` |
| **Singleton** | `GradeCalculator.instance`, `ExcelHandler.instance` |

---

## 🐛 Troubleshooting

**"flutter: command not found"**  
→ Add Flutter SDK `bin` folder to your PATH and restart terminal.

**"No supported devices found"**  
→ Run `flutter config --enable-windows-desktop` then `flutter devices`

**Build error about Visual Studio**  
→ Install Visual Studio 2022 with "Desktop development with C++" workload

**pub get fails**  
→ Check internet connection. Try `flutter pub get --verbose`

**Excel file not reading**  
→ Make sure your file is `.xlsx` format (not `.xls` or `.csv`)  
→ Check that Row 1 is headers and data starts from Row 2

---

## 📦 Building a Release EXE (Windows)

```bash
flutter build windows --release
```

Output will be in:
```
build/windows/x64/runner/Release/GradeCalculatorApp.exe
```

---

*Built with Flutter 3.x | Dart 3.x | Apache POI for Excel*
