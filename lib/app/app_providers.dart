import 'dart:async';
import 'dart:convert';

import 'package:bluemesh_chat/app/app_state.dart';
import 'package:bluemesh_chat/features/ble/ble_transport.dart';
import 'package:bluemesh_chat/features/ble/ble_transport_impl.dart';
import 'package:bluemesh_chat/features/chat/chat_models.dart';
import 'package:bluemesh_chat/features/security/security_service.dart';
import 'package:bluemesh_chat/features/security/security_service_impl.dart';
import 'package:bluemesh_chat/features/sync/sync_models.dart';
import 'package:bluemesh_chat/features/sync/sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

final bleTransportProvider = Provider<BleTransport>((ref) {
  final transport = BleTransportImpl();
  ref.onDispose(() {
    transport.dispose();
  });
  return transport;
});

final securityServiceProvider = Provider<SecurityService>((ref) => SecurityServiceImpl(keyStore: InMemoryLocalKeyStore()));

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncServiceImpl(local: InMemoryLocalSyncRepository(), remote: InMemoryRemoteSyncDataSource());
});

final appControllerProvider = StateNotifierProvider<AppController, AppViewState>((ref) {
  return AppController(ref.read(bleTransportProvider), ref.read(securityServiceProvider), ref.read(syncServiceProvider));
});

final chatHistoryStorageProvider = Provider<ChatHistoryStorage>((_) => ChatHistoryStorage());

final publicMessagesProvider = StateProvider<Map<String, List<ChatMessage>>>((_) => <String, List<ChatMessage>>{});
final dmMessagesProvider = StateProvider<Map<String, List<ChatMessage>>>((_) => <String, List<ChatMessage>>{});

class ChatHistoryStorage {
  static const _publicKey = 'chat_history_public';
  static const _dmKey = 'chat_history_dm';

  Future<Map<String, List<ChatMessage>>> loadPublic() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_publicKey));
  }

  Future<Map<String, List<ChatMessage>>> loadDm() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_dmKey));
  }

  Future<void> savePublic(Map<String, List<ChatMessage>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_publicKey, _encode(data));
  }

  Future<void> saveDm(Map<String, List<ChatMessage>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dmKey, _encode(data));
  }

  String _encode(Map<String, List<ChatMessage>> data) {
    final mapped = data.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList(growable: false)));
    return jsonEncode(mapped);
  }

  Map<String, List<ChatMessage>> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return <String, List<ChatMessage>>{};
    final map = (jsonDecode(raw) as Map<String, dynamic>);
    return map.map((key, value) {
      final list = (value as List<dynamic>)
          .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
      return MapEntry(key, list);
    });
  }
}

class AppController extends StateNotifier<AppViewState> {
  AppController(this._ble, this._security, this._sync) : super(AppViewState.initial) {
    _bootstrap();
  }

  final BleTransport _ble;
  final SecurityService _security;
  final SyncService _sync;
  final _uuid = const Uuid();

  StreamSubscription<BleTransportState>? _bleStateSub;
  StreamSubscription<List<BlePeer>>? _peerSub;

  Future<void> _bootstrap() async {
    try {
      final identity = await _security.ensureIdentity();
      if (!mounted) return;
      state = state.copyWith(hasIdentity: true, identityLabel: identity.identityId.substring(0, 8));
      _bleStateSub = _ble.watchState().listen((s) {
        if (!mounted) return;
        state = state.copyWith(bleState: s);
      });
      _peerSub = _ble.watchPeers().listen((list) {
        if (!mounted) return;
        state = state.copyWith(peers: list.map(AppPeer.fromBle).toList(growable: false));
      });
      await _ble.start();
      if (!mounted) return;
      unawaited(_sync.runOnce());
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: e.toString());
    }
  }

  void setAlias(String alias) {
    final clean = alias.trim();
    if (clean.isEmpty) return;
    state = state.copyWith(identityLabel: clean);
  }

  void setRadius(int radiusKm) => state = state.copyWith(radiusKm: radiusKm.clamp(1, 200));

  void setOnlineMode(bool enabled) => state = state.copyWith(isOnlineMode: enabled);

  void setTab(AppRouteTab tab) => state = state.copyWith(tab: tab);

  void openDm(String peerId) => state = state.copyWith(activeDmPeerId: peerId);

  void closeDm() => state = state.copyWith(activeDmPeerId: null);

  void updateLifecycle(AppLifecycleStatus lifecycle) {
    if (!mounted) return;
    state = state.copyWith(lifecycle: lifecycle);
    if (lifecycle == AppLifecycleStatus.background) {
      unawaited(_ble.stop());
    } else {
      unawaited(_ble.start());
    }
  }

  ChatMessage buildOutgoingMessage(String text, {String? peerId, ChatMessageType type = ChatMessageType.text, String? mediaPath}) {
    return ChatMessage(
      id: _uuid.v4(),
      sender: state.identityLabel,
      text: text,
      createdAt: DateTime.now(),
      roomKey: state.currentRoomKey,
      radiusKm: state.radiusKm,
      type: type,
      isMine: true,
      peerId: peerId,
      mediaPath: mediaPath,
    );
  }

  @override
  void dispose() {
    _bleStateSub?.cancel();
    _peerSub?.cancel();
    super.dispose();
  }
}

class InMemoryLocalSyncRepository implements LocalSyncRepository {
  final Map<String, SyncMessage> _storage = <String, SyncMessage>{};

  @override
  Future<bool> exists(String messageId) async => _storage.containsKey(messageId);

  @override
  Future<List<SyncMessage>> getPendingMessages() async {
    return _storage.values.where((m) => m.status == SyncDeliveryStatus.pending).toList();
  }

  @override
  Future<void> markStatus(String messageId, SyncDeliveryStatus status) async {
    final item = _storage[messageId];
    if (item == null) return;
    _storage[messageId] = item.copyWith(status: status, updatedAtMs: DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Future<void> upsertFromRemote(List<SyncMessage> messages) async {
    for (final m in messages) {
      _storage[m.id] = m;
    }
  }
}

class InMemoryRemoteSyncDataSource implements RemoteSyncDataSource {
  final Map<String, SyncMessage> _storage = <String, SyncMessage>{};

  @override
  Future<List<SyncMessage>> pullMessages({required int sinceUpdatedAtMs}) async {
    return _storage.values.where((m) => m.updatedAtMs > sinceUpdatedAtMs).toList();
  }

  @override
  Future<void> pushMessages(List<SyncMessage> messages) async {
    for (final m in messages) {
      _storage[m.id] = m;
    }
  }
}
