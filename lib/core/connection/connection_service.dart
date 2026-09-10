import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../discovery/device_info.dart';
import 'connection_protocol.dart';

class PendingConnection {
  PendingConnection({
    required this.sessionId,
    required this.deviceId,
    required this.deviceName,
    required this.socket,
  });

  final String sessionId;
  final String deviceId;
  final String deviceName;
  final Socket socket;
}

class ConnectionService {
  ConnectionService({this.port = 45822});

  final int port;
  final _pendingController = StreamController<PendingConnection>.broadcast();
  final _connectionController = StreamController<Socket>.broadcast();
  final _random = Random.secure();

  ServerSocket? _server;

  Stream<PendingConnection> get pendingConnections => _pendingController.stream;
  Stream<Socket> get connections => _connectionController.stream;
  bool get isRunning => _server != null;

  Future<int> start() async {
    if (_server != null) return _server!.port;
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, port, shared: true);
    _server!.listen(_handleSocket, onError: (_) {});
    return _server!.port;
  }

  String createSessionId() =>
      '${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}-${_random.nextInt(1 << 32).toRadixString(36)}';

  Future<Socket> requestConnection({
    required DeviceInfo device,
    required String localDeviceId,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final socket = await Socket.connect(
      device.address,
      device.port,
      timeout: timeout,
    );
    final sessionId = createSessionId();
    socket.write(encodeMessage(connectionRequestMessage(
      sessionId: sessionId,
      deviceId: localDeviceId,
      deviceName: Platform.localHostname,
    )));
    await socket.flush();

    final completer = Completer<Socket>();
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
          completer.complete(socket);
        } else if (message['accepted'] == false && !completer.isCompleted) {
          completer.completeError(StateError(message['reason'] ?? 'Connection rejected'));
        }
      } catch (_) {
        if (!completer.isCompleted) completer.completeError(const FormatException('Invalid response'));
      }
    }, onError: (Object error, StackTrace stack) {
      if (!completer.isCompleted) completer.completeError(error, stack);
    });

    try {
      return await completer.future.timeout(timeout);
    } finally {
      await subscription.cancel();
      if (completer.isCompleted && !completer.future.isCompleted) socket.destroy();
    }
  }

  Future<void> approve(PendingConnection pending) async {
    pending.socket.write(encodeMessage(approvalMessage(
      sessionId: pending.sessionId,
      accepted: true,
    )));
    await pending.socket.flush();
    _connectionController.add(pending.socket);
  }

  Future<void> reject(PendingConnection pending, {String reason = 'Rejected by host'}) async {
    pending.socket.write(encodeMessage(approvalMessage(
      sessionId: pending.sessionId,
      accepted: false,
      reason: reason,
    )));
    await pending.socket.flush();
    pending.socket.destroy();
  }

  void _handleSocket(Socket socket) {
    final buffer = StringBuffer();
    late StreamSubscription<List<int>> subscription;
    subscription = socket.listen((data) {
      buffer.write(utf8.decode(data, allowMalformed: false));
      final text = buffer.toString();
      final lines = text.split('\n');
      buffer.clear();
      buffer.write(lines.removeLast());
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
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
          ));
          subscription.pause();
        } catch (_) {
          socket.destroy();
        }
      }
    }, onError: (_) => socket.destroy(), onDone: () {});
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
