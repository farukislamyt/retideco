enum MediaSessionState { idle, negotiating, active, stopped, failed }

enum MediaKind { screen, audio }

class MediaSession {
  MediaSession({required this.kinds});

  final Set<MediaKind> kinds;
  MediaSessionState state = MediaSessionState.idle;

  bool get hasScreen => kinds.contains(MediaKind.screen);
  bool get hasAudio => kinds.contains(MediaKind.audio);

  void setState(MediaSessionState next) => state = next;
}
