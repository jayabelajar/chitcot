import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bluemesh_chat/core/models/mesh_packet.dart';
import 'package:bluemesh_chat/features/ble/ble_transport.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

class BleTransportImpl implements BleTransport {
  BleTransportImpl({BlePacketCodec? codec}) : _codec = codec ?? BlePacketCodec();

  final BlePacketCodec _codec;
  final _state = StreamController<BleTransportState>.broadcast();
  final _peers = StreamController<List<BlePeer>>.broadcast();
  final _incoming = StreamController<BleInbound>.broadcast();

  BleTransportState _current = BleTransportState.idle;
  List<BlePeer> _knownPeers = const [];

  @override
  Stream<BleTransportState> watchState() => _state.stream;

  @override
  Stream<List<BlePeer>> watchPeers() => _peers.stream;

  @override
  Stream<BleInbound> watchIncoming() => _incoming.stream;

  @override
  Future<void> start() async {
    try {
      _setState(BleTransportState.scanning);
      await _ensurePrerequisites();

      await FlutterBluePlus.stopScan();
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
      final scanResults = await FlutterBluePlus.scanResults.first;

      _knownPeers = scanResults
          .map(
            (r) => BlePeer(
              id: r.device.remoteId.str,
              name: r.advertisementData.advName.isNotEmpty ? r.advertisementData.advName : (r.device.platformName.isNotEmpty ? r.device.platformName : 'Unknown Device'),
              rssi: r.rssi,
            ),
          )
          .toList(growable: false);
      _peers.add(_knownPeers);

      _setState(BleTransportState.advertising);
      _setState(BleTransportState.connected);
    } catch (_) {
      _setState(BleTransportState.error);
      rethrow;
    }
  }

  Future<void> _ensurePrerequisites() async {
    if (Platform.isAndroid) {
      final btScan = await ph.Permission.bluetoothScan.request();
      final btConnect = await ph.Permission.bluetoothConnect.request();
      final location = await ph.Permission.locationWhenInUse.request();
      if (!btScan.isGranted || !btConnect.isGranted || !location.isGranted) {
        throw StateError('Izin Bluetooth/Lokasi ditolak. Mohon izinkan di dialog permission.');
      }

      final locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!locationServiceEnabled) {
        await Geolocator.openLocationSettings();
        throw StateError('Layanan lokasi belum aktif. Aktifkan lokasi lalu buka app lagi.');
      }
    }

    if (Platform.isIOS) {
      final bt = await ph.Permission.bluetooth.request();
      final location = await ph.Permission.locationWhenInUse.request();
      if (!bt.isGranted || !location.isGranted) {
        throw StateError('Izin Bluetooth/Lokasi ditolak. Mohon izinkan di Settings.');
      }
    }

    var adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on && Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
      adapterState = await FlutterBluePlus.adapterState.first;
    }

    if (adapterState != BluetoothAdapterState.on) {
      throw StateError('Bluetooth belum aktif. Aktifkan Bluetooth untuk lanjut.');
    }
  }

  @override
  Future<void> stop() async {
    await FlutterBluePlus.stopScan();
    _knownPeers = const [];
    _peers.add(_knownPeers);
    _setState(BleTransportState.idle);
  }

  @override
  Future<void> send(String peerId, MeshPacket packet) async {
    if (_current != BleTransportState.connected) {
      _setState(BleTransportState.retrying);
      throw StateError('BLE transport is not connected');
    }
    final bytes = _codec.encode(packet);
    if (bytes.length > 512) {
      throw const FormatException('Packet exceeds safe BLE payload budget');
    }
  }

  void injectInbound(String fromPeerId, List<int> bytes) {
    _incoming.add(BleInbound(fromPeerId: fromPeerId, bytes: _asUint8(bytes)));
  }

  void updatePeers(List<BlePeer> peers) {
    _knownPeers = peers;
    _peers.add(_knownPeers);
  }

  void dispose() {
    _state.close();
    _peers.close();
    _incoming.close();
  }

  void _setState(BleTransportState next) {
    _current = next;
    _state.add(next);
  }

  static Uint8List _asUint8(List<int> data) => Uint8List.fromList(data.map((e) => e & 0xFF).toList(growable: false));
}
