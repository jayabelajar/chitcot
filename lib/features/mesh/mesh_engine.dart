import 'package:bluemesh_chat/core/models/mesh_packet.dart';
import 'package:bluemesh_chat/features/mesh/relay_decision.dart';

abstract class SeenMessageStore {
  Future<bool> contains(String messageId);
  Future<void> markSeen(String messageId);
}

abstract class RelayQueueStore {
  Future<void> enqueue(MeshPacket packet, {required DateTime expiresAt});
}

class MeshProcessResult {
  const MeshProcessResult({required this.decision, this.relayPacket});

  final RelayDecision decision;
  final MeshPacket? relayPacket;
}

abstract class MeshEngine {
  Future<MeshProcessResult> processIncoming({
    required MeshPacket packet,
    required String fromPeerId,
    required bool isFinalRecipient,
  });
}
