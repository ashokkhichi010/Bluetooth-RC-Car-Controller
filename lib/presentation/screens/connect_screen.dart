import 'package:bluetooth_rc_car/domain/models/app_state.dart';
import 'package:bluetooth_rc_car/domain/models/bluetooth_device_info.dart';
import 'package:bluetooth_rc_car/domain/models/car_state.dart';
import 'package:bluetooth_rc_car/presentation/providers/app_state_provider.dart';
import 'package:bluetooth_rc_car/presentation/screens/screen_scaffold.dart';
import 'package:bluetooth_rc_car/presentation/widgets/connection_status_chip.dart';
import 'package:bluetooth_rc_car/presentation/widgets/status_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectScreen extends ConsumerWidget {
  const ConnectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    final theme = Theme.of(context);

    return ScreenScaffold(
      title: 'Bluetooth Connection',
      subtitle:
          'Manage your HC-05 link, reconnect faster, and keep the car ready for line, obstacle, or manual driving.',
      children: [
        _HeroCard(state: state),
        const SizedBox(height: 18),
        _QuickActions(
          state: state,
          onScan: controller.scanDevices,
          onRefresh: controller.refreshDevices,
          onDisconnect: controller.disconnect,
          onForgetSavedDevice: controller.forgetSavedDevice,
        ),
        const SizedBox(height: 18),
        if (state.lastSavedDevice != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: _SavedDeviceCard(
              device: state.lastSavedDevice!,
              isConnected:
                  state.connectedDevice?.address ==
                  state.lastSavedDevice!.address,
              onConnect: () => controller.connect(
                state.lastSavedDevice!,
                showStatusMessage: true,
              ),
            ),
          ),
        _DeviceSection(
          title: 'Paired Devices',
          subtitle:
              'Fastest path for HC-05 modules already paired in Android settings.',
          icon: Icons.link_rounded,
          accentColor: theme.colorScheme.primary,
          devices: state.pairedDevices,
          connectedAddress: state.connectedDevice?.address,
          onConnect: controller.connect,
          emptyMessage: 'No paired devices found yet.',
        ),
        const SizedBox(height: 18),
        _DeviceSection(
          title: 'Nearby Discovery',
          subtitle: state.isScanning
              ? 'Searching for nearby classic Bluetooth devices right now.'
              : 'Start a scan to discover nearby Bluetooth modules.',
          icon: Icons.radar_rounded,
          accentColor: const Color(0xFF79C7FF),
          devices: state.discoveredDevices,
          connectedAddress: state.connectedDevice?.address,
          onConnect: controller.connect,
          emptyMessage: state.isScanning
              ? 'Scanning in progress...'
              : 'No discovered devices yet.',
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = switch (state.connectionStatus) {
      ConnectionStatus.connected => const Color(0xFF38D39F),
      ConnectionStatus.connecting => const Color(0xFFFFC857),
      ConnectionStatus.disconnected => const Color(0xFFFF6B6B),
    };

    final headline = switch (state.connectionStatus) {
      ConnectionStatus.connected => 'Car linked and ready',
      ConnectionStatus.connecting => 'Establishing Bluetooth link',
      ConnectionStatus.disconnected => 'Waiting for a device',
    };

    final supportingText = state.connectedDevice != null
        ? 'Connected device: ${state.connectedDevice!.name}'
        : state.lastSavedDevice != null
        ? 'Last used device: ${state.lastSavedDevice!.name}'
        : 'Pair your HC-05 module, then connect from this dashboard.';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.22),
            theme.cardColor,
            const Color(0xFF121B24),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: statusColor.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: statusColor.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    Icons.bluetooth_searching_rounded,
                    color: statusColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConnectionStatusChip(status: state.connectionStatus),
                      const SizedBox(height: 12),
                      Text(headline, style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        supportingText,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.76),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Paired',
                    value: '${state.pairedDevices.length}',
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStat(
                    label: 'Nearby',
                    value: state.isScanning
                        ? '...'
                        : '${state.discoveredDevices.length}',
                    color: const Color(0xFF79C7FF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStat(
                    label: 'Saved',
                    value: state.lastSavedDevice == null ? 'No' : 'Yes',
                    color: const Color(0xFFF4A261),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.state,
    required this.onScan,
    required this.onRefresh,
    required this.onDisconnect,
    required this.onForgetSavedDevice,
  });

  final AppState state;
  final VoidCallback onScan;
  final VoidCallback onRefresh;
  final VoidCallback onDisconnect;
  final VoidCallback onForgetSavedDevice;

  @override
  Widget build(BuildContext context) {
    return StatusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Run discovery, refresh paired modules, or clear the saved car in one place.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.96,
            children: [
              _ActionTile(
                title: state.isScanning ? 'Scanning' : 'Scan Devices',
                caption: 'Find nearby modules',
                icon: state.isScanning ? null : Icons.radar_rounded,
                tint: const Color(0xFF7ED6C4),
                onTap: onScan,
                loading: state.isScanning,
              ),
              _ActionTile(
                title: 'Refresh Paired',
                caption: 'Reload bonded devices',
                icon: Icons.refresh_rounded,
                tint: const Color(0xFF79C7FF),
                onTap: onRefresh,
              ),
              _ActionTile(
                title: 'Disconnect',
                caption: 'Close active link safely',
                icon: Icons.link_off_rounded,
                tint: const Color(0xFFFF8A80),
                onTap: state.connectedDevice != null ? onDisconnect : null,
              ),
              _ActionTile(
                title: 'Forget Saved',
                caption: 'Remove stored quick reconnect',
                icon: Icons.bookmark_remove_rounded,
                tint: const Color(0xFFF6BD60),
                onTap: state.lastSavedDevice != null
                    ? onForgetSavedDevice
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.caption,
    required this.tint,
    required this.onTap,
    this.icon,
    this.loading = false,
  });

  final String title;
  final String caption;
  final Color tint;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: enabled
              ? tint.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.03),
          border: Border.all(
            color: enabled
                ? tint.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.04),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: enabled
                      ? tint.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.06),
                ),
                child: loading
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(tint),
                        ),
                      )
                    : Icon(icon, color: enabled ? tint : Colors.white38),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: enabled ? Colors.white : Colors.white54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedDeviceCard extends StatelessWidget {
  const _SavedDeviceCard({
    required this.device,
    required this.isConnected,
    required this.onConnect,
  });

  final BluetoothDeviceInfo device;
  final bool isConnected;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF151E28),
        border: Border.all(
          color: const Color(0xFFF6BD60).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFFF6BD60).withValues(alpha: 0.14),
            ),
            child: const Icon(
              Icons.bookmark_added_rounded,
              color: Color(0xFFF6BD60),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved Device',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${device.name}  |  ${device.address}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonal(
            onPressed: isConnected ? null : onConnect,
            child: Text(isConnected ? 'Active' : 'Reconnect'),
          ),
        ],
      ),
    );
  }
}

