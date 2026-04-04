import 'package:bluetooth_rc_car/core/constants/app_constants.dart';
import 'package:bluetooth_rc_car/domain/models/app_state.dart';
import 'package:bluetooth_rc_car/domain/models/bluetooth_device_info.dart';
import 'package:bluetooth_rc_car/domain/models/car_state.dart';
import 'package:bluetooth_rc_car/presentation/providers/app_state_provider.dart';
import 'package:bluetooth_rc_car/presentation/widgets/movement_visualizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  CarMode _activeMode = CarMode.manual;
  MovementDirection? _gestureDirection;

  @override
  Widget build(BuildContext context) {
    ref.listen<AppState>(appControllerProvider, (previous, next) {
      final messenger = ScaffoldMessenger.of(context);

      if (previous?.errorMessage != next.errorMessage &&
          next.errorMessage != null) {
        messenger.showSnackBar(SnackBar(content: Text(next.errorMessage!)));
        ref.read(appControllerProvider.notifier).clearMessages();
      } else if (previous?.infoMessage != next.infoMessage &&
          next.infoMessage != null) {
        messenger.showSnackBar(SnackBar(content: Text(next.infoMessage!)));
        ref.read(appControllerProvider.notifier).clearMessages();
      }

      if (_gestureDirection == null &&
          next.carState.mode != CarMode.idle &&
          next.carState.mode != _activeMode) {
        setState(() => _activeMode = next.carState.mode);
      }
    });

    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);

    return Scaffold(
      body: Container(
        color: const Color(0xFF0B1219),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: state.isConnected
                ? _ConnectedHome(
                    state: state,
                    activeMode: _gestureDirection == null
                        ? _activeMode
                        : CarMode.manual,
                    previewDirection: _gestureDirection,
                    onFollowLine: () =>
                        _activateMode(controller, CarMode.lineFollower),
                    onAutoMode: () =>
                        _activateMode(controller, CarMode.obstacleAvoidance),
                    onFollowMe: () =>
                        _activateMode(controller, CarMode.followMe),
                    onSwitchToManual: () => _switchToManual(controller),
                    onDisconnect: controller.disconnect,
                    onDirectionChanged: _handleGestureDirection,
                    onInteractionEnd: _endManualInteraction,
                  )
                : _ConnectHome(
                    state: state,
                    onRefresh: controller.refreshDevices,
                    onScan: controller.scanDevices,
                    onConnect: (device) =>
                        controller.connect(device, showStatusMessage: true),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _activateMode(AppController controller, CarMode mode) async {
    setState(() {
      _gestureDirection = null;
      _activeMode = mode;
    });
    await controller.activateMode(mode);
  }

  Future<void> _switchToManual(AppController controller) async {
    if (_activeMode == CarMode.manual) {
      return;
    }

    setState(() {
      _gestureDirection = null;
      _activeMode = CarMode.manual;
    });
    await controller.activateMode(CarMode.manual);
  }

  Future<void> _handleGestureDirection(MovementDirection direction) async {
    if (_gestureDirection == direction) {
      return;
    }

    final controller = ref.read(appControllerProvider.notifier);
    setState(() {
      _gestureDirection = direction;
      _activeMode = CarMode.manual;
    });

    await controller.sendManualCommand(
      _commandForDirection(direction),
      direction: direction,
    );
  }

  Future<void> _endManualInteraction() async {
    final controller = ref.read(appControllerProvider.notifier);
    setState(() => _gestureDirection = null);
    await controller.sendManualCommand(
      AppConstants.commandStop,
      direction: MovementDirection.stop,
    );
  }

  String _commandForDirection(MovementDirection direction) {
    return switch (direction) {
      MovementDirection.forward => AppConstants.commandForward,
      MovementDirection.backward => AppConstants.commandBackward,
      MovementDirection.left => AppConstants.commandLeft,
      MovementDirection.right => AppConstants.commandRight,
      MovementDirection.forwardLeft => AppConstants.commandForwardLeft,
      MovementDirection.forwardRight => AppConstants.commandForwardRight,
      MovementDirection.backwardLeft => AppConstants.commandBackwardLeft,
      MovementDirection.backwardRight => AppConstants.commandBackwardRight,
      MovementDirection.stop => AppConstants.commandStop,
    };
  }
}

class _ConnectHome extends StatelessWidget {
  const _ConnectHome({
    required this.state,
    required this.onRefresh,
    required this.onScan,
    required this.onConnect,
  });

  final AppState state;
  final VoidCallback onRefresh;
  final VoidCallback onScan;
  final Future<void> Function(BluetoothDeviceInfo device) onConnect;

  @override
  Widget build(BuildContext context) {
    final devices = <BluetoothDeviceInfo>[
      ...state.pairedDevices,
      ...state.discoveredDevices.where(
        (device) => !state.pairedDevices.any(
          (paired) => paired.address == device.address,
        ),
      ),
    ];

    return Column(
      children: [
        _StatusCard(
          label: state.connectionStatus == ConnectionStatus.connecting
              ? 'Connecting'
              : 'Disconnected',
          deviceName: state.lastSavedDevice?.name,
          color: state.connectionStatus == ConnectionStatus.connecting
              ? const Color(0xFFFFC857)
              : const Color(0xFFFF6B6B),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filled(
                onPressed: onScan,
                icon: state.isScanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.radar_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF121A24),
              borderRadius: BorderRadius.circular(18),
            ),
            child: devices.isEmpty
                ? Center(
                    child: Text(
                      state.isScanning
                          ? 'Searching devices...'
                          : 'No devices found',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: devices.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return _DeviceTile(
                        device: device,
                        onConnect: () => onConnect(device),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _ConnectedHome extends StatelessWidget {
  const _ConnectedHome({
    required this.state,
    required this.activeMode,
    required this.previewDirection,
    required this.onFollowLine,
    required this.onAutoMode,
    required this.onFollowMe,
    required this.onSwitchToManual,
    required this.onDisconnect,
    required this.onDirectionChanged,
    required this.onInteractionEnd,
  });

  final AppState state;
  final CarMode activeMode;
  final MovementDirection? previewDirection;
  final Future<void> Function() onFollowLine;
  final Future<void> Function() onAutoMode;
  final Future<void> Function() onFollowMe;
  final Future<void> Function() onSwitchToManual;
  final Future<void> Function() onDisconnect;
  final Future<void> Function(MovementDirection direction) onDirectionChanged;
  final Future<void> Function() onInteractionEnd;

  @override
  Widget build(BuildContext context) {
    final displayDirection = previewDirection ?? state.carState.direction;
    final displaySpeed = previewDirection == null
        ? state.carState.speed
        : previewDirection == MovementDirection.stop
        ? 0
        : state.manualSpeed.round();

    return Column(
      children: [
        _StatusCard(
          label: _labelForMode(activeMode),
          deviceName: state.connectedDevice?.name,
          color: const Color(0xFF38D39F),
          trailing: IconButton.filledTonal(
            onPressed: onDisconnect,
            icon: const Icon(Icons.link_off_rounded),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ModeCard(
                label: 'Follow Line',
                icon: Icons.route_rounded,
                selected: activeMode == CarMode.lineFollower,
                onTap: onFollowLine,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ModeCard(
                label: 'Auto Mode',
                icon: Icons.sensors_rounded,
                selected: activeMode == CarMode.obstacleAvoidance,
                onTap: onAutoMode,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ModeCard(
                label: 'Follow Me',
                icon: Icons.person_pin_circle_rounded,
                selected: activeMode == CarMode.followMe,
                onTap: onFollowMe,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: MovementVisualizer(
            mode: activeMode,
            direction: displayDirection,
            speed: displaySpeed,
            interactive: activeMode == CarMode.manual,
            onTap: activeMode == CarMode.manual
                ? null
                : () {
                    onSwitchToManual();
                  },
            onDirectionChanged: (direction) {
              onDirectionChanged(direction);
            },
            onInteractionEnd: () {
              onInteractionEnd();
            },
          ),
        ),
      ],
    );
  }

  String _labelForMode(CarMode mode) {
    return switch (mode) {
      CarMode.lineFollower => 'Follow Line',
      CarMode.obstacleAvoidance => 'Auto Mode',
      CarMode.followMe => 'Follow Me',
      CarMode.manual => 'Manual Control',
      CarMode.idle => 'Connected',
    };
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.label,
    required this.color,
    required this.trailing,
    this.deviceName,
  });

  final String label;
  final String? deviceName;
  final Color color;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF121A24),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                if (deviceName != null)
                  Text(
                    deviceName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.18)
              : const Color(0xFF121A24),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 10),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.device, required this.onConnect});

  final BluetoothDeviceInfo device;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final resolvedName = device.name.trim().isEmpty
        ? 'Unknown Device'
        : device.name;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bluetooth_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resolvedName,
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
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onConnect,
                    child: const Text('Connect'),
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              const Icon(Icons.bluetooth_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resolvedName,
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
              FilledButton(onPressed: onConnect, child: const Text('Connect')),
            ],
          );
        },
      ),
    );
  }
}
