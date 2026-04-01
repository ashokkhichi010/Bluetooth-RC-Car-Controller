import 'dart:async';

import 'package:bluetooth_rc_car/core/constants/app_constants.dart';
import 'package:bluetooth_rc_car/data/services/bluetooth_service.dart';
import 'package:bluetooth_rc_car/domain/models/bluetooth_device_info.dart';
import 'package:bluetooth_rc_car/domain/repositories/bluetooth_repository.dart';
import 'package:flutter_bluetooth_classic_serial/flutter_bluetooth_classic.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BluetoothRepositoryImpl implements BluetoothRepository {
  BluetoothRepositoryImpl({
    required BluetoothService bluetoothService,
    required SharedPreferences preferences,
  })  : _bluetoothService = bluetoothService,
        _preferences = preferences;

  final BluetoothService _bluetoothService;
  final SharedPreferences _preferences;

  @override
  Stream<String> get incomingData => _bluetoothService.incomingData;

  @override
  Stream<bool> get connectionState => _bluetoothService.connectionState;

  @override
  bool get isConnected => _bluetoothService.isConnected;

  @override
  Future<bool> ensureBluetoothReady() => _bluetoothService.ensureBluetoothReady();

  @override
  Future<List<BluetoothDeviceInfo>> getBondedDevices() async {
    final devices = await _bluetoothService.getBondedDevices();
    return devices.map(_mapDevice).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Stream<BluetoothDeviceInfo> discoverDevices() async* {
    await for (final device in _bluetoothService.discoverDevices()) {
      yield _mapDevice(device);
    }
  }

  @override
  Future<void> connect(BluetoothDeviceInfo device) async {
    await _bluetoothService.connect(device.address);
    await saveLastDevice(device);
  }

  @override
  Future<void> disconnect() => _bluetoothService.disconnect();

  @override
  Future<void> sendCommand(String command) => _bluetoothService.sendCommand(command);

  @override
  Future<void> saveLastDevice(BluetoothDeviceInfo device) async {
    await _preferences.setString(
      AppConstants.prefLastDeviceAddress,
      device.address,
    );
    await _preferences.setString(
      AppConstants.prefLastDeviceName,
      device.name,
    );
  }

  @override
  Future<BluetoothDeviceInfo?> getLastDevice() async {
    final address = _preferences.getString(AppConstants.prefLastDeviceAddress);
    if (address == null || address.isEmpty) {
      return null;
    }

    final name = _preferences.getString(AppConstants.prefLastDeviceName) ?? 'Saved Device';
    return BluetoothDeviceInfo(
      name: name,
      address: address,
      isBonded: true,
      isConnected: false,
    );
  }

  @override
  Future<void> clearLastDevice() async {
    await _preferences.remove(AppConstants.prefLastDeviceAddress);
    await _preferences.remove(AppConstants.prefLastDeviceName);
  }

  @override
  Future<void> saveManualSpeed(double speed) {
    return _preferences.setDouble(AppConstants.prefManualSpeed, speed);
  }

  @override
  Future<double?> getManualSpeed() async {
    return _preferences.getDouble(AppConstants.prefManualSpeed);
  }

  BluetoothDeviceInfo _mapDevice(BluetoothDevice device, {int? rssi}) {
    return BluetoothDeviceInfo(
      name: device.name.trim().isNotEmpty ? device.name.trim() : 'Unnamed device',
      address: device.address,
      isBonded: device.paired,
      isConnected: _bluetoothService.isConnected,
      rssi: rssi,
    );
  }
}
