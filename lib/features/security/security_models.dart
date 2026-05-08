import 'dart:convert';

class IdentityKeyMaterial {
  const IdentityKeyMaterial({
    required this.identityId,
    required this.x25519PublicKey,
    required this.x25519PrivateKey,
    required this.ed25519PublicKey,
    required this.ed25519PrivateKey,
    required this.createdAt,
  });

  final String identityId;
  final String x25519PublicKey;
  final String x25519PrivateKey;
  final String ed25519PublicKey;
  final String ed25519PrivateKey;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'identity_id': identityId,
        'x25519_public_key': x25519PublicKey,
        'x25519_private_key': x25519PrivateKey,
        'ed25519_public_key': ed25519PublicKey,
        'ed25519_private_key': ed25519PrivateKey,
        'created_at': createdAt.toIso8601String(),
      };

  String toRawJson() => jsonEncode(toJson());
}

class EncryptedEnvelope {
  const EncryptedEnvelope({
    required this.messageId,
    required this.senderIdentityId,
    required this.senderPublicKey,
    required this.nonce,
    required this.ciphertext,
    required this.mac,
    required this.signature,
    required this.createdAtMs,
  });

  final String messageId;
  final String senderIdentityId;
  final String senderPublicKey;
  final String nonce;
  final String ciphertext;
  final String mac;
  final String signature;
  final int createdAtMs;

  EncryptedEnvelope copyWith({
    String? nonce,
    String? ciphertext,
    String? mac,
    String? signature,
  }) {
    return EncryptedEnvelope(
      messageId: messageId,
      senderIdentityId: senderIdentityId,
      senderPublicKey: senderPublicKey,
      nonce: nonce ?? this.nonce,
      ciphertext: ciphertext ?? this.ciphertext,
      mac: mac ?? this.mac,
      signature: signature ?? this.signature,
      createdAtMs: createdAtMs,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'message_id': messageId,
        'sender_identity_id': senderIdentityId,
        'sender_public_key': senderPublicKey,
        'nonce': nonce,
        'ciphertext': ciphertext,
        'mac': mac,
        'signature': signature,
        'created_at_ms': createdAtMs,
      };
}
