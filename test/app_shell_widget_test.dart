import 'package:bluetooth_rc_car/domain/models/robot_log_entry.dart';
import 'package:bluetooth_rc_car/domain/models/robot_state.dart';
import 'package:bluetooth_rc_car/domain/repositories/robot_repository.dart';
import 'package:bluetooth_rc_car/presentation/providers/app_state_provider.dart';
import 'package:bluetooth_rc_car/presentation/screens/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows restored controller cards', (tester) async {
    final repository = FakeRobotRepository(
      initialState: RobotState(
        obstacleDistance: 24.5,
        obstacleTooClose: false,
        servoDirection: 90,
        currentMode: RobotMode.manual,
        speed: 120,
        direction: MovementDirection.forward,
        lastSeen: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          robotRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: AppShell()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Manual Control'), findsOneWidget);
    expect(find.text('Follow Line'), findsOneWidget);
    expect(find.text('Auto Mode'), findsOneWidget);
    expect(find.text('Follow Me'), findsOneWidget);
  });

  testWidgets('shows movement board only when mode is not manual', (
    tester,
  ) async {
    final repository = FakeRobotRepository(
      initialState: RobotState(
        obstacleDistance: 12.2,
        obstacleTooClose: true,
        servoDirection: 70,
        currentMode: RobotMode.auto,
        speed: 100,
        direction: MovementDirection.right,
        lastSeen: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          robotRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: AppShell()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Car Movement Board'), findsOneWidget);
  });
}

class FakeRobotRepository implements RobotRepository {
  FakeRobotRepository({required RobotState initialState})
      : _initialState = initialState;

  final RobotState _initialState;

  @override
  Future<void> sendCommand({
    required MovementDirection direction,
  }) async {}

  @override
  Future<void> updateMode(RobotMode mode) async {}

  @override
  Future<void> updateSpeed(int speed) async {}

  @override
  Stream<List<RobotLogEntry>> watchLogs() =>
      Stream.value(const <RobotLogEntry>[]).asBroadcastStream();

  @override
  Stream<RobotState> watchRobotState() =>
      Stream.value(_initialState).asBroadcastStream();
}
