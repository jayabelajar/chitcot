import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:bluemesh_chat/features/security/security_models.dart';
import 'package:bluemesh_chat/features/security/security_service.dart';
import 'package:cryptography/cryptography.dart';
import 'package:uuid/uuid.dart';

class InMemoryLocalKeyStore implements LocalKeyStore {
  IdentityKeyMaterial? _material;

  @override
  Future<IdentityKeyMaterial?> read() async => _material;

  @override
  Future<void> write(IdentityKeyMaterial material) async {
    _material = material;
  }
}

class SecurityServiceImpl implements SecurityService {
  SecurityServiceImpl({
    required LocalKeyStore keyStore,
    X25519? x25519,
    Ed25519? ed25519,
    AesGcm? aesGcm,
    Uuid? uuid,
  })  : _keyStore = keyStore,
        _x25519 = x25519 ?? X25519(),
        _ed25519 = ed25519 ?? Ed25519(),
        _aesGcm = aesGcm ?? AesGcm.with256bits(),
        _uuid = uuid ?? const Uuid();

  final LocalKeyStore _keyStore;
  final X25519 _x25519;
  final Ed25519 _ed25519;
  final AesGcm _aesGcm;
  final Uuid _uuid;

  @override
  Future<IdentityKeyMaterial> ensureIdentity() async {
    final existing = await _keyStore.read();
    if (existing != null) return existing;

    final dh = await _x25519.newKeyPair();
    final dhPub = await dh.extractPublicKey();
    final dhPriv = await dh.extractPrivateKeyBytes();

    final signing = await _ed25519.newKeyPair();
    final signPub = await signing.extractPublicKey();
    final signPriv = await signing.extractPrivateKeyBytes();

    final material = IdentityKeyMaterial(
      identityId: _uuid.v4(),
      x25519PublicKey: _b64(dhPub.bytes),
      x25519PrivateKey: _b64(dhPriv),
      ed25519PublicKey: _b64(signPub.bytes),
      ed25519PrivateKey: _b64(signPriv),
      createdAt: DateTime.now().toUtc(),
    );

    await _keyStore.write(material);
    return material;
  }

  @override
  Future<EncryptedEnvelope> encryptDirectMessage({
    required String messageId,
    required String plaintext,
    required String receiverX25519PublicKey,
  }) async {
    final self = await ensureIdentity();
    final secretKey = await _deriveSharedSecret(
      ownPrivateKeyB64: self.x25519PrivateKey,
      peerPublicKeyB64: receiverX25519PublicKey,
    );

    final nonce = _randomNonce(12);
    final box = await _aesGcm.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
      aad: utf8.encode(messageId),
    );

    final signaturePayload = <int>[...nonce, ...box.cipherText, ...box.mac.bytes];
    final signature = await _signPayload(signaturePayload, self.ed25519PrivateKey);

    return EncryptedEnvelope(
      messageId: messageId,
      senderIdentityId: self.identityId,
      senderPublicKey: self.ed25519PublicKey,
      nonce: _b64(nonce),
      ciphertext: _b64(box.cipherText),
      mac: _b64(box.mac.bytes),
      signature: _b64(signature.bytes),
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  Future<String> decryptDirectMessage({
    required EncryptedEnvelope envelope,
    required String senderX25519PublicKey,
  }) async {
    final ok = await verifyEnvelope(envelope);
    if (!ok) {
      throw const FormatException('Envelope signature is invalid');
    }

    final self = await ensureIdentity();
    final secretKey = await _deriveSharedSecret(
      ownPrivateKeyB64: self.x25519PrivateKey,
      peerPublicKeyB64: senderX25519PublicKey,
    );

    final nonce = _b64d(envelope.nonce);
    final cipher = _b64d(envelope.ciphertext);
    final mac = Mac(_b64d(envelope.mac));

    final clear = await _aesGcm.decrypt(
      SecretBox(cipher, nonce: nonce, mac: mac),
      secretKey: secretKey,
      aad: utf8.encode(envelope.messageId),
    );

    return utf8.decode(clear);
  }

  @override
  Future<bool> verifyEnvelope(EncryptedEnvelope envelope) async {
    final payload = <int>[
      ..._b64d(envelope.nonce),
      ..._b64d(envelope.ciphertext),
      ..._b64d(envelope.mac),
    ];

    return _ed25519.verify(
      payload,
      signature: Signature(
        _b64d(envelope.signature),
        publicKey: SimplePublicKey(_b64d(envelope.senderPublicKey), type: KeyPairType.ed25519),
      ),
    );
  }

  Future<SecretKey> _deriveSharedSecret({
    required String ownPrivateKeyB64,
    required String peerPublicKeyB64,
  }) async {
    final own = SimpleKeyPairData(
      _b64d(ownPrivateKeyB64),
      publicKey: SimplePublicKey(const [], type: KeyPairType.x25519),
      type: KeyPairType.x25519,
    );
    final peer = SimplePublicKey(_b64d(peerPublicKeyB64), type: KeyPairType.x25519);
    final raw = await _x25519.sharedSecretKey(keyPair: own, remotePublicKey: peer);
    final rawBytes = await raw.extractBytes();
    final stretched = await Hkdf(hmac: Hmac.sha256(), outputLength: 32).deriveKey(
      secretKey: SecretKey(rawBytes),
      nonce: utf8.encode('bluemesh-dm-v1'),
      info: utf8.encode('aes256-gcm-key'),
    );
    return stretched;
  }

  Future<Signature> _signPayload(List<int> payload, String privateKeyB64) async {
    final self = await ensureIdentity();
    final key = SimpleKeyPairData(
      _b64d(privateKeyB64),
      publicKey: SimplePublicKey(_b64d(self.ed25519PublicKey), type: KeyPairType.ed25519),
      type: KeyPairType.ed25519,
    );
    return _ed25519.sign(payload, keyPair: key);
  }

  Uint8List _randomNonce(int length) {
    final rand = Random.secure();
    return Uint8List.fromList(List<int>.generate(length, (_) => rand.nextInt(256)));
  }

  String _b64(List<int> data) => base64Encode(data);
  Uint8List _b64d(String data) => Uint8List.fromList(base64Decode(data));
}
