class AppConstants {
  const AppConstants._();

  static const String appTitle = 'RC Car Controller';
  static const double maxSpeed = 255;
  static const double defaultManualSpeed = 140;
  static const Duration defaultAnimationDuration = Duration(milliseconds: 320);
  static const Duration scanTimeout = Duration(seconds: 12);
  static const Duration reconnectDelay = Duration(milliseconds: 600);

  static const String lineModeCommand = 'N';
  static const String obstacleModeCommand = 'O';
  static const String menualModeCommand = 'MS';

  static const String commandForward = 'FS';
  static const String commandBackward = 'BS';
  static const String commandLeft = 'LS';
  static const String commandRight = 'RS';
  static const String commandStop = 'SS';
  static const String commandForwardLeft = 'GS';
  static const String commandForwardRight = 'IS';
  static const String commandBackwardLeft = 'HS';
  static const String commandBackwardRight = 'JS';

  static const String prefLastDeviceAddress = 'last_device_address';
  static const String prefLastDeviceName = 'last_device_name';
  static const String prefManualSpeed = 'manual_speed';

  static const String telemetryModeKey = 'MODE';
  static const String telemetrySpeedKey = 'SPD';
  static const String telemetryDirectionKey = 'DIR';
  static const String telemetryObstacleKey = 'OBS';
}
