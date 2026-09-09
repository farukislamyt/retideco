import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'device_info.dart';
import 'discovery_service.dart';

class UdpLanDiscoveryService implements DiscoveryService {
  UdpLanDiscoveryService({
    this.port = 45821,
    this.heartbeat = const Duration(seconds: 2),
    this.deviceTimeout = const Duration(seconds: 7),
  });

  static const protocol = 'retideco-discovery';
  static const version = 1;

  final int port;
  final Duration heartbeat;
  final Duration deviceTimeout;
  final Map<String, DeviceInfo> _devices = {};
  final _controller = StreamController<List<DeviceInfo>>.broadcast();

  RawDatagramSocket? _socket;
  Timer? _heartbeatTimer;
  Timer? _cleanupTimer;
  DeviceInfo? _advertisedDevice;

  @override
  Stream<List<DeviceInfo>> get devices => _controller.stream;

  @override
  Future<void> start() async {
    if (_socket != null) return;

    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port,
        reuseAddress: true, reusePort: true);
    _socket!
      ..broadcastEnabled = true
      ..listen(_handleDatagram, onError: (_) {});

    _cleanupTimer = Timer.periodic(const Duration(seconds: 2), (_) => _cleanup());
    _heartbeatTimer = Timer.periodic(heartbeat, (_) => _sendAdvertisement());
    await refresh();
  }

  @override
  Future<void> refresh() async {
    _sendAdvertisement();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _emit();
  }

  @override
  Future<void> advertise(DeviceInfo device) async {
    _advertisedDevice = device;
    if (_socket == null) await start();
    _sendAdvertisement();
  }

  @override
  Future<void> stopAdvertising() async {
    _advertisedDevice = null;
  }

  void _sendAdvertisement() {
    final socket = _socket;
    final device = _advertisedDevice;
    if (socket == null || device == null) return;

    final payload = jsonEncode({
      'protocol': protocol,
      'version': version,
      'device': device.toJson(),
    });
    final bytes = utf8.encode(payload);

    try {
      socket.send(bytes, InternetAddress('255.255.255.255'), port);
    } on SocketException {
      // A platform/network can reject broadcast. Discovery continues listening.
    }
  }

  void _handleDatagram(RawSocketEvent event) {
    final socket = _socket;
    if (socket == null) return;

    Datagram? datagram;
    while ((datagram = socket.receive()) != null) {
      final packet = datagram!;
      try {
        final decoded = jsonDecode(utf8.decode(packet.data));
        if (decoded is! Map<String, dynamic> ||
            decoded['protocol'] != protocol ||
            decoded['version'] != version) {
          continue;
        }

        final rawDevice = decoded['device'];
        if (rawDevice is! Map<String, dynamic>) continue;
        final device = DeviceInfo.fromJson(
          rawDevice,
          address: packet.address.address,
        );
        if (device.id.isEmpty || device.id == _advertisedDevice?.id) continue;

        _devices[device.id] = device;
        _emit();
      } catch (_) {
        // Ignore malformed or unrelated LAN packets.
      }
    }
  }

  void _cleanup() {
    final cutoff = DateTime.now().subtract(deviceTimeout);
    _devices.removeWhere((_, device) => device.lastSeen.isBefore(cutoff));
    _emit();
  }

  void _emit() {
    if (!_controller.isClosed) {
      final list = _devices.values.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _controller.add(List.unmodifiable(list));
    }
  }

  @override
  Future<void> stop() async {
    _heartbeatTimer?.cancel();
    _cleanupTimer?.cancel();
    _heartbeatTimer = null;
    _cleanupTimer = null;
    _socket?.close();
    _socket = null;
    _devices.clear();
    _emit();
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}
