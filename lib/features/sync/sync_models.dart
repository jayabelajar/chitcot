enum SyncDeliveryStatus { pending, relayed, delivered, failed }

enum SyncRunState { idle, running, succeeded, failed }

class SyncMessage {
  const SyncMessage({
    required this.id,
    required this.ciphertext,
    required this.status,
    required this.updatedAtMs,
    this.receiverId,
  });

  final String id;
  final String? receiverId;
  final String ciphertext;
  final SyncDeliveryStatus status;
  final int updatedAtMs;

  SyncMessage copyWith({
    SyncDeliveryStatus? status,
    int? updatedAtMs,
  }) {
    return SyncMessage(
      id: id,
      receiverId: receiverId,
      ciphertext: ciphertext,
      status: status ?? this.status,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }
}

class SyncState {
  const SyncState({
    required this.runState,
    required this.attempt,
    this.lastError,
    this.pushed = 0,
    this.pulled = 0,
  });

  final SyncRunState runState;
  final int attempt;
  final String? lastError;
  final int pushed;
  final int pulled;

  SyncState copyWith({
    SyncRunState? runState,
    int? attempt,
    String? lastError,
    int? pushed,
    int? pulled,
  }) {
    return SyncState(
      runState: runState ?? this.runState,
      attempt: attempt ?? this.attempt,
      lastError: lastError,
      pushed: pushed ?? this.pushed,
      pulled: pulled ?? this.pulled,
    );
  }

  static const idle = SyncState(runState: SyncRunState.idle, attempt: 0);
}
