import 'package:bluetooth_rc_car/domain/models/robot_log_entry.dart';
import 'package:bluetooth_rc_car/domain/models/robot_state.dart';
import 'package:bluetooth_rc_car/domain/repositories/robot_repository.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseRobotRepository implements RobotRepository {
  FirebaseRobotRepository({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _database;

  DatabaseReference get _root => _database.ref();
  DatabaseReference get _car => _root.child('car');

  @override
  Stream<List<RobotLogEntry>> watchLogs() {
    return _root.child('logs').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is List) {
        return raw
            .where((item) => item != null)
            .map(RobotLogEntry.fromValue)
            .toList(growable: false)
            .reversed
            .toList(growable: false);
      }
      if (raw is Map) {
        return raw.values
            .map(RobotLogEntry.fromValue)
            .toList(growable: false)
            .reversed
            .toList(growable: false);
      }
      return const <RobotLogEntry>[];
    });
  }

  @override
  Future<void> sendCommand({
    required MovementDirection direction,
  }) {
    return _car.child('direction').set(direction.label);
  }

  @override
  Future<void> updateSpeed(int speed) {
    return _car.child('speed').set(speed);
  }

  @override
  Future<void> updateMode(RobotMode mode) async {
    await _car.child('mode').set(mode.label);
    if (mode == RobotMode.manual) {
      await _car.child('direction').set(MovementDirection.stop.label);
    }
  }

  @override
  Stream<RobotState> watchRobotState() {
    return _root.onValue.map((event) {
      final raw = event.snapshot.value;
      final map = raw is Map ? Map<Object?, Object?>.from(raw) : null;
      return RobotState.fromMap(map);
    });
  }
}
