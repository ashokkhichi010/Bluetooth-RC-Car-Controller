import 'package:bluetooth_rc_car/core/constants/app_constants.dart';
import 'package:bluetooth_rc_car/domain/models/car_state.dart';
import 'package:bluetooth_rc_car/presentation/providers/app_state_provider.dart';
import 'package:bluetooth_rc_car/presentation/screens/screen_scaffold.dart';
import 'package:bluetooth_rc_car/presentation/widgets/control_button.dart';
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
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF121A24),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Text(
                'Current Speed',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                '${state.carState.speed}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SpeedTuningCard(
          speed: state.manualSpeed,
          onChanged: controller.updateManualSpeed,
        ),
        const SizedBox(height: 12),
        _ManualPad(
          enabled: state.isConnected,
          onCommand: controller.sendManualCommand,
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
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF121A24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                Text('${speed.round()} / ${AppConstants.maxSpeed.toInt()}'),
              ],
            ),
            const SizedBox(height: 8),
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
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFF121A24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (!enabled) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Connect the car to enable controls.'),
                ),
                const SizedBox(height: 12),
              ],
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  ControlButton(
                    icon: Icons.north_west_rounded,
                    label: 'FL',
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
                    label: 'F',
                    onPressed: enabled
                        ? () => onCommand(
                              AppConstants.commandForward,
                              direction: MovementDirection.forward,
                            )
                        : null,
                  ),
                  ControlButton(
                    icon: Icons.north_east_rounded,
                    label: 'FR',
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
                    label: 'L',
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
                    label: 'S',
                    onPressed: enabled
                        ? () => onCommand(
                              AppConstants.commandStop,
                              direction: MovementDirection.stop,
                            )
                        : null,
                  ),
                  ControlButton(
                    icon: Icons.east_rounded,
                    label: 'R',
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
                    label: 'BL',
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
                    label: 'B',
                    onPressed: enabled
                        ? () => onCommand(
                              AppConstants.commandBackward,
                              direction: MovementDirection.backward,
                            )
                        : null,
                  ),
                  ControlButton(
                    icon: Icons.south_east_rounded,
                    label: 'BR',
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
