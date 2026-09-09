# ReTiDeCo LAN Discovery Protocol

## Purpose

ReTiDeCo uses a small UDP broadcast protocol for zero-configuration discovery on the local network. This is the discovery layer only; media traffic will use a separate peer-to-peer transport.

## Transport

- IPv4 UDP broadcast
- Port: `45821`
- Broadcast address: `255.255.255.255`
- Heartbeat: every 2 seconds while advertising
- Device expiry: 7 seconds without a heartbeat

## Packet

Each packet is UTF-8 JSON:

```json
{
  "protocol": "retideco-discovery",
  "version": 1,
  "device": {
    "id": "stable-device-id",
    "name": "Faruk's PC",
    "platform": "windows",
    "port": 45822,
    "host": true,
    "sharingMode": "screen",
    "timestamp": 1760000000000
  }
}
```

## Rules

1. Ignore packets with an unknown protocol or version.
2. Ignore malformed JSON and malformed device records.
3. Ignore packets originating from the local device ID.
4. Key discovered devices by their stable device ID.
5. Refresh `lastSeen` whenever a valid advertisement arrives.
6. Remove a device after the discovery timeout.
7. Discovery must not carry screen/audio media.

## Security

Discovery is intentionally treated as untrusted input. A discovered device is not automatically trusted or connected. Phase 3/4 will introduce explicit connection negotiation, authentication, pairing, and session security.
