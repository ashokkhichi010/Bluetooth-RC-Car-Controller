import 'package:bluetooth_rc_car/domain/models/robot_state.dart';
import 'package:bluetooth_rc_car/domain/models/robot_log_entry.dart';

abstract class RobotRepository {
  Stream<RobotState> watchRobotState();
  Stream<List<RobotLogEntry>> watchLogs();
  Future<void> sendCommand({
    required MovementDirection direction,
  });
  Future<void> updateDeviceLocation({
    required double lat,
    required double lng,
  });
  Future<void> updateSpeed(int speed);
  Future<void> updateMode(RobotMode mode);
}
