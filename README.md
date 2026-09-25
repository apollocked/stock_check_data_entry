# Stockly

Stockly is a Flutter inventory and stock-management app: track items and quantities, record stock in / out / damage and shelf counts, review reports, and export data for accounting. Supabase handles sign-in and data; Riverpod handles state.

## Features

- **Inventory**: search by name, barcode or description; filter chips for low, out-of-stock and negative items (with live counts); sort by newest, name, lowest stock or stock value.
- **Barcode scanner**: live camera with a scan window and torch, or type a code. A scan opens the item, updates its stock, or adds it as a new item.
- **Item screen**: photo, live stock and value, one-tap *In / Out / Damage / Count*, details, and the item's own movement history.
- **Stock sheet**: stepper with hold-to-repeat, live "12 → 17" preview, and an optional note. *Count* mode is for stock checks: enter what is on the shelf and the difference is recorded.
- **Reports**: stock value, 14-day in/out activity chart, stock health, all-time totals, items needing attention, recent movements.
- **History**: pick any day from a day strip or calendar to see its totals and every movement.
- **Settings**: light / dark / system theme, store name and location, which fields items record, team access, change password, sign out.
- **Exports**: CSV inventory and a multi-sheet Excel report (Overview, Inventory, Movements).
- Material 3 design with light and dark themes, animations, predictive back, and edge-to-edge layout; respects the system "reduce motion" setting.

## Tech stack

Flutter · Dart · [supabase_flutter](https://pub.dev/packages/supabase_flutter) · [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) · [go_router](https://pub.dev/packages/go_router) · [flutter_animate](https://pub.dev/packages/flutter_animate) · [fl_chart](https://pub.dev/packages/fl_chart) · [intl](https://pub.dev/packages/intl) · [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) · [mobile_scanner](https://pub.dev/packages/mobile_scanner) · [image_picker](https://pub.dev/packages/image_picker) · csv · excel · share_plus

## Project structure

```text
lib/
├── core/              # config, errors, security helpers, theme tokens, formatters
├── domain/            # entities (Item, StockMovement, StockChange, …) and repository contracts
├── data/              # Supabase datasources, repository implementations, export services
├── presentation/
│   ├── controllers/   # Riverpod providers and notifiers
│   ├── router/        # go_router routes and the sign-in / access redirect
│   ├── screens/       # one folder per feature, each with its own widgets/
│   └── widgets/       # shared components: cards, badges, states, motion, brand
└── main.dart
supabase/schema/       # database schema, run in order (01 … 05)
tool/brand/            # renders the logo, launcher icons and splash images
test/                  # unit and widget tests
```

Every Dart file is kept under 200 lines; larger screens are split into widgets in their feature folder.

## Getting started

```bash
flutter pub get
cp env.example.json env.json   # then fill in your Supabase URL and publishable key
flutter run --dart-define-from-file=env.json
```

The Supabase URL and key are read at build time (`lib/core/config.dart`) and never stored in the source. Use the same flag for release builds. In VS Code, `.vscode/settings.json` adds it to every run, so the Run button and the launch configurations both work.

## Supabase setup

1. In the SQL editor, run the files in [`supabase/schema/`](supabase/schema/) **in order** (`01_tables.sql` to `05_storage.sql`). They are idempotent, so running them again upgrades an existing project.
2. **Authentication → URL Configuration**: add `com.apollocked.stockly://login-callback/` to Redirect URLs (email confirmation and password reset open the app through it).
3. **Authentication → Providers → Email**: set the minimum password length to 8 and require letters and digits, so the server matches the app.

### Access model

Signing up is **not** enough to see a store. Only accounts in `public.members` can read or change data:

- The first account created in a new project becomes a member automatically.
- When upgrading an existing project, everyone who already had an account keeps access. Review `public.members` afterwards.
- Members add and remove people in the app under **Settings → Team** (the person must create an account first). Accounts that are not members see a "Waiting for access" screen.

## Security

- **Database**: row level security limits every table to members. Stock quantities and the movement log can only change through the `record_stock_movement` function, so they cannot be edited or forged directly. Table grants are narrowed to the columns the app writes, and input sizes are limited.
- **Storage**: members-only uploads, images only, 5 MB maximum, random file names, no overwrites.
- **Device**: the session is stored in the Android Keystore / iOS Keychain, and Android backups of app data are disabled.
- **App**: item images are only loaded from your Supabase project; CSV exports neutralize spreadsheet formulas; exports are written to temporary storage and deleted after sharing; raw errors are logged in debug builds only.

## Branding

The logo is drawn in code (`lib/presentation/widgets/brand/brand_mark_painter.dart`), so the in-app logo is vector and animated. To regenerate the PNGs after changing it:

```bash
flutter test tool/brand/generate_brand_assets_test.dart   # logo, adaptive icon layers, splash images
dart run flutter_launcher_icons                            # launcher icons for Android, iOS, web, Windows, macOS
```

## Tests

```bash
flutter analyze
flutter test
```

The tests cover the domain rules (stock levels, count mode, daily activity, inventory filters), security helpers, the router's redirect rules, and widget tests that render the main screens with fake data in light and dark themes.

## Android release build

- The application ID is `com.apollocked.stockly` (`android/app/build.gradle.kts`). It cannot change after the first Play Store upload.
- Copy `android/key.properties.example` to `android/key.properties` (git-ignored) and point it at your keystore. Without it, release builds fall back to the debug key and print a warning; never upload those.
- Release builds use R8 code and resource shrinking.

```bash
flutter build appbundle --release --dart-define-from-file=env.json
```

## License

This project does not currently declare a license. Add one before publishing or distributing it.
