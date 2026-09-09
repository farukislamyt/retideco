import 'device_info.dart';

abstract interface class DiscoveryService {
  Stream<List<DeviceInfo>> get devices;

  Future<void> start();

  Future<void> stop();

  Future<void> refresh();

  Future<void> advertise(DeviceInfo device);

  Future<void> stopAdvertising();

  Future<void> dispose();
}
