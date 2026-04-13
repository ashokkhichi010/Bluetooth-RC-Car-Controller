import 'package:bluetooth_rc_car/data/repositories/firebase_robot_repository.dart';
import 'package:bluetooth_rc_car/domain/models/robot_state.dart';
import 'package:bluetooth_rc_car/domain/repositories/robot_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final robotRepositoryProvider = Provider<RobotRepository>((ref) {
  return FirebaseRobotRepository();
});

final robotTelemetryStreamProvider = StreamProvider<RobotState>((ref) {
  return ref.watch(robotRepositoryProvider).watchRobotState();
});

final robotControllerProvider = Provider<RobotController>((ref) {
  return RobotController(ref.watch(robotRepositoryProvider));
});

class RobotController {
  RobotController(this._repository);

  final RobotRepository _repository;

  Future<void> changeMode(RobotMode mode) {
    return _repository.updateMode(mode);
  }

  Future<void> updateSpeed(int speed) {
    return _repository.updateSpeed(speed);
  }

  Future<void> sendMove(MovementDirection direction) {
    return _repository.sendCommand(direction: direction);
  }
}
