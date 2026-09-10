import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../discovery/device_info.dart';
import 'connection_protocol.dart';
import 'session_channel.dart';

class PendingConnection {
  PendingConnection({
    required this.sessionId,
    required this.deviceId,
    required this.deviceName,
    required this.socket,
    required this.subscription,
  });

  final String sessionId;
  final String deviceId;
  final String deviceName;
  final Socket socket;
  final StreamSubscription<String> subscription;
}

class ConnectionService {
  ConnectionService({this.port = 45822});

  final int port;
  final _pendingController = StreamController<PendingConnection>.broadcast();
  final _connectionController = StreamController<SessionChannel>.broadcast();
  final _random = Random.secure();

  ServerSocket? _server;

  Stream<PendingConnection> get pendingConnections => _pendingController.stream;
  Stream<SessionChannel> get connections => _connectionController.stream;
  bool get isRunning => _server != null;

  Future<int> start() async {
    if (_server != null) return _server!.port;
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, port, shared: true);
    _server!.listen(_handleSocket, onError: (_) {});
    return _server!.port;
  }

  String createSessionId() =>
      '${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}-${_random.nextInt(1 << 32).toRadixString(36)}';

  Future<SessionChannel> requestConnection({
    required DeviceInfo device,
    required String localDeviceId,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final address = device.address;
    if (address == null || address.isEmpty || device.port <= 0) {
      throw ArgumentError('The discovered device has no usable connection endpoint.');
    }

    final socket = await Socket.connect(address, device.port, timeout: timeout);
    final sessionId = createSessionId();
    socket.write(encodeMessage(connectionRequestMessage(
      sessionId: sessionId,
      deviceId: localDeviceId,
      deviceName: Platform.localHostname,
    )));
    await socket.flush();

    final completer = Completer<SessionChannel>();
    late StreamSubscription<String> subscription;
    subscription = socket
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      try {
        final message = jsonDecode(line);
        if (message is! Map<String, dynamic> || message['sessionId'] != sessionId) return;
        if (message['type'] != 'connection_response') return;
        if (message['accepted'] == true && !completer.isCompleted) {
          completer.complete(SessionChannel.fromSocket(socket));
        } else if (message['accepted'] == false && !completer.isCompleted) {
          completer.completeError(
            StateError(message['reason']?.toString() ?? 'Connection rejected'),
          );
        }
      } catch (_) {
        if (!completer.isCompleted) {
          completer.completeError(const FormatException('Invalid connection response'));
        }
      }
    }, onError: (Object error, StackTrace stack) {
      if (!completer.isCompleted) completer.completeError(error, stack);
    });

    try {
      return await completer.future.timeout(timeout);
    } catch (_) {
      socket.destroy();
      rethrow;
    } finally {
      await subscription.cancel();
    }
  }

  Future<SessionChannel> approve(PendingConnection pending) async {
    pending.socket.write(encodeMessage(approvalMessage(
      sessionId: pending.sessionId,
      accepted: true,
    )));
    await pending.socket.flush();
    await pending.subscription.cancel();
    final channel = SessionChannel.fromSocket(pending.socket);
    _connectionController.add(channel);
    return channel;
  }

  Future<void> reject(PendingConnection pending, {String reason = 'Rejected by host'}) async {
    pending.socket.write(encodeMessage(approvalMessage(
      sessionId: pending.sessionId,
      accepted: false,
      reason: reason,
    )));
    await pending.socket.flush();
    await pending.subscription.cancel();
    pending.socket.destroy();
  }

  void _handleSocket(Socket socket) {
    late StreamSubscription<String> subscription;
    subscription = socket
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      if (line.trim().isEmpty) return;
      try {
        final message = jsonDecode(line);
        if (message is! Map<String, dynamic> ||
            message['protocol'] != connectionProtocol ||
            message['version'] != connectionProtocolVersion ||
            message['type'] != 'connection_request') {
          socket.destroy();
          return;
        }
        final sessionId = message['sessionId'] as String?;
        final deviceId = message['deviceId'] as String?;
        final deviceName = message['deviceName'] as String?;
        if (sessionId == null || deviceId == null || deviceName == null) {
          socket.destroy();
          return;
        }
        _pendingController.add(PendingConnection(
          sessionId: sessionId,
          deviceId: deviceId,
          deviceName: deviceName,
          socket: socket,
          subscription: subscription,
        ));
        subscription.pause();
      } catch (_) {
        socket.destroy();
      }
    }, onError: (_) => socket.destroy());
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;
  }

  Future<void> dispose() async {
    await stop();
    await _pendingController.close();
    await _connectionController.close();
  }
}
