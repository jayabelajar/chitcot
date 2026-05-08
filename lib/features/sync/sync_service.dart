import 'dart:async';

import 'package:bluemesh_chat/features/sync/sync_models.dart';

abstract class LocalSyncRepository {
  Future<List<SyncMessage>> getPendingMessages();
  Future<void> upsertFromRemote(List<SyncMessage> messages);
  Future<void> markStatus(String messageId, SyncDeliveryStatus status);
  Future<bool> exists(String messageId);
}

abstract class RemoteSyncDataSource {
  Future<void> pushMessages(List<SyncMessage> messages);
  Future<List<SyncMessage>> pullMessages({required int sinceUpdatedAtMs});
}

abstract class SyncService {
  Stream<SyncState> watchState();
  Future<void> runOnce();
}

class SyncServiceImpl implements SyncService {
  SyncServiceImpl({
    required LocalSyncRepository local,
    required RemoteSyncDataSource remote,
    this.maxRetries = 3,
    this.baseRetryDelayMs = 300,
  })  : _local = local,
        _remote = remote;

  final LocalSyncRepository _local;
  final RemoteSyncDataSource _remote;
  final int maxRetries;
  final int baseRetryDelayMs;

  final _stateController = StreamController<SyncState>.broadcast();
  SyncState _state = SyncState.idle;
  int _lastPulledAtMs = 0;

  @override
  Stream<SyncState> watchState() => _stateController.stream;

  @override
  Future<void> runOnce() async {
    _emit(_state.copyWith(runState: SyncRunState.running, lastError: null));
    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        _emit(_state.copyWith(attempt: attempt));

        final pending = await _local.getPendingMessages();
        if (pending.isNotEmpty) {
          await _remote.pushMessages(pending);
          for (final msg in pending) {
            await _local.markStatus(msg.id, SyncDeliveryStatus.delivered);
          }
        }

        final pulled = await _remote.pullMessages(sinceUpdatedAtMs: _lastPulledAtMs);
        final deduped = <SyncMessage>[];
        for (final msg in pulled) {
          if (!await _local.exists(msg.id)) {
            deduped.add(msg);
          }
        }

        if (deduped.isNotEmpty) {
          await _local.upsertFromRemote(deduped);
          _lastPulledAtMs = deduped.map((e) => e.updatedAtMs).reduce((a, b) => a > b ? a : b);
        }

        _emit(_state.copyWith(
          runState: SyncRunState.succeeded,
          pushed: pending.length,
          pulled: deduped.length,
          lastError: null,
        ));
        return;
      } catch (e) {
        if (attempt == maxRetries) {
          _emit(_state.copyWith(runState: SyncRunState.failed, lastError: e.toString()));
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: baseRetryDelayMs * attempt));
      }
    }
  }

  void _emit(SyncState next) {
    _state = next;
    _stateController.add(next);
  }
}
