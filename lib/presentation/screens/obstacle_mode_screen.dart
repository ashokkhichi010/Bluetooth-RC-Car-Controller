import 'package:bluetooth_rc_car/domain/models/car_state.dart';
import 'package:bluetooth_rc_car/presentation/providers/app_state_provider.dart';
import 'package:bluetooth_rc_car/presentation/screens/line_mode_screen.dart'
    show InfoStrip, SimpleStatData, SimpleStatsRow;
import 'package:bluetooth_rc_car/presentation/screens/screen_scaffold.dart';
import 'package:bluetooth_rc_car/presentation/widgets/direction_indicator.dart';
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
      children: [
        SimpleStatsRow(
          values: [
            SimpleStatData('Alert', carState.obstacleSide.label),
            SimpleStatData('Speed', '${carState.speed}'),
            SimpleStatData('Direction', carState.direction.label),
          ],
        ),
        const SizedBox(height: 12),
        ObstacleIndicator(obstacleSide: carState.obstacleSide),
        const SizedBox(height: 12),
        SpeedIndicator(speed: carState.speed),
        const SizedBox(height: 12),
        DirectionIndicator(direction: carState.direction),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: MovementVisualizer(
            mode: carState.mode,
            direction: carState.direction,
          ),
        ),
        if (!appState.isConnected) ...[
          const SizedBox(height: 12),
          const InfoStrip(label: 'Connect the car to start obstacle mode.'),
        ],
      ],
    );
  }
}
