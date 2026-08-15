import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

import '../models/wear_sync_state.dart';

final wearSyncControllerProvider =
    StateNotifierProvider<WearSyncController, WearSyncState>(
      (ref) => WearSyncController(),
    );

class WearSyncController extends StateNotifier<WearSyncState> {
  WearSyncController() : super(WearSyncState.initial()) {
    _initialize();
  }

  static const _lastContextKey = 'wear_last_context';

  final WatchConnectivity _watch = WatchConnectivity();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<dynamic>? _contextSub;
  StreamSubscription<dynamic>? _messageSub;
  Timer? _heartbeatTimer;
  DateTime? _lastPingAt;

  Future<void> _initialize() async {
    await _initNotifications();
    await _loadCachedData();

    final supported = await _watch.isSupported;
    final paired = await _watch.isPaired;
    final reachable = await _watch.isReachable;

    state = state.copyWith(
      supported: supported,
      paired: paired,
      reachable: reachable,
    );

    final contexts = await _watch.receivedApplicationContexts;
    if (contexts.isNotEmpty) {
      _handleContext(contexts.last.cast<String, dynamic>());
    }

    _contextSub = _watch.contextStream.listen((message) {
      _handleContext(message.cast<String, dynamic>());
    });

    _messageSub = _watch.messageStream.listen((message) {
      _handleIncomingMessage(message.cast<String, dynamic>());
    });

    await _refreshReachability(forcePing: true);
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshReachability(),
    );
  }

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _notifications.initialize(settings: settings);
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastContextKey);
    if (raw == null) return;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _applySyncMap(map);
    } catch (_) {
      // Ignore malformed cache.
    }
  }

  void _handleContext(Map<String, dynamic> context) {
    if (context['type'] != 'sync') return;
    _applySyncMap(context);
    _cacheContext(context);
  }

  Future<void> _cacheContext(Map<String, dynamic> context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastContextKey, jsonEncode(context));
  }

  void _applySyncMap(Map<String, dynamic> map) {
    DateTime? parsedLastSync;
    final timestamp = map['timestamp'];
    if (timestamp is num) {
      parsedLastSync = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
    }

    state = state.copyWith(
      levelPercent: _toInt(map['levelPercent']),
      temperatureC: _toDouble(map['temperatureC']),
      tdsPpm: _toInt(map['tdsPpm']),
      todayDrankLiters: _toDouble(map['todayDrank']) ?? state.todayDrankLiters,
      goalLiters: _toDouble(map['goalLiters']) ?? state.goalLiters,
      nextSyncSeconds: _toInt(map['nextSyncSeconds']) ?? state.nextSyncSeconds,
      btState: (map['btState'] as String?) ?? state.btState,
      lastSync: parsedLastSync ?? DateTime.now(),
    );
  }

  int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  double? _toDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  void _handleIncomingMessage(Map<String, dynamic> message) {
    if (message['type'] == 'reminder') {
      _showReminder(
        title: (message['title'] as String?) ?? 'Hydration reminder',
        body: (message['body'] as String?) ?? 'Drink water now.',
      );
    }
  }

  Future<void> _showReminder({
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'wear_hydration_reminders',
        'Wear hydration reminders',
        channelDescription: 'Hydration reminders received from phone',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _notifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> _refreshReachability({bool forcePing = false}) async {
    try {
      final supported = await _watch.isSupported;
      final paired = await _watch.isPaired;
      final reachable = await _watch.isReachable;
      state = state.copyWith(
        reachable: reachable,
        paired: paired,
        supported: supported,
      );

      if (!supported || !paired) {
        return;
      }

      final now = DateTime.now();
      final canPing =
          _lastPingAt == null ||
          now.difference(_lastPingAt!) >= const Duration(seconds: 2);
      if (forcePing || (reachable && canPing)) {
        _lastPingAt = now;
        try {
          await _watch.sendMessage({
            'type': 'watch_ping',
            'timestamp': now.millisecondsSinceEpoch,
          });
        } catch (_) {
          // Ignore ping failures; reachability above is source of truth.
        }
      }
    } catch (_) {
      state = state.copyWith(reachable: false, paired: false);
    }
  }

  @override
  void dispose() {
    _contextSub?.cancel();
    _messageSub?.cancel();
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}
