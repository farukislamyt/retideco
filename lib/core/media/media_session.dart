import '../discovery/device_info.dart';

enum MediaSessionState { idle, preparing, negotiating, publishing, receiving, active, stopped, failed }

class MediaSession {
  MediaSession({
    required this.sessionId,
    required this.mode,
    required this.isPublisher,
    this.state = MediaSessionState.idle,
  });

  final String sessionId;
  final SharingMode mode;
  final bool isPublisher;
  MediaSessionState state;

  bool get hasVideo => mode == SharingMode.screen || mode == SharingMode.screenAndAudio;
  bool get hasAudio => mode == SharingMode.audio || mode == SharingMode.screenAndAudio;

  void setState(MediaSessionState next) => state = next;
}
