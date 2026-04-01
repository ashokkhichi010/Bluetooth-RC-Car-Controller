import 'package:bluetooth_rc_car/core/constants/app_constants.dart';
import 'package:bluetooth_rc_car/domain/models/car_state.dart';
import 'package:bluetooth_rc_car/presentation/providers/app_state_provider.dart';
import 'package:bluetooth_rc_car/presentation/screens/screen_scaffold.dart';
import 'package:bluetooth_rc_car/presentation/widgets/control_button.dart';
import 'package:bluetooth_rc_car/presentation/widgets/direction_indicator.dart';
import 'package:bluetooth_rc_car/presentation/widgets/mode_dashboard_widgets.dart';
import 'package:bluetooth_rc_car/presentation/widgets/movement_visualizer.dart';
import 'package:bluetooth_rc_car/presentation/widgets/speed_indicator.dart';
import 'package:bluetooth_rc_car/presentation/widgets/status_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManualModeScreen extends ConsumerWidget {
  const ManualModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);

    return ScreenScaffold(
      title: 'Manual Drive',
      subtitle:
          'Take direct control of the RC car with live commands, saved speed tuning, and a refined directional pad.',
      children: [
        ModeHeroCard(
          title: 'Hands-on driving',
          description: state.isConnected
              ? 'Manual commands are live. Use the pad below to steer, stop instantly, or test diagonals.'
              : 'Connect the HC-05 module first, then use this screen as the direct driving console.',
          accentColor: const Color(0xFF79C7FF),
          icon: Icons.gamepad_rounded,
          carState: state.carState,
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TelemetryStat(
                label: 'Control Link',
                value: state.isConnected ? 'Live' : 'Offline',
                tint: state.isConnected
                    ? const Color(0xFF7ED6C4)
                    : const Color(0xFFFF8A80),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TelemetryStat(
                label: 'Direction',
                value: state.carState.direction.label,
                tint: const Color(0xFF79C7FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TelemetryStat(
                label: 'Preset',
                value: '${state.manualSpeed.round()}',
                tint: const Color(0xFFF6BD60),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SpeedIndicator(speed: state.carState.speed),
        const SizedBox(height: 18),
        DirectionIndicator(direction: state.carState.direction),
        const SizedBox(height: 18),
        MovementVisualizer(
          mode: CarMode.manual,
          direction: state.carState.direction,
        ),
        const SizedBox(height: 18),
        _SpeedTuningCard(
          speed: state.manualSpeed,
          onChanged: controller.updateManualSpeed,
        ),
        const SizedBox(height: 18),
        _ManualPad(
          enabled: state.isConnected,
          onCommand: controller.sendManualCommand,
        ),
        const SizedBox(height: 18),
        const InsightsCard(
          title: 'Manual Mode Notes',
          points: [
            'Diagonal buttons send G, I, H, and J for finer turning control.',
            'Stop stays centered for quick emergency interruption while driving.',
            'The manual speed slider updates the optimistic UI speed shown after each command.',
          ],
        ),
      ],
    );
  }
}

class _SpeedTuningCard extends StatelessWidget {
  const _SpeedTuningCard({
    required this.speed,
    required this.onChanged,
  });

  final double speed;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF79C7FF).withValues(alpha: 0.16),
            const Color(0xFF121B24),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFF79C7FF).withValues(alpha: 0.16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Manual Speed',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  child: Text('${speed.round()} / ${AppConstants.maxSpeed.toInt()}'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Tune the pace before sending commands so the car responds predictably during live manual control.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Slider(
              value: speed,
              min: 0,
              max: AppConstants.maxSpeed,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualPad extends StatelessWidget {
  const _ManualPad({
    required this.enabled,
    required this.onCommand,
  });

  final bool enabled;
  final Future<void> Function(
    String command, {
    required MovementDirection direction,
  })
  onCommand;

  @override
  Widget build(BuildContext context) {
    return StatusCard(
      padding: const EdgeInsets.all(0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.03),
              const Color(0xFF79C7FF).withValues(alpha: 0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Control Pad',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                enabled
                    ? 'Tap any direction to send live commands instantly.'
                    : 'Connect to the HC-05 module to unlock the drive controls.',
              ),
              const SizedBox(height: 18),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  ControlButton(
                    icon: Icons.north_west_rounded,
                    label: 'Front Left',
                    onPressed: enabled
                        ? () => onCommand(
                              AppConstants.commandForwardLeft,
                              direction: MovementDirection.forwardLeft,
                            )
                        : null,
                    filled: false,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                    ),
                  ),
                  ControlButton(
                    icon: Icons.north_rounded,
                    label: 'Forward',
                    onPressed: enabled
                        ? () => onCommand(
                              AppConstants.commandForward,
                              direction: MovementDirection.forward,
                            )
                        : null,
                  ),
                  ControlButton(
                    icon: Icons.north_east_rounded,
                    label: 'Front Right',
                    onPressed: enabled
                        ? () => onCommand(
                              AppConstants.commandForwardRight,
                              direction: MovementDirection.forwardRight,
                            )
                        : null,
                    filled: false,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                    ),
                  ),
                  ControlButton(
                    icon: Icons.west_rounded,
                    label: 'Left',
                    onPressed: enabled
                        ? () => onCommand(
                              AppConstants.commandLeft,
                              direction: MovementDirection.left,
                            )
                        : null,
                    filled: false,
                  ),
                  ControlButton(
                    icon: Icons.stop_rounded,
                    label: 'Stop',
                    onPressed: enabled
                        ? () => onCommand(
                              AppConstants.commandStop,
                              direction: MovementDirection.stop,
                            )
                        : null,
                  ),
                  ControlButton(
                    icon: Icons.east_rounded,
                    label: 'Right',
                    onPressed: enabled
                        ? () => onCommand(
                              AppConstants.commandRight,
                              direction: MovementDirection.right,
                            )
                        : null,
                    filled: false,
                  ),
                  ControlButton(
                    icon: Icons.south_west_rounded,
                    label: 'Back Left',
                    onPressed: enabled
                        ? () => onCommand(
                              AppConstants.commandBackwardLeft,
                              direction: MovementDirection.backwardLeft,
                            )
                        : null,
                    filled: false,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                  ControlButton(
                    icon: Icons.south_rounded,
                    label: 'Backward',
                    onPressed: enabled
                        ? () => onCommand(
                              AppConstants.commandBackward,
                              direction: MovementDirection.backward,
                            )
                        : null,
                  ),
                  ControlButton(
                    icon: Icons.south_east_rounded,
                    label: 'Back Right',
                    onPressed: enabled
                        ? () => onCommand(
                              AppConstants.commandBackwardRight,
                              direction: MovementDirection.backwardRight,
                            )
                        : null,
                    filled: false,
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
