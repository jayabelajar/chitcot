import 'dart:io';

import 'package:bluemesh_chat/app/app_providers.dart';
import 'package:bluemesh_chat/app/app_state.dart';
import 'package:bluemesh_chat/features/chat/chat_models.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BlueMeshRootApp extends ConsumerStatefulWidget {
  const BlueMeshRootApp({super.key});

  @override
  ConsumerState<BlueMeshRootApp> createState() => _BlueMeshRootAppState();
}

class _BlueMeshRootAppState extends ConsumerState<BlueMeshRootApp> with WidgetsBindingObserver {
  bool _historyLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(_restoreHistory);
  }

  Future<void> _restoreHistory() async {
    if (_historyLoaded || !mounted) return;
    final storage = ref.read(chatHistoryStorageProvider);
    final publicMap = await storage.loadPublic();
    final dmMap = await storage.loadDm();
    if (!mounted) return;
    ref.read(publicMessagesProvider.notifier).state = publicMap;
    ref.read(dmMessagesProvider.notifier).state = dmMap;
    _historyLoaded = true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(appControllerProvider.notifier);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      controller.updateLifecycle(AppLifecycleStatus.background);
    }
    if (state == AppLifecycleState.resumed) {
      controller.updateLifecycle(AppLifecycleStatus.foreground);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);

    return MaterialApp(
      title: 'Chitcot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF08110D),
        colorScheme: const ColorScheme.dark(primary: Color(0xFF38F29B), secondary: Color(0xFF38F29B), surface: Color(0xFF101A14)),
      ),
      home: app.hasIdentity ? const _HomeShell() : const _OnboardingScreen(),
    );
  }
}

class _OnboardingScreen extends ConsumerWidget {
  const _OnboardingScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Chitcot', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Inisialisasi... ${app.bleState.name}'),
            if (app.error != null) ...[
              const SizedBox(height: 8),
              Text(app.error!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ],
        ),
      ),
    );
  }
}

class _HomeShell extends ConsumerWidget {
  const _HomeShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final ctrl = ref.read(appControllerProvider.notifier);

    if (app.activeDmPeerId != null) {
      return _DmScreen(peerId: app.activeDmPeerId!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(app.identityLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(app.currentRoomLabel, style: const TextStyle(fontSize: 12, color: Color(0xFF90B7A1))),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: switch (app.tab) {
              AppRouteTab.chat => const _PublicRoomScreen(),
              AppRouteTab.peers => const _PeerStatusScreen(),
              AppRouteTab.profile => const _ProfileScreen(),
            },
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: app.tab.index,
        onDestinationSelected: (index) => ctrl.setTab(AppRouteTab.values[index]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.bluetooth_searching_rounded), label: 'Peers'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), label: 'Profil'),
        ],
      ),
    );
  }
}

class _ProfileScreen extends ConsumerStatefulWidget {
  const _ProfileScreen();

  @override
  ConsumerState<_ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<_ProfileScreen> {
  late final TextEditingController _aliasCtrl;

  @override
  void initState() {
    super.initState();
    _aliasCtrl = TextEditingController(text: ref.read(appControllerProvider).identityLabel);
  }

  @override
  void dispose() {
    _aliasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final ctrl = ref.read(appControllerProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('Profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        TextField(controller: _aliasCtrl, decoration: const InputDecoration(labelText: 'Nama samaran/inisial')),
        const SizedBox(height: 10),
        FilledButton(onPressed: () => ctrl.setAlias(_aliasCtrl.text), child: const Text('Simpan Nama')),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Mode Online'),
          subtitle: const Text('Jika mati, chat pakai mode radius (mesh lokal).'),
          value: app.isOnlineMode,
          onChanged: ctrl.setOnlineMode,
        ),
        const SizedBox(height: 12),
        Text('Radius Chat: ${app.radiusKm} km'),
        Slider(value: app.radiusKm.toDouble(), min: 1, max: 200, divisions: 199, onChanged: (v) => ctrl.setRadius(v.round())),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Bluetooth status'),
          subtitle: Text(app.bleState.name),
        ),
      ],
    );
  }
}

class _PublicRoomScreen extends ConsumerStatefulWidget {
  const _PublicRoomScreen();

  @override
  ConsumerState<_PublicRoomScreen> createState() => _PublicRoomScreenState();
}

class _PublicRoomScreenState extends ConsumerState<_PublicRoomScreen> {
  late final TextEditingController _input;

  @override
  void initState() {
    super.initState();
    _input = TextEditingController();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final allRooms = ref.watch(publicMessagesProvider);
    final messages = allRooms[app.currentRoomKey] ?? const <ChatMessage>[];
    final controller = ref.read(appControllerProvider.notifier);
    final storage = ref.read(chatHistoryStorageProvider);

    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? const Center(child: Text('Belum ada pesan'))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (_, i) => _MessageTile(msg: messages[messages.length - 1 - i]),
                ),
        ),
        _Composer(
          controller: _input,
          hint: 'Tulis pesan...',
          onSend: () async {
            final text = _input.text.trim();
            if (text.isEmpty) return;
            final next = controller.buildOutgoingMessage(text);
            final updatedRoom = [...messages, next];
            final updated = {...allRooms, app.currentRoomKey: updatedRoom};
            ref.read(publicMessagesProvider.notifier).state = updated;
            await storage.savePublic(updated);
            _input.clear();
          },
          onAttach: (type, path) async {
            final fileName = path.split(Platform.pathSeparator).last;
            final next = controller.buildOutgoingMessage(
              type == ChatMessageType.image ? '[Image] $fileName' : '[Audio] $fileName',
              type: type,
              mediaPath: path,
            );
            final updatedRoom = [...messages, next];
            final updated = {...allRooms, app.currentRoomKey: updatedRoom};
            ref.read(publicMessagesProvider.notifier).state = updated;
            await storage.savePublic(updated);
          },
        ),
      ],
    );
  }
}

