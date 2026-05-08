import 'package:bluemesh_chat/core/models/mesh_packet.dart';
import 'package:bluemesh_chat/features/mesh/mesh_engine.dart';
import 'package:bluemesh_chat/features/mesh/relay_decision.dart';

class MeshEngineImpl implements MeshEngine {
  MeshEngineImpl({
    required SeenMessageStore seenStore,
    required RelayQueueStore relayQueueStore,
    this.maxHop = 10,
  })  : _seenStore = seenStore,
        _relayQueueStore = relayQueueStore;

  final SeenMessageStore _seenStore;
  final RelayQueueStore _relayQueueStore;
  final int maxHop;

  @override
  Future<MeshProcessResult> processIncoming({
    required MeshPacket packet,
    required String fromPeerId,
    required bool isFinalRecipient,
  }) async {
    if (await _seenStore.contains(packet.messageId)) {
      return const MeshProcessResult(
        decision: RelayDecision(action: RelayAction.drop, reason: 'duplicate_message'),
      );
    }

    await _seenStore.markSeen(packet.messageId);

    if (packet.ttl <= 0) {
      return const MeshProcessResult(
        decision: RelayDecision(action: RelayAction.consumeOnly, reason: 'ttl_exhausted'),
      );
    }

    if (packet.hopCount >= maxHop) {
      return const MeshProcessResult(
        decision: RelayDecision(action: RelayAction.consumeOnly, reason: 'hop_limit_reached'),
      );
    }

    if (isFinalRecipient) {
      return const MeshProcessResult(
        decision: RelayDecision(action: RelayAction.consumeOnly, reason: 'final_recipient'),
      );
    }

    final relayPacket = packet.copyWith(ttl: packet.ttl - 1, hopCount: packet.hopCount + 1);
    await _relayQueueStore.enqueue(
      relayPacket,
      expiresAt: DateTime.now().add(Duration(minutes: relayPacket.ttl.clamp(1, 60))),
    );

    return MeshProcessResult(
      decision: const RelayDecision(action: RelayAction.consumeAndRelay, reason: 'relay_eligible'),
      relayPacket: relayPacket,
    );
  }
}
