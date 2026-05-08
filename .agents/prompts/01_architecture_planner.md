# AGENT PROMPT - Architecture Planner

Gunakan konteks dari `00_master_context.md`.

## Misi
Buat rancangan arsitektur implementatif untuk BlueMesh Chat berbasis Flutter + BLE mesh.

## Yang Harus Dihasilkan
1. Diagram arsitektur tekstual (layer + alur data).
2. Struktur folder Flutter project yang scalable.
3. Definisi interface antar modul:
   - BLE Transport
   - Mesh Engine
   - Messaging Engine
   - Security Layer
   - Local DB
   - Online Sync
4. Event flow utama:
   - app start
   - identity init
   - peer discovery
   - send message
   - relay message
   - receive/decrypt/store
5. Daftar dependency awal + alasan pemilihan.
6. Keputusan tradeoff penting (mis. Drift vs Isar).

## Format Output
- Ringkasan arsitektur
- Interface contracts (Dart-like)
- Task implementation sequence (mingguan)
- Risiko dan mitigasi
- Definition of Done Phase 1
