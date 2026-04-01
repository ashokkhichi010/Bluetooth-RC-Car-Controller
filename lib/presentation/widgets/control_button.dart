import 'package:flutter/material.dart';

class ControlButton extends StatelessWidget {
  const ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
    this.filled = true,
    this.borderRadius = BorderRadius.zero,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 18),
      backgroundColor: filled
          ? Theme.of(context).colorScheme.primary
          : Colors.white.withValues(alpha: 0.08),
      foregroundColor: filled ? Colors.black : Colors.white,
      disabledBackgroundColor: Colors.white.withValues(alpha: 0.04),
      disabledForegroundColor: Colors.white38,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
    );

    return FilledButton(
      onPressed: onPressed,
      style: buttonStyle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon), const SizedBox(height: 8), Text(label)],
      ),
    );
  }
}
