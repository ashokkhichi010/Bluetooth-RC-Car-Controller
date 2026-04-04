import 'dart:async';

import 'package:bluetooth_rc_car/core/constants/app_constants.dart';
import 'package:bluetooth_rc_car/core/utils/telemetry_parser.dart';
import 'package:bluetooth_rc_car/data/repositories/bluetooth_repository_impl.dart';
import 'package:bluetooth_rc_car/data/services/bluetooth_service.dart';
import 'package:bluetooth_rc_car/domain/models/app_state.dart';
import 'package:bluetooth_rc_car/domain/models/bluetooth_device_info.dart';
import 'package:bluetooth_rc_car/domain/models/car_state.dart';
import 'package:bluetooth_rc_car/domain/repositories/bluetooth_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main().');
});

final bluetoothServiceProvider = Provider<BluetoothService>((ref) {
  final service = BluetoothService();
  ref.onDispose(service.dispose);
  return service;
});

final bluetoothRepositoryProvider = Provider<BluetoothRepository>((ref) {
  return BluetoothRepositoryImpl(
    bluetoothService: ref.watch(bluetoothServiceProvider),
    preferences: ref.watch(sharedPreferencesProvider),
  );
});

final appBootstrapProvider = Provider<bool>((ref) => true);

final appControllerProvider =
    StateNotifierProvider<AppController, AppState>((ref) {
  final controller = AppController(
    ref.watch(bluetoothRepositoryProvider),
    autoInitialize: ref.watch(appBootstrapProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

class AppController extends StateNotifier<AppState> {
  AppController(
    this._repository, {
    this.autoInitialize = true,
  }) : super(AppState.initial()) {
    _connectionStateSubscription = _repository.connectionState.listen(
      _handleConnectionChange,
    );
    _incomingDataSubscription = _repository.incomingData.listen(_handleIncomingData);
    if (autoInitialize) {
      unawaited(_initialize());
    }
  }

  final BluetoothRepository _repository;
  final bool autoInitialize;

  StreamSubscription<bool>? _connectionStateSubscription;
  StreamSubscription<String>? _incomingDataSubscription;
  StreamSubscription<BluetoothDeviceInfo>? _discoverySubscription;
  String _serialBuffer = '';
  bool _isRecoveringConnection = false;
  bool _manualDisconnectInProgress = false;

  Future<void> _initialize() async {
    await _loadPreferences();
    await refreshDevices(autoReconnect: true);
  }

  Future<void> _loadPreferences() async {
    final lastDevice = await _repository.getLastDevice();
    final savedSpeed = await _repository.getManualSpeed();

    state = state.copyWith(
      lastSavedDevice: lastDevice,
      manualSpeed: savedSpeed ?? AppConstants.defaultManualSpeed,
    );
  }

  Future<void> refreshDevices({bool autoReconnect = false}) async {
    final hasPermission = await _ensurePermissions();
    if (!hasPermission) {
      state = state.copyWith(
        errorMessage:
            'Bluetooth and location permissions are required to find nearby devices.',
      );
      return;
    }

    final enabled = await _repository.ensureBluetoothReady();
    state = state.copyWith(
      bluetoothEnabled: enabled,
      clearErrorMessage: enabled,
    );

    if (!enabled) {
      state = state.copyWith(
        errorMessage: 'Bluetooth is disabled. Please enable it and try again.',
      );
      return;
    }

    final bonded = await _repository.getBondedDevices();
    state = state.copyWith(
      pairedDevices: _mergeConnectionFlags(bonded),
      discoveredDevices: const <BluetoothDeviceInfo>[],
      clearErrorMessage: true,
    );

    if (autoReconnect && state.lastSavedDevice != null && !state.isConnected) {
      final savedAddress = state.lastSavedDevice!.address;
      final candidate = bonded.where((device) => device.address == savedAddress).firstOrNull;
      if (candidate != null) {
        await connect(candidate, showStatusMessage: false);
      }
    }
  }

  Future<void> scanDevices() async {
    if (state.isScanning) {
      return;
    }

    await refreshDevices();
    await _discoverySubscription?.cancel();

    state = state.copyWith(
      isScanning: true,
      discoveredDevices: const <BluetoothDeviceInfo>[],
      infoMessage: 'Scanning nearby Bluetooth devices...',
      clearErrorMessage: true,
    );

    _discoverySubscription = _repository.discoverDevices().listen(
      (device) {
        final updated = [...state.discoveredDevices];
        final index = updated.indexWhere((item) => item.address == device.address);
        if (index >= 0) {
          updated[index] = device.copyWith(isConnected: device.address == state.connectedDevice?.address);
        } else {
          updated.add(
            device.copyWith(isConnected: device.address == state.connectedDevice?.address),
          );
        }

        updated.sort((a, b) => a.name.compareTo(b.name));
        state = state.copyWith(discoveredDevices: updated);
      },
      onError: (_) {
        state = state.copyWith(
          isScanning: false,
          errorMessage: 'Device discovery failed. Please try again.',
        );
      },
      onDone: () {
        state = state.copyWith(
          isScanning: false,
          infoMessage: 'Scan complete.',
        );
      },
      cancelOnError: false,
    );
  }

  Future<void> connect(
    BluetoothDeviceInfo device, {
    bool showStatusMessage = true,
  }) async {
    if (state.connectionStatus == ConnectionStatus.connecting) {
      return;
    }

    state = state.copyWith(
      connectionStatus: ConnectionStatus.connecting,
      connectedDevice: device.copyWith(isConnected: true),
      clearErrorMessage: true,
      infoMessage: 'Connecting to ${device.name}...',
    );

    try {
      await _repository.connect(device);
      state = state.copyWith(
        connectionStatus: ConnectionStatus.connected,
        connectedDevice: device.copyWith(isConnected: true),
        lastSavedDevice: device,
        pairedDevices: _markConnected(state.pairedDevices, device.address),
        discoveredDevices: _markConnected(state.discoveredDevices, device.address),
        infoMessage: showStatusMessage ? 'Connected to ${device.name}.' : null,
      );
    } catch (_) {
      state = state.copyWith(
        connectionStatus: ConnectionStatus.disconnected,
        clearConnectedDevice: true,
        errorMessage: 'Unable to connect to ${device.name}.',
      );
    }
  }

  Future<void> disconnect() async {
    _manualDisconnectInProgress = true;
    await _repository.disconnect();
    state = state.copyWith(
      connectionStatus: ConnectionStatus.disconnected,
      pairedDevices: _clearConnected(state.pairedDevices),
      discoveredDevices: _clearConnected(state.discoveredDevices),
      carState: CarState.initial(),
      infoMessage: 'Bluetooth connection closed.',
      clearConnectedDevice: true,
    );
  }

  Future<void> activateMode(CarMode mode) async {
    final command = switch (mode) {
      CarMode.lineFollower => AppConstants.lineModeCommand,
      CarMode.obstacleAvoidance => AppConstants.obstacleModeCommand,
      CarMode.followMe => AppConstants.followMeModeCommand,
      CarMode.manual => AppConstants.menualModeCommand,
      CarMode.idle => AppConstants.commandStop,
    };

    if (!state.isConnected) {
      state = state.copyWith(
        errorMessage: 'Connect to the HC-05 module before changing modes.',
      );
      return;
    }

    try {
      await _repository.sendCommand(command);
      if (mode == CarMode.manual) {
        state = state.copyWith(
          carState: state.carState.copyWith(
            mode: CarMode.manual,
            lastUpdatedAt: DateTime.now(),
          ),
        );
      }
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Command failed because the Bluetooth link is unavailable.',
      );
    }
  }

  Future<void> sendManualCommand(
    String command, {
    required MovementDirection direction,
  }) async {
    if (!state.isConnected) {
      state = state.copyWith(
        errorMessage: 'Please connect to your RC car before sending commands.',
      );
      return;
    }

    try {
      HapticFeedback.selectionClick();
      await _repository.sendCommand(command);
      state = state.copyWith(
        carState: state.carState.copyWith(
          mode: CarMode.manual,
          speed: direction == MovementDirection.stop
              ? 0
              : state.manualSpeed.round(),
          direction: direction,
          obstacleSide: ObstacleSide.none,
          lastUpdatedAt: DateTime.now(),
        ),
      );
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'The command could not be delivered.',
      );
    }
  }

  Future<void> updateManualSpeed(double speed) async {
    await _repository.saveManualSpeed(speed);
    state = state.copyWith(
      manualSpeed: speed,
      carState: state.carState.mode == CarMode.manual && state.carState.isMoving
          ? state.carState.copyWith(
              speed: speed.round(),
              lastUpdatedAt: DateTime.now(),
            )
          : state.carState,
    );
  }

  Future<void> forgetSavedDevice() async {
    await _repository.clearLastDevice();
    state = state.copyWith(
      clearLastSavedDevice: true,
      infoMessage: 'Saved device cleared.',
    );
  }

  void clearMessages() {
    state = state.copyWith(
      clearErrorMessage: true,
      clearInfoMessage: true,
    );
  }

  void _handleIncomingData(String chunk) {
    _serialBuffer = '$_serialBuffer$chunk';
    final extraction = TelemetryParser.extractPackets(_serialBuffer);
    _serialBuffer = extraction.remainder;

    if (extraction.packets.isEmpty) {
      return;
    }

    var nextState = state.carState;
    for (final packet in extraction.packets) {
      final parsed = TelemetryParser.parsePacket(packet, previous: nextState);
      if (parsed != null) {
        nextState = parsed;
      }
    }

    state = state.copyWith(carState: nextState);
  }

  void _handleConnectionChange(bool connected) {
    if (connected) {
      _manualDisconnectInProgress = false;
      _isRecoveringConnection = false;
      return;
    }

    if (_manualDisconnectInProgress) {
      _manualDisconnectInProgress = false;
      return;
    }

    if (_isRecoveringConnection) {
      return;
    }

    if (mounted) {
      state = state.copyWith(
        connectionStatus: ConnectionStatus.disconnected,
        pairedDevices: _clearConnected(state.pairedDevices),
        discoveredDevices: _clearConnected(state.discoveredDevices),
        clearConnectedDevice: true,
        errorMessage: 'Bluetooth disconnected unexpectedly.',
      );

      unawaited(_recoverLastConnection());
    }
  }

  Future<void> _recoverLastConnection() async {
    if (_isRecoveringConnection) {
      return;
    }

    _isRecoveringConnection = true;
    state = state.copyWith(
      connectionStatus: ConnectionStatus.connecting,
      infoMessage: 'Trying to reconnect...',
      clearErrorMessage: true,
    );

    await Future<void>.delayed(AppConstants.reconnectDelay);
    await refreshDevices(autoReconnect: true);

    if (!state.isConnected) {
      state = state.copyWith(
        connectionStatus: ConnectionStatus.disconnected,
        clearConnectedDevice: true,
        infoMessage: 'Reconnect failed.',
      );
    }

    _isRecoveringConnection = false;
  }

  Future<bool> _ensurePermissions() async {
    final statuses = await <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final allGranted = statuses.values.every(
      (status) => status.isGranted || status.isLimited,
    );

    if (!allGranted) {
      final permanentlyDenied = statuses.values.any(
        (status) => status.isPermanentlyDenied,
      );
      if (permanentlyDenied) {
        state = state.copyWith(
          infoMessage:
              'Enable Bluetooth permissions from Settings to scan for the RC car.',
        );
      }
      return false;
    }

    return true;
  }

  List<BluetoothDeviceInfo> _markConnected(
    List<BluetoothDeviceInfo> devices,
    String address,
  ) {
    return devices
        .map((device) => device.copyWith(isConnected: device.address == address))
        .toList();
  }

  List<BluetoothDeviceInfo> _clearConnected(List<BluetoothDeviceInfo> devices) {
    return devices.map((device) => device.copyWith(isConnected: false)).toList();
  }

  List<BluetoothDeviceInfo> _mergeConnectionFlags(List<BluetoothDeviceInfo> devices) {
    final address = state.connectedDevice?.address;
    if (address == null) {
      return devices;
    }

    return _markConnected(devices, address);
  }

  @override
  void dispose() {
    _discoverySubscription?.cancel();
    _incomingDataSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    super.dispose();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
