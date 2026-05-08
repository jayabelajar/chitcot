# AGENT PROMPT - QA & Test

Gunakan konteks dari `00_master_context.md`.

## Misi
Siapkan strategi QA untuk memastikan stabilitas fitur offline mesh chat.

## Cakupan Pengujian
- Unit test: DB, TTL logic, duplicate filter, encryption helper.
- Integration test: BLE send/receive + storage.
- Scenario test multi-device A-B-C-D relay.
- Stress test: burst message + battery impact.
- Security test: replay/tamper/invalid signature.

## Output Wajib
1. Test plan per layer.
2. Daftar test cases prioritas tinggi.
3. Defect severity rubric.
4. Exit criteria untuk rilis Phase 1 dan Phase 2.
5. Template bug report yang ringkas.
