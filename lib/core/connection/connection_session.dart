import '../discovery/device_info.dart';

enum SessionState { idle, connecting, pendingApproval, connected, rejected, failed, closed }

class ConnectionSession {
  ConnectionSession({
    required this.sessionId,
    required this.remoteDevice,
    required this.initiator,
    this.state = SessionState.idle,
  });

  final String sessionId;
  final DeviceInfo remoteDevice;
  final bool initiator;
  SessionState state;

  void setState(SessionState next) => state = next;
}
