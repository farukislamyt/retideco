import 'dart:io';

enum CaptureType { screen, audio }

abstract interface class MediaCaptureProvider {
  bool supports(CaptureType type);

  Future<void> start(CaptureType type);

  Future<void> stop(CaptureType type);

  Future<void> dispose();
}

class PlatformMediaCapabilities {
  static bool supportsScreenCapture() =>
      Platform.isWindows || Platform.isAndroid || Platform.isMacOS || Platform.isLinux || Platform.isIOS;

  static bool supportsSystemAudioCapture() => Platform.isWindows || Platform.isAndroid;
}
