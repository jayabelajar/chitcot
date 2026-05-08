# AGENT PROMPT - Online Sync

Gunakan konteks dari `00_master_context.md`.

## Misi
Definisikan Online Transport untuk mode hybrid: sinkronisasi saat online, fallback BLE saat offline.

## Cakupan
- Pilihan backend default: Supabase.
- Sync pending message queue.
- Conflict resolution (last-write vs vector-like metadata sederhana).
- Status delivery transition: pending, relayed, delivered, failed.
- Retry policy saat koneksi fluktuatif.

## Output Wajib
1. Arsitektur sync engine.
2. Mapping schema lokal ke remote.
3. Algoritma sync pull/push.
4. Idempotency strategy untuk cegah duplikasi.
5. Security boundaries (apa yang terenkripsi end-to-end).
6. Observability metrics untuk kualitas sync.
