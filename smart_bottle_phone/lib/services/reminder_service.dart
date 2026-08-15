import '../core/constants.dart';
import '../models/smart_bottle_reading.dart';
import '../repositories/settings_repository.dart';
import 'notification_service.dart';

class ReminderEvaluationResult {
  const ReminderEvaluationResult({
    required this.shouldNotify,
    required this.stateText,
  });

  final bool shouldNotify;
  final String stateText;
}

class ReminderService {
  ReminderService({required SettingsRepository settingsRepository})
    : _settings = settingsRepository;

  final SettingsRepository _settings;

  Future<ReminderEvaluationResult> evaluateOnSyncedReading({
    required SmartBottleReading reading,
    required bool reminderEnabled,
    required double intervalMinutes,
  }) async {
    if (!reminderEnabled) {
      return const ReminderEvaluationResult(
        shouldNotify: false,
        stateText: 'Reminder off',
      );
    }

    final baselineLevel = await _settings.getReminderBaselineLevelPercent();
    final baselineTime = await _settings.getReminderBaselineTime();
    final now = reading.timestamp;

    if (baselineLevel == null || baselineTime == null) {
      await _settings.saveReminderBaseline(
        levelPercent: reading.levelPercent,
        at: now,
      );
      return ReminderEvaluationResult(
        shouldNotify: false,
        stateText:
            'Tracking inactivity for ${intervalMinutes.toStringAsFixed(0)} min',
      );
    }

    final levelDelta = (reading.levelPercent - baselineLevel).abs();
    if (levelDelta > AppConstants.reminderLevelThresholdPercent) {
      await _settings.saveReminderBaseline(
        levelPercent: reading.levelPercent,
        at: now,
      );
      return ReminderEvaluationResult(
        shouldNotify: false,
        stateText: 'Level changed enough, timer reset',
      );
    }

    final elapsed = now.difference(baselineTime);
    final interval = Duration(milliseconds: (intervalMinutes * 60000).round());
    if (elapsed >= interval) {
      await NotificationService.instance.showReminder(
        title: 'Hydration reminder',
        body: 'Your bottle level stayed almost the same. Take a sip now.',
      );
      await _settings.setLastReminderTime(now);
      await _settings.saveReminderBaseline(
        levelPercent: reading.levelPercent,
        at: now,
      );
      return ReminderEvaluationResult(
        shouldNotify: true,
        stateText:
            'Reminder sent at ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      );
    }

    final remaining = interval - elapsed;
    return ReminderEvaluationResult(
      shouldNotify: false,
      stateText:
          'Reminder in ${remaining.inMinutes}m ${remaining.inSeconds % 60}s',
    );
  }
}
