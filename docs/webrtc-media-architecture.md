# ReTiDeCo WebRTC Media Architecture

ReTiDeCo uses WebRTC for low-latency peer media after a LAN connection is approved.

## Flow

1. LAN discovery finds a host.
2. TCP connection request is sent to the advertised connection port.
3. Host explicitly approves or rejects the request.
4. The approved session exchanges WebRTC SDP and ICE messages over the authenticated connection channel.
5. The publisher captures the requested media and adds tracks to the peer connection.
6. WebRTC transports the media directly between peers on the LAN.

## Current implementation

- `MediaSession` describes screen/audio intent and lifecycle.
- `WebRtcService` owns peer connection creation, SDP offer/answer, ICE candidates, and local capture.
- `getDisplayMedia` is used for screen capture.
- `getUserMedia` is explicitly treated as microphone capture, not system audio.
- No public STUN/TURN service is required for the LAN MVP; the peer connection starts with an empty ICE-server list.

The current WebRTC Flutter package supports Android and Windows screen capture and audio/video transport. Windows loopback/system-audio support is available in current upstream WebRTC plugin releases, but it must be wired into ReTiDeCo's platform-specific capture path and tested on real Windows hardware before being called production-ready.

## Next media work

- Connect signaling messages to the live `ConnectionService` socket.
- Add receiver-side `RTCVideoRenderer` UI.
- Add Android MediaProjection permission/background handling.
- Add Windows system-audio loopback capture.
- Add screen/audio synchronization and adaptive bitrate controls.
- Add end-to-end media tests on Windows ↔ Android.
