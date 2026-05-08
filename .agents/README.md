# AI Agents Workspace - BlueMesh Chat

Workspace ini berisi kumpulan prompt siap pakai untuk AI agents, mengacu pada `prd.md`.

## Struktur
- `prompts/00_master_context.md` : konteks global dan aturan kerja agent
- `prompts/01_architecture_planner.md` : breakdown arsitektur & modul
- `prompts/02_database_setup.md` : desain schema, migrasi, indexing, dan query awal
- `prompts/03_ble_transport_agent.md` : implementasi BLE transport
- `prompts/04_mesh_engine_agent.md` : relay multi-hop, TTL, duplicate filter
- `prompts/05_security_agent.md` : key management, E2E encryption, signature
- `prompts/06_online_sync_agent.md` : hybrid sync online/offline
- `prompts/07_flutter_app_agent.md` : integrasi UI + state management
- `prompts/08_qa_test_agent.md` : test plan fungsional, performa, keamanan
- `prompts/09_release_roadmap_agent.md` : roadmap eksekusi per phase

## Cara pakai
1. Berikan `00_master_context.md` ke semua agent sebagai context awal.
2. Jalankan agent per domain menggunakan file prompt terkait.
3. Minta output dalam format checklist + task breakdown + acceptance criteria.
4. Gunakan hasil setiap agent sebagai input ke agent berikutnya.
