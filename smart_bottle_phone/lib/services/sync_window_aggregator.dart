import 'dart:async';

import 'package:collection/collection.dart';

import '../core/constants.dart';
import '../models/smart_bottle_reading.dart';

class SyncTick {
  const SyncTick({required this.secondsRemaining, required this.progress});

  final int secondsRemaining;
  final double progress;
}

class SyncWindowAggregator {
  SyncWindowAggregator({Duration? window})
    : _window =
          window ?? const Duration(seconds: AppConstants.syncWindowSeconds);

  final Duration _window;
  final _tickController = StreamController<SyncTick>.broadcast();
  final _resultController = StreamController<SmartBottleReading>.broadcast();

  Stream<SyncTick> get tickStream => _tickController.stream;
  Stream<SmartBottleReading> get resultStream => _resultController.stream;

  final List<SmartBottleReading> _windowReadings = [];
  Timer? _timer;
  DateTime _windowStart = DateTime.now();

  void start() {
    _windowStart = DateTime.now();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    _tickController.add(
      const SyncTick(
        secondsRemaining: AppConstants.syncWindowSeconds,
        progress: 0,
      ),
    );
  }

  void addReading(SmartBottleReading reading) {
    _windowReadings.add(reading);
  }

  void _onTick() {
    final now = DateTime.now();
    final elapsed = now.difference(_windowStart);

    if (elapsed >= _window) {
      _finalizeWindow();
      _windowStart = now;
      _tickController.add(
        const SyncTick(
          secondsRemaining: AppConstants.syncWindowSeconds,
          progress: 0,
        ),
      );
      return;
    }

    final remaining = (_window.inSeconds - elapsed.inSeconds).clamp(
      0,
      _window.inSeconds,
    );
    final progress = (elapsed.inMilliseconds / _window.inMilliseconds).clamp(
      0.0,
      1.0,
    );
    _tickController.add(
      SyncTick(secondsRemaining: remaining, progress: progress),
    );
  }

  void _finalizeWindow() {
    if (_windowReadings.isEmpty) {
      return;
    }

    final level = _stableModeInt(
      _windowReadings.map((e) => e.levelPercent).toList(),
    );
    final tempScaled = _stableModeInt(
      _windowReadings.map((e) => (e.temperatureC * 10).round()).toList(),
    );
    final tds = _stableModeInt(_windowReadings.map((e) => e.tdsPpm).toList());

    final synced = SmartBottleReading(
      levelPercent: level,
      temperatureC: tempScaled / 10,
      tdsPpm: tds,
      timestamp: DateTime.now(),
    );

    _windowReadings.clear();
    _resultController.add(synced);
  }

  int _stableModeInt(List<int> values) {
    if (values.isEmpty) return 0;

    final freq = <int, int>{};
    for (final value in values) {
      freq.update(value, (count) => count + 1, ifAbsent: () => 1);
    }

    final maxCount = freq.values.max;
    final modes = freq.entries
        .where((entry) => entry.value == maxCount)
        .map((entry) => entry.key)
        .toList();

    if (modes.length == 1) {
      return modes.first;
    }

    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) {
      return sorted[mid];
    }
    return ((sorted[mid - 1] + sorted[mid]) / 2).round();
  }

  Future<void> dispose() async {
    _timer?.cancel();
    await _tickController.close();
    await _resultController.close();
  }
}
