class RobotLogEntry {
  const RobotLogEntry({
    required this.message,
    this.timestamp,
  });

  final String message;
  final DateTime? timestamp;

  factory RobotLogEntry.fromValue(Object? raw) {
    if (raw is String) {
      return RobotLogEntry(message: raw);
    }

    if (raw is Map) {
      final map = Map<Object?, Object?>.from(raw);
      final timestampRaw = map['timestamp'] ?? map['time'] ?? map['createdAt'];
      final milliseconds = int.tryParse(timestampRaw?.toString() ?? '');
      return RobotLogEntry(
        message: map['message']?.toString() ?? raw.toString(),
        timestamp: milliseconds == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(milliseconds),
      );
    }

    return RobotLogEntry(message: raw?.toString() ?? 'Unknown log');
  }
}
