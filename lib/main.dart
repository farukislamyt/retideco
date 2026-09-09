import 'package:flutter/material.dart';

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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ReTiDeCo')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.devices_rounded, size: 72),
                const SizedBox(height: 24),
                Text(
                  'Real-Time Device Communication',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Connect devices on the same local network and share screen or audio in real time.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _showComingSoon(context, 'Start Server'),
                    icon: const Icon(Icons.cast_rounded),
                    label: const Text('Start Server'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showComingSoon(context, 'Connect to Device'),
                    icon: const Icon(Icons.link_rounded),
                    label: const Text('Connect to Device'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action will be implemented in the next milestone.')),
    );
  }
}
