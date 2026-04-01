import 'package:bluetooth_rc_car/core/constants/app_constants.dart';
import 'package:bluetooth_rc_car/domain/models/bluetooth_device_info.dart';
import 'package:bluetooth_rc_car/domain/models/car_state.dart';

class AppState {
  const AppState({
    required this.connectionStatus,
    required this.carState,
    required this.pairedDevices,
    required this.discoveredDevices,
    required this.isScanning,
    required this.bluetoothEnabled,
    required this.manualSpeed,
    this.connectedDevice,
    this.lastSavedDevice,
    this.errorMessage,
    this.infoMessage,
  });

  factory AppState.initial() => AppState(
        connectionStatus: ConnectionStatus.disconnected,
        carState: CarState.initial(),
        pairedDevices: const <BluetoothDeviceInfo>[],
        discoveredDevices: const <BluetoothDeviceInfo>[],
        isScanning: false,
        bluetoothEnabled: false,
        manualSpeed: AppConstants.defaultManualSpeed,
      );

  final ConnectionStatus connectionStatus;
  final CarState carState;
  final List<BluetoothDeviceInfo> pairedDevices;
  final List<BluetoothDeviceInfo> discoveredDevices;
  final bool isScanning;
  final bool bluetoothEnabled;
  final double manualSpeed;
  final BluetoothDeviceInfo? connectedDevice;
  final BluetoothDeviceInfo? lastSavedDevice;
  final String? errorMessage;
  final String? infoMessage;

  bool get isConnected => connectionStatus == ConnectionStatus.connected;

  AppState copyWith({
    ConnectionStatus? connectionStatus,
    CarState? carState,
    List<BluetoothDeviceInfo>? pairedDevices,
    List<BluetoothDeviceInfo>? discoveredDevices,
    bool? isScanning,
    bool? bluetoothEnabled,
    double? manualSpeed,
    BluetoothDeviceInfo? connectedDevice,
    bool clearConnectedDevice = false,
    BluetoothDeviceInfo? lastSavedDevice,
    bool clearLastSavedDevice = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? infoMessage,
    bool clearInfoMessage = false,
  }) {
    return AppState(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      carState: carState ?? this.carState,
      pairedDevices: pairedDevices ?? this.pairedDevices,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      isScanning: isScanning ?? this.isScanning,
      bluetoothEnabled: bluetoothEnabled ?? this.bluetoothEnabled,
      manualSpeed: manualSpeed ?? this.manualSpeed,
      connectedDevice: clearConnectedDevice
          ? null
          : (connectedDevice ?? this.connectedDevice),
      lastSavedDevice: clearLastSavedDevice
          ? null
          : (lastSavedDevice ?? this.lastSavedDevice),
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfoMessage ? null : (infoMessage ?? this.infoMessage),
    );
  }
}
