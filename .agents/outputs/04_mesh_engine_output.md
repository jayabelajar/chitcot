# Output Eksekusi Prompt 04 - Mesh Engine

## Assumption
- Routing fase awal menggunakan controlled flooding.
- Dedup berbasis `message_id` wajib sebelum proses relay.

## Desain Solusi
- `MeshEngine` sebagai interface proses inbound packet.
- `MeshEngineImpl` menjalankan aturan inti:
  1. Drop jika duplicate.
  2. Consume-only jika TTL habis.
  3. Consume-only jika hop limit tercapai.
  4. Consume-only jika final recipient.
  5. Jika eligible, TTL-- dan hop++ lalu enqueue ke relay queue.

## File Implementasi
- `lib/features/mesh/mesh_engine.dart`
- `lib/features/mesh/mesh_engine_impl.dart`
- `lib/features/mesh/relay_decision.dart`
- `test/features/mesh/mesh_engine_test.dart`

## Relay Policy
- `drop`: duplicate message.
- `consumeOnly`: packet diterima local tapi tidak diteruskan.
- `consumeAndRelay`: packet diterima local dan dijadwalkan relay.

## Anti-Spam/Loop Baseline
- Duplicate suppression via `SeenMessageStore`.
- Hop limit (`maxHop`, default 10).
- TTL decrement tiap hop.

## Acceptance Criteria
- Duplicate tidak pernah menambah relay queue.
- Packet `ttl=0` tidak direlay.
- Packet eligible menghasilkan packet baru dengan `ttl-1` dan `hop+1`.
- Unit test relay logic lulus.
