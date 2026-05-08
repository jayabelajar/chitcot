# Chitcot

Chitcot is an offline-first Flutter chat app powered by BLE mesh communication. It supports radius-based channels, online mode, persistent local history, and image/audio attachments.

## Key Features

- Offline mesh chat over Bluetooth Low Energy
- Online/offline mode switch
- Radius-based chat rooms
- Direct messaging to discovered peers
- Persistent local chat history
- Image and audio attachments from local files

## Requirements

- Flutter SDK 3.22+
- Dart SDK 3.4+
- Android SDK and/or Xcode (depending on target platform)
- Physical device recommended for BLE and permission testing

## Installation

```bash
git clone <repo-url>
cd chitcot
flutter pub get
```

## Run

```bash
flutter run
```

Specific targets:

```bash
flutter run -d android
flutter run -d ios
flutter run -d chrome
```

## Build

```bash
flutter build apk
flutter build ios
flutter build web
```

## Permissions and Platform Notes

- Android: Bluetooth and location permissions are requested at startup
- iOS: Bluetooth and location permissions are requested at startup
- BLE functionality should be validated on physical devices

## Project Structure

- `lib/app`: app state and main UI
- `lib/features/ble`: BLE transport and peer discovery
- `lib/features/mesh`: mesh routing and relay logic
- `lib/features/security`: identity and encryption
- `lib/features/sync`: online sync flow
- `lib/data/local/db`: local database schema

## Quality Checks

```bash
flutter analyze
flutter test
```
