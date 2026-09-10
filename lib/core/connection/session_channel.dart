import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Bidirectional JSON-line channel used after a connection is approved.
///
/// The channel is intentionally transport-focused: media/WebRTC signaling
/// messages can flow through it without coupling the connection layer to media.
class SessionChannel {
  SessionChannel._(this.socket) {
    _subscription = socket
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleLine, onError: _handleError, onDone: _handleDone);
  }

  final Socket socket;
  final _messagesController = StreamController<Map<String, dynamic>>.broadcast();
  late final StreamSubscription<String> _subscription;
  bool _closed = false;

  factory SessionChannel.fromSocket(Socket socket) => SessionChannel._(socket);

  Stream<Map<String, dynamic>> get messages => _messagesController.stream;
  bool get isClosed => _closed;

  Future<void> send(Map<String, dynamic> message) async {
    if (_closed) throw StateError('Session channel is closed.');
    socket.write('${jsonEncode(message)}\n');
    await socket.flush();
  }

  void _handleLine(String line) {
    if (line.trim().isEmpty || _closed) return;
    try {
      final decoded = jsonDecode(line);
      if (decoded is Map<String, dynamic>) {
        _messagesController.add(decoded);
      } else {
        _messagesController.addError(
          const FormatException('Connection message must be a JSON object.'),
        );
      }
    } catch (error, stackTrace) {
      _messagesController.addError(error, stackTrace);
    }
  }

  void _handleError(Object error, StackTrace stackTrace) {
    if (!_closed) _messagesController.addError(error, stackTrace);
  }

  void _handleDone() {
    _closeController();
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _subscription.cancel();
    socket.destroy();
    await _messagesController.close();
  }

  void _closeController() {
    if (_closed) return;
    _closed = true;
    _messagesController.close();
  }
}
