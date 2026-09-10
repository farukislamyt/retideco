import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../discovery/device_info.dart';
import 'media_session.dart';

/// Owns the WebRTC peer connection lifecycle. Signaling remains transport-agnostic
/// and is supplied by the ReTiDeCo connection layer.
class WebRtcService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  RTCPeerConnection? get peerConnection => _peerConnection;
  MediaStream? get localStream => _localStream;

  Future<void> initialize() async {
    await Helper.ensureInitialized();
  }

  Future<void> createPeerConnection() async {
    if (_peerConnection != null) return;
    _peerConnection = await createPeerConnection({
      'iceServers': <Map<String, dynamic>>[],
      'sdpSemantics': 'unified-plan',
    });
  }

  Future<MediaStream> captureScreen({bool withAudio = false}) async {
    await initialize();
    final constraints = <String, dynamic>{
      'video': true,
      'audio': withAudio,
    };
    _localStream = await navigator.mediaDevices.getDisplayMedia(constraints);
    return _localStream!;
  }

  Future<MediaStream> captureAudio() async {
    await initialize();
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });
    return _localStream!;
  }

  Future<void> addLocalTracks(MediaStream stream) async {
    await createPeerConnection();
    for (final track in stream.getTracks()) {
      await _peerConnection!.addTrack(track, stream);
    }
  }

  Future<RTCSessionDescription> createOffer() async {
    await createPeerConnection();
    final offer = await _peerConnection!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': true,
    });
    await _peerConnection!.setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription> createAnswer() async {
    await createPeerConnection();
    final answer = await _peerConnection!.createAnswer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': true,
    });
    await _peerConnection!.setLocalDescription(answer);
    return answer;
  }

  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    await createPeerConnection();
    await _peerConnection!.setRemoteDescription(description);
  }

  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    await createPeerConnection();
    await _peerConnection!.addCandidate(candidate);
  }

  Future<void> stop(MediaSession session) async {
    session.setState(MediaSessionState.stopped);
    for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      track.stop();
    }
    await _localStream?.dispose();
    _localStream = null;
    await _peerConnection?.close();
    _peerConnection = null;
  }

  Future<void> dispose() async {
    for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      track.stop();
    }
    await _localStream?.dispose();
    await _peerConnection?.close();
    _localStream = null;
    _peerConnection = null;
  }
}
