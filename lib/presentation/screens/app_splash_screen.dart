import 'dart:math' as math;

import 'package:bluetooth_rc_car/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

class AppSplashScreen extends StatefulWidget {
  const AppSplashScreen({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _showHome = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.splashDuration,
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _showHome = true);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppConstants.defaultAnimationDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _showHome
          ? KeyedSubtree(
              key: const ValueKey<String>('home'),
              child: widget.child,
            )
          : _SplashScene(
              key: const ValueKey<String>('splash'),
              animation: _controller,
            ),
    );
  }
}

class _SplashScene extends StatelessWidget {
  const _SplashScene({
    required this.animation,
    super.key,
  });

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF061018),
              Color(0xFF0D1720),
              Color(0xFF132634),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                final progress = animation.value.clamp(0.0, 1.0);
                final percentage = (progress * 100).round();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Icon(
                        Icons.precision_manufacturing_rounded,
                        size: 36,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppConstants.appTitle,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 34,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Booting Firebase control plane and syncing live telemetry.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.76),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 36),
                    _RobotCarLoader(progress: progress),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Text(
                          'Starting up',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$percentage%',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _RobotCarLoader extends StatelessWidget {
  const _RobotCarLoader({
    required this.progress,
  });

  final double progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        const carWidth = 108.0;
        final travelDistance = math.max(0.0, constraints.maxWidth - carWidth);
        final leftOffset = travelDistance * progress;
        final bounce = math.sin(progress * math.pi * 10) * 4;

        return SizedBox(
          height: 132,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 22,
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: const Color(0xFF18212B),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 22,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary.withValues(alpha: 0.48),
                              colorScheme.primary,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.28),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 48,
                child: Row(
                  children: List.generate(
                    24,
                    (index) => Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        color: index / 23 <= progress
                            ? colorScheme.primary.withValues(alpha: 0.34)
                            : Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: leftOffset,
                bottom: 34 + bounce,
                child: _RobotCar(progress: progress),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RobotCar extends StatelessWidget {
  const _RobotCar({
    required this.progress,
  });

  final double progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final wheelRotation = progress * math.pi * 10;

    return SizedBox(
      width: 108,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 18,
            right: 18,
            bottom: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _RobotWheel(rotation: wheelRotation),
                _RobotWheel(rotation: wheelRotation),
              ],
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 14,
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF163746),
                    colorScheme.primary,
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.smart_toy_rounded,
                    size: 18,
                    color: const Color(0xFF06232B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF06232B).withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFB8FFF6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 28,
            bottom: 40,
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF203443),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          Positioned(
            right: 14,
            bottom: 33,
            child: Container(
              width: 18,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RobotWheel extends StatelessWidget {
  const _RobotWheel({
    required this.rotation,
  });

  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF0A1118),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      alignment: Alignment.center,
      child: Transform.rotate(
        angle: rotation,
        child: Icon(
          Icons.settings_rounded,
          size: 14,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.72),
        ),
      ),
    );
  }
}
