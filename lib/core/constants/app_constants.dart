class AppConstants {
  const AppConstants._();

  static const String appTitle = 'RC Car Controller';
  static const double maxSpeed = 255;
  static const double defaultManualSpeed = 140;
  static const Duration defaultAnimationDuration = Duration(milliseconds: 320);
  static const Duration scanTimeout = Duration(seconds: 12);
  static const Duration reconnectDelay = Duration(milliseconds: 600);

  static const String lineModeCommand = 'M:LINE;';
  static const String obstacleModeCommand = 'M:OBS;';

  static const String commandForward = 'F';
  static const String commandBackward = 'B';
  static const String commandLeft = 'L';
  static const String commandRight = 'R';
  static const String commandStop = 'S';
  static const String commandForwardLeft = 'G';
  static const String commandForwardRight = 'I';
  static const String commandBackwardLeft = 'H';
  static const String commandBackwardRight = 'J';

  static const String prefLastDeviceAddress = 'last_device_address';
  static const String prefLastDeviceName = 'last_device_name';
  static const String prefManualSpeed = 'manual_speed';

  static const String telemetryModeKey = 'MODE';
  static const String telemetrySpeedKey = 'SPD';
  static const String telemetryDirectionKey = 'DIR';
  static const String telemetryObstacleKey = 'OBS';
}
