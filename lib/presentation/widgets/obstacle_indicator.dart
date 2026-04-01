import 'package:bluetooth_rc_car/domain/models/car_state.dart';
import 'package:bluetooth_rc_car/presentation/widgets/status_card.dart';
import 'package:flutter/material.dart';

class ObstacleIndicator extends StatelessWidget {
  const ObstacleIndicator({
    required this.obstacleSide,
    super.key,
  });

  final ObstacleSide obstacleSide;

  @override
  Widget build(BuildContext context) {
    return StatusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Obstacle Detection',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Zone(
                  label: 'Left',
                  active: obstacleSide == ObstacleSide.left ||
                      obstacleSide == ObstacleSide.both,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Zone(
                  label: 'Right',
                  active: obstacleSide == ObstacleSide.right ||
                      obstacleSide == ObstacleSide.both,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                obstacleSide == ObstacleSide.none
                    ? Icons.verified_outlined
                    : Icons.warning_amber_rounded,
                color: obstacleSide == ObstacleSide.none
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
              ),
              const SizedBox(width: 10),
              Text(obstacleSide.label),
            ],
          ),
        ],
      ),
    );
  }
}

class _Zone extends StatelessWidget {
  const _Zone({
    required this.label,
    required this.active,
  });

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      height: 74,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: active
            ? Colors.redAccent.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: active
              ? Colors.redAccent.withValues(alpha: 0.55)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
