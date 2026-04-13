class RobotState {
  const RobotState({
    required this.obstacleDistance,
    required this.obstacleTooClose,
    required this.servoDirection,
    required this.currentMode,
    required this.speed,
    required this.direction,
    required this.lastSeenCounter,
    required this.lastHeartbeatAt,
  });

  factory RobotState.initial() => const RobotState(
        obstacleDistance: 0,
        obstacleTooClose: false,
        servoDirection: 90,
        currentMode: RobotMode.manual,
        speed: 0,
        direction: MovementDirection.stop,
    lastSeenCounter: 0,
    lastHeartbeatAt: null,
      );

  factory RobotState.fromMap(
    Map<Object?, Object?>? raw, {
    required int? previousLastSeenCounter,
    required DateTime? previousHeartbeatAt,
    required DateTime observedAt,
  }) {
    if (raw == null) {
      return RobotState.initial();
    }

    final obstacle = _mapFrom(raw['obstacl']);
    final car = _mapFrom(raw['car']);
    final lastSeenCounter = _toInt(raw['last-seen'], 0);
    final heartbeatAt = previousLastSeenCounter == lastSeenCounter
        ? previousHeartbeatAt
        : observedAt;

    return RobotState(
      obstacleDistance: _toDouble(obstacle['distance']),
      obstacleTooClose: obstacle['too-close'] == true,
      servoDirection: _toInt(raw['servo-angle'], 90),
      currentMode: RobotModeX.fromWire(car['mode']?.toString()),
      speed: _toInt(car['speed'], 0),
      direction: MovementDirectionX.fromWire(car['direction']?.toString()),
      lastSeenCounter: lastSeenCounter,
      lastHeartbeatAt: heartbeatAt,
    );
  }

  final double obstacleDistance;
  final bool obstacleTooClose;
  final int servoDirection;
  final RobotMode currentMode;
  final int speed;
  final MovementDirection direction;
  final int lastSeenCounter;
  final DateTime? lastHeartbeatAt;

  DateTime? get lastSeenAt => lastHeartbeatAt;

  bool get shouldPlotPath => currentMode != RobotMode.manual;
  bool get isHeartbeatFresh =>
      lastHeartbeatAt != null &&
      DateTime.now().difference(lastHeartbeatAt!).inMilliseconds <= 5000;
  bool get isConnected => lastSeenCounter > 0 && isHeartbeatFresh;

  static int _toInt(Object? value, int fallback) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

enum RobotMode {
  manual,
  auto,
  line,
  follow,
}

extension RobotModeX on RobotMode {
  String get label => switch (this) {
        RobotMode.manual => 'MANUAL',
        RobotMode.auto => 'AUTO',
        RobotMode.line => 'LINE',
        RobotMode.follow => 'FOLLOW',
      };

  static RobotMode fromWire(String? value) {
    switch (value?.toUpperCase()) {
      case 'AUTO':
        return RobotMode.auto;
      case 'LINE':
        return RobotMode.line;
      case 'FOLLOW':
      case 'FOLLOW_ME':
        return RobotMode.follow;
      case 'MANUAL':
      default:
        return RobotMode.manual;
    }
  }
}

enum MovementDirection {
  stop,
  forward,
  backward,
  left,
  right,
  forwardLeft,
  forwardRight,
  backwardLeft,
  backwardRight,
}

extension MovementDirectionX on MovementDirection {
  String get label => switch (this) {
        MovementDirection.stop => 'STOP',
        MovementDirection.forward => 'FORWARD',
        MovementDirection.backward => 'BACKWARD',
        MovementDirection.left => 'LEFT',
        MovementDirection.right => 'RIGHT',
        MovementDirection.forwardLeft => 'FORWARDLEFT',
        MovementDirection.forwardRight => 'FORWARDRIGHT',
        MovementDirection.backwardLeft => 'BACKWARDLEFT',
        MovementDirection.backwardRight => 'BACKWARDRIGHT',
      };

  static MovementDirection fromWire(String? value) {
    switch (value?.toUpperCase()) {
      case 'FORWARD':
        return MovementDirection.forward;
      case 'BACKWARD':
        return MovementDirection.backward;
      case 'LEFT':
        return MovementDirection.left;
      case 'RIGHT':
        return MovementDirection.right;
      case 'FORWARDLEFT':
      case 'FORWORDLEFT':
        return MovementDirection.forwardLeft;
      case 'FORWARDRIGHT':
      case 'FORWORDRIGHT':
        return MovementDirection.forwardRight;
      case 'BACKWARDLEFT':
      case 'BACKWORDLEFT':
        return MovementDirection.backwardLeft;
      case 'BACKWARDRIGHT':
      case 'BACKWORDRIGHT':
        return MovementDirection.backwardRight;
      case 'STOP':
      default:
        return MovementDirection.stop;
    }
  }
}

double _toDouble(Object? value) {
  if (value is int) {
    return value.toDouble();
  }
  if (value is double) {
    return value;
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

Map<Object?, Object?> _mapFrom(Object? raw) {
  if (raw is Map) {
    return Map<Object?, Object?>.from(raw);
  }
  return const {};
}
