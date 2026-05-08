import 'package:bluemesh_chat/core/models/mesh_packet.dart';
import 'package:bluemesh_chat/features/mesh/mesh_engine.dart';
import 'package:bluemesh_chat/features/mesh/mesh_engine_impl.dart';
import 'package:bluemesh_chat/features/mesh/relay_decision.dart';
import 'package:flutter_test/flutter_test.dart';

class _SeenStore implements SeenMessageStore {
  final Set<String> _seen = <String>{};

  @override
  Future<bool> contains(String messageId) async => _seen.contains(messageId);

  @override
  Future<void> markSeen(String messageId) async => _seen.add(messageId);
}

class _RelayStore implements RelayQueueStore {
  final List<MeshPacket> queued = <MeshPacket>[];

  @override
  Future<void> enqueue(MeshPacket packet, {required DateTime expiresAt}) async {
    queued.add(packet);
  }
}

MeshPacket _packet({required String id, int ttl = 3, int hop = 0}) {
  return MeshPacket(
    messageId: id,
    senderId: 'A',
    ttl: ttl,
    hopCount: hop,
    payload: const [1, 2, 3],
    type: PacketType.publicMessage,
  );
}

void main() {
  test('drops duplicate message', () async {
    final seen = _SeenStore();
    final relay = _RelayStore();
    final engine = MeshEngineImpl(seenStore: seen, relayQueueStore: relay);

    await engine.processIncoming(packet: _packet(id: 'm1'), fromPeerId: 'peer-1', isFinalRecipient: false);
    final result = await engine.processIncoming(
      packet: _packet(id: 'm1'),
      fromPeerId: 'peer-2',
      isFinalRecipient: false,
    );

    expect(result.decision.action, RelayAction.drop);
    expect(relay.queued.length, 1);
  });

  test('consumes only when ttl exhausted', () async {
    final engine = MeshEngineImpl(seenStore: _SeenStore(), relayQueueStore: _RelayStore());
    final result = await engine.processIncoming(
      packet: _packet(id: 'm2', ttl: 0),
      fromPeerId: 'peer-1',
      isFinalRecipient: false,
    );

    expect(result.decision.action, RelayAction.consumeOnly);
    expect(result.decision.reason, 'ttl_exhausted');
  });

  test('relays eligible packet and decrements ttl', () async {
    final relay = _RelayStore();
    final engine = MeshEngineImpl(seenStore: _SeenStore(), relayQueueStore: relay);

    final result = await engine.processIncoming(
      packet: _packet(id: 'm3', ttl: 4, hop: 1),
      fromPeerId: 'peer-1',
      isFinalRecipient: false,
    );

    expect(result.decision.action, RelayAction.consumeAndRelay);
    expect(result.relayPacket?.ttl, 3);
    expect(result.relayPacket?.hopCount, 2);
    expect(relay.queued.length, 1);
  });
}
