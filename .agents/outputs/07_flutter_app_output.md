# Output Eksekusi Prompt 07 - Flutter App Integrator

## Struktur Feature-First
- `lib/app/app_widget.dart`: shell app + routing/tab flow + lifecycle binding.
- `lib/app/app_state.dart`: global UI state (identity, BLE, peers, tab, DM route).
- `lib/app/app_providers.dart`: provider graph Riverpod + bootstrap controller.
- `lib/features/chat/chat_models.dart`: model pesan UI untuk public/DM.

## Provider Graph
- `bleTransportProvider` -> `BleTransportImpl`
- `securityServiceProvider` -> `SecurityServiceImpl`
- `syncServiceProvider` -> `SyncServiceImpl(local, remote)`
- `appControllerProvider` bergantung pada ketiga provider di atas
- `publicMessagesProvider` dan `dmMessagesProvider` untuk state timeline UI

## Navigasi & Route Map
- Entry app: onboarding screen (auto bootstrap identity/BLE)
- Setelah identity ready: home shell
- Home shell punya tab:
  - Public Room
  - Peer Status
- Dari Peer Status klik peer -> masuk screen DM (`activeDmPeerId`)

## Event-Driven UI Flow
1. Bootstrap:
- `ensureIdentity()`
- subscribe `watchState()` BLE
- subscribe `watchPeers()` BLE
- `ble.start()`
- trigger `sync.runOnce()`

2. Lifecycle:
- foreground -> `ble.start()`
- background -> `ble.stop()`

3. Message flow (MVP):
- User send dari composer -> create outgoing message -> update provider state timeline.
- Integrasi kirim packet ke mesh/ble dan persist DB jadi next task.

## Error State & Fallback BLE
- State menyimpan `error` global dari bootstrap.
- Header menampilkan status BLE realtime (`idle/scanning/connected/retrying`).
- Screen peer menampilkan readiness BLE untuk indikasi fallback UX.

## Technical Debt yang Bisa Ditunda Setelah MVP
- Replace in-memory timeline dengan repository Drift.
- Wire encryption + mesh relay ke composer send action.
- Real BLE scan/advertise/connect dari `flutter_blue_plus`.
- Sinkronisasi remote Supabase beneran + auth anon channel.
- Background task strategy platform-specific Android/iOS.

## Definition of Done Demo Internal
- App start -> onboarding -> otomatis masuk home.
- Tab public room dan peer status bisa dipakai.
- Navigasi ke DM dari daftar peer berfungsi.
- Lifecycle foreground/background memicu start/stop BLE transport.
- Analyze/test lulus.
