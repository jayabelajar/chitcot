# Output Eksekusi Prompt 01 - Architecture Planner

## Ringkasan Arsitektur
BlueMesh Chat menggunakan arsitektur layered di Flutter dengan prinsip offline-first dan event-driven pipeline.

Alur utama data:
1. UI mengirim command ke Messaging Engine.
2. Messaging Engine meminta Security Layer melakukan encrypt/sign.
3. Payload terenkripsi dikirim ke Mesh Engine.
4. Mesh Engine memutuskan direct-send/relay via BLE Transport.
5. Semua event (incoming/outgoing/relay/ack) disimpan ke Local DB.
6. Saat internet tersedia, Online Sync mengekspor state message yang relevan tanpa melanggar E2E boundary.

## Diagram Arsitektur Tekstual
```text
Flutter App
├── UI Layer (Screens + Widgets)
├── Application Layer
│   ├── Messaging Engine
│   ├── Mesh Engine
│   └── Use Cases
├── Infrastructure Layer
│   ├── BLE Transport
│   ├── Online Transport (Supabase)
│   ├── Security Layer
│   └── Local Database (Drift/SQLite)
└── Shared Core
    ├── Models
    ├── Result/Error Types
    └── Config/Constants
```

## Struktur Folder Flutter (Scalable)
```text
lib/
├── app/
├── core/
│   ├── config/
│   └── utils/
├── features/
│   ├── identity/
│   ├── chat/
│   ├── ble/
│   ├── mesh/
│   ├── security/
│   └── sync/
└── data/
    ├── local/db/
    └── repositories/
```

## Interface Contracts (Dart-like)
```dart
abstract class BleTransport {
  Stream<PeerEvent> watchPeers();
  Future<void> startScan();
  Future<void> startAdvertise();
  Future<void> sendPacket(String peerId, Uint8List packet);
}

abstract class MeshEngine {
  Future<void> processIncoming(Packet packet, String fromPeer);
  Future<void> broadcast(Packet packet);
  bool shouldRelay(Packet packet);
}

abstract class MessagingEngine {
  Future<MessageId> sendPublic(String plaintext);
  Future<MessageId> sendDirect(String receiverId, String plaintext);
  Stream<MessageEvent> watchTimeline(String roomOrPeerId);
}

abstract class SecurityService {
  Future<KeyPair> ensureLocalIdentity();
  Future<EncryptedEnvelope> encryptForPeer(String peerId, Uint8List plain);
  Future<Uint8List> decryptFromPeer(String peerId, EncryptedEnvelope env);
  Future<Signature> sign(Uint8List payload);
  Future<bool> verify(Uint8List payload, Signature sig, String publicKey);
}

abstract class MessageRepository {
  Future<void> upsertMessage(MessageEntity message);
  Stream<List<MessageEntity>> watchRoomTimeline();
  Stream<List<MessageEntity>> watchDmTimeline(String peerId);
}

abstract class OnlineSyncService {
  Future<void> pushPending();
  Future<void> pullLatest();
  Stream<SyncState> watchState();
}
```

## Event Flow Utama
1. App Start
- inisialisasi DB
- load/generate local identity
- start BLE scan + advertise

2. Send Message
- UI submit message
- encrypt + sign
- simpan status `pending`
- kirim via BLE
- update status `relayed/delivered`

3. Receive Message
- BLE receive packet
- cek duplicate + TTL
- verify signature
- decrypt payload
- simpan ke timeline
- relay jika eligible

## Dependency Awal + Alasan
- `flutter_riverpod`: state management modular dan testable.
- `drift` + `sqlite3_flutter_libs`: query kuat, migrasi jelas, cocok untuk timeline chat.
- `flutter_blue_plus`: BLE cross-platform Flutter.
- `cryptography`: baseline crypto API; dapat diganti libsodium binding untuk hardening.
- `uuid`: message id unik untuk dedup dan idempotency.

## Tradeoff Utama
- Drift vs Isar: Drift dipilih karena SQL expressiveness, index tuning, dan migrasi versi lebih transparan untuk kebutuhan query timeline + queue.
- Flood relay vs routing kompleks: fase awal gunakan controlled flooding + TTL agar cepat mencapai MVP; optimasi routing dilakukan setelah metrik lapangan tersedia.

## Sequence Implementasi (Mingguan)
1. Minggu 1: fondasi app, identity, DB schema, repository.
2. Minggu 2: BLE discovery + packet send/receive + public room.
3. Minggu 3: DM + mesh relay + TTL + duplicate filter.
4. Minggu 4: encryption/signature + QA skenario multi-device.

## Risiko dan Mitigasi
- Background restriction OS: batasi target awal foreground reliability, tambah background strategy bertahap.
- BLE payload kecil: chunking + reassembly dengan timeout.
- Relay storm: dedup ketat + TTL + per-peer throttling.

## Definition of Done Phase 1
- Device dapat discover peer di sekitar.
- Public chat berjalan tanpa internet.
- Basic DM antar dua device berjalan.
- Message masuk tersimpan lokal dan tampil konsisten setelah app restart.
