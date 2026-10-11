# Padelicious

Padelicious is a Flutter app for managing padel sessions, clubs, players, and match activity. The app includes a login flow, club browsing, player management, session summaries, and leaderboard-style views.

## Tech Stack

- Flutter
- Dart
- Material Design

## Project Structure

```text
lib/
  main.dart
  data/
  models/
  screens/
  state/
  theme/
  utils/
  widgets/
```

## Requirements

Before you begin, make sure the following are installed:

- Flutter SDK (version 3.3.0 or newer)
- Android Studio with Android SDK (for Android build/run)
- Xcode (for iOS development on macOS)
- VS Code or Android Studio for development
- A physical device or emulator

Check your environment:

```bash
flutter --version
flutter doctor
```

If Flutter is not installed or configured, follow the official Flutter installation guide for macOS:

https://docs.flutter.dev/get-started/install/macos

## Installation

1. Clone the repository:

```bash
git clone https://github.com/iqbal-floo/padelicious_app.git
cd padelicious_app
```

2. Install dependencies:

```bash
flutter pub get
```

3. Verify that the Flutter environment is ready:

```bash
flutter doctor
```

If you use FVM, this project is compatible with Flutter 3.3+; for example:

```bash
fvm install 3.3.0
fvm use 3.3.0
flutter pub get
```

## Running the App

Run the app in debug mode:

```bash
flutter run
```

If you want to run on a specific device or emulator:

```bash
flutter devices
flutter run -d <device_id>
```

You can also run in release mode on a connected device:

```bash
flutter run --release
```

## Building APK

Create a release APK:

```bash
flutter build apk --release
```

The APK will be generated at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Optional: generate split APKs per ABI for smaller device-specific builds:

```bash
flutter build apk --release --split-per-abi
```

This will generate separate APK files in:

```text
build/app/outputs/flutter-apk/
```

## Building Android App Bundle (AAB)

Create a release app bundle for Google Play:

```bash
flutter build appbundle --release
```

The AAB will be generated at:

```text
build/app/outputs/bundle/release/app-release.aab
```

This is the recommended format for submitting to the Google Play Store.

## Common Build Notes

- Run `flutter clean` if you encounter stale build issues:

```bash
flutter clean
flutter pub get
```

- If you get Android SDK errors, open Android Studio and install the required SDK components, then run:

```bash
flutter doctor --android-licenses
```

- If the app cannot start on an emulator, ensure the emulator is running and visible in `flutter devices`.

## Useful Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --release
flutter build appbundle --release
```

## License

This project does not currently include a license file. Add one if you plan to distribute the app publicly.
