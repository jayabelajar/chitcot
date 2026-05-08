import 'package:bluemesh_chat/features/ble/ble_transport.dart';

class AppPeer {
  const AppPeer({required this.id, required this.name, this.rssi});

  final String id;
  final String name;
  final int? rssi;

  factory AppPeer.fromBle(BlePeer peer) {
    return AppPeer(id: peer.id, name: peer.name, rssi: peer.rssi);
  }
}

enum AppRouteTab { chat, peers, profile }

enum AppLifecycleStatus { foreground, background }

class AppViewState {
  const AppViewState({
    required this.hasIdentity,
    required this.identityLabel,
    required this.bleState,
    required this.peers,
    required this.tab,
    required this.lifecycle,
    required this.radiusKm,
    required this.isOnlineMode,
    this.activeDmPeerId,
    this.error,
  });

  final bool hasIdentity;
  final String identityLabel;
  final BleTransportState bleState;
  final List<AppPeer> peers;
  final AppRouteTab tab;
  final AppLifecycleStatus lifecycle;
  final int radiusKm;
  final bool isOnlineMode;
  final String? activeDmPeerId;
  final String? error;

  bool get isBleReady => bleState == BleTransportState.connected;
  String get currentRoomKey => isOnlineMode ? 'online:global' : 'radius:$radiusKm-km';
  String get currentRoomLabel => isOnlineMode ? 'ONLINE GLOBAL' : 'RADIUS $radiusKm KM';

  AppViewState copyWith({
    bool? hasIdentity,
    String? identityLabel,
    BleTransportState? bleState,
    List<AppPeer>? peers,
    AppRouteTab? tab,
    AppLifecycleStatus? lifecycle,
    int? radiusKm,
    bool? isOnlineMode,
    String? activeDmPeerId,
    String? error,
    bool clearError = false,
  }) {
    return AppViewState(
      hasIdentity: hasIdentity ?? this.hasIdentity,
      identityLabel: identityLabel ?? this.identityLabel,
      bleState: bleState ?? this.bleState,
      peers: peers ?? this.peers,
      tab: tab ?? this.tab,
      lifecycle: lifecycle ?? this.lifecycle,
      radiusKm: radiusKm ?? this.radiusKm,
      isOnlineMode: isOnlineMode ?? this.isOnlineMode,
      activeDmPeerId: activeDmPeerId ?? this.activeDmPeerId,
      error: clearError ? null : (error ?? this.error),
    );
  }

  static const initial = AppViewState(
    hasIdentity: false,
    identityLabel: 'Anon',
    bleState: BleTransportState.idle,
    peers: <AppPeer>[],
    tab: AppRouteTab.chat,
    lifecycle: AppLifecycleStatus.foreground,
    radiusKm: 10,
    isOnlineMode: false,
  );
}
