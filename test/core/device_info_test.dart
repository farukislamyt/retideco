import 'package:flutter_test/flutter_test.dart';
import 'package:retideco/core/discovery/device_info.dart';

void main() {
  test('device info serializes and restores discovery metadata', () {
    const original = DeviceInfo(
      id: 'device-1',
      name: 'Office PC',
      platform: DevicePlatform.windows,
      port: 45822,
      isHost: true,
      sharingMode: SharingMode.screenAndAudio,
      lastSeen: null,
    );

    final restored = DeviceInfo.fromJson(original.toJson(), address: '192.168.1.20');

    expect(restored.id, original.id);
    expect(restored.name, original.name);
    expect(restored.platform, original.platform);
    expect(restored.port, original.port);
    expect(restored.isHost, original.isHost);
    expect(restored.sharingMode, original.sharingMode);
    expect(restored.address, '192.168.1.20');
  });
}
