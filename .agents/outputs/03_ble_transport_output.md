# Output Eksekusi Prompt 03 - BLE Transport

## Assumption
- Implementasi ini adalah skeleton production-ready untuk iterasi awal, belum mengaktifkan scan/advertise real device.
- Packet protocol dipusatkan di codec agar mudah dipakai lintas platform.

## Desain Solusi
- `BleTransport` sebagai kontrak utama stream-based.
- `BleTransportImpl` memegang state machine:
  - `idle -> scanning -> advertising -> connected`
  - masuk `retrying` saat kirim gagal.
- `BlePacketCodec` untuk framing packet:
  - header: version, type, ttl, hop_count, payload_len, checksum
  - body: message_id + delimiter + payload

## File Implementasi
- `lib/features/ble/ble_transport.dart`
- `lib/features/ble/ble_transport_impl.dart`
- `lib/core/models/mesh_packet.dart`

## Packet Protocol Minimal
- `version` (1 byte)
- `type` (1 byte)
- `ttl` (1 byte)
- `hop_count` (1 byte)
- `payload_len` (2 byte)
- `checksum` (2 byte)
- `message_id` (string bytes + null delimiter)
- `payload`

## Retry/Timeout Policy (MVP)
- Saat `send()` dipanggil dan belum `connected`, state diubah ke `retrying` dan error dilempar.
- Guard payload budget saat ini 512 bytes untuk baseline BLE safety.

## Acceptance Criteria
- BLE state bisa dipantau via stream.
- Peer list dan inbound bytes punya stream terpisah.
- Encode/decode packet tervalidasi checksum.
- Packet invalid menghasilkan `FormatException`.
