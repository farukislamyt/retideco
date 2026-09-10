import 'dart:io';

import '../discovery/device_info.dart';

class LocalDevice {
  static DevicePlatform get platform => switch (Platform.operatingSystem) {
        'windows' => DevicePlatform.windows,
        'android' => DevicePlatform.android,
        'ios' => DevicePlatform.ios,
        'macos' => DevicePlatform.macos,
        'linux' => DevicePlatform.linux,
        _ => DevicePlatform.unknown,
      };

  static String get name => Platform.localHostname.isEmpty
      ? 'ReTiDeCo Device'
      : Platform.localHostname;

  static String get id {
    final input = '${platform.name}:$name';
    var hash = 0x811c9dc5;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return 'device-${hash.toRadixString(16).padLeft(8, '0')}';
  }

  static DeviceInfo create({
    required int port,
    bool isHost = false,
    SharingMode sharingMode = SharingMode.none,
  }) => DeviceInfo(
        id: id,
        name: name,
        platform: platform,
        port: port,
        isHost: isHost,
        sharingMode: sharingMode,
        lastSeen: DateTime.now(),
      );
}
