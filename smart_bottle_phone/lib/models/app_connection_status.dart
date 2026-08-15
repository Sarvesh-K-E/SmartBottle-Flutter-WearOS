enum AppConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class WatchSyncStatus {
  const WatchSyncStatus({
    required this.supported,
    required this.paired,
    required this.reachable,
    required this.lastSync,
    required this.lastError,
  });

  final bool supported;
  final bool paired;
  final bool reachable;
  final DateTime? lastSync;
  final String? lastError;

  static const empty = WatchSyncStatus(
    supported: false,
    paired: false,
    reachable: false,
    lastSync: null,
    lastError: null,
  );

  WatchSyncStatus copyWith({
    bool? supported,
    bool? paired,
    bool? reachable,
    DateTime? lastSync,
    String? lastError,
    bool clearError = false,
  }) {
    return WatchSyncStatus(
      supported: supported ?? this.supported,
      paired: paired ?? this.paired,
      reachable: reachable ?? this.reachable,
      lastSync: lastSync ?? this.lastSync,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}
