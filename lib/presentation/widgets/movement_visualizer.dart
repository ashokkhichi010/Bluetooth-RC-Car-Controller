import 'package:bluetooth_rc_car/core/constants/app_constants.dart';
import 'package:bluetooth_rc_car/domain/models/robot_state.dart';
import 'package:bluetooth_rc_car/presentation/widgets/status_card.dart';
import 'package:flutter/material.dart';

class MovementVisualizer extends StatefulWidget {
  const MovementVisualizer({
    required this.mode,
    required this.direction,
    required this.obstacleDistance,
    required this.obstacleTooClose,
    required this.servoAngle,
    this.speed,
    this.interactive = false,
    this.onTap,
    this.onDirectionChanged,
    this.onInteractionEnd,
    super.key,
  });

  final RobotMode mode;
  final MovementDirection direction;
  final double obstacleDistance;
  final bool obstacleTooClose;
  final int servoAngle;
  final int? speed;
  final bool interactive;
  final VoidCallback? onTap;
  final ValueChanged<MovementDirection>? onDirectionChanged;
  final VoidCallback? onInteractionEnd;

  @override
  State<MovementVisualizer> createState() => _MovementVisualizerState();
}

class _MovementVisualizerState extends State<MovementVisualizer> {
  MovementDirection? _lastDragDirection;

