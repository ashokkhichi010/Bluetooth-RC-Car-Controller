# IoT Robot Controller

Flutter app for a single ESP8266 robot using Firebase Realtime Database as the only backend.

## What Changed

This project now uses:
- Firebase Realtime Database instead of Bluetooth
- a flat root-level database structure
- startup into a single live controller screen
- live telemetry streaming from `db.ref().onValue`
- path plotting for `AUTO`, `LINE`, and `FOLLOW`

## Database Shape

```json
{
  "isOnline": true,
  "deviceLocation": { "lat": 23.25, "lng": 77.41 },
  "carLocation": { "x": 120, "y": 80 },
  "servoDirection": 90,
  "currentMode": "AUTO",
  "speed": 120,
  "command": { "action": "MOVE", "direction": "FORWARD" },
  "lastSeen": 1710000000
}
```

## App Flow

1. Splash screen starts the app.
2. The app opens the main controller.
3. Live status is derived from `isOnline` and `lastSeen`.

## Main UI

- online/offline indicator
- live telemetry cards for X, Y, direction, and speed
- mode chips for `MANUAL`, `AUTO`, `LINE`, and `FOLLOW`
- custom painted path canvas
- manual direction controls that write to root `command`

## Important Files

- `lib/main.dart`
- `lib/firebase_options.dart`
- `lib/domain/models/robot_state.dart`
- `lib/domain/repositories/robot_repository.dart`
- `lib/data/repositories/firebase_robot_repository.dart`
- `lib/presentation/providers/app_state_provider.dart`
- `lib/presentation/screens/app_shell.dart`
- `database.rules.json`

## Firebase Setup

1. Run `flutter pub get`
2. Replace placeholder values in `lib/firebase_options.dart`
3. Set the real `databaseURL`
4. Apply `database.rules.json` while testing

## Notes

- `lib/firebase_options.dart` contains placeholder Firebase credentials and must be updated for your project.
- `database.rules.json` is open for test mode only.
- The ESP8266 firmware should read and write the same flat root keys used here.
