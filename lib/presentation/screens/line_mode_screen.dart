import 'package:bluetooth_rc_car/domain/models/car_state.dart';
import 'package:bluetooth_rc_car/presentation/providers/app_state_provider.dart';
import 'package:bluetooth_rc_car/presentation/screens/screen_scaffold.dart';
import 'package:bluetooth_rc_car/presentation/widgets/direction_indicator.dart';
import 'package:bluetooth_rc_car/presentation/widgets/mode_dashboard_widgets.dart';
import 'package:bluetooth_rc_car/presentation/widgets/movement_visualizer.dart';
import 'package:bluetooth_rc_car/presentation/widgets/speed_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LineModeScreen extends ConsumerWidget {
  const LineModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appControllerProvider);
    final carState = appState.carState;

    return ScreenScaffold(
      title: 'Line Follower',
      subtitle:
          'Monitor line-tracking behavior, motion confidence, and live steering changes from the Arduino controller.',
      children: [
        ModeHeroCard(
          title: 'Autonomous line tracking',
          description: appState.isConnected
              ? 'Telemetry is streaming from the HC-05 link. Keep the robot centered on the line and watch heading corrections live.'
              : 'Connect to your HC-05 module, then open this screen to push the car into line-follow mode automatically.',
          accentColor: const Color(0xFF7ED6C4),
          icon: Icons.route_rounded,
          carState: carState,
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TelemetryStat(
                label: 'Mode',
                value: carState.mode == CarMode.lineFollower
                    ? 'LINE'
                    : carState.mode.label.toUpperCase(),
                tint: const Color(0xFF7ED6C4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TelemetryStat(
                label: 'Motion',
                value: carState.isMoving ? 'Active' : 'Idle',
                tint: const Color(0xFF79C7FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TelemetryStat(
                label: 'Heading',
                value: carState.direction.label,
                tint: const Color(0xFFF6BD60),
              ),
            ),
          ],
        ),
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
        InsightsCard(
          title: 'Line Follower Notes',
          points: [
            appState.isConnected
                ? 'The screen auto-requests line-follow mode when opened from the drawer.'
                : 'A Bluetooth connection is required before the robot can enter line-follow mode.',
            'Speed and direction update directly from parsed serial telemetry packets.',
            'Use this view to confirm that line corrections remain smooth instead of jittery.',
          ],
        ),
      ],
    );
  }
}
