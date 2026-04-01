import 'package:bluetooth_rc_car/domain/models/car_state.dart';
import 'package:bluetooth_rc_car/presentation/widgets/status_card.dart';
import 'package:flutter/material.dart';

class DirectionIndicator extends StatelessWidget {
  const DirectionIndicator({
    required this.direction,
    super.key,
  });

  final MovementDirection direction;

  @override
  Widget build(BuildContext context) {
    final icon = switch (direction) {
      MovementDirection.forward => Icons.north_rounded,
      MovementDirection.backward => Icons.south_rounded,
      MovementDirection.left => Icons.west_rounded,
      MovementDirection.right => Icons.east_rounded,
      MovementDirection.forwardLeft => Icons.north_west_rounded,
      MovementDirection.forwardRight => Icons.north_east_rounded,
      MovementDirection.backwardLeft => Icons.south_west_rounded,
      MovementDirection.backwardRight => Icons.south_east_rounded,
      MovementDirection.stop => Icons.stop_circle_outlined,
    };

    return StatusCard(
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
            ),
            child: Icon(icon, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Direction',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(direction.label),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
