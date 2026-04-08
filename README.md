# RC Car Controller

Android Flutter app for controlling and monitoring a Bluetooth-based RC car built with Arduino + HC-05.

The app is designed around a single-screen control experience:
- connect to the HC-05 module
- switch between autonomous modes
- monitor incoming telemetry
- drag on the movement panel for manual driving
- adjust speed with an integer-only speed controller

## Overview

This project is a Flutter mobile controller for an Arduino robot car that communicates over classic Bluetooth serial.

It supports:
- Bluetooth scan and connect flow
- automatic reconnect to the last saved module
- live telemetry parsing from Arduino
- single-screen mode switching
- manual directional control through a draggable movement panel
- customizable Bluetooth command mapping
- speed control using integer commands

The app is Android-only because HC-05 uses classic Bluetooth serial, which is not a practical iOS target for this implementation.

## Current UX

The app currently uses a simplified single-screen design.

### App startup

1. A splash screen is shown briefly.
2. The app loads saved preferences.
3. It checks Bluetooth state and refreshes paired devices.
4. If a previously connected module is saved, the app tries to reconnect automatically.

### When not connected

The main screen shows:
- connection status
- Bluetooth scan button
- settings button for command customization
- paired and discovered devices list
- connect button per device

### When connected

The same screen changes into the controller view and shows:
- connection status card
- speed controller at the top
- mode cards
- movement visualizer

No drawer navigation is used in the current version.

## Supported Modes

The controller supports these robot modes:

### 1. Follow Line

Used for line-follower behavior.

Default command:
- `N`

### 2. Auto Mode

Used for obstacle avoidance / autonomous obstacle behavior.

Default command:
- `O`

### 3. Follow Me

Used for follow-me behavior.

Default command:
- `W`

### 4. Manual Mode

Manual mode is entered automatically when the user taps the movement visualizer while the robot is in an autonomous mode.

Default command:
- `MS`

Once manual mode is active, dragging on the movement visualizer sends directional movement commands.

## Movement Visualizer Behavior

The movement visualizer has two roles:

### Telemetry view

When the car is in:
- Follow Line
- Auto Mode
- Follow Me

the movement visualizer displays the car direction using incoming telemetry from Arduino.

### Manual controller

When the user taps the movement visualizer while an autonomous mode is active:

1. the app first sends the manual mode switch command
2. the mode changes to manual
3. the visualizer becomes interactive
4. dragging sends manual direction commands
5. releasing the drag sends stop

Manual directions supported:
- forward
- backward
- left
- right
- forward-left
- forward-right
- backward-left
- backward-right
- stop

## Speed Controller

The speed controller is shown at the top of the connected screen.

Behavior:
- slider updates the UI speed live
- releasing the slider sends the value to the car
- only integer values are sent

Current speed command range:
- `0` to `9`

Important:
- UI uses a slider value
- the command sent to the car is normalized and rounded
- the command is sent as a stringified integer, for example `5`, `8`, `9`

## Bluetooth Command Protocol

The app uses two groups of Bluetooth commands:

### Mode commands

Default values:

| Mode | Command |
|---|---|
| Follow Line | `N` |
| Auto Mode | `O` |
| Follow Me | `W` |
| Manual Mode | `MS` |

### Movement commands

Default values:

| Action | Command |
|---|---|
| Forward | `F` |
| Backward | `B` |
| Left | `L` |
| Right | `R` |
| Stop | `S` |
| Forward Left | `G` |
| Forward Right | `I` |
| Backward Left | `H` |
| Backward Right | `J` |

### Speed commands

Current behavior:
- integer-only speed commands
- range `0` to `9`

Example:
- `0`
- `3`
- `7`
- `9`

## Custom Command Settings

The app includes a command settings screen where the user can customize Bluetooth commands without changing code.

Configurable:
- manual mode command
- follow line command
- auto mode command
- follow me command
- all movement commands

The settings screen can be opened from the disconnected view using the settings icon.

These settings are stored locally with `SharedPreferences`.

## Telemetry Format

The app expects incoming Arduino telemetry in this format:

```text
MODE:LINE;SPD:120;DIR:FWD;
MODE:OBS;SPD:90;DIR:LEFT;OBS:L;
MODE:FOLLOW_ME;SPD:70;DIR:FWD;
```

Parsed fields:
- `MODE`
- `SPD`
- `DIR`
- optional `OBS`

### Supported mode tokens

The parser currently recognizes:
- `LINE`
- `OBS`
- `FOLLOW_ME`
- `FOLLOWME`
- `FOLLOW`
- `FM`
- `MANUAL`
- `IDLE`

### Supported obstacle tokens

The parser currently recognizes:
- `NONE`
- `L`
- `LEFT`
- `R`
- `RIGHT`
- `B`
- `BOTH`

### Supported direction tokens

The parser currently recognizes:
- `STOP`, `S`
- `FWD`, `FORWARD`, `F`
- `BACK`, `BWD`, `BACKWARD`, `B`
- `LEFT`, `L`
- `RIGHT`, `R`
- `FL`, `FORWARD_LEFT`, `G`
- `FR`, `FORWARD_RIGHT`, `I`
- `BL`, `BACKWARD_LEFT`, `H`
- `BR`, `BACKWARD_RIGHT`, `J`

