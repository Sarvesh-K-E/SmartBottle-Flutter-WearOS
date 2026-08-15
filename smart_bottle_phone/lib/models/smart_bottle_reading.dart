class SmartBottleReading {
  SmartBottleReading({
    required this.levelPercent,
    required this.temperatureC,
    required this.tdsPpm,
    required this.timestamp,
  });

  final int levelPercent;
  final double temperatureC;
  final int tdsPpm;
  final DateTime timestamp;

  SmartBottleReading copyWith({
    int? levelPercent,
    double? temperatureC,
    int? tdsPpm,
    DateTime? timestamp,
  }) {
    return SmartBottleReading(
      levelPercent: levelPercent ?? this.levelPercent,
      temperatureC: temperatureC ?? this.temperatureC,
      tdsPpm: tdsPpm ?? this.tdsPpm,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'levelPercent': levelPercent,
      'temperatureC': temperatureC,
      'tdsPpm': tdsPpm,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory SmartBottleReading.fromMap(Map<String, dynamic> map) {
    return SmartBottleReading(
      levelPercent: (map['levelPercent'] as num).toInt(),
      temperatureC: (map['temperatureC'] as num).toDouble(),
      tdsPpm: (map['tdsPpm'] as num).toInt(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as num).toInt(),
      ),
    );
  }
}
