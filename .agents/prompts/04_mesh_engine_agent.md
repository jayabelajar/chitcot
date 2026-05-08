# AGENT PROMPT - Mesh Engine

Gunakan konteks dari `00_master_context.md`.

## Misi
Bangun Mesh Engine untuk relay multi-hop dengan kontrol TTL, duplicate filter, dan store-forward.

## Cakupan
- Routing sederhana berbasis flood-control.
- TTL decrement di setiap hop.
- Hop count increment.
- Duplicate suppression via `seen_messages`.
- Relay queue management saat peer tidak tersedia.

## Output Wajib
1. Algoritma relay step-by-step.
2. Kebijakan kapan message diteruskan vs dibuang.
3. Struktur data in-memory + sinkronisasi ke DB.
4. Anti-spam/throttling policy.
5. Failure handling (loop, stale packet, clock drift).
6. Test matrix untuk topologi A-B-C-D.

## Target
- Stabil pada kondisi peer dinamis (device keluar/masuk jangkauan).
- Tidak membanjiri jaringan BLE oleh packet duplikat.
