import 'package:bluemesh_chat/features/security/security_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encrypt/decrypt happy path between two identities', () async {
    final alice = SecurityServiceImpl(keyStore: InMemoryLocalKeyStore());
    final bob = SecurityServiceImpl(keyStore: InMemoryLocalKeyStore());

    final aliceId = await alice.ensureIdentity();
    final bobId = await bob.ensureIdentity();

    final envelope = await alice.encryptDirectMessage(
      messageId: 'msg-1',
      plaintext: 'hello bob',
      receiverX25519PublicKey: bobId.x25519PublicKey,
    );

    final clear = await bob.decryptDirectMessage(
      envelope: envelope,
      senderX25519PublicKey: aliceId.x25519PublicKey,
    );

    expect(clear, 'hello bob');
  });

  test('tampered envelope fails verification', () async {
    final alice = SecurityServiceImpl(keyStore: InMemoryLocalKeyStore());
    final bob = SecurityServiceImpl(keyStore: InMemoryLocalKeyStore());

    final bobId = await bob.ensureIdentity();
    final envelope = await alice.encryptDirectMessage(
      messageId: 'msg-2',
      plaintext: 'secure payload',
      receiverX25519PublicKey: bobId.x25519PublicKey,
    );

    final tampered = envelope.copyWith(ciphertext: envelope.ciphertext.substring(1));

    await expectLater(
      () => bob.verifyEnvelope(tampered),
      throwsA(isA<FormatException>()),
    );
  });
}
