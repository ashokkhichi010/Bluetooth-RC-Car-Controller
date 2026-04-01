import 'package:bluetooth_rc_car/core/constants/app_constants.dart';
import 'package:bluetooth_rc_car/domain/models/bluetooth_device_info.dart';
import 'package:bluetooth_rc_car/domain/repositories/bluetooth_repository.dart';
import 'package:bluetooth_rc_car/presentation/providers/app_state_provider.dart';
import 'package:bluetooth_rc_car/presentation/screens/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('drawer navigation activates line follower mode command', (
    tester,
  ) async {
    final repository = _RecordingBluetoothRepository()..connected = true;
    final controller = AppController(repository, autoInitialize: false);
    await controller.connect(
      const BluetoothDeviceInfo(
        name: 'HC-05',
        address: '00:11:22:33:44:55',
        isBonded: true,
        isConnected: false,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bluetoothRepositoryProvider.overrideWithValue(repository),
          appBootstrapProvider.overrideWithValue(false),
          appControllerProvider.overrideWith((ref) => controller),
        ],
        child: const MaterialApp(home: AppShell()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Line Follower Mode'));
    await tester.pumpAndSettle();

    expect(repository.sentCommands, contains(AppConstants.lineModeCommand));
  });
}

class _RecordingBluetoothRepository implements BluetoothRepository {
  @override
  Stream<bool> get connectionState => const Stream<bool>.empty();

  @override
  Stream<String> get incomingData => const Stream<String>.empty();

  final List<String> sentCommands = <String>[];
  bool connected = false;

  @override
  bool get isConnected => connected;

  @override
  Future<void> clearLastDevice() async {}

  @override
  Future<void> connect(BluetoothDeviceInfo device) async {}

  @override
  Stream<BluetoothDeviceInfo> discoverDevices() => const Stream.empty();

  @override
  Future<void> disconnect() async {}

  @override
  Future<bool> ensureBluetoothReady() async => true;

  @override
  Future<BluetoothDeviceInfo?> getLastDevice() async => null;

  @override
  Future<double?> getManualSpeed() async => AppConstants.defaultManualSpeed;

  @override
  Future<List<BluetoothDeviceInfo>> getBondedDevices() async => const [];

  @override
  Future<void> saveLastDevice(BluetoothDeviceInfo device) async {}

  @override
  Future<void> saveManualSpeed(double speed) async {}

  @override
  Future<void> sendCommand(String command) async {
    sentCommands.add(command);
  }
}
