import 'package:bluetooth_rc_car/core/constants/app_constants.dart';
import 'package:bluetooth_rc_car/domain/models/car_state.dart';
import 'package:bluetooth_rc_car/presentation/widgets/status_card.dart';
import 'package:flutter/material.dart';

class MovementVisualizer extends StatelessWidget {
  const MovementVisualizer({
    required this.mode,
    required this.direction,
    super.key,
  });

  final CarMode mode;
  final MovementDirection direction;

  @override
  Widget build(BuildContext context) {
    final alignment = switch (direction) {
      MovementDirection.forward => Alignment.topCenter,
      MovementDirection.backward => Alignment.bottomCenter,
      MovementDirection.left => Alignment.centerLeft,
      MovementDirection.right => Alignment.centerRight,
      MovementDirection.forwardLeft => Alignment.topLeft,
      MovementDirection.forwardRight => Alignment.topRight,
      MovementDirection.backwardLeft => Alignment.bottomLeft,
      MovementDirection.backwardRight => Alignment.bottomRight,
      MovementDirection.stop => Alignment.center,
    };

    return StatusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mode == CarMode.lineFollower
                ? 'Line Tracking'
                : mode == CarMode.obstacleAvoidance
                    ? 'Avoidance Path'
                    : 'Motion Preview',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.03),
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                const _PathOverlay(),
                AnimatedAlign(
                  duration: AppConstants.defaultAnimationDuration,
                  curve: Curves.easeOutCubic,
                  alignment: alignment,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: _CarGlyph(direction: direction),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PathOverlay extends StatelessWidget {
  const _PathOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PathPainter(
        lineColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.24),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _CarGlyph extends StatelessWidget {
  const _CarGlyph({required this.direction});

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
      MovementDirection.stop => Icons.stop_rounded,
    };

    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 22,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Icon(icon, size: 38, color: Colors.black87),
    );
  }
}

class _PathPainter extends CustomPainter {
  _PathPainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path()
      ..moveTo(size.width * 0.5, size.height)
      ..quadraticBezierTo(
        size.width * 0.15,
        size.height * 0.65,
        size.width * 0.32,
        size.height * 0.35,
      )
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.12,
        size.width * 0.5,
        0,
      );

    final altPath = Path()
      ..moveTo(size.width * 0.5, size.height)
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.65,
        size.width * 0.68,
        size.height * 0.35,
      )
      ..quadraticBezierTo(
        size.width * 0.52,
        size.height * 0.12,
        size.width * 0.5,
        0,
      );

    canvas.drawPath(path, paint);
    canvas.drawPath(altPath, paint);
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}
