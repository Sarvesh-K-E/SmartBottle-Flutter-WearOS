import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../core/constants.dart';
import '../repositories/settings_repository.dart';
import 'notification_service.dart';

const reminderWorkerTaskName = 'smart_bottle_reminder_worker';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    final settings = SettingsRepository();
    await NotificationService.instance.initialize();

    final enabled = await settings.isReminderEnabled();
    if (!enabled) {
      return true;
    }

    final intervalMinutes = await settings.getReminderIntervalMinutes();
    final baselineLevel = await settings.getReminderBaselineLevelPercent();
    final baselineTime = await settings.getReminderBaselineTime();
    final latestLevel = await settings.getLatestSyncedLevelPercent();
    final latestSyncTime = await settings.getLatestSyncTime();

    if (baselineLevel == null ||
        baselineTime == null ||
        latestLevel == null ||
        latestSyncTime == null) {
      return true;
    }

    final delta = (latestLevel - baselineLevel).abs().toDouble();
    if (delta > AppConstants.reminderLevelThresholdPercent) {
      await settings.saveReminderBaseline(
        levelPercent: latestLevel,
        at: latestSyncTime,
      );
      return true;
    }

    final now = DateTime.now();
    final elapsed = now.difference(baselineTime);
    final interval = Duration(milliseconds: (intervalMinutes * 60000).round());

    if (elapsed >= interval) {
      await NotificationService.instance.showReminder(
        title: 'Hydration reminder',
        body: 'No notable water-level change detected. Time to drink water.',
      );
      await settings.setLastReminderTime(now);
      await settings.saveReminderBaseline(levelPercent: latestLevel, at: now);
    }

    return true;
  });
}

class BackgroundReminderScheduler {
  Future<void> start() async {
    await Workmanager().registerPeriodicTask(
      'smart_bottle_reminder_unique',
      reminderWorkerTaskName,
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      constraints: Constraints(networkType: NetworkType.notRequired),
    );
  }

  Future<void> stop() async {
    await Workmanager().cancelByUniqueName('smart_bottle_reminder_unique');
  }
}
