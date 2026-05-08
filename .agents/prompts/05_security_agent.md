# AGENT PROMPT - Security

Gunakan konteks dari `00_master_context.md`.

## Misi
Rancang Security Layer untuk komunikasi anonim namun aman end-to-end.

## Cakupan
- Local keypair generation (Curve25519).
- Shared secret derivation untuk DM.
- Enkripsi payload (AES-GCM).
- Signature verification untuk integritas/authenticity.
- Key storage aman di device.
- Key rotation strategy.

## Yang Harus Dihasilkan
1. Skema handshake untuk pertukaran public key.
2. Format envelope terenkripsi (nonce, ciphertext, tag, sender_pubkey).
3. Prosedur encrypt/decrypt end-to-end.
4. Threat model singkat (MITM, replay, spam relay abuse).
5. Mitigasi tiap ancaman.
6. Test plan kriptografi (happy path + tampered payload).
