enum CarMode { idle, manual, lineFollower, obstacleAvoidance }

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

enum ObstacleSide { none, left, right, both }

enum ConnectionStatus { disconnected, connecting, connected }

class CarState {
  const CarState({
    required this.mode,
    required this.speed,
    required this.direction,
    required this.obstacleSide,
    required this.lastUpdatedAt,
  });

  factory CarState.initial() => CarState(
        mode: CarMode.idle,
        speed: 0,
        direction: MovementDirection.stop,
        obstacleSide: ObstacleSide.none,
        lastUpdatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

  final CarMode mode;
  final int speed;
  final MovementDirection direction;
  final ObstacleSide obstacleSide;
  final DateTime lastUpdatedAt;

  bool get isMoving => direction != MovementDirection.stop && speed > 0;

  CarState copyWith({
    CarMode? mode,
    int? speed,
    MovementDirection? direction,
    ObstacleSide? obstacleSide,
    DateTime? lastUpdatedAt,
  }) {
    return CarState(
      mode: mode ?? this.mode,
      speed: speed ?? this.speed,
      direction: direction ?? this.direction,
      obstacleSide: obstacleSide ?? this.obstacleSide,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}

extension CarModeX on CarMode {
  String get label => switch (this) {
        CarMode.idle => 'Idle',
        CarMode.manual => 'Manual',
        CarMode.lineFollower => 'Line Follower',
        CarMode.obstacleAvoidance => 'Obstacle Avoidance',
      };

  static CarMode? fromWire(String? value) {
    switch (value?.toUpperCase()) {
      case 'LINE':
        return CarMode.lineFollower;
      case 'OBS':
        return CarMode.obstacleAvoidance;
      case 'MANUAL':
        return CarMode.manual;
      case 'IDLE':
        return CarMode.idle;
      default:
        return null;
    }
  }
}

extension MovementDirectionX on MovementDirection {
  String get label => switch (this) {
        MovementDirection.stop => 'Stop',
        MovementDirection.forward => 'Forward',
        MovementDirection.backward => 'Backward',
        MovementDirection.left => 'Left',
        MovementDirection.right => 'Right',
        MovementDirection.forwardLeft => 'Forward Left',
        MovementDirection.forwardRight => 'Forward Right',
        MovementDirection.backwardLeft => 'Backward Left',
        MovementDirection.backwardRight => 'Backward Right',
      };

  static MovementDirection? fromWire(String? value) {
    switch (value?.toUpperCase()) {
      case 'STOP':
      case 'S':
        return MovementDirection.stop;
      case 'FWD':
      case 'FORWARD':
      case 'F':
        return MovementDirection.forward;
      case 'BACK':
      case 'BWD':
      case 'BACKWARD':
      case 'B':
        return MovementDirection.backward;
      case 'LEFT':
      case 'L':
        return MovementDirection.left;
      case 'RIGHT':
      case 'R':
        return MovementDirection.right;
      case 'FL':
      case 'FORWARD_LEFT':
      case 'G':
        return MovementDirection.forwardLeft;
      case 'FR':
      case 'FORWARD_RIGHT':
      case 'I':
        return MovementDirection.forwardRight;
      case 'BL':
      case 'BACKWARD_LEFT':
      case 'H':
        return MovementDirection.backwardLeft;
      case 'BR':
      case 'BACKWARD_RIGHT':
      case 'J':
        return MovementDirection.backwardRight;
      default:
        return null;
    }
  }
}

extension ObstacleSideX on ObstacleSide {
  String get label => switch (this) {
        ObstacleSide.none => 'Clear',
        ObstacleSide.left => 'Obstacle Left',
        ObstacleSide.right => 'Obstacle Right',
        ObstacleSide.both => 'Obstacle Ahead',
      };

  static ObstacleSide? fromWire(String? value) {
    switch (value?.toUpperCase()) {
      case null:
        return null;
      case 'NONE':
        return ObstacleSide.none;
      case 'L':
      case 'LEFT':
        return ObstacleSide.left;
      case 'R':
      case 'RIGHT':
        return ObstacleSide.right;
      case 'B':
      case 'BOTH':
        return ObstacleSide.both;
      default:
        return null;
    }
  }
}
