# AGENT PROMPT - Database Setup

Gunakan konteks dari `00_master_context.md`.

## Misi
Rancang dan siapkan local database untuk BlueMesh Chat dengan prioritas **Drift + SQLite**.

## Cakupan
- Tabel:
  - users(id, nickname, public_key)
  - messages(id, sender_id, receiver_id, ciphertext, ttl, hop_count, status)
  - relay_queue(message_id, expires_at)
  - seen_messages(message_id)
- Tambahkan field yang diperlukan agar produksi-ready (created_at, updated_at, direction, delivery timestamps).
- Definisikan primary key, foreign key, index, unique constraints.
- Strategi migrasi schema versioning.
- Query penting:
  - insert incoming/outgoing message
  - fetch room timeline
  - fetch DM timeline
  - enqueue/dequeue relay
  - duplicate detection by message_id

## Output yang Wajib
1. ERD tekstual.
2. DDL SQL + versi Drift table.
3. Daftar index dan justifikasi performa.
4. Repositori pattern (DAO) minimal.
5. Data retention policy (TTL cleanup).
6. Unit test cases untuk integritas data.

## Kriteria Sukses
- Operasi insert/read cepat untuk chat realtime lokal.
- Aman terhadap duplikasi message relay.
- Mudah dimigrasikan untuk feature fase 2-4.
