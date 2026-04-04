import 'package:bluetooth_rc_car/core/constants/app_constants.dart';
import 'package:bluetooth_rc_car/domain/models/car_state.dart';
import 'package:bluetooth_rc_car/presentation/widgets/status_card.dart';
import 'package:flutter/material.dart';

class MovementVisualizer extends StatefulWidget {
  const MovementVisualizer({
    required this.mode,
    required this.direction,
    this.speed,
    this.interactive = false,
    this.onTap,
    this.onDirectionChanged,
    this.onInteractionEnd,
    super.key,
  });

  final CarMode mode;
  final MovementDirection direction;
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
                  const Positioned.fill(child: _PathOverlay()),
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
                        if (widget.speed != null)
                          Text(
                            'Speed ${widget.speed}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                  if (widget.interactive)
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: Text(
                        'Drag to control manually',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )
                  else
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: Text(
                        'Tap to switch to manual control',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
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

  String _titleForMode(CarMode mode) {
    return switch (mode) {
      CarMode.lineFollower => 'Follow Line',
      CarMode.obstacleAvoidance => 'Auto Mode',
      CarMode.followMe => 'Follow Me',
      CarMode.manual => 'Manual Control',
      CarMode.idle => 'Movement',
    };
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
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}
