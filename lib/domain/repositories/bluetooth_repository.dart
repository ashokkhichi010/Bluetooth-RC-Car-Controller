import 'dart:async';

import 'package:bluetooth_rc_car/domain/models/bluetooth_device_info.dart';

abstract class BluetoothRepository {
  Stream<String> get incomingData;
  Stream<bool> get connectionState;

  Future<bool> ensureBluetoothReady();
  Future<List<BluetoothDeviceInfo>> getBondedDevices();
  Stream<BluetoothDeviceInfo> discoverDevices();
  Future<void> connect(BluetoothDeviceInfo device);
  Future<void> disconnect();
  Future<void> sendCommand(String command);
  Future<void> saveLastDevice(BluetoothDeviceInfo device);
  Future<BluetoothDeviceInfo?> getLastDevice();
  Future<void> clearLastDevice();
  Future<void> saveManualSpeed(double speed);
  Future<double?> getManualSpeed();
  bool get isConnected;
}
