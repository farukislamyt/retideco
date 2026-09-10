import 'package:flutter_test/flutter_test.dart';
import 'package:retideco/core/connection/connection_protocol.dart';

void main() {
  test('connection request contains protocol and session identity', () {
    final message = connectionRequestMessage(
      sessionId: 'session-123',
      deviceId: 'device-123',
      deviceName: 'Test Device',
    );

    expect(message['protocol'], connectionProtocol);
    expect(message['version'], connectionProtocolVersion);
    expect(message['type'], 'connection_request');
    expect(message['sessionId'], 'session-123');
    expect(message['deviceId'], 'device-123');
  });

  test('approval can explicitly accept or reject a session', () {
    expect(approvalMessage(sessionId: 's1', accepted: true)['accepted'], isTrue);
    expect(
      approvalMessage(sessionId: 's2', accepted: false, reason: 'Busy')['reason'],
      'Busy',
    );
  });
}
