# RC Car Bluetooth Controller App Plan

## Summary
Build an Android-only Flutter app for an Arduino + HC-05 RC car using clean architecture and Riverpod, with four main screens, drawer navigation, smooth real-time telemetry updates, and classic Bluetooth serial communication via `flutter_bluetooth_serial`.

The app will:
- Scan, connect, reconnect, and disconnect from paired/discovered Bluetooth devices
- Parse Arduino telemetry packets into strongly typed app state
- Auto-send mode commands when entering Line Follower and Obstacle Avoidance screens
- Provide manual drive controls with guarded command sending when disconnected
- Persist the last connected device and preferred manual speed
- Run in portrait only with a dark, modern UI and reusable widgets

## Key Changes
### App architecture
- Use `lib/core`, `lib/data`, `lib/domain`, and `lib/presentation` with feature-friendly separation.
- Add domain models and enums for `CarMode`, `MovementDirection`, `ObstacleSide`, `ConnectionStatus`, and `CarState`.
- Introduce repository/service boundaries so Bluetooth transport stays in `data` and UI state orchestration stays in Riverpod not in widgets.
- Define app constants for outbound commands, telemetry keys, animation timings, drawer routes, and storage keys.

### Bluetooth and protocol
- Use `flutter_bluetooth_serial` for classic Bluetooth SPP compatible with HC-05.
- Implement a Bluetooth service that supports:
  - paired/discovered device listing
  - connection lifecycle
  - outbound string command sending
  - inbound byte stream handling
  - reconnect attempt to last saved device on app launch
- Adopt these outbound commands as app protocol:
  - `M:LINE;`
  - `M:OBS;`
  - manual movement commands: `F`, `B`, `L`, `R`, `S`, `G`, `I`, `H`, `J`
- Parse telemetry packets like:
  - `MODE:LINE;SPD:120;DIR:FWD;`
  - `MODE:OBS;SPD:90;DIR:LEFT;OBS:L;`
- Treat `OBS` as required for obstacle UI in obstacle mode; supported values: `NONE`, `L`, `R`, `BOTH`.
- Ignore malformed packet fragments safely and keep the last valid state rather than crashing or clearing UI.

### Presentation and UX
- Create four screens:
  - Connection screen with scan, connect/disconnect, saved device marker, RSSI when available, and connection-state banners
  - Line Follower screen with speed gauge, direction label, animated arrows, path-tracking visual, and auto-send `M:LINE;` on entry
  - Obstacle Avoidance screen with the same movement telemetry plus obstacle warning zones/icons and auto-send `M:OBS;` on entry
  - Manual Mode screen with directional controls, optional diagonal buttons enabled in layout, stop button, speed slider, and haptic feedback
- Add a shared app shell with `Drawer` navigation and route-aware active item highlighting.
- Use reusable widgets for:
  - speed indicator
  - direction indicator
  - movement visualizer
  - obstacle indicator
  - connection status chip
  - command control button
- Prevent command sending while disconnected and show lightweight in-app feedback instead.

### Android and platform config
- Update `pubspec.yaml` with Riverpod, Bluetooth serial, local persistence, and vibration/haptics dependencies as needed.
- Configure Android manifest permissions for Android 12+ and older Android versions:
  - `BLUETOOTH`
  - `BLUETOOTH_ADMIN`
  - `BLUETOOTH_SCAN`
  - `BLUETOOTH_CONNECT`
  - `ACCESS_FINE_LOCATION`
- Lock orientation to portrait in app startup.
- Keep scope Android-only because HC-05 classic Bluetooth is not a practical iOS target.

## Public Interfaces and Contracts
- `CarState` will expose at minimum: `mode`, `speed`, `direction`, `obstacleSide`, `isMoving`, `lastUpdatedAt`.
- `BluetoothDeviceInfo` view model will expose: `name`, `address`, `isBonded`, `isConnected`, `rssi`.
- Providers/notifiers will expose:
  - connection/device list state
  - current telemetry state
  - current screen mode
  - send-command actions
- Firmware/app serial contract defaults:
  - mode-switch: `M:LINE;`, `M:OBS;`
  - telemetry fields: `MODE`, `SPD`, `DIR`, optional `OBS`
  - field delimiter: `;`
  - packet terminator: newline-safe buffered parsing, but each complete semicolon-delimited record is parsed independently

## Test Plan
- Unit test telemetry parsing for valid packets, missing fields, partial packets, invalid values, and obstacle variants.
- Unit test state transitions for connect, disconnect, reconnect, and command blocking when not connected.
- Widget test drawer navigation, connection-state messaging, manual control enable/disable behavior, and live telemetry rendering.
- Widget test mode-entry behavior to confirm `M:LINE;` and `M:OBS;` are dispatched once on screen entry.
- Manual device test with HC-05:
  - connect to paired module
  - receive live speed/direction updates without visible UI lag
  - send manual commands and confirm motion response
  - disconnect Bluetooth mid-session and verify graceful recovery UI
  - relaunch app and confirm last-device reconnect attempt

## Assumptions
- Arduino firmware will support `M:LINE;` and `M:OBS;` for automatic mode activation.
- Obstacle telemetry will be extended to include `OBS:L|R|BOTH|NONE;`.
- Android is the only supported runtime target for this release.
- The initial implementation will prioritize robust serial handling and scalable structure over advanced visual custom painting; animations remain polished but maintainable.
