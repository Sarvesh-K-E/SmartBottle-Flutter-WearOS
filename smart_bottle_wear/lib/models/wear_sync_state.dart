class WearSyncState {
  const WearSyncState({
    required this.supported,
    required this.paired,
    required this.reachable,
    required this.levelPercent,
    required this.temperatureC,
    required this.tdsPpm,
    required this.todayDrankLiters,
    required this.goalLiters,
    required this.nextSyncSeconds,
    required this.btState,
    required this.lastSync,
  });

  final bool supported;
  final bool paired;
  final bool reachable;
  final int? levelPercent;
  final double? temperatureC;
  final int? tdsPpm;
  final double todayDrankLiters;
  final double goalLiters;
  final int nextSyncSeconds;
  final String btState;
  final DateTime? lastSync;

  double get levelLiters => ((levelPercent ?? 0) / 100.0) * 2.0;

  double get goalProgress {
    if (goalLiters <= 0) return 0;
    return (todayDrankLiters / goalLiters).clamp(0.0, 1.0);
  }

  bool get hasData => levelPercent != null;

  WearSyncState copyWith({
    bool? supported,
    bool? paired,
    bool? reachable,
    int? levelPercent,
    bool clearLevel = false,
    double? temperatureC,
    bool clearTemp = false,
    int? tdsPpm,
    bool clearTds = false,
    double? todayDrankLiters,
    double? goalLiters,
    int? nextSyncSeconds,
    String? btState,
    DateTime? lastSync,
  }) {
    return WearSyncState(
      supported: supported ?? this.supported,
      paired: paired ?? this.paired,
      reachable: reachable ?? this.reachable,
      levelPercent: clearLevel ? null : (levelPercent ?? this.levelPercent),
      temperatureC: clearTemp ? null : (temperatureC ?? this.temperatureC),
      tdsPpm: clearTds ? null : (tdsPpm ?? this.tdsPpm),
      todayDrankLiters: todayDrankLiters ?? this.todayDrankLiters,
      goalLiters: goalLiters ?? this.goalLiters,
      nextSyncSeconds: nextSyncSeconds ?? this.nextSyncSeconds,
      btState: btState ?? this.btState,
      lastSync: lastSync ?? this.lastSync,
    );
  }

  factory WearSyncState.initial() => const WearSyncState(
    supported: false,
    paired: false,
    reachable: false,
    levelPercent: null,
    temperatureC: null,
    tdsPpm: null,
    todayDrankLiters: 0,
    goalLiters: 2.5,
    nextSyncSeconds: 30,
    btState: 'disconnected',
    lastSync: null,
  );
}
