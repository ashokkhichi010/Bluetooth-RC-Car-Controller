import 'package:bluetooth_rc_car/core/constants/app_constants.dart';
import 'package:bluetooth_rc_car/domain/models/app_state.dart';
import 'package:bluetooth_rc_car/domain/models/bluetooth_device_info.dart';
import 'package:bluetooth_rc_car/domain/models/car_state.dart';
import 'package:bluetooth_rc_car/presentation/providers/app_state_provider.dart';
import 'package:bluetooth_rc_car/presentation/widgets/control_button.dart';
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

      if (next.carState.mode != CarMode.idle &&
          next.carState.mode != _activeMode) {
        setState(() => _activeMode = next.carState.mode);
      }

      final justConnected = previous?.isConnected != true && next.isConnected;
      if (justConnected) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _openModeSwitcher();
          }
        });
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
                    activeMode: _activeMode,
                    onOpenModeSwitcher: _openModeSwitcher,
                    onManualCommand: controller.sendManualCommand,
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

  Future<void> _openModeSwitcher() async {
    final controller = ref.read(appControllerProvider.notifier);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF141D27),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ModeOption(
                  label: 'Line',
                  selected: _activeMode == CarMode.lineFollower,
                  onTap: () async {
                    Navigator.of(context).pop();
                    setState(() => _activeMode = CarMode.lineFollower);
                    await controller.activateMode(CarMode.lineFollower);
                  },
                ),
                const SizedBox(height: 10),
                _ModeOption(
                  label: 'Obstacle',
                  selected: _activeMode == CarMode.obstacleAvoidance,
                  onTap: () async {
                    Navigator.of(context).pop();
                    setState(() => _activeMode = CarMode.obstacleAvoidance);
                    await controller.activateMode(CarMode.obstacleAvoidance);
                  },
                ),
                const SizedBox(height: 10),
                _ModeOption(
                  label: 'Manual',
                  selected: _activeMode == CarMode.manual,
                  onTap: () async {
                    Navigator.of(context).pop();
                    setState(() => _activeMode = CarMode.manual);
                    await controller.activateMode(CarMode.manual);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
        Row(
          children: [
            Expanded(
              child: _StatusStrip(
                label: state.connectionStatus == ConnectionStatus.connecting
                    ? 'Connecting'
                    : 'Disconnected',
                color: state.connectionStatus == ConnectionStatus.connecting
                    ? const Color(0xFFFFC857)
                    : const Color(0xFFFF6B6B),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: onScan,
              icon: state.isScanning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.radar_rounded),
            ),
          ],
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
    required this.onOpenModeSwitcher,
    required this.onManualCommand,
  });

  final AppState state;
  final CarMode activeMode;
  final VoidCallback onOpenModeSwitcher;
  final Future<void> Function(
    String command, {
    required MovementDirection direction,
  })
  onManualCommand;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatusStrip(
                label: state.connectedDevice?.name ?? 'Connected',
                color: const Color(0xFF38D39F),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              onPressed: onOpenModeSwitcher,
              icon: const Icon(Icons.more_vert_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: activeMode == CarMode.manual
              ? _ManualModePanel(state: state, onManualCommand: onManualCommand)
              : _TelemetryModePanel(state: state, activeMode: activeMode),
        ),
      ],
    );
  }
}

class _TelemetryModePanel extends StatelessWidget {
  const _TelemetryModePanel({required this.state, required this.activeMode});

  final AppState state;
  final CarMode activeMode;

  @override
  Widget build(BuildContext context) {
    final obstacleText = switch (state.carState.obstacleSide) {
      ObstacleSide.left => 'Left',
      ObstacleSide.right => 'Right',
      ObstacleSide.both => 'Both',
      ObstacleSide.none => 'Clear',
    };

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ValueTile(
                label: 'Mode',
                value: activeMode == CarMode.lineFollower ? 'Line' : 'Obstacle',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ValueTile(
                label: 'Speed',
                value: '${state.carState.speed}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ValueTile(
                label: activeMode == CarMode.obstacleAvoidance
                    ? 'Obstacle'
                    : 'Direction',
                value: activeMode == CarMode.obstacleAvoidance
                    ? obstacleText
                    : state.carState.direction.label,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF121A24),
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.all(12),
            child: MovementVisualizer(
              mode: activeMode,
              direction: state.carState.direction,
            ),
          ),
        ),
      ],
    );
  }
}

class _ManualModePanel extends StatelessWidget {
  const _ManualModePanel({required this.state, required this.onManualCommand});

  final AppState state;
  final Future<void> Function(
    String command, {
    required MovementDirection direction,
  })
  onManualCommand;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ValueTile(label: 'Current Speed', value: '${state.carState.speed}'),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.only(top: 120),
            crossAxisCount: 3,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
            children: [
              ControlButton(
                icon: Icons.north_west_rounded,
                label: 'FL',
                onPressed: () => onManualCommand(
                  AppConstants.commandForwardLeft,
                  direction: MovementDirection.forwardLeft,
                ),
                filled: false,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                ),
              ),
              ControlButton(
                icon: Icons.north_rounded,
                label: 'F',
                onPressed: () => onManualCommand(
                  AppConstants.commandForward,
                  direction: MovementDirection.forward,
                ),
              ),
              ControlButton(
                icon: Icons.north_east_rounded,
                label: 'FR',
                onPressed: () => onManualCommand(
                  AppConstants.commandForwardRight,
                  direction: MovementDirection.forwardRight,
                ),
                filled: false,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(18),
                ),
              ),
              ControlButton(
                icon: Icons.west_rounded,
                label: 'L',
                onPressed: () => onManualCommand(
                  AppConstants.commandLeft,
                  direction: MovementDirection.left,
                ),
                filled: false,
              ),
              ControlButton(
                icon: Icons.stop_rounded,
                label: 'S',
                onPressed: () => onManualCommand(
                  AppConstants.commandStop,
                  direction: MovementDirection.stop,
                ),
              ),
              ControlButton(
                icon: Icons.east_rounded,
                label: 'R',
                onPressed: () => onManualCommand(
                  AppConstants.commandRight,
                  direction: MovementDirection.right,
                ),
                filled: false,
              ),
              ControlButton(
                icon: Icons.south_west_rounded,
                label: 'BL',
                onPressed: () => onManualCommand(
                  AppConstants.commandBackwardLeft,
                  direction: MovementDirection.backwardLeft,
                ),
                filled: false,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                ),
              ),
              ControlButton(
                icon: Icons.south_rounded,
                label: 'B',
                onPressed: () => onManualCommand(
                  AppConstants.commandBackward,
                  direction: MovementDirection.backward,
                ),
              ),
              ControlButton(
                icon: Icons.south_east_rounded,
                label: 'BR',
                onPressed: () => onManualCommand(
                  AppConstants.commandBackwardRight,
                  direction: MovementDirection.backwardRight,
                ),
                filled: false,
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.device, required this.onConnect});

  final BluetoothDeviceInfo device;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
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
                Text(device.name, maxLines: 1, overflow: TextOverflow.ellipsis),
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
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
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
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  const _ValueTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF121A24),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            if (selected) const Icon(Icons.check_rounded),
          ],
        ),
      ),
    );
  }
}
