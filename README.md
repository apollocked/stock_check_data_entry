# Inventory Manager

A Flutter inventory and stock-check application for tracking items, monitoring stock movements, and exporting inventory data for reporting.

## Overview

This project is built for warehouse, retail, and stock-taking workflows where teams need to:

- track inventory items and quantities
- search and filter stock quickly
- log stock movements such as inbound, outbound, and damage adjustments
- capture item details, barcode references, and photos
- review stock summaries and low-stock alerts
- export inventory data to CSV for sharing and reporting

The app uses Supabase for authentication and backend data storage, and Riverpod for state management.

## Features

- Email/password sign-in and account creation with Supabase Auth
- Inventory dashboard with search and refresh
- Add, edit, and delete inventory items
- Barcode-based item lookup and entry flow
- Per-store configurable item fields
- Stock movement tracking and reporting overview
- Low-stock and out-of-stock alerts
- CSV export and share support
- Image support for product records

## Tech Stack

- Flutter
- Dart
- Supabase Flutter SDK
- Riverpod
- Mobile Scanner
- Image Picker
- CSV export utilities
- Share Plus

## Project Structure

```text
.
├── android/                     # Android project files
├── ios/                         # iOS project files
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

3. Run the app:

```bash
flutter run
```

## Supabase Configuration

This project is already initialized with Supabase in `lib/main.dart` and uses project credentials stored in `lib/core/config.dart`.

Update the values in `lib/core/config.dart` if you want to point the app to a different Supabase instance:

```dart
class Config {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

For a clean setup, you should also configure:

- Supabase Auth for sign-in/sign-up
- the required database tables used by the inventory workflow
- RLS policies if your project is shared across users

## Local Development Notes

- The app entry point is `lib/main.dart`.
- State management is handled with Riverpod.
- Business logic is separated into domain/data/presentation layers.
- The inventory screens are currently designed around a single-store stock workflow and can be extended for multi-store or multi-user requirements.

## Typical Workflow

1. Sign in or create an account
2. Select or configure the store and custom item fields
3. Add new items or scan barcodes to locate records
4. Update stock quantities and record stock movements
5. Review the reporting tab for totals, warnings, and movement history
6. Export inventory data to CSV when needed

## License

This project does not currently declare a license. Add an appropriate license file if you plan to publish or distribute it publicly.

## Contributing

Contributions are welcome. If you improve the app, open a pull request with a clear summary of the changes and how they were validated.
