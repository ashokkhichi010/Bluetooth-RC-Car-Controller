import 'package:bluetooth_rc_car/domain/models/bluetooth_device_info.dart';
import 'package:bluetooth_rc_car/presentation/providers/app_state_provider.dart';
import 'package:bluetooth_rc_car/presentation/screens/screen_scaffold.dart';
import 'package:bluetooth_rc_car/presentation/widgets/connection_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectScreen extends ConsumerWidget {
  const ConnectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    final devices = <BluetoothDeviceInfo>[
      ...state.pairedDevices,
      ...state.discoveredDevices.where(
        (device) => !state.pairedDevices.any(
          (paired) => paired.address == device.address,
        ),
      ),
    ];

    return ScreenScaffold(
      title: 'Bluetooth Connection',
      children: [
        Row(
          children: [
            ConnectionStatusChip(status: state.connectionStatus),
            const Spacer(),
            TextButton.icon(
              onPressed: controller.refreshDevices,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: controller.scanDevices,
              icon: state.isScanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.radar_rounded),
              label: Text(state.isScanning ? 'Scanning' : 'Scan'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF121A24),
            borderRadius: BorderRadius.circular(18),
          ),
          child: devices.isEmpty
              ? SizedBox(
                  height: 180,
                  child: Center(
                    child: Text(
                      state.isScanning ? 'Searching devices...' : 'No devices found',
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount: devices.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return _DeviceRow(
                      device: device,
                      connectedAddress: state.connectedDevice?.address,
                      onConnect: () => controller.connect(
                        device,
                        showStatusMessage: true,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.device,
    required this.connectedAddress,
    required this.onConnect,
  });

  final BluetoothDeviceInfo device;
  final String? connectedAddress;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final isConnected = connectedAddress == device.address;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.bluetooth_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  device.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          isConnected
              ? const Text('Connected')
              : FilledButton(
                  onPressed: onConnect,
                  child: const Text('Connect'),
                ),
        ],
      ),
    );
  }
}
