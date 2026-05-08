import 'package:bluemesh_chat/features/security/security_models.dart';

abstract class LocalKeyStore {
  Future<IdentityKeyMaterial?> read();
  Future<void> write(IdentityKeyMaterial material);
}

abstract class SecurityService {
  Future<IdentityKeyMaterial> ensureIdentity();

  Future<EncryptedEnvelope> encryptDirectMessage({
    required String messageId,
    required String plaintext,
    required String receiverX25519PublicKey,
  });

  Future<String> decryptDirectMessage({
    required EncryptedEnvelope envelope,
    required String senderX25519PublicKey,
  });

  Future<bool> verifyEnvelope(EncryptedEnvelope envelope);
}
