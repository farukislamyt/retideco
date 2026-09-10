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

## Architecture

- **Flutter** for the shared application UI and cross-platform application layer.
- **UDP LAN discovery** for zero-configuration device discovery during the MVP.
- **TCP session negotiation** for connection requests and explicit host approval.
- **Native platform APIs** for screen and system-audio capture where required.
- **WebRTC** for low-latency peer media transport.

Discovery and connection negotiation are intentionally separate from media transport. A discovered device is never trusted automatically.

## Current status

🚧 **v0.2.0 — LAN discovery + connection foundation**

Implemented:

- Nearby-device discovery over UDP broadcast.
- Host/server advertisement and heartbeat.
- Host sharing-mode selection.
- Connection request/accept/reject flow.
- Session IDs and protocol versioning.
- Cross-platform media-capture abstraction.
- Initial unit tests for discovery/connection protocol models.

Next: authenticated session security, WebRTC negotiation, and native screen/audio capture.

## Protocol documentation

- [LAN Discovery Protocol](docs/lan-discovery-protocol.md)

## License

License will be added before the first public release.
