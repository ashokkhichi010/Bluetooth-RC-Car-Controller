import 'package:bluetooth_rc_car/domain/models/robot_log_entry.dart';
import 'package:bluetooth_rc_car/domain/models/robot_state.dart';
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
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RobotState>(
      stream: ref.read(robotRepositoryProvider).watchRobotState(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorScaffold(message: snapshot.error.toString());
        }

        final state = snapshot.data ?? RobotState.initial();
        final controller = ref.read(robotControllerProvider);
        final speedValue = state.speed.clamp(0, 255);
        final connectionTime = state.lastSeenCounter;

        return Scaffold(
          body: Container(
            color: const Color(0xFF0B1219),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _StatusCard(
                      label: _labelForMode(
                        state.currentMode,
                        state.isConnected,
                      ),
                      deviceName: state.isConnected
                          ? 'Time: $connectionTime'
                          : 'Robot disconnected',
                      color: state.isConnected
                          ? const Color(0xFF38D39F)
                          : const Color(0xFFFF6B6B),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton.filledTonal(
                            onPressed: () => _openLogs(context),
                            icon: const Icon(Icons.notes_rounded),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            onPressed: () => _openSpeedSheet(
                              context,
                              controller,
                              speedValue.toDouble(),
                            ),
                            icon: const Icon(Icons.speed_rounded),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ModeGrid(
                      activeMode: state.currentMode,
                      onModeSelected: controller.changeMode,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: MovementVisualizer(
                        mode: state.currentMode,
                        direction: state.direction,
                        obstacleDistance: state.obstacleDistance,
                        obstacleTooClose: state.obstacleTooClose,
                        servoAngle: state.servoDirection,
                        speed: state.speed,
                        interactive: state.currentMode == RobotMode.manual,
                        onDirectionChanged: (direction) {
                          controller.sendMove(direction);
                        },
                        onInteractionEnd: () {
                          controller.sendMove(MovementDirection.stop);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openLogs(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LogsScreen()));
  }

  Future<void> _openSpeedSheet(
    BuildContext context,
    RobotController controller,
    double initialSpeed,
  ) async {
    double draft = initialSpeed;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF121A24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set Speed',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${draft.round()} / 255',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Slider(
                    value: draft,
                    min: 0,
                    max: 255,
                    divisions: 255,
                    onChanged: (value) {
                      setModalState(() => draft = value);
                    },
                  ),
                  FilledButton(
                    onPressed: () async {
                      // setState(() => _speedDraft = null);
                      await controller.updateSpeed(draft.round());
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Apply Speed'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _labelForMode(RobotMode mode, bool connected) {
    if (!connected) {
      return 'Disconnected';
    }

    return switch (mode) {
      RobotMode.line => 'Follow Line',
      RobotMode.auto => 'Auto Mode',
      RobotMode.follow => 'Follow Me',
      RobotMode.manual => 'Manual Control',
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

class _ModeGrid extends StatelessWidget {
  const _ModeGrid({required this.activeMode, required this.onModeSelected});

  final RobotMode activeMode;
  final Future<void> Function(RobotMode mode) onModeSelected;

  @override
  Widget build(BuildContext context) {
    final items = <({RobotMode mode, String label, IconData icon})>[
      (mode: RobotMode.manual, label: 'Manual', icon: Icons.gamepad_rounded),
      (mode: RobotMode.line, label: 'Follow Line', icon: Icons.route_rounded),
      (mode: RobotMode.auto, label: 'Auto Mode', icon: Icons.sensors_rounded),
      (
        mode: RobotMode.follow,
        label: 'Follow Me',
        icon: Icons.person_pin_circle_rounded,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.3,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final selected = item.mode == activeMode;
        return InkWell(
          onTap: () async {
            if (item.mode == RobotMode.follow) {
              final status = await context.readFollowMe();
              if (!context.mounted) {
                return;
              }
              final messenger = ScaffoldMessenger.of(context);
              switch (status) {
                case FollowMeStatus.active:
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Follow Me mode activated.')),
                  );
                case FollowMeStatus.locationDisabled:
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Turn on location services to use Follow Me.',
                      ),
                    ),
                  );
                case FollowMeStatus.permissionDenied:
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Location permission is required for Follow Me.',
                      ),
                    ),
                  );
              }
              return;
            }

            await onModeSelected(item.mode);
          },
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              color: selected
                  ? Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.18)
                  : const Color(0xFF121A24),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.45)
                    : Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(item.icon),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class LogsScreen extends ConsumerWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          IconButton.filledTonal(
            onPressed: ref.read(robotRepositoryProvider).deleteLogs,
            icon: const Icon(Icons.delete_sweep),
          ),
        ],
      ),
      body: StreamBuilder<List<RobotLogEntry>>(
        stream: ref.read(robotRepositoryProvider).watchLogs(),
        builder: (context, snapshot) {
          final logs = snapshot.data ?? const <RobotLogEntry>[];
          if (logs.isEmpty) {
            return const Center(child: Text('No logs yet'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final log = logs[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF121A24),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log.message),
                    if (log.timestamp != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        log.timestamp.toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

extension on BuildContext {
  Future<FollowMeStatus> readFollowMe() {
    final container = ProviderScope.containerOf(this, listen: false);
    return container.read(robotControllerProvider).activateFollowMe();
  }
}
