import 'dart:convert';

const connectionProtocol = 'retideco-connection';
const connectionProtocolVersion = 1;

Map<String, dynamic> helloMessage({required String sessionId, required String deviceId}) => {
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

Map<String, dynamic> mediaOfferMessage({
  required String sessionId,
  required String sdp,
}) => _mediaMessage('media_offer', sessionId, {'sdp': sdp});

Map<String, dynamic> mediaAnswerMessage({
  required String sessionId,
  required String sdp,
}) => _mediaMessage('media_answer', sessionId, {'sdp': sdp});

Map<String, dynamic> iceCandidateMessage({
  required String sessionId,
  required String candidate,
  String? sdpMid,
  int? sdpMLineIndex,
}) => _mediaMessage('ice_candidate', sessionId, {
      'candidate': candidate,
      if (sdpMid != null) 'sdpMid': sdpMid,
      if (sdpMLineIndex != null) 'sdpMLineIndex': sdpMLineIndex,
    });

Map<String, dynamic> mediaStopMessage({required String sessionId}) =>
    _mediaMessage('media_stop', sessionId, const {});

Map<String, dynamic> _mediaMessage(
  String type,
  String sessionId,
  Map<String, dynamic> payload,
) => {
      'protocol': connectionProtocol,
      'version': connectionProtocolVersion,
      'type': type,
      'sessionId': sessionId,
      ...payload,
    };

String encodeMessage(Map<String, dynamic> message) => '${jsonEncode(message)}\n';
