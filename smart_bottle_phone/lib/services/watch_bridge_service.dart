import 'dart:async';

import 'package:watch_connectivity/watch_connectivity.dart';

import '../models/app_connection_status.dart';
import '../models/smart_bottle_reading.dart';

class WatchBridgeService {
  WatchBridgeService() : _watch = WatchConnectivity();

  final WatchConnectivity _watch;

  StreamSubscription<dynamic>? _messageSub;
  final _incomingMessages = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get incomingMessages => _incomingMessages.stream;

  Future<WatchSyncStatus> initialize() async {
    final supported = await _watch.isSupported;
    final paired = await _watch.isPaired;
    final reachable = await _watch.isReachable;

    _messageSub?.cancel();
    _messageSub = _watch.messageStream.listen((message) {
      _incomingMessages.add(message.cast<String, dynamic>());
    });

    return WatchSyncStatus(
      supported: supported,
      paired: paired,
      reachable: reachable,
      lastSync: null,
      lastError: null,
    );
  }

  Future<WatchSyncStatus> refreshStatus(WatchSyncStatus previous) async {
    try {
      final supported = await _watch.isSupported;
      final paired = await _watch.isPaired;
      final reachable = await _watch.isReachable;
      return previous.copyWith(
        supported: supported,
        paired: paired,
        reachable: reachable,
        clearError: true,
      );
    } catch (e) {
      return previous.copyWith(lastError: 'Watch status failed: $e');
    }
  }

  Future<WatchSyncStatus> sendSyncedReading({
    required SmartBottleReading reading,
    required double todayDrank,
    required double goalLiters,
    required int nextSyncSeconds,
    required AppConnectionStatus btState,
    required WatchSyncStatus previous,
  }) async {
    try {
      await _watch.updateApplicationContext({
        'type': 'sync',
        'timestamp': reading.timestamp.millisecondsSinceEpoch,
        'levelPercent': reading.levelPercent,
        'temperatureC': reading.temperatureC,
        'tdsPpm': reading.tdsPpm,
        'todayDrank': todayDrank,
        'goalLiters': goalLiters,
        'nextSyncSeconds': nextSyncSeconds,
        'btState': btState.name,
      });

      return previous.copyWith(lastSync: DateTime.now(), clearError: true);
    } catch (e) {
      return previous.copyWith(lastError: 'Watch sync failed: $e');
    }
  }

  Future<void> sendReminderMessage() async {
    await _watch.sendMessage({
      'type': 'reminder',
      'title': 'Hydration reminder',
      'body': 'Water level stayed almost unchanged. Drink water now.',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> dispose() async {
    await _messageSub?.cancel();
    await _incomingMessages.close();
  }
}