class _DeviceSection extends StatelessWidget {
  const _DeviceSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.devices,
    required this.connectedAddress,
    required this.onConnect,
    required this.emptyMessage,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final List<BluetoothDeviceInfo> devices;
  final String? connectedAddress;
  final Future<void> Function(
    BluetoothDeviceInfo device, {
    bool showStatusMessage,
  }) onConnect;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return StatusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: accentColor.withValues(alpha: 0.14),
                ),
                child: Icon(icon, color: accentColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (devices.isEmpty)
            _EmptyDevices(message: emptyMessage)
          else
            ...devices.map(
              (device) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DeviceTile(
                  device: device,
                  accentColor: accentColor,
                  isConnected: connectedAddress == device.address,
                  onConnect: () => onConnect(device, showStatusMessage: true),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyDevices extends StatelessWidget {
  const _EmptyDevices({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Text(message),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.device,
    required this.accentColor,
    required this.isConnected,
    required this.onConnect,
  });

  final BluetoothDeviceInfo device;
  final Color accentColor;
  final bool isConnected;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final details = [
      device.address,
      if (device.rssi != null) 'RSSI ${device.rssi}',
      if (device.isBonded) 'Paired',
    ].join('  |  ');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: isConnected
              ? accentColor.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 430;

            final info = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: accentColor.withValues(alpha: 0.14),
                  ),
                  child: Icon(
                    isConnected
                        ? Icons.bluetooth_connected_rounded
                        : Icons.bluetooth_rounded,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              device.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (isConnected)
                            Container(
                              margin: const EdgeInsets.only(left: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: accentColor.withValues(alpha: 0.14),
                              ),
                              child: Text(
                                'Active',
                                style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        details,
                        maxLines: compact ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            );

            final action = FilledButton.tonal(
              onPressed: isConnected ? null : onConnect,
              style: FilledButton.styleFrom(
                backgroundColor: accentColor.withValues(alpha: 0.12),
                foregroundColor: accentColor,
              ),
              child: Text(isConnected ? 'Connected' : 'Connect'),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  info,
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: action,
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: info),
                const SizedBox(width: 16),
                action,
              ],
            );
          },
        ),
      ),
    );
  }
}
