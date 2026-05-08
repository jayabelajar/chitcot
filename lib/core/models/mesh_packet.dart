enum PacketType { publicMessage, directMessage, ack, control }

class MeshPacket {
  MeshPacket({
    required this.messageId,
    required this.senderId,
    this.receiverId,
    required this.ttl,
    required this.hopCount,
    required this.payload,
    required this.type,
    this.timestampMs,
  });

  final String messageId;
  final String senderId;
  final String? receiverId;
  final int ttl;
  final int hopCount;
  final List<int> payload;
  final PacketType type;
  final int? timestampMs;

  MeshPacket copyWith({
    int? ttl,
    int? hopCount,
    List<int>? payload,
    int? timestampMs,
  }) {
    return MeshPacket(
      messageId: messageId,
      senderId: senderId,
      receiverId: receiverId,
      ttl: ttl ?? this.ttl,
      hopCount: hopCount ?? this.hopCount,
      payload: payload ?? this.payload,
      type: type,
      timestampMs: timestampMs ?? this.timestampMs,
    );
  }
}
