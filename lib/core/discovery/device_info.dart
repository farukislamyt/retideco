enum DevicePlatform { windows, android, ios, macos, linux, unknown }

enum SharingMode { none, screen, audio, screenAndAudio }

class DeviceInfo {
  const DeviceInfo({
    required this.id,
    required this.name,
    required this.platform,
    required this.port,
    required this.isHost,
    required this.sharingMode,
    required this.lastSeen,
    this.address,
  });

  final String id;
  final String name;
  final DevicePlatform platform;
  final int port;
  final bool isHost;
  final SharingMode sharingMode;
  final DateTime lastSeen;
  final String? address;

  bool get isSharing => sharingMode != SharingMode.none;

  DeviceInfo copyWith({
    String? address,
    DateTime? lastSeen,
  }) => DeviceInfo(
        id: id,
        name: name,
        platform: platform,
        port: port,
        isHost: isHost,
        sharingMode: sharingMode,
        lastSeen: lastSeen ?? this.lastSeen,
        address: address ?? this.address,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'platform': platform.name,
        'port': port,
        'host': isHost,
        'sharingMode': sharingMode.name,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

  static DeviceInfo fromJson(Map<String, dynamic> json, {String? address}) {
    final platform = DevicePlatform.values.firstWhere(
      (value) => value.name == json['platform'],
      orElse: () => DevicePlatform.unknown,
    );
    final mode = SharingMode.values.firstWhere(
      (value) => value.name == json['sharingMode'],
      orElse: () => SharingMode.none,
    );
    return DeviceInfo(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'ReTiDeCo Device',
      platform: platform,
      port: (json['port'] as num?)?.toInt() ?? 0,
      isHost: json['host'] as bool? ?? false,
      sharingMode: mode,
      lastSeen: DateTime.now(),
      address: address,
    );
  }
}
