# Output Eksekusi Prompt 06 - Online Sync

## Assumption
- Backend default: Supabase (abstraksi ada di `RemoteSyncDataSource`).
- Local source of truth tetap SQLite lokal.

## Arsitektur Sync Engine
- `SyncServiceImpl` mengorkestrasi:
  1. Push pending lokal ke remote.
  2. Mark status jadi `delivered` jika push sukses.
  3. Pull perubahan remote berdasarkan watermark `sinceUpdatedAtMs`.
  4. Dedup via check `exists(message_id)` sebelum upsert lokal.

## Mapping Local -> Remote
- `id` -> `message_id`
- `ciphertext` -> `ciphertext`
- `receiver_id` -> `receiver_id`
- `status` -> `delivery_status`
- `updated_at_ms` -> `updated_at_ms`

## Algoritma Push/Pull
- Push:
  - ambil `pending`
  - kirim batch
  - update status local `delivered`
- Pull:
  - request perubahan > watermark
  - filter idempotent (skip jika sudah ada lokal)
  - upsert lokal
  - update watermark

## Retry Policy
- Exponential-like linear backoff sederhana `baseRetryDelayMs * attempt`.
- Batas `maxRetries` (default 3).
- Jika semua gagal, state `failed` + `lastError`.

## Idempotency Strategy
- Message identity tunggal: `message_id`.
- Pull path skip message yang sudah ada lokal (`exists`).
- Push path remote disarankan upsert by `message_id`.

## Security Boundary
- Sync hanya membawa ciphertext/envelope; plaintext tidak keluar device.
- Key private tidak disinkronkan ke server.

## Observability Metrics
- `pushed` count per run.
- `pulled` count per run.
- retry attempt.
- failure reason (`lastError`).

## Implementasi
- `lib/features/sync/sync_models.dart`
- `lib/features/sync/sync_service.dart`
