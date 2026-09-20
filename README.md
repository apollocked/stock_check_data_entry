# Stockly

Stockly is a Flutter inventory and stock-management app for tracking items, monitoring stock movements (in / out / damage / adjustments), reviewing reports, and exporting data for accounting.

## Overview

This project is built for warehouse, retail, and stock-checking workflows where teams need to:

- track inventory items and quantities (including zero and negative stock)
- search and filter stock quickly by name or barcode
- log stock movements such as inbound, outbound, damage, and corrections
- capture item details, barcode references, and photos
- browse daily history with a calendar and per-day summaries
- review stock summaries, low-stock alerts, and category counts (in stock / zero / minus)
- export inventory data to CSV and Excel for sharing and reporting

The app uses Supabase for authentication and backend data storage, and Riverpod for state management.

## Features

- Email/password sign-in and account creation with Supabase Auth, including password reset
- Inventory dashboard with search and refresh
- Add, edit, and delete inventory items via barcode flow or manual entry
- Per-store configurable item fields
- Stock movement tracking (Stock in, Stock out, Damage) with signed quantities
- Adjust-stock corrections that accept positive and negative values
- Calendar history of stock movements with daily in/out/damage summaries
- Reporting overview: totals, stock value, low-stock alerts, and in-stock / zero / minus counts
- CSV export and multi-sheet Excel report export (Overview, Inventory, Movements)
- Image support for product records
- Branded Material 3 design with app icon

## Tech Stack

- Flutter
- Dart
- Supabase Flutter SDK
- Riverpod
- Mobile Scanner
- Image Picker
- CSV export utilities
- Excel export utilities
- Share Plus

## Project Structure

```text
.
├── android/                     # Android project files
├── ios/                         # iOS project files
├── assets/
│   └── branding/                # App logo
├── lib/
│   ├── core/                    # App configuration and theme
│   ├── data/                    # Repositories and data sources
│   ├── domain/                  # Domain entities and repository contracts
│   ├── presentation/            # Screens, controllers, and providers
│   ├── main.dart                # App entry point
│   └── ...
├── test/                        # Unit/widget tests
├── analysis_options.yaml        # Lint configuration
├── pubspec.yaml                 # Flutter package configuration
├── README.md                    # Project documentation
├── .gitignore                   # Git ignore rules
├── .metadata                    # Flutter metadata
└── ...                          # Platform-specific folders
```

## Prerequisites

Before running the project, make sure you have:

- Flutter SDK installed and configured
- Android Studio or Xcode for emulation/simulation
- VS Code or Android Studio for development
- A Supabase project for authentication and data storage

## Getting Started

1. Clone the repository:

```bash
git clone https://github.com/apollocked/stock_check_data_entry.git
cd stock_check_entry
```

2. Install dependencies:

```bash
flutter pub get
```

3. Add your Supabase credentials (see [Supabase Configuration](#supabase-configuration)):

```bash
cp env.example.json env.json
```

4. Run the app:

```bash
flutter run --dart-define-from-file=env.json
```

The VS Code launch configurations in `.vscode/launch.json` already pass this flag.

## Supabase Configuration

Supabase is initialized in `lib/main.dart`. The project URL and key are not stored in the source: they are read at build time from `--dart-define` values in `lib/core/config.dart`.

Copy `env.example.json` to `env.json` (git-ignored) and fill in your project's URL and publishable (anon) key. Use the same flag for release builds:

```bash
flutter build apk --release --dart-define-from-file=env.json
```

If the values are missing, the app shows a setup message instead of crashing.

For a clean setup, you should also configure:

- Supabase Auth for sign-in/sign-up
- the database: run [`supabase/schema.sql`](supabase/schema.sql) once in the Supabase SQL editor. It creates the tables, the `record_stock_movement` and `branch_stock_report` functions, the RLS policies, the `grocery_images` storage bucket, and the first store.

The RLS policies give every signed-in user full access. Tighten them if the project is shared across teams.

### Email links (confirmation and password reset)

Sign-up confirmation and "Forgot password?" emails open the app through a deep link, `com.apollocked.stockly://login-callback/` (`Config.authRedirectUrl`). For this to work:

1. In the Supabase dashboard go to **Authentication → URL Configuration** and add `com.apollocked.stockly://login-callback/` to **Redirect URLs**.
2. Keep the scheme in sync with `android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info.plist` if you change it.
3. Open the email on the phone that has the app installed.


## Android Release Build

- The application ID is `com.apollocked.stockly` (set in `android/app/build.gradle.kts`). Change it before your first Play Store upload if you want a different one; it cannot change afterwards.
- Release builds are signed with your own keystore. Create one with `keytool`, copy `android/key.properties.example` to `android/key.properties` (git-ignored) and fill it in. Without that file, release builds fall back to the debug key and print a warning. Do not upload those.
- Release builds have code shrinking and resource shrinking enabled (R8). Extra keep rules go in `android/app/proguard-rules.pro`.

```bash
flutter build appbundle --release --dart-define-from-file=env.json
```

## Local Development Notes

- The app entry point is `lib/main.dart`.
- State management is handled with Riverpod.
- Business logic is separated into domain/data/presentation layers.
- The app is designed around a single-store stock workflow and can be extended for multi-store or multi-user requirements.
- The app name and launcher icon can be regenerated from `assets/branding/logo.png` using `flutter_launcher_icons`.

## Typical Workflow

1. Sign in or create an account
2. Configure the store and custom item fields
3. Add new items or scan barcodes to locate records
4. Update stock with Stock in / Stock out / Damage, or fix counts with Adjust stock
5. Review the calendar history and reporting overview
6. Export inventory data to CSV or Excel when needed

## License

This project does not currently declare a license. Add an appropriate license file if you plan to publish or distribute it publicly.

## Contributing

Contributions are welcome. If you improve the app, open a pull request with a clear summary of the changes and how they were validated.