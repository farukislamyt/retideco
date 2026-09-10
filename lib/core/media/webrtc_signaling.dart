import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../connection/connection_protocol.dart';
import '../connection/session_channel.dart';
import 'media_session.dart';
import 'webrtc_service.dart';

/// Coordinates SDP/ICE exchange over an already-approved ReTiDeCo session.
///
/// This class does not perform discovery or authentication. The caller is
/// responsible for creating an approved SessionChannel first.
class WebRtcSignaling {
  WebRtcSignaling({required this.channel, WebRtcService? webRtc})
      : _webRtc = webRtc ?? WebRtcService();

  final SessionChannel channel;
  final WebRtcService _webRtc;
  StreamSubscription<Map<String, dynamic>>? _subscription;
  final List<RTCIceCandidate> _pendingCandidates = [];
  bool _remoteDescriptionSet = false;
  bool _closed = false;

  final _remoteStreamController = StreamController<MediaStream>.broadcast();
  final _stateController = StreamController<RTCPeerConnectionState>.broadcast();

  Stream<MediaStream> get remoteStreams => _remoteStreamController.stream;
  Stream<RTCPeerConnectionState> get connectionStates => _stateController.stream;
  RTCPeerConnection? get peerConnection => _webRtc.peerConnection;

  Future<void> startPublisher(MediaSession session, MediaStream localStream) async {
    await _webRtc.addLocalTracks(localStream);
    final pc = _webRtc.peerConnection!;
    _configurePeerConnection(pc, session.sessionId);
    _listen(session.sessionId);
    session.setState(MediaSessionState.negotiating);
    final offer = await _webRtc.createOffer();
    await channel.send(mediaOfferMessage(
      sessionId: session.sessionId,
      sdp: offer.sdp ?? '',
    ));
    session.setState(MediaSessionState.publishing);
  }

  Future<void> startReceiver(MediaSession session) async {
    await _webRtc.preparePeerConnection();
    final pc = _webRtc.peerConnection!;
    _configurePeerConnection(pc, session.sessionId);
    _listen(session.sessionId);
    session.setState(MediaSessionState.receiving);
  }

  void _configurePeerConnection(RTCPeerConnection pc, String sessionId) {
    pc.onIceCandidate = (candidate) {
      unawaited(channel.send(iceCandidateMessage(
        sessionId: sessionId,
        candidate: candidate.candidate ?? '',
        sdpMid: candidate.sdpMid,
        sdpMLineIndex: candidate.sdpMLineIndex,
      )));
    };
    pc.onTrack = (event) {
      final stream = event.streams.isNotEmpty ? event.streams.first : null;
      if (stream != null) _remoteStreamController.add(stream);
    };
    pc.onConnectionState = (state) => _stateController.add(state);
  }

  void _listen(String sessionId) {
    _subscription ??= channel.messages.listen((message) async {
      if (_closed || message['sessionId'] != sessionId) return;
      try {
        switch (message['type']) {
          case 'media_offer':
            final sdp = message['sdp'] as String?;
            if (sdp == null) return;
            await _webRtc.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
            _remoteDescriptionSet = true;
            await _flushCandidates();
            final answer = await _webRtc.createAnswer();
            await channel.send(mediaAnswerMessage(
              sessionId: sessionId,
              sdp: answer.sdp ?? '',
            ));
            break;
          case 'media_answer':
            final sdp = message['sdp'] as String?;
            if (sdp == null) return;
            await _webRtc.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
            _remoteDescriptionSet = true;
            await _flushCandidates();
            break;
          case 'ice_candidate':
            final candidate = RTCIceCandidate(
              message['candidate'] as String?,
              message['sdpMid'] as String?,
              (message['sdpMLineIndex'] as num?)?.toInt(),
            );
            if (_remoteDescriptionSet) {
              await _webRtc.addIceCandidate(candidate);
            } else {
              _pendingCandidates.add(candidate);
            }
            break;
          case 'media_stop':
            break;
        }
      } catch (error, stackTrace) {
        _stateController.addError(error, stackTrace);
      }
    });
  }

  Future<void> _flushCandidates() async {
    for (final candidate in List<RTCIceCandidate>.from(_pendingCandidates)) {
      await _webRtc.addIceCandidate(candidate);
    }
    _pendingCandidates.clear();
  }

  Future<void> stop(MediaSession session) async {
    if (_closed) return;
    await channel.send(mediaStopMessage(sessionId: session.sessionId));
    await _webRtc.stop(session);
  }

  Future<void> dispose() async {
    if (_closed) return;
    _closed = true;
    await _subscription?.cancel();
    await _remoteStreamController.close();
    await _stateController.close();
    await _webRtc.dispose();
  }
}
