import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/connection/connection_service.dart';
import '../../core/device/local_device.dart';
import '../../core/discovery/device_info.dart';
import '../../core/discovery/udp_lan_discovery_service.dart';

class HostPage extends StatefulWidget {
  const HostPage({super.key});

  @override
  State<HostPage> createState() => _HostPageState();
}

class _HostPageState extends State<HostPage> {
  final _connection = ConnectionService();
  final _discovery = UdpLanDiscoveryService();
  StreamSubscription<PendingConnection>? _pendingSubscription;

  SharingMode _mode = SharingMode.screen;
  bool _running = false;
  int? _port;
  PendingConnection? _pending;

  @override
  void initState() {
    super.initState();
    _pendingSubscription = _connection.pendingConnections.listen((pending) {
      if (!mounted) return;
      setState(() => _pending = pending);
    });
  }

  Future<void> _toggleHost() async {
    if (_running) {
      await _discovery.stopAdvertising();
      await _connection.stop();
      if (mounted) setState(() { _running = false; _port = null; });
      return;
    }

    final port = await _connection.start();
    final device = LocalDevice.create(
      port: port,
      isHost: true,
      sharingMode: _mode,
    );
    await _discovery.start();
    await _discovery.advertise(device);
    if (mounted) setState(() { _running = true; _port = port; });
  }

  Future<void> _approve() async {
    final pending = _pending;
    if (pending == null) return;
    await _connection.approve(pending);
    if (mounted) setState(() => _pending = null);
  }

  Future<void> _reject() async {
    final pending = _pending;
    if (pending == null) return;
    await _connection.reject(pending);
    if (mounted) setState(() => _pending = null);
  }

  @override
  void dispose() {
    _pendingSubscription?.cancel();
    _discovery.dispose();
    _connection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start Server')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Sharing mode', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SegmentedButton<SharingMode>(
            segments: const [
              ButtonSegment(value: SharingMode.screen, label: Text('Screen'), icon: Icon(Icons.monitor)),
              ButtonSegment(value: SharingMode.audio, label: Text('Audio'), icon: Icon(Icons.volume_up)),
              ButtonSegment(value: SharingMode.screenAndAudio, label: Text('Both'), icon: Icon(Icons.cast)),
            ],
            selected: {_mode},
            onSelectionChanged: _running ? null : (value) => setState(() => _mode = value.first),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: Icon(_running ? Icons.wifi_tethering : Icons.wifi_off),
              title: Text(_running ? 'Server is running' : 'Server is stopped'),
              subtitle: Text(_running
                  ? 'Discoverable on the local network • port $_port'
                  : 'Start the server to allow nearby devices to request a connection.'),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _toggleHost,
            icon: Icon(_running ? Icons.stop : Icons.play_arrow),
            label: Text(_running ? 'Stop Server' : 'Start Server'),
          ),
          if (_pending != null) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Connection request', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('${_pending!.deviceName} wants to connect.'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: OutlinedButton(onPressed: _reject, child: const Text('Reject'))),
                        const SizedBox(width: 12),
                        Expanded(child: FilledButton(onPressed: _approve, child: const Text('Accept'))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
