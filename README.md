# ReTiDeCo

**Real-Time Device Communication**

ReTiDeCo is a cross-platform peer-to-peer application for real-time screen and audio sharing between devices over the same local network.

## Vision

Connect devices on the same LAN with minimal setup:

- Start a device as a host/server.
- Discover available ReTiDeCo devices automatically.
- Connect with one click.
- Share **screen**, **audio**, or **screen + audio**.
- Keep media traffic local; no cloud relay is required for the LAN MVP.

## Initial MVP

The first milestone targets **Windows ↔ Android**:

1. Flutter application shell.
2. Host / Connect role selection.
3. LAN device discovery.
4. Host session creation and receiver connection.
5. Screen-only streaming.
6. Audio-only streaming.
7. Screen + audio streaming.

## Architecture direction

- **Flutter** for the shared application UI and cross-platform application layer.
- **Native platform APIs** for screen and system-audio capture where required.
- **WebRTC** for low-latency peer media transport.
- **mDNS / local-network discovery** for zero-configuration device discovery.

Platform-specific capture capabilities will be implemented behind small native interfaces so the core application remains portable.

## Project status

🚧 Early development — architecture and MVP foundation.

## License

License will be added before the first public release.
