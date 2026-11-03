# Patro Flutter (पात्रो) 🇳🇵

> **A minimalist, distraction-free Bikram Sambat calendar app for Android and iOS with native Home Screen & Lock Screen Widgets.**

Built with **Flutter (Dart)** and designed with an elegant, modern Apple-inspired aesthetic. 100% offline, privacy-first, zero cloud/Firebase dependencies.

---

## 🌟 Key Features

- **Clean Minimalist Design**: Pure date calendar grid. No tithi clutter, no moon emojis, no distracting ad banners.
- **Home Screen & Lock Screen Widgets**:
  - **Android**: Native `AppWidget` (2x2 and 4x2) with daily midnight auto-refresh.
  - **iOS**: SwiftUI `WidgetKit` extension (`systemSmall` & `systemMedium`) via shared AppGroup.
- **Pure Dart High-Performance Engine**:
  - Direct port of Howard Hinnant's civil algorithm and sidereal day offset matrix.
  - Exact Kathmandu sunrise tithi calculation via Jean Meeus *Astronomical Algorithms* (Ch 25 & 47).
  - Validated across all **33,237 days** (BS 2000–2090) with **100% round-trip parity**.
- **Zero-Rebuild In-App Calendar Update**:
  - When Nepal Panchanga Nirnayak Bikas Samiti publishes BS 2084+, users can tap **"Check Updates"** in Settings.
  - The app hot-reloads new month lengths directly from the upstream GitHub repo without needing a Play Store or App Store app update!
- **Bidirectional Date Converter**:
  - Instant conversion between Vikram Samvat (BS) and Gregorian (AD).
  - Supports both Devanagari numerals (`२०८३-०७-१७`) and English numerals (`2083-07-17`).

---

## 📱 Screenshots & UI

| Monthly Calendar View | Date Converter | Home Screen Widget |
|:---:|:---:|:---:|
| Clean 7x6 Grid with Saturday in subtle red | Fast BS $\leftrightarrow$ AD with Tithi & Holidays | 2x2 & 4x2 Widgets for Android & iOS |

---

## 🏗️ Architecture & Project Structure

```
patro-flutter/
├── lib/
│   ├── main.dart                      # App entry point & bottom navigation
│   ├── engine/                        # Pure Dart Calendar Engine (Zero dependency)
│   │   ├── calendar_data.dart         # Consensus matrix (BS 2000-2090)
│   │   ├── bikram.dart                # Hinnant arithmetic & date models
│   │   ├── astro.dart                 # Meeus astronomical elongation & tithi
│   │   ├── nepali.dart                # Localization & Devanagari numerals
│   │   ├── observances.dart           # Public holidays & markers
│   │   └── patro_engine.dart          # Unified facade & view model generator
│   ├── ui/
│   │   ├── calendar_view.dart         # Clean 7x6 Monthly Grid & Detail Card
│   │   ├── converter_view.dart        # Bidirectional BS ↔ AD Converter
│   │   └── settings_view.dart         # Numerals style & In-App GitHub Sync
│   └── widgets/
│       └── home_screen_widget.dart    # Bridge for Android & iOS widgets
├── android/                           # Android native configuration
│   └── app/src/main/
│       ├── res/layout/                # XML layout for Android AppWidget
│       └── kotlin/.../PatroAppWidget  # AppWidgetProvider implementation
├── ios/                               # iOS native configuration
│   └── PatroWidget/                   # SwiftUI WidgetKit extension
├── test/
│   └── engine_test.dart               # Complete 10-phase verification test suite
└── pubspec.yaml                       # Dependencies (http, shared_preferences, home_widget)
```

---

## 🧪 Verification & Unit Testing

The pure Dart engine is tested against all 77 reference test cases:

```bash
dart test/engine_test.dart
```

Output:
```text
Running Patro Engine Tests in Dart...
✓ Test 1: Table structural integrity verified (33,237 days)
✓ Test 2: Anchor (1 Baisakh 2000 BS = 14 April 1943 AD) verified
✓ Test 3: Round-trip conversion verified for all 33,237 days without loss
✓ Test 4: Consecutive calendar continuity verified across 91 years
✓ Test 5: Out of range inputs safely rejected
✓ Test 6: Today calculation verified: 2083 Kartik 17 = 2026 Nov 3 (मङ्गलबार)
✓ Test 7: Astronomical Kathmandu sunrise Tithi calculation verified: Tithi #9
✓ Test 8: Devanagari numerals and localized strings verified
✓ Test 9: Observances and national public holidays verified
✓ Test 10: Bidirectional date converter verified

🎉 ALL TESTS PASSED! 100% Parity with Patro Reference Engine.
```

---

## 🚀 Building & Running

### Requirements
- Flutter SDK `>=3.0.0`
- Android Studio / Xcode

### Get Dependencies
```bash
flutter pub get
```

### Run on Device or Emulator
```bash
# Android
flutter run -d android

# iOS Simulator
flutter run -d ios

# macOS Desktop
flutter run -d macos
```

---

## 📄 License
MIT License. Upstream calendar arithmetic derived from [yogeshojha/patro](https://github.com/yogeshojha/patro).
