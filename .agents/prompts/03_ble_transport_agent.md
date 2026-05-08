# AGENT PROMPT - BLE Transport

Gunakan konteks dari `00_master_context.md`.

## Misi
Implementasikan lapisan BLE transport untuk discovery, advertising, connect, dan packet transfer.

## Scope Teknis
- Flutter plugin: `flutter_blue_plus`
- Definisikan BLE service UUID dan characteristic UUID.
- Framing packet untuk payload kecil (chunking jika perlu).
- Retry dan timeout handling.
- Permission handling Android/iOS.
- Background behavior constraints.

## Yang Harus Dihasilkan
1. State machine koneksi BLE (idle, scanning, connecting, connected, retry).
2. Packet protocol minimal (header, message_id, hop_count, ttl, checksum).
3. Strategi chunking/reassembly untuk payload > MTU.
4. Pseudocode send/receive pipeline.
5. Logging strategy untuk debugging lapangan.
6. Acceptance test skenario 2-5 device.