  @override
  Widget build(BuildContext context) {
    final alignment = switch (widget.direction) {
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
      padding: const EdgeInsets.all(0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.interactive ? null : widget.onTap,
            onTapDown: widget.interactive
                ? (details) => _emitDirection(
                      _directionFromPosition(details.localPosition, size),
                    )
                : null,
            onPanStart: widget.interactive
                ? (details) => _emitDirection(
                      _directionFromPosition(details.localPosition, size),
                    )
                : null,
            onPanUpdate: widget.interactive
                ? (details) => _emitDirection(
                      _directionFromPosition(details.localPosition, size),
                    )
                : null,
            onPanEnd: widget.interactive ? (_) => _finishInteraction() : null,
            onPanCancel: widget.interactive ? _finishInteraction : null,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.03),
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
                child: Stack(
                  children: [
                  Positioned.fill(
                    child: _PathOverlay(
                      mode: widget.mode,
                      direction: widget.direction,
                      obstacleDistance: widget.obstacleDistance,
                      obstacleTooClose: widget.obstacleTooClose,
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 14,
                    right: 14,
                    child: Row(
                      children: [
                        Text(
                          _titleForMode(widget.mode),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        _ObstacleDot(
                          distance: widget.obstacleDistance,
                          tooClose: widget.obstacleTooClose,
                        ),
                        const SizedBox(width: 10),
                        if (widget.speed != null)
                          Text(
                            'Speed ${widget.speed}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.interactive
                                ? 'Drag to control manually'
                                : 'Realtime direction preview',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Text(
                          'Servo ${widget.servoAngle} deg',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 24,
                    top: 56,
                    child: _DirectionBadge(direction: widget.direction),
                  ),
                  Positioned(
                    left: 24,
                    top: 56,
                    child: _ObstacleBadge(
                      distance: widget.obstacleDistance,
                      tooClose: widget.obstacleTooClose,
                    ),
                  ),
                  AnimatedAlign(
                    duration: AppConstants.defaultAnimationDuration,
                    curve: Curves.easeOutCubic,
                    alignment: alignment,
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: _CarGlyph(direction: widget.direction),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _emitDirection(MovementDirection direction) {
    if (direction == _lastDragDirection) {
      return;
    }

    _lastDragDirection = direction;
    widget.onDirectionChanged?.call(direction);
  }

  void _finishInteraction() {
    _lastDragDirection = null;
    widget.onInteractionEnd?.call();
  }

  MovementDirection _directionFromPosition(Offset position, Size size) {
    final dx = position.dx - (size.width / 2);
    final dy = position.dy - (size.height / 2);
    final deadZoneX = size.width * 0.14;
    final deadZoneY = size.height * 0.14;

    final horizontal = dx.abs() <= deadZoneX
        ? 0
        : dx.isNegative
            ? -1
            : 1;
    final vertical = dy.abs() <= deadZoneY
        ? 0
        : dy.isNegative
            ? -1
            : 1;

    return switch ((horizontal, vertical)) {
      (0, -1) => MovementDirection.forward,
      (0, 1) => MovementDirection.backward,
      (-1, 0) => MovementDirection.left,
      (1, 0) => MovementDirection.right,
      (-1, -1) => MovementDirection.forwardLeft,
      (1, -1) => MovementDirection.forwardRight,
      (-1, 1) => MovementDirection.backwardLeft,
      (1, 1) => MovementDirection.backwardRight,
      _ => MovementDirection.stop,
    };
  }

  String _titleForMode(RobotMode mode) {
    return switch (mode) {
      RobotMode.line => 'Follow Line',
      RobotMode.auto => 'Auto Mode',
      RobotMode.follow => 'Follow Me',
      RobotMode.manual => 'Manual Control',
    };
  }
}

class _ObstacleDot extends StatelessWidget {
  const _ObstacleDot({
    required this.distance,
    required this.tooClose,
  });

  final double distance;
  final bool tooClose;

  @override
  Widget build(BuildContext context) {
    final color = _resolveColor();
    return AnimatedContainer(
      duration: AppConstants.defaultAnimationDuration,
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: color.opacity == 0 ? 0.08 : 0.18),
        ),
      ),
    );
  }

  Color _resolveColor() {
    if (tooClose) {
      return const Color(0xFFFF5A5A);
    }
    if (distance > 0 && distance < 100) {
      return const Color(0xFFFFA726);
    }
    return Colors.transparent;
  }
}

class _DirectionBadge extends StatelessWidget {
  const _DirectionBadge({required this.direction});

  final MovementDirection direction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        direction.label,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _ObstacleBadge extends StatelessWidget {
  const _ObstacleBadge({
    required this.distance,
    required this.tooClose,
  });

  final double distance;
  final bool tooClose;

  @override
  Widget build(BuildContext context) {
    final text = tooClose
        ? 'Obstacle too close'
        : distance > 0 && distance < 100
            ? 'Obstacle ${distance.toStringAsFixed(1)}'
            : 'Path clear';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _PathOverlay extends StatelessWidget {
  const _PathOverlay({
    required this.mode,
    required this.direction,
    required this.obstacleDistance,
    required this.obstacleTooClose,
  });

  final RobotMode mode;
  final MovementDirection direction;
  final double obstacleDistance;
  final bool obstacleTooClose;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PathPainter(
        mode: mode,
        direction: direction,
        obstacleDistance: obstacleDistance,
        obstacleTooClose: obstacleTooClose,
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
  _PathPainter({
    required this.lineColor,
    required this.mode,
    required this.direction,
    required this.obstacleDistance,
    required this.obstacleTooClose,
  });

  final Color lineColor;
  final RobotMode mode;
  final MovementDirection direction;
  final double obstacleDistance;
  final bool obstacleTooClose;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final vertical = Path()
      ..moveTo(size.width * 0.5, size.height * 0.08)
      ..lineTo(size.width * 0.5, size.height * 0.92);
    final horizontal = Path()
      ..moveTo(size.width * 0.08, size.height * 0.5)
      ..lineTo(size.width * 0.92, size.height * 0.5);

    canvas.drawPath(vertical, paint);
    canvas.drawPath(horizontal, paint);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.shortestSide * 0.14,
      paint,
    );

    if (mode != RobotMode.manual) {
      final pulsePaint = Paint()
        ..color = lineColor.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10;
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        size.shortestSide * 0.28,
        pulsePaint,
      );

      final trailPaint = Paint()
        ..color = lineColor.withValues(alpha: 0.36)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      final trail = Path()
        ..moveTo(size.width * 0.24, size.height * 0.76)
        ..quadraticBezierTo(
          size.width * 0.38,
          size.height * 0.58,
          size.width * 0.5,
          size.height * 0.5,
        )
        ..quadraticBezierTo(
          size.width * 0.62,
          size.height * 0.42,
          size.width * 0.76,
          size.height * 0.24,
        );
      canvas.drawPath(trail, trailPaint);

      final dirPaint = Paint()
        ..color = lineColor.withValues(alpha: 0.60)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      final center = Offset(size.width / 2, size.height / 2);
      final target = switch (direction) {
        MovementDirection.forward => Offset(center.dx, size.height * 0.18),
        MovementDirection.backward => Offset(center.dx, size.height * 0.82),
        MovementDirection.left => Offset(size.width * 0.18, center.dy),
        MovementDirection.right => Offset(size.width * 0.82, center.dy),
        MovementDirection.forwardLeft => Offset(size.width * 0.24, size.height * 0.24),
        MovementDirection.forwardRight => Offset(size.width * 0.76, size.height * 0.24),
        MovementDirection.backwardLeft => Offset(size.width * 0.24, size.height * 0.76),
        MovementDirection.backwardRight => Offset(size.width * 0.76, size.height * 0.76),
        MovementDirection.stop => center,
      };
      canvas.drawLine(center, target, dirPaint);

      if (obstacleDistance > 0 && obstacleDistance < 100) {
        final obstaclePaint = Paint()
          ..color = obstacleTooClose
              ? const Color(0x66FF5A5A)
              : const Color(0x66FFA726)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(size.width * 0.78, size.height * 0.22),
          obstacleTooClose ? 18 : 12,
          obstaclePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.mode != mode ||
        oldDelegate.direction != direction ||
        oldDelegate.obstacleDistance != obstacleDistance ||
        oldDelegate.obstacleTooClose != obstacleTooClose;
  }
}
