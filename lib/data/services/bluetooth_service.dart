import 'dart:async';

import 'package:bluetooth_rc_car/core/constants/app_constants.dart';
import 'package:flutter_bluetooth_classic_serial/flutter_bluetooth_classic.dart';

class BluetoothService {
  BluetoothService() {
    _stateSubscription = _bluetooth.onStateChanged.listen((state) {
      _stateController.add(state.isEnabled);
    });

    _connectionSubscription = _bluetooth.onConnectionChanged.listen((state) {
      _connected = state.isConnected;
      _connectionStateController.add(state.isConnected);
    });

    _dataSubscription = _bluetooth.onDataReceived.listen((data) {
      final message = data.asString();
      if (message.isNotEmpty) {
        _incomingController.add(message);
      }
    });

    _discoverySubscription = _bluetooth.onDeviceDiscovered.listen((device) {
      _discoveryController.add(device);
    });
  }

  final FlutterBluetoothClassic _bluetooth = FlutterBluetoothClassic();

  final StreamController<String> _incomingController =
      StreamController<String>.broadcast();
  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _stateController =
      StreamController<bool>.broadcast();
  final StreamController<BluetoothDevice> _discoveryController =
      StreamController<BluetoothDevice>.broadcast();

  StreamSubscription<BluetoothState>? _stateSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<BluetoothData>? _dataSubscription;
  StreamSubscription<BluetoothDevice>? _discoverySubscription;

  bool _connected = false;

  Stream<String> get incomingData => _incomingController.stream;
  Stream<bool> get connectionState => _connectionStateController.stream;
  Stream<bool> get bluetoothState => _stateController.stream;
  Stream<BluetoothDevice> get discoveredDevices => _discoveryController.stream;

  bool get isConnected => _connected;

  Future<bool> ensureBluetoothReady() async {
    final isSupported = await _bluetooth.isBluetoothSupported();
    if (!isSupported) {
      return false;
    }

    var enabled = await _bluetooth.isBluetoothEnabled();
    _stateController.add(enabled);

    if (!enabled) {
      try {
        final requested = await _bluetooth.enableBluetooth();
        if (requested) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
        enabled = await _bluetooth.isBluetoothEnabled();
      } catch (_) {
        enabled = false;
      }
      _stateController.add(enabled);
    }

    return enabled;
  }

  Future<List<BluetoothDevice>> getBondedDevices() {
    return _bluetooth.getPairedDevices();
  }

  Stream<BluetoothDevice> discoverDevices() {
    final controller = StreamController<BluetoothDevice>();
    final alreadyFound = <String>{};

    late final StreamSubscription<BluetoothDevice> subscription;
    subscription = discoveredDevices.listen(
      (device) {
        if (alreadyFound.add(device.address)) {
          controller.add(device);
        }
      },
      onError: controller.addError,
    );

    unawaited(() async {
      try {
        final started = await _bluetooth.startDiscovery();
        if (!started) {
          controller.addError(
            StateError('Bluetooth discovery could not be started.'),
          );
          return;
        }

        await Future<void>.delayed(AppConstants.scanTimeout);
        final snapshot = await _bluetooth.getDiscoveredDevices();
        for (final device in snapshot) {
          if (alreadyFound.add(device.address)) {
            controller.add(device);
          }
        }
      } catch (error, stackTrace) {
        controller.addError(error, stackTrace);
      } finally {
        await stopDiscovery();
        await subscription.cancel();
        await controller.close();
      }
    }());

    return controller.stream;
  }

  Future<void> stopDiscovery() async {
    try {
      await _bluetooth.stopDiscovery();
    } catch (_) {
    }
  }

  Future<void> connect(String address) async {
    await disconnect();
    final connected = await _bluetooth.connect(address);
    _connected = connected;
    _connectionStateController.add(connected);
  }

  Future<void> sendCommand(String command) async {
    if (!_connected) {
      throw StateError('Bluetooth connection is not active.');
    }

    final sent = await _bluetooth.sendString(command);
    if (!sent) {
      throw StateError('Bluetooth write failed.');
    }
  }

  Future<void> disconnect() async {
    await stopDiscovery();
    if (_connected) {
      await _bluetooth.disconnect();
      _connectionStateController.add(false);
    }
    _connected = false;
  }

  Future<void> dispose() async {
    await disconnect();
    await _stateSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _dataSubscription?.cancel();
    await _discoverySubscription?.cancel();
    await _incomingController.close();
    await _connectionStateController.close();
    await _stateController.close();
    await _discoveryController.close();
  }
}
