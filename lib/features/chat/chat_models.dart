enum ChatMessageType { text, image, audio }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.createdAt,
    required this.roomKey,
    required this.radiusKm,
    required this.type,
    this.isMine = false,
    this.peerId,
    this.mediaPath,
  });

  final String id;
  final String sender;
  final String text;
  final DateTime createdAt;
  final String roomKey;
  final int radiusKm;
  final ChatMessageType type;
  final bool isMine;
  final String? peerId;
  final String? mediaPath;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'roomKey': roomKey,
      'radiusKm': radiusKm,
      'type': type.name,
      'isMine': isMine,
      'peerId': peerId,
      'mediaPath': mediaPath,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      sender: json['sender'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      roomKey: json['roomKey'] as String,
      radiusKm: (json['radiusKm'] as num).toInt(),
      type: ChatMessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChatMessageType.text,
      ),
      isMine: json['isMine'] as bool? ?? false,
      peerId: json['peerId'] as String?,
      mediaPath: json['mediaPath'] as String?,
    );
  }
}
