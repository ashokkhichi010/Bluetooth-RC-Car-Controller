import 'package:bluetooth_rc_car/domain/models/car_state.dart';
import 'package:bluetooth_rc_car/presentation/providers/app_state_provider.dart';
import 'package:bluetooth_rc_car/presentation/screens/screen_scaffold.dart';
import 'package:bluetooth_rc_car/presentation/widgets/direction_indicator.dart';
import 'package:bluetooth_rc_car/presentation/widgets/mode_dashboard_widgets.dart';
import 'package:bluetooth_rc_car/presentation/widgets/movement_visualizer.dart';
import 'package:bluetooth_rc_car/presentation/widgets/obstacle_indicator.dart';
import 'package:bluetooth_rc_car/presentation/widgets/speed_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ObstacleModeScreen extends ConsumerWidget {
  const ObstacleModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appControllerProvider);
    final carState = appState.carState;

    return ScreenScaffold(
      title: 'Obstacle Avoidance',
      subtitle:
          'Watch obstacle telemetry, rerouting behavior, and sensor-driven motion changes in real time.',
      children: [
        ModeHeroCard(
          title: 'Reactive obstacle handling',
          description: appState.isConnected
              ? 'The robot is ready to scan, warn, and reroute around nearby obstacles through the HC-05 link.'
              : 'Connect the car first, then open this screen to auto-request obstacle-avoidance mode.',
          accentColor: const Color(0xFFFF8A80),
          icon: Icons.sensors_rounded,
          carState: carState,
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TelemetryStat(
                label: 'Alert',
                value: carState.obstacleSide.label,
                tint: const Color(0xFFFF8A80),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TelemetryStat(
                label: 'Direction',
                value: carState.direction.label,
                tint: const Color(0xFF79C7FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TelemetryStat(
                label: 'Speed',
                value: '${carState.speed}',
                tint: const Color(0xFFF6BD60),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        ObstacleIndicator(obstacleSide: carState.obstacleSide),
        const SizedBox(height: 18),
        SpeedIndicator(speed: carState.speed),
        const SizedBox(height: 18),
        DirectionIndicator(direction: carState.direction),
        const SizedBox(height: 18),
        MovementVisualizer(
          mode: carState.mode,
          direction: carState.direction,
        ),
        const SizedBox(height: 18),
        const InsightsCard(
          title: 'Obstacle Mode Notes',
          points: [
            'Left, right, and both-side warnings are rendered directly from OBS telemetry.',
            'Use this view to confirm that rerouting decisions match live sensor detections.',
            'Unexpected rapid warning flips usually indicate noisy sensor data or unstable spacing.',
          ],
        ),
      ],
    );
  }
}
