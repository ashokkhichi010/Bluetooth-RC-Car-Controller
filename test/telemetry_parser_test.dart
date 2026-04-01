import 'package:bluetooth_rc_car/core/utils/telemetry_parser.dart';
import 'package:bluetooth_rc_car/domain/models/car_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TelemetryParser', () {
    test('parses valid packets with obstacle telemetry', () {
      final state = TelemetryParser.parsePacket(
        'MODE:OBS;SPD:90;DIR:LEFT;OBS:BOTH;',
      );

      expect(state, isNotNull);
      expect(state!.mode, CarMode.obstacleAvoidance);
      expect(state.speed, 90);
      expect(state.direction, MovementDirection.left);
      expect(state.obstacleSide, ObstacleSide.both);
    });

    test('extracts only complete packets and keeps remainder', () {
      final extraction = TelemetryParser.extractPackets(
        'MODE:LINE;SPD:120;DIR:FWD;MODE:OBS;SPD:70;',
      );

      expect(extraction.packets, ['MODE:LINE;SPD:120;DIR:FWD;']);
      expect(extraction.remainder, 'MODE:OBS;SPD:70;');
    });

    test('returns null for invalid packets', () {
      final state = TelemetryParser.parsePacket('MODE:LINE;DIR:FWD;');
      expect(state, isNull);
    });
  });
}
