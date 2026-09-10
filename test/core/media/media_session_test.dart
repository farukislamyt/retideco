import 'package:flutter_test/flutter_test.dart';
import 'package:retideco/core/discovery/device_info.dart';
import 'package:retideco/core/media/media_session.dart';

void main() {
  test('screen and audio mode exposes both media kinds', () {
    final session = MediaSession(
      sessionId: 'session-1',
      mode: SharingMode.screenAndAudio,
      isPublisher: true,
    );

    expect(session.hasVideo, isTrue);
    expect(session.hasAudio, isTrue);
    expect(session.state, MediaSessionState.idle);

    session.setState(MediaSessionState.negotiating);
    expect(session.state, MediaSessionState.negotiating);
  });
}
