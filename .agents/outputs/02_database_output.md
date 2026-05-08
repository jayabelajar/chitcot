# Output Eksekusi Prompt 02 - Database Setup

## Assumption
- Local DB utama: Drift + SQLite.
- User anonim, `users.id` adalah local-generated ID.
- `receiver_id = NULL` menandakan public room message.

## ERD Tekstual
```text
users (1) --------< messages >-------- (0..1) users(receiver)
messages (1) ----- (0..1) relay_queue
messages (1) ----- (0..1) seen_messages
```

## DDL SQL
```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  nickname TEXT NOT NULL,
  public_key TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE messages (
  id TEXT PRIMARY KEY,
  sender_id TEXT NOT NULL,
  receiver_id TEXT,
  ciphertext TEXT NOT NULL,
  ttl INTEGER NOT NULL DEFAULT 0,
  hop_count INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL,
  direction TEXT NOT NULL,
  sent_at TEXT,
  delivered_at TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(sender_id) REFERENCES users(id),
  FOREIGN KEY(receiver_id) REFERENCES users(id)
);

CREATE TABLE relay_queue (
  message_id TEXT PRIMARY KEY,
  expires_at TEXT NOT NULL,
  next_attempt_at TEXT,
  retry_count INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(message_id) REFERENCES messages(id) ON DELETE CASCADE
);

CREATE TABLE seen_messages (
  message_id TEXT PRIMARY KEY,
  seen_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_messages_room_created
ON messages(receiver_id, created_at DESC);

CREATE INDEX idx_messages_sender_created
ON messages(sender_id, created_at DESC);

CREATE INDEX idx_messages_status
ON messages(status);

CREATE INDEX idx_relay_queue_expiry
ON relay_queue(expires_at);

CREATE INDEX idx_relay_queue_next_attempt
ON relay_queue(next_attempt_at);
```

## Drift Tables
Implementasi awal tersedia di:
- `bluemesh_chat/lib/data/local/db/app_database.dart`

Catatan:
- Sudah mencakup `users`, `messages`, `relay_queue`, `seen_messages`.
- Sudah siap untuk codegen drift.

## Query Penting
1. Insert outgoing message
```sql
INSERT INTO messages (
  id, sender_id, receiver_id, ciphertext, ttl, hop_count, status, direction, sent_at
) VALUES (?, ?, ?, ?, ?, 0, 'pending', 'outgoing', CURRENT_TIMESTAMP);
```

2. Insert incoming message (idempotent)
```sql
INSERT OR IGNORE INTO messages (
  id, sender_id, receiver_id, ciphertext, ttl, hop_count, status, direction
) VALUES (?, ?, ?, ?, ?, ?, 'received', 'incoming');
```

3. Fetch public room timeline
```sql
SELECT * FROM messages
WHERE receiver_id IS NULL
ORDER BY created_at DESC
LIMIT ? OFFSET ?;
```

4. Fetch DM timeline
```sql
SELECT * FROM messages
WHERE (sender_id = ? AND receiver_id = ?)
   OR (sender_id = ? AND receiver_id = ?)
ORDER BY created_at DESC
LIMIT ? OFFSET ?;
```

5. Enqueue relay
```sql
INSERT OR REPLACE INTO relay_queue(message_id, expires_at, next_attempt_at, retry_count)
VALUES (?, ?, ?, ?);
```

6. Duplicate detection
```sql
SELECT 1 FROM seen_messages WHERE message_id = ? LIMIT 1;
```

## DAO Pattern Minimal
- `UserDao`
  - `upsertUser`, `getById`
- `MessageDao`
  - `insertOutgoing`, `insertIncomingIgnoreDuplicate`, `watchPublicTimeline`, `watchDmTimeline`
- `RelayQueueDao`
  - `enqueue`, `dequeue`, `pickReadyBatch`
- `SeenMessageDao`
  - `markSeen`, `isSeen`

## Strategi Migrasi
- `schemaVersion` mulai `1`.
- Tambahan kolom wajib via migrasi incremental (`if (from < 2) ...`).
- Dilarang drop table untuk upgrade minor; gunakan alter + backfill.

## Retention Policy
- `seen_messages`: hapus record > 7 hari.
- `relay_queue`: hapus yang `expires_at < now`.
- `messages`: default simpan penuh untuk UX chat, opsi purge manual di settings.

## Unit Test Cases Prioritas
1. Insert message valid tersimpan dengan status benar.
2. Duplicate incoming message tidak membuat row baru.
3. Timeline DM terurut descending by `created_at`.
4. Relay queue hanya mengambil item yang `next_attempt_at <= now`.
5. TTL/hop_count update tersimpan konsisten.
6. Foreign key sender/receiver invalid ditolak DB.

## Acceptance Criteria
- Query timeline tetap responsif pada >10.000 row message.
- Duplicate relay suppression konsisten lintas restart app.
- Migrasi versi schema dapat dijalankan tanpa kehilangan data.
