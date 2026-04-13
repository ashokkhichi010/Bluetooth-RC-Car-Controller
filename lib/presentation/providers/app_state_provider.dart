import 'dart:async';

import 'package:bluetooth_rc_car/data/repositories/firebase_robot_repository.dart';
import 'package:bluetooth_rc_car/domain/models/robot_state.dart';
import 'package:bluetooth_rc_car/domain/repositories/robot_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final robotRepositoryProvider = Provider<RobotRepository>((ref) {
  return FirebaseRobotRepository();
});

final robotTelemetryStreamProvider = StreamProvider<RobotState>((ref) {
  return ref.watch(robotRepositoryProvider).watchRobotState();
});

final robotControllerProvider = Provider<RobotController>((ref) {
  final controller = RobotController(ref.watch(robotRepositoryProvider));
  ref.onDispose(controller.dispose);
  return controller;
});

class RobotController {
  RobotController(this._repository);

  final RobotRepository _repository;
  Timer? _followMeTimer;

  Future<void> changeMode(RobotMode mode) async {
    if (mode != RobotMode.follow) {
      _followMeTimer?.cancel();
      _followMeTimer = null;
    }
    await _repository.updateMode(mode);
  }

  Future<void> updateSpeed(int speed) {
    return _repository.updateSpeed(speed);
  }

  Future<void> sendMove(MovementDirection direction) {
    return _repository.sendCommand(direction: direction);
  }

  Future<FollowMeStatus> activateFollowMe() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return FollowMeStatus.locationDisabled;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return FollowMeStatus.permissionDenied;
    }

    await _repository.updateMode(RobotMode.follow);
    // await _positionSubscription?.cancel();

    final current = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    await _repository.updateDeviceLocation(
      lat: current.latitude,
      lng: current.longitude,
    );

    _followMeTimer?.cancel();
    _followMeTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final updated = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _repository.updateDeviceLocation(
        lat: updated.latitude,
        lng: updated.longitude,
      );
    });

    return FollowMeStatus.active;
  }

  Future<void> dispose() async {
    _followMeTimer?.cancel();
  }
}

enum FollowMeStatus {
  active,
  locationDisabled,
  permissionDenied,
}
