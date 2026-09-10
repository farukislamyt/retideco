import 'package:flutter/material.dart';

import 'core/connection/connection_service.dart';
import 'core/device/local_device.dart';
import 'core/discovery/device_info.dart';
import 'core/discovery/udp_lan_discovery_service.dart';
import 'features/host/host_page.dart';

void main() {
  runApp(const ReTiDeCoApp());
}

class ReTiDeCoApp extends StatelessWidget {
  const ReTiDeCoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReTiDeCo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _discovery = UdpLanDiscoveryService();
  final _connection = ConnectionService();
  final _devices = <DeviceInfo>[];
  bool _discovering = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _discovery.devices.listen((devices) {
      if (!mounted) return;
      setState(() {
        _devices
          ..clear()
          ..addAll(devices);
      });
    });
    _startDiscovery();
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _discovering = true;
      _error = null;
    });
    try {
      await _discovery.start();
    } catch (error) {
      if (mounted) setState(() => _error = 'LAN discovery failed: $error');
    } finally {
      if (mounted) setState(() => _discovering = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _discovering = true);
    try {
      await _discovery.refresh();
    } catch (error) {
      if (mounted) setState(() => _error = 'Refresh failed: $error');
    } finally {
      if (mounted) setState(() => _discovering = false);
    }
  }

  Future<void> _connect(DeviceInfo device) async {
    try {
      await _connection.requestConnection(
        device: device,
        localDeviceId: LocalDevice.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${device.name}.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: $error')),
      );
    }
  }

  @override
  void dispose() {
    _discovery.dispose();
    _connection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReTiDeCo'),
        actions: [
          IconButton(
            tooltip: 'Refresh nearby devices',
            onPressed: _discovering ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.devices_rounded, size: 64),
              const SizedBox(height: 16),
              Text('Nearby Devices', textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                _discovering
                    ? 'Discovering devices on your local network…'
                    : 'Devices found on the same LAN appear here automatically.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HostPage()),
                ),
                icon: const Icon(Icons.cast_rounded),
                label: const Text('Start Server'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              if (_devices.isEmpty && !_discovering)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.wifi_find_rounded, size: 48),
                        const SizedBox(height: 12),
                        Text('No ReTiDeCo devices found',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        const Text(
                          'Make sure another ReTiDeCo device is running on the same Wi-Fi or LAN.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._devices.map(_deviceCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deviceCard(DeviceInfo device) {
    final platformLabel = switch (device.platform) {
      DevicePlatform.windows => 'Windows',
      DevicePlatform.android => 'Android',
      DevicePlatform.ios => 'iOS',
      DevicePlatform.macos => 'macOS',
      DevicePlatform.linux => 'Linux',
      DevicePlatform.unknown => 'Unknown platform',
    };
    final sharingLabel = switch (device.sharingMode) {
      SharingMode.none => 'Not sharing',
      SharingMode.screen => 'Screen sharing',
      SharingMode.audio => 'Audio sharing',
      SharingMode.screenAndAudio => 'Screen + audio',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: Icon(device.isHost ? Icons.cast : Icons.devices)),
        title: Text(device.name),
        subtitle: Text('$platformLabel • $sharingLabel'),
        trailing: device.isHost
            ? FilledButton(onPressed: () => _connect(device), child: const Text('Connect'))
            : null,
      ),
    );
  }
}
