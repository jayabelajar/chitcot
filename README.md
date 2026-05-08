# Chitcot

Chitcot adalah aplikasi chat Flutter dengan pendekatan offline-first menggunakan BLE mesh. Aplikasi mendukung chat berbasis radius, mode online, riwayat pesan lokal, serta attachment gambar dan audio.

## Fitur Utama

- Offline mesh chat berbasis Bluetooth Low Energy
- Mode online/offline
- Chat berbasis radius
- Direct message ke peer terdeteksi
- Riwayat chat persisten (tetap ada setelah aplikasi ditutup)
- Attachment gambar dan audio dari file lokal

## Requirement

- Flutter SDK 3.22+
- Dart SDK 3.4+
- Android SDK / Xcode sesuai target platform
- Device fisik untuk pengujian BLE dan permission

## Instalasi

```bash
git clone <repo-url>
cd bluemesh_chat
flutter pub get
```

## Menjalankan Aplikasi

```bash
flutter run
```

Untuk target spesifik:

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

## Permission dan Catatan Platform

- Android: Bluetooth dan lokasi akan diminta saat startup
- iOS: Bluetooth dan lokasi akan diminta saat startup
- Fitur BLE direkomendasikan diuji di device fisik

## Struktur Direktori Singkat

- `lib/app`: state dan UI utama
- `lib/features/ble`: transport BLE dan discovery peer
- `lib/features/mesh`: relay/mesh engine
- `lib/features/security`: enkripsi dan identitas
- `lib/features/sync`: sinkronisasi mode online
- `lib/data/local/db`: skema database lokal

## Quality Check

```bash
flutter analyze
flutter test
```

