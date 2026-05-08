import 'dart:async';
import 'dart:typed_data';

import 'package:bluemesh_chat/core/models/mesh_packet.dart';

enum BleTransportState { idle, scanning, advertising, connecting, connected, retrying, error }

class BlePeer {
  const BlePeer({required this.id, required this.name, this.rssi});

  final String id;
  final String name;
  final int? rssi;
}

class BleInbound {
  const BleInbound({required this.fromPeerId, required this.bytes});

  final String fromPeerId;
  final Uint8List bytes;
}

abstract class BleTransport {
  Stream<BleTransportState> watchState();
  Stream<List<BlePeer>> watchPeers();
  Stream<BleInbound> watchIncoming();

  Future<void> start();
  Future<void> stop();
  Future<void> send(String peerId, MeshPacket packet);
}

class BlePacketCodec {
  static const int _version = 1;

  Uint8List encode(MeshPacket packet) {
    final payload = Uint8List.fromList(packet.payload);
    final header = ByteData(8)
      ..setUint8(0, _version)
      ..setUint8(1, packet.type.index)
      ..setUint8(2, packet.ttl)
      ..setUint8(3, packet.hopCount)
      ..setUint16(4, payload.length)
      ..setUint16(6, _checksum(payload));
    final messageId = Uint8List.fromList(packet.messageId.codeUnits.take(36).toList());
    return Uint8List.fromList([...header.buffer.asUint8List(), ...messageId, 0, ...payload]);
  }

  MeshPacket decode(Uint8List bytes, {required String senderId}) {
    if (bytes.length < 10) {
      throw const FormatException('Invalid BLE packet');
    }
    final header = ByteData.sublistView(bytes, 0, 8);
    final version = header.getUint8(0);
    if (version != _version) {
      throw const FormatException('Unsupported packet version');
    }
    final type = PacketType.values[header.getUint8(1)];
    final ttl = header.getUint8(2);
    final hopCount = header.getUint8(3);
    final payloadLen = header.getUint16(4);
    final checksum = header.getUint16(6);
    final delimiter = bytes.indexOf(0, 8);
    if (delimiter < 0 || delimiter + 1 + payloadLen > bytes.length) {
      throw const FormatException('Corrupt packet body');
    }

    final messageId = String.fromCharCodes(bytes.sublist(8, delimiter));
    final payload = bytes.sublist(delimiter + 1, delimiter + 1 + payloadLen);
    if (_checksum(Uint8List.fromList(payload)) != checksum) {
      throw const FormatException('Checksum mismatch');
    }

    return MeshPacket(
      messageId: messageId,
      senderId: senderId,
      ttl: ttl,
      hopCount: hopCount,
      payload: payload,
      type: type,
    );
  }

  int _checksum(Uint8List data) => data.fold<int>(0, (sum, b) => (sum + b) & 0xFFFF);
}
