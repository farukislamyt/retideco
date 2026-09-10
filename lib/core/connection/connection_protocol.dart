import 'dart:convert';

const connectionProtocol = 'retideco-connection';
const connectionProtocolVersion = 1;

Map<String, dynamic> helloMessage({
  required String sessionId,
  required String deviceId,
}) => {
      'protocol': connectionProtocol,
      'version': connectionProtocolVersion,
      'type': 'hello',
      'sessionId': sessionId,
      'deviceId': deviceId,
    };

Map<String, dynamic> connectionRequestMessage({
  required String sessionId,
  required String deviceId,
  required String deviceName,
}) => {
      'protocol': connectionProtocol,
      'version': connectionProtocolVersion,
      'type': 'connection_request',
      'sessionId': sessionId,
      'deviceId': deviceId,
      'deviceName': deviceName,
    };

Map<String, dynamic> approvalMessage({
  required String sessionId,
  required bool accepted,
  String? reason,
}) => {
      'protocol': connectionProtocol,
      'version': connectionProtocolVersion,
      'type': 'connection_response',
      'sessionId': sessionId,
      'accepted': accepted,
      if (reason != null) 'reason': reason,
    };

String encodeMessage(Map<String, dynamic> message) => '${jsonEncode(message)}\n';
