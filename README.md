# Stock Check Entry

A Flutter mobile app for stock checking and inventory data entry. The project is set up for barcode scanning, item capture, and cloud-backed data sync, with dependencies for Supabase, CSV export, image capture, and mobile scanning.

## Overview

This application is designed to support quick stock-taking workflows in a warehouse, retail, or inventory environment. It is structured as a Flutter project and includes tools commonly used for:

- scanning product codes or barcodes
- entering or verifying stock quantities
- capturing product data and photos
- exporting data for reporting or auditing
- syncing records with a backend service such as Supabase

## Tech Stack

- Flutter
- Dart
- Supabase Flutter SDK
- Riverpod for state management
- Mobile Scanner for barcode scanning
- Image Picker for photos
- CSV package for export generation
- Share Plus for sharing generated files

## Project Structure

```text
.
├── android/              # Android project files
├── ios/                  # iOS project files
├── lib/
│   └── main.dart         # Application entry point
├── test/                 # Test files
├── analysis_options.yaml # Lint configuration
├── pubspec.yaml          # Flutter package configuration
├── README.md             # Project documentation
├── .gitignore            # Git ignore rules
└── ...                   # Platform-specific folders
```

## Prerequisites

Before running the project, make sure you have the following installed:

- Flutter SDK (version compatible with the project configuration in `pubspec.yaml`)
- Android Studio or Xcode for device emulation/simulation
- A code editor such as VS Code or Android Studio

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

## Supabase Setup

This project includes `supabase_flutter`, so it can be connected to a Supabase backend for stock data storage and sync.

To configure it:

1. Create a Supabase project in the Supabase dashboard.
2. Copy your project URL and anon key.
3. Add the required initialization code in the app entry or app configuration layer.
4. Ensure your database tables and policies match your stock-check workflow.

Example configuration pattern:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

## Development Notes

- The app is currently scaffolded as a Flutter project and may evolve as business logic and UI screens are added.
- `lib/main.dart` is the entry point and can be expanded into the full stock-check application flow.
- Features such as scanner integrations, export workflows, and backend sync should be implemented in dedicated modules as the project grows.

## Recommended Next Steps

- Add a product model and stock record schema
- Implement barcode scanning and item lookup screens
- Add validation and offline storage for stock updates
- Create CSV export and share functionality for reporting
- Add authentication and user access controls if needed

## License

This project currently does not declare a license. If you plan to publish it publicly, add an appropriate license file and update this section.

## Contributing

Contributions are welcome. If you want to improve the app, open a pull request with a clear description of the changes and verification steps.
