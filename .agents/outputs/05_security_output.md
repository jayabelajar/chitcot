# Output Eksekusi Prompt 05 - Security Layer

## Assumption
- Protokol DM memakai X25519 untuk shared secret, AES-256-GCM untuk enkripsi payload, dan Ed25519 untuk signature.
- Penyimpanan kunci saat ini memakai `InMemoryLocalKeyStore` sebagai placeholder; production wajib diganti secure storage.

## Skema Handshake
1. Tiap device generate identity lokal:
   - `x25519 keypair` untuk key agreement.
   - `ed25519 keypair` untuk signature.
2. Public key dibagikan saat peer discovery/handshake.
3. Pengirim derive shared secret dari private X25519 sendiri + public X25519 peer.
4. Penerima melakukan derivasi yang sama untuk dekripsi.

## Format Encrypted Envelope
- `message_id`
- `sender_identity_id`
- `sender_public_key` (Ed25519 public key)
- `nonce` (base64)
- `ciphertext` (base64)
- `mac` (base64)
- `signature` (base64, tanda tangan atas nonce+ciphertext+mac)
- `created_at_ms`

## Implementasi
- `lib/features/security/security_models.dart`
- `lib/features/security/security_service.dart`
- `lib/features/security/security_service_impl.dart`

## Threat Model Singkat + Mitigasi
- MITM saat pertukaran key: mitigasi dengan verifikasi identity fingerprint di fase UX lanjutan.
- Replay packet: gunakan `message_id` + `seen_messages` + timestamp window.
- Relay spam abuse: throttle relay + TTL + hop limit di mesh engine.
- Tampering payload: signature verification + AES-GCM MAC.

## Key Rotation Strategy
- Simpan `created_at` key material.
- Rotasi berkala (mis. 30-90 hari) dengan dual-publish public key sementara.
- Message baru pakai key baru, key lama dipakai sementara untuk backward decrypt.

## Test Plan Kriptografi
- Happy path Alice->Bob encrypt/decrypt berhasil.
- Tampered envelope gagal verifikasi/dekripsi.
- Key tidak cocok harus gagal decrypt.
