import 'dart:async';

import 'package:bluetooth_rc_car/core/constants/app_constants.dart';
import 'package:bluetooth_rc_car/domain/models/bluetooth_device_info.dart';
import 'package:bluetooth_rc_car/domain/models/car_state.dart';
import 'package:bluetooth_rc_car/domain/models/command_settings.dart';
import 'package:bluetooth_rc_car/domain/repositories/bluetooth_repository.dart';
import 'package:bluetooth_rc_car/presentation/providers/app_state_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppController', () {
    test('blocks manual commands while disconnected', () async {
      final repository = FakeBluetoothRepository();
      final controller = AppController(repository, autoInitialize: false);

      await controller.sendManualCommand(
        AppConstants.commandForward,
        direction: MovementDirection.forward,
      );

      expect(repository.sentCommands, isEmpty);
      expect(
        controller.state.errorMessage,
        'Please connect to your RC car before sending commands.',
      );

      controller.dispose();
    });

    test('updates telemetry from incoming stream', () async {
      final repository = FakeBluetoothRepository()..connected = true;
      final controller = AppController(repository, autoInitialize: false);

      repository.emitConnection(true);
      repository.emitTelemetry('MODE:LINE;SPD:120;DIR:FWD;');
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.carState.mode, CarMode.lineFollower);
      expect(controller.state.carState.speed, 120);
      expect(controller.state.carState.direction, MovementDirection.forward);

      controller.dispose();
    });

    test('sends speed commands as a single digit from 0 to 9', () async {
      final repository = FakeBluetoothRepository()..connected = true;
      final controller = AppController(repository, autoInitialize: false);

      repository.emitConnection(true);
      await controller.sendSpeedValue(18);

      expect(repository.sentCommands, ['9']);
      expect(repository.savedManualSpeed, 9);
      expect(controller.state.manualSpeed, 9);
      expect(controller.state.carState.speed, 9);

      controller.dispose();
    });

    test('uses saved custom commands when changing modes', () async {
      final repository = FakeBluetoothRepository()
        ..connected = true
        ..commandSettings = CommandSettings.defaults().copyWith(
          lineFollowerMode: 'Z',
        );
      final controller = AppController(repository, autoInitialize: false);

      await controller.saveCommandSettings(repository.commandSettings);
      await controller.activateMode(CarMode.lineFollower);

      expect(repository.sentCommands, contains('Z'));

      controller.dispose();
    });
  });
}

class FakeBluetoothRepository implements BluetoothRepository {
  final StreamController<String> _incomingController =
      StreamController<String>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  final List<String> sentCommands = <String>[];
  bool connected = false;
  double? savedManualSpeed;
  CommandSettings commandSettings = CommandSettings.defaults();

  @override
  Stream<String> get incomingData => _incomingController.stream;

  @override
  Stream<bool> get connectionState => _connectionController.stream;

  @override
  bool get isConnected => connected;

  @override
  Future<void> clearLastDevice() async {}

  @override
  Future<void> connect(BluetoothDeviceInfo device) async {
    connected = true;
    emitConnection(true);
  }

  @override
  Stream<BluetoothDeviceInfo> discoverDevices() => const Stream.empty();

  @override
  Future<void> disconnect() async {
    connected = false;
    emitConnection(false);
  }

  @override
  Future<bool> ensureBluetoothReady() async => true;

  void emitConnection(bool value) => _connectionController.add(value);

  void emitTelemetry(String packet) => _incomingController.add(packet);

  @override
  Future<BluetoothDeviceInfo?> getLastDevice() async => null;

  @override
  Future<double?> getManualSpeed() async => AppConstants.defaultManualSpeed;

  @override
  Future<CommandSettings> getCommandSettings() async => commandSettings;

  @override
  Future<List<BluetoothDeviceInfo>> getBondedDevices() async => const [];

  @override
  Future<void> saveLastDevice(BluetoothDeviceInfo device) async {}

  @override
  Future<void> saveManualSpeed(double speed) async {
    savedManualSpeed = speed;
  }

  @override
  Future<void> saveCommandSettings(CommandSettings settings) async {
    commandSettings = settings;
  }

  @override
  Future<void> sendCommand(String command) async {
    if (!connected) {
      throw StateError('No connection');
    }
    sentCommands.add(command);
  }
}
