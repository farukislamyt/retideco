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

Discovery, connection negotiation, and media transport are separate layers. A discovered device is never trusted automatically.

## Current status

🚧 **v0.3.0 — WebRTC media foundation**

Implemented:

- Nearby-device discovery over UDP broadcast.
- Host/server advertisement and heartbeat.
- Connection request/accept/reject flow.
- Session IDs and protocol versioning.
- WebRTC peer-connection foundation.
- Screen-capture API integration through `getDisplayMedia`.
- Microphone capture through `getUserMedia`.
- SDP offer/answer and ICE signaling message definitions.
- Media session lifecycle model.

Still required before calling streaming production-ready:

- Live signaling over the connection socket.
- Receiver video renderer/UI.
- Android MediaProjection/background handling.
- Windows system-audio loopback integration.
- Screen/audio synchronization and adaptive bitrate.
- Real Windows ↔ Android device testing.

## Protocol documentation

- [LAN Discovery Protocol](docs/lan-discovery-protocol.md)
- [WebRTC Media Architecture](docs/webrtc-media-architecture.md)

## License

License will be added before the first public release.
