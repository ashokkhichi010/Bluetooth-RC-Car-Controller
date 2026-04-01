import 'package:bluetooth_rc_car/domain/models/car_state.dart';
import 'package:flutter/material.dart';

class ConnectionStatusChip extends StatelessWidget {
  const ConnectionStatusChip({required this.status, super.key});

  final ConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ConnectionStatus.connected => Colors.greenAccent,
      ConnectionStatus.connecting => Colors.amberAccent,
      ConnectionStatus.disconnected => Colors.redAccent,
    };

    final label = switch (status) {
      ConnectionStatus.connected => 'Connected',
      ConnectionStatus.connecting => 'Connecting',
      ConnectionStatus.disconnected => 'Disconnected',
    };

    return Chip(
      avatar: CircleAvatar(radius: 5, backgroundColor: color),
      label: Text(label),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
