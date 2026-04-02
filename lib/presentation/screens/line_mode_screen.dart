import 'package:bluetooth_rc_car/domain/models/car_state.dart';
import 'package:bluetooth_rc_car/presentation/providers/app_state_provider.dart';
import 'package:bluetooth_rc_car/presentation/screens/screen_scaffold.dart';
import 'package:bluetooth_rc_car/presentation/widgets/direction_indicator.dart';
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
      children: [
        SimpleStatsRow(
          values: [
            SimpleStatData('Mode', 'Line'),
            SimpleStatData('Speed', '${carState.speed}'),
            SimpleStatData('Direction', carState.direction.label),
          ],
        ),
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
          const InfoStrip(label: 'Connect the car to start line mode.'),
        ],
      ],
    );
  }
}

class SimpleStatsRow extends StatelessWidget {
  const SimpleStatsRow({required this.values, super.key});

  final List<SimpleStatData> values;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < values.length; i++) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF121A24),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    values[i].label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    values[i].value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          if (i != values.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class SimpleStatData {
  const SimpleStatData(this.label, this.value);

  final String label;
  final String value;
}

class InfoStrip extends StatelessWidget {
  const InfoStrip({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(label),
    );
  }
}
