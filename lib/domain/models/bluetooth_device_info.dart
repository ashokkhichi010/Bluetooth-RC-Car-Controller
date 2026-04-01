class BluetoothDeviceInfo {
  const BluetoothDeviceInfo({
    required this.name,
    required this.address,
    required this.isBonded,
    required this.isConnected,
    this.rssi,
  });

  final String name;
  final String address;
  final bool isBonded;
  final bool isConnected;
  final int? rssi;

  BluetoothDeviceInfo copyWith({
    String? name,
    String? address,
    bool? isBonded,
    bool? isConnected,
    int? rssi,
    bool clearRssi = false,
  }) {
    return BluetoothDeviceInfo(
      name: name ?? this.name,
      address: address ?? this.address,
      isBonded: isBonded ?? this.isBonded,
      isConnected: isConnected ?? this.isConnected,
      rssi: clearRssi ? null : (rssi ?? this.rssi),
    );
  }
}