class _PeerStatusScreen extends ConsumerWidget {
  const _PeerStatusScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final ctrl = ref.read(appControllerProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF142019), borderRadius: BorderRadius.circular(12)),
          child: Text('BLE: ${app.isBleReady ? 'Connected' : 'Not ready'}'),
        ),
        const SizedBox(height: 10),
        ...app.peers.map(
          (p) => Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(p.name.isEmpty ? p.id : p.name),
              subtitle: Text('RSSI ${p.rssi ?? '-'}'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => ctrl.openDm(p.id),
            ),
          ),
        ),
      ],
    );
  }
}

class _DmScreen extends ConsumerStatefulWidget {
  const _DmScreen({required this.peerId});

  final String peerId;

  @override
  ConsumerState<_DmScreen> createState() => _DmScreenState();
}

class _DmScreenState extends ConsumerState<_DmScreen> {
  late final TextEditingController _input;

  @override
  void initState() {
    super.initState();
    _input = TextEditingController();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.read(appControllerProvider.notifier);
    final dmMap = ref.watch(dmMessagesProvider);
    final messages = dmMap[widget.peerId] ?? const <ChatMessage>[];
    final storage = ref.read(chatHistoryStorageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.peerId),
        leading: IconButton(onPressed: ctrl.closeDm, icon: const Icon(Icons.arrow_back_rounded)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? const Center(child: Text('Belum ada DM'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(10),
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (_, i) => _MessageTile(msg: messages[messages.length - 1 - i]),
                    ),
            ),
            _Composer(
              controller: _input,
              hint: 'Tulis DM...',
              onSend: () async {
                final text = _input.text.trim();
                if (text.isEmpty) return;
                final next = ctrl.buildOutgoingMessage(text, peerId: widget.peerId);
                final updated = [...messages, next];
                final state = {...dmMap, widget.peerId: updated};
                ref.read(dmMessagesProvider.notifier).state = state;
                await storage.saveDm(state);
                _input.clear();
              },
              onAttach: (type, path) async {
                final fileName = path.split(Platform.pathSeparator).last;
                final next = ctrl.buildOutgoingMessage(
                  type == ChatMessageType.image ? '[Image] $fileName' : '[Audio] $fileName',
                  peerId: widget.peerId,
                  type: type,
                  mediaPath: path,
                );
                final updated = [...messages, next];
                final state = {...dmMap, widget.peerId: updated};
                ref.read(dmMessagesProvider.notifier).state = state;
                await storage.saveDm(state);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.hint, required this.onSend, required this.onAttach});

  final TextEditingController controller;
  final String hint;
  final Future<void> Function() onSend;
  final Future<void> Function(ChatMessageType type, String path) onAttach;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
        child: Row(
          children: [
            IconButton(
              onPressed: () async {
                final selected = await showModalBottomSheet<String>(
                  context: context,
                  builder: (_) => SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(leading: const Icon(Icons.image_outlined), title: const Text('Kirim Gambar'), onTap: () => Navigator.pop(context, 'image')),
                        ListTile(leading: const Icon(Icons.mic_none_rounded), title: const Text('Kirim Audio'), onTap: () => Navigator.pop(context, 'audio')),
                      ],
                    ),
                  ),
                );
                if (selected == null) return;
                final result = await FilePicker.platform.pickFiles(
                  type: selected == 'image' ? FileType.image : FileType.custom,
                  allowedExtensions: selected == 'image' ? null : ['mp3', 'm4a', 'wav', 'aac', 'ogg'],
                );
                final path = result?.files.single.path;
                if (path == null) return;
                await onAttach(selected == 'image' ? ChatMessageType.image : ChatMessageType.audio, path);
              },
              icon: const Icon(Icons.attach_file_rounded),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: hint,
                  filled: true,
                  fillColor: const Color(0xFF142019),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(height: 46, child: FilledButton(onPressed: onSend, child: const Text('Kirim'))),
          ],
        ),
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({required this.msg});

  final ChatMessage msg;

  @override
  Widget build(BuildContext context) {
    final time = '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: msg.isMine ? const Color(0xFF1D3227) : const Color(0xFF16231C), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(msg.sender, style: const TextStyle(fontSize: 12, color: Color(0xFF8DB29E))),
          const SizedBox(height: 4),
          if (msg.type == ChatMessageType.image && msg.mediaPath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(msg.mediaPath!), height: 120, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Text(msg.text)),
            )
          else
            Text(msg.text),
          if (msg.type == ChatMessageType.audio)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Row(children: [Icon(Icons.audiotrack_rounded, size: 16), SizedBox(width: 6), Text('Audio attached')]),
            ),
          const SizedBox(height: 6),
          Text('$time • ${msg.radiusKm}km', style: const TextStyle(fontSize: 11, color: Color(0xFF7D9789))),
        ],
      ),
    );
  }
}


