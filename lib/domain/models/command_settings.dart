import 'package:bluetooth_rc_car/core/constants/app_constants.dart';
import 'package:bluetooth_rc_car/domain/models/car_state.dart';

class CommandSettings {
  const CommandSettings({
    required this.lineFollowerMode,
    required this.obstacleAvoidanceMode,
    required this.followMeMode,
    required this.manualMode,
    required this.forward,
    required this.backward,
    required this.left,
    required this.right,
    required this.stop,
    required this.forwardLeft,
    required this.forwardRight,
    required this.backwardLeft,
    required this.backwardRight,
  });

  factory CommandSettings.defaults() => const CommandSettings(
    lineFollowerMode: AppConstants.lineModeCommand,
    obstacleAvoidanceMode: AppConstants.obstacleModeCommand,
    followMeMode: AppConstants.followMeModeCommand,
    manualMode: AppConstants.menualModeCommand,
    forward: AppConstants.commandForward,
    backward: AppConstants.commandBackward,
    left: AppConstants.commandLeft,
    right: AppConstants.commandRight,
    stop: AppConstants.commandStop,
    forwardLeft: AppConstants.commandForwardLeft,
    forwardRight: AppConstants.commandForwardRight,
    backwardLeft: AppConstants.commandBackwardLeft,
    backwardRight: AppConstants.commandBackwardRight,
  );

  factory CommandSettings.fromJson(Map<String, dynamic> json) {
    final defaults = CommandSettings.defaults();
    return CommandSettings(
      lineFollowerMode: _readValue(
        json,
        'lineFollowerMode',
        defaults.lineFollowerMode,
      ),
      obstacleAvoidanceMode: _readValue(
        json,
        'obstacleAvoidanceMode',
        defaults.obstacleAvoidanceMode,
      ),
      followMeMode: _readValue(json, 'followMeMode', defaults.followMeMode),
      manualMode: _readValue(json, 'manualMode', defaults.manualMode),
      forward: _readValue(json, 'forward', defaults.forward),
      backward: _readValue(json, 'backward', defaults.backward),
      left: _readValue(json, 'left', defaults.left),
      right: _readValue(json, 'right', defaults.right),
      stop: _readValue(json, 'stop', defaults.stop),
      forwardLeft: _readValue(json, 'forwardLeft', defaults.forwardLeft),
      forwardRight: _readValue(json, 'forwardRight', defaults.forwardRight),
      backwardLeft: _readValue(json, 'backwardLeft', defaults.backwardLeft),
      backwardRight: _readValue(json, 'backwardRight', defaults.backwardRight),
    );
  }

  final String lineFollowerMode;
  final String obstacleAvoidanceMode;
  final String followMeMode;
  final String manualMode;
  final String forward;
  final String backward;
  final String left;
  final String right;
  final String stop;
  final String forwardLeft;
  final String forwardRight;
  final String backwardLeft;
  final String backwardRight;

  Map<String, String> toJson() {
    final normalized = this.normalized();
    return <String, String>{
      'lineFollowerMode': normalized.lineFollowerMode,
      'obstacleAvoidanceMode': normalized.obstacleAvoidanceMode,
      'followMeMode': normalized.followMeMode,
      'manualMode': normalized.manualMode,
      'forward': normalized.forward,
      'backward': normalized.backward,
      'left': normalized.left,
      'right': normalized.right,
      'stop': normalized.stop,
      'forwardLeft': normalized.forwardLeft,
      'forwardRight': normalized.forwardRight,
      'backwardLeft': normalized.backwardLeft,
      'backwardRight': normalized.backwardRight,
    };
  }

  CommandSettings copyWith({
    String? lineFollowerMode,
    String? obstacleAvoidanceMode,
    String? followMeMode,
    String? manualMode,
    String? forward,
    String? backward,
    String? left,
    String? right,
    String? stop,
    String? forwardLeft,
    String? forwardRight,
    String? backwardLeft,
    String? backwardRight,
  }) {
    return CommandSettings(
      lineFollowerMode: lineFollowerMode ?? this.lineFollowerMode,
      obstacleAvoidanceMode: obstacleAvoidanceMode ?? this.obstacleAvoidanceMode,
      followMeMode: followMeMode ?? this.followMeMode,
      manualMode: manualMode ?? this.manualMode,
      forward: forward ?? this.forward,
      backward: backward ?? this.backward,
      left: left ?? this.left,
      right: right ?? this.right,
      stop: stop ?? this.stop,
      forwardLeft: forwardLeft ?? this.forwardLeft,
      forwardRight: forwardRight ?? this.forwardRight,
      backwardLeft: backwardLeft ?? this.backwardLeft,
      backwardRight: backwardRight ?? this.backwardRight,
    );
  }

  CommandSettings normalized() {
    final defaults = CommandSettings.defaults();
    return CommandSettings(
      lineFollowerMode: _sanitize(lineFollowerMode, defaults.lineFollowerMode),
      obstacleAvoidanceMode: _sanitize(
        obstacleAvoidanceMode,
        defaults.obstacleAvoidanceMode,
      ),
      followMeMode: _sanitize(followMeMode, defaults.followMeMode),
      manualMode: _sanitize(manualMode, defaults.manualMode),
      forward: _sanitize(forward, defaults.forward),
      backward: _sanitize(backward, defaults.backward),
      left: _sanitize(left, defaults.left),
      right: _sanitize(right, defaults.right),
      stop: _sanitize(stop, defaults.stop),
      forwardLeft: _sanitize(forwardLeft, defaults.forwardLeft),
      forwardRight: _sanitize(forwardRight, defaults.forwardRight),
      backwardLeft: _sanitize(backwardLeft, defaults.backwardLeft),
      backwardRight: _sanitize(backwardRight, defaults.backwardRight),
    );
  }

  String commandForMode(CarMode mode) {
    final normalized = this.normalized();
    return switch (mode) {
      CarMode.lineFollower => normalized.lineFollowerMode,
      CarMode.obstacleAvoidance => normalized.obstacleAvoidanceMode,
      CarMode.followMe => normalized.followMeMode,
      CarMode.manual => normalized.manualMode,
      CarMode.idle => normalized.stop,
    };
  }

  String commandForDirection(MovementDirection direction) {
    final normalized = this.normalized();
    return switch (direction) {
      MovementDirection.forward => normalized.forward,
      MovementDirection.backward => normalized.backward,
      MovementDirection.left => normalized.left,
      MovementDirection.right => normalized.right,
      MovementDirection.forwardLeft => normalized.forwardLeft,
      MovementDirection.forwardRight => normalized.forwardRight,
      MovementDirection.backwardLeft => normalized.backwardLeft,
      MovementDirection.backwardRight => normalized.backwardRight,
      MovementDirection.stop => normalized.stop,
    };
  }

  static String _readValue(
    Map<String, dynamic> json,
    String key,
    String fallback,
  ) {
    final value = json[key];
    if (value is! String) {
      return fallback;
    }

    return _sanitize(value, fallback);
  }

  static String _sanitize(String value, String fallback) {
    final normalized = value.trim();
    return normalized.isEmpty ? fallback : normalized;
  }
}
