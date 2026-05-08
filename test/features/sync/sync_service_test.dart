import 'package:bluemesh_chat/features/sync/sync_models.dart';
import 'package:bluemesh_chat/features/sync/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _LocalRepo implements LocalSyncRepository {
  final Map<String, SyncMessage> _messages = <String, SyncMessage>{};

  @override
  Future<bool> exists(String messageId) async => _messages.containsKey(messageId);

  @override
  Future<List<SyncMessage>> getPendingMessages() async {
    return _messages.values.where((e) => e.status == SyncDeliveryStatus.pending).toList();
  }

  @override
  Future<void> markStatus(String messageId, SyncDeliveryStatus status) async {
    final msg = _messages[messageId];
    if (msg == null) return;
    _messages[messageId] = msg.copyWith(status: status, updatedAtMs: msg.updatedAtMs + 1);
  }

  @override
  Future<void> upsertFromRemote(List<SyncMessage> messages) async {
    for (final m in messages) {
      _messages[m.id] = m;
    }
  }
}

class _RemoteRepo implements RemoteSyncDataSource {
  _RemoteRepo({this.throwOnFirstPush = false});

  bool throwOnFirstPush;
  int pushCalls = 0;
  final List<SyncMessage> remoteStorage = <SyncMessage>[];

  @override
  Future<List<SyncMessage>> pullMessages({required int sinceUpdatedAtMs}) async {
    return remoteStorage.where((m) => m.updatedAtMs > sinceUpdatedAtMs).toList();
  }

  @override
  Future<void> pushMessages(List<SyncMessage> messages) async {
    pushCalls++;
    if (throwOnFirstPush && pushCalls == 1) {
      throw StateError('temporary offline');
    }
    remoteStorage.removeWhere((r) => messages.any((m) => m.id == r.id));
    remoteStorage.addAll(messages);
  }
}

void main() {
  test('runOnce pushes pending and marks delivered', () async {
    final local = _LocalRepo();
    await local.upsertFromRemote([
      const SyncMessage(
        id: 'm1',
        ciphertext: 'abc',
        status: SyncDeliveryStatus.pending,
        updatedAtMs: 1,
      ),
    ]);

    final remote = _RemoteRepo();
    final sync = SyncServiceImpl(local: local, remote: remote);

    await sync.runOnce();

    final pending = await local.getPendingMessages();
    expect(pending, isEmpty);
    expect(remote.remoteStorage.length, 1);
  });

  test('runOnce retries on transient failure', () async {
    final local = _LocalRepo();
    await local.upsertFromRemote([
      const SyncMessage(
        id: 'm2',
        ciphertext: 'xyz',
        status: SyncDeliveryStatus.pending,
        updatedAtMs: 2,
      ),
    ]);

    final remote = _RemoteRepo(throwOnFirstPush: true);
    final sync = SyncServiceImpl(local: local, remote: remote, maxRetries: 2, baseRetryDelayMs: 10);

    await sync.runOnce();

    expect(remote.pushCalls, 2);
  });
}
