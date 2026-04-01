import 'package:bluetooth_rc_car/core/constants/app_constants.dart';
import 'package:bluetooth_rc_car/domain/models/car_state.dart';

class TelemetryParser {
  const TelemetryParser._();

  static final RegExp _packetExpression = RegExp(
    r'MODE:[^;]+;SPD:-?\d+;DIR:[^;]+;(?:OBS:[^;]+;)?',
  );

  static PacketExtraction extractPackets(String buffer) {
    final matches = _packetExpression.allMatches(buffer).toList();
    if (matches.isEmpty) {
      final modeIndex = buffer.lastIndexOf('${AppConstants.telemetryModeKey}:');
      if (modeIndex >= 0) {
        return PacketExtraction(
          packets: const <String>[],
          remainder: buffer.substring(modeIndex),
        );
      }

      return const PacketExtraction(packets: <String>[], remainder: '');
    }

    return PacketExtraction(
      packets: matches.map((match) => match.group(0)!).toList(),
      remainder: buffer.substring(matches.last.end),
    );
  }

  static CarState? parsePacket(String packet, {CarState? previous}) {
    final entries = <String, String>{};
    for (final chunk in packet.split(';')) {
      if (chunk.isEmpty || !chunk.contains(':')) {
        continue;
      }

      final parts = chunk.split(':');
      entries[parts.first.trim()] = parts.sublist(1).join(':').trim();
    }

    final mode = CarModeX.fromWire(entries[AppConstants.telemetryModeKey]);
    final speed = int.tryParse(entries[AppConstants.telemetrySpeedKey] ?? '');
    final direction = MovementDirectionX.fromWire(
      entries[AppConstants.telemetryDirectionKey],
    );
    final obstacle = ObstacleSideX.fromWire(
      entries[AppConstants.telemetryObstacleKey],
    );

    if (mode == null || speed == null || direction == null) {
      return null;
    }

    return (previous ?? CarState.initial()).copyWith(
      mode: mode,
      speed: speed.clamp(0, AppConstants.maxSpeed.toInt()),
      direction: direction,
      obstacleSide: obstacle ?? ObstacleSide.none,
      lastUpdatedAt: DateTime.now(),
    );
  }
}

class PacketExtraction {
  const PacketExtraction({
    required this.packets,
    required this.remainder,
  });

  final List<String> packets;
  final String remainder;
}