If telemetry is malformed, the parser ignores the bad packet and keeps the last valid state.

## Reconnect and Disconnect Handling

The app attempts to recover gracefully when Bluetooth disconnects unexpectedly.

Current behavior:
- marks the connection as disconnected
- clears connected-device state
- refreshes available devices
- tries reconnecting to the previously saved device
- if reconnect fails, the app stays on the connect view

Manual disconnect does not trigger reconnect recovery.

## Project Structure

```text
lib/
├── main.dart
├── core/
│   ├── constants/
│   ├── theme/
│   └── utils/
├── data/
│   ├── repositories/
│   └── services/
├── domain/
│   ├── models/
│   └── repositories/
└── presentation/
    ├── providers/
    ├── screens/
    └── widgets/
```

## Key Files

### App entry

- `lib/main.dart`
  Starts Flutter, locks portrait orientation, loads shared preferences, and launches the app.

### Main controller screen

- `lib/presentation/screens/app_shell.dart`
  Main single-screen UI for connection, mode switching, speed control, and manual gesture control.

### State management

- `lib/presentation/providers/app_state_provider.dart`
  Main Riverpod state notifier that handles:
  - app bootstrap
  - Bluetooth lifecycle
  - device refresh and scan
  - connect/disconnect
  - mode changes
  - speed commands
  - manual driving commands
  - reconnect logic

### Bluetooth layer

- `lib/data/services/bluetooth_service.dart`
  Low-level Bluetooth integration using `flutter_bluetooth_classic_serial`

- `lib/data/repositories/bluetooth_repository_impl.dart`
  Repository adapter between service layer and app logic

### Domain models

- `lib/domain/models/car_state.dart`
  Robot mode, direction, obstacle state, and parsed car telemetry

- `lib/domain/models/app_state.dart`
  Global app state exposed to the UI

- `lib/domain/models/command_settings.dart`
  User-configurable command mapping for modes and manual directions

### Telemetry parser

- `lib/core/utils/telemetry_parser.dart`
  Parses incoming serial packets into `CarState`

### Movement UI

- `lib/presentation/widgets/movement_visualizer.dart`
  Visual telemetry area and manual drag controller

### Command customization

- `lib/presentation/screens/command_settings_screen.dart`
  UI for editing Bluetooth commands used by the app

## State Management

This project uses Riverpod.

Main provider:
- `appControllerProvider`

The controller owns:
- Bluetooth state
- paired/discovered devices
- last connected device
- current telemetry
- manual speed
- command settings
- status/error messages

## Persistence

The app uses `SharedPreferences` to store:
- last connected device address
- last connected device name
- manual speed
- custom command settings

## Dependencies

Main packages:
- `flutter_bluetooth_classic_serial`
- `flutter_riverpod`
- `permission_handler`
- `shared_preferences`

## Android Permissions

The app requires Bluetooth and location permissions for scanning and connecting.

Typical permissions include:
- Bluetooth scan
- Bluetooth connect
- location when in use

These are requested at runtime by the app controller.

## Build and Run

### Requirements

- Flutter SDK compatible with Dart `^3.10.0`
- Android Studio or Android SDK tools
- Android device with Bluetooth
- HC-05 module paired or discoverable

### Install packages

```bash
flutter pub get
```

### Run in debug

```bash
flutter run
```

### Build debug APK

```bash
flutter build apk --debug
```

### Build release APK

```bash
flutter build apk --release --target-platform android-arm64
```

## Device Setup Notes

For best results:
- pair HC-05 from Android Bluetooth settings first if required by the phone
- then open the app
- allow Bluetooth and location permissions
- scan for devices
- connect to the module

If discovery appears empty:
- confirm Bluetooth is enabled
- confirm Android location services are enabled
- confirm the module is powered and discoverable

## Manual Test Flow

Recommended test flow:

1. Launch the app
2. Wait for saved-device reconnect attempt
3. If not connected, tap scan and connect to HC-05
4. Adjust speed at the top
5. Tap `Follow Line`
6. Confirm telemetry updates on the movement visualizer
7. Tap `Auto Mode`
8. Confirm obstacle-driving telemetry is shown
9. Tap `Follow Me`
10. Confirm the new mode command is sent
11. Tap the movement visualizer
12. Confirm the app switches to manual mode first
13. Drag in different directions
14. Confirm movement commands are sent
15. Release drag and confirm stop is sent

## Known Design Choices

- Single-screen UX instead of multiple navigation screens
- Android-only classic Bluetooth support
- Manual mode is entered through the movement visualizer
- Speed commands are normalized to integer values
- Commands can be customized without recompiling the app

## Future Improvements

Possible next upgrades:
- stronger telemetry status labels for each autonomous mode
- visible joystick ring inside the movement panel
- richer signal-strength and link diagnostics
- command import/export presets
- firmware profile support for multiple robot variants
- automated integration tests against a mock Bluetooth serial source

## License

No license file is currently included in this repository. Add one if you plan to distribute or open source the project.
