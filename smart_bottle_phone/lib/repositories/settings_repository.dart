import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const _onboardingDoneKey = 'onboarding_done';
  static const _goalLitersKey = 'goal_liters';
  static const _reminderEnabledKey = 'reminder_enabled';
  static const _reminderMinutesKey = 'reminder_minutes';
  static const _connectedAddressKey = 'connected_address';

  static const _lastLevelPercentKey = 'last_level_percent';
  static const _lastSyncEpochMsKey = 'last_sync_epoch_ms';
  static const _baselineLevelPercentKey = 'baseline_level_percent';
  static const _baselineEpochMsKey = 'baseline_epoch_ms';
  static const _lastReminderEpochMsKey = 'last_reminder_epoch_ms';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<bool> isOnboardingDone() async =>
      (await _prefs).getBool(_onboardingDoneKey) ?? false;

  Future<void> setOnboardingDone(bool value) async {
    await (await _prefs).setBool(_onboardingDoneKey, value);
  }

  Future<double> getGoalLiters() async =>
      (await _prefs).getDouble(_goalLitersKey) ?? 2.5;

  Future<void> setGoalLiters(double value) async {
    await (await _prefs).setDouble(_goalLitersKey, value);
  }

  Future<bool> isReminderEnabled() async =>
      (await _prefs).getBool(_reminderEnabledKey) ?? false;

  Future<void> setReminderEnabled(bool value) async {
    await (await _prefs).setBool(_reminderEnabledKey, value);
  }

  Future<double> getReminderIntervalMinutes() async =>
      (await _prefs).getDouble(_reminderMinutesKey) ?? 60;

  Future<void> setReminderIntervalMinutes(double minutes) async {
    await (await _prefs).setDouble(_reminderMinutesKey, minutes);
  }

  Future<String?> getConnectedAddress() async =>
      (await _prefs).getString(_connectedAddressKey);

  Future<void> setConnectedAddress(String? address) async {
    final prefs = await _prefs;
    if (address == null || address.isEmpty) {
      await prefs.remove(_connectedAddressKey);
      return;
    }
    await prefs.setString(_connectedAddressKey, address);
  }

  Future<void> saveLatestSyncedLevel({
    required int levelPercent,
    required DateTime at,
  }) async {
    final prefs = await _prefs;
    await prefs.setInt(_lastLevelPercentKey, levelPercent);
    await prefs.setInt(_lastSyncEpochMsKey, at.millisecondsSinceEpoch);
  }

  Future<int?> getLatestSyncedLevelPercent() async =>
      (await _prefs).getInt(_lastLevelPercentKey);

  Future<DateTime?> getLatestSyncTime() async {
    final millis = (await _prefs).getInt(_lastSyncEpochMsKey);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> saveReminderBaseline({
    required int levelPercent,
    required DateTime at,
  }) async {
    final prefs = await _prefs;
    await prefs.setInt(_baselineLevelPercentKey, levelPercent);
    await prefs.setInt(_baselineEpochMsKey, at.millisecondsSinceEpoch);
  }

  Future<int?> getReminderBaselineLevelPercent() async =>
      (await _prefs).getInt(_baselineLevelPercentKey);

  Future<DateTime?> getReminderBaselineTime() async {
    final millis = (await _prefs).getInt(_baselineEpochMsKey);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> setLastReminderTime(DateTime time) async {
    await (await _prefs).setInt(
      _lastReminderEpochMsKey,
      time.millisecondsSinceEpoch,
    );
  }

  Future<DateTime?> getLastReminderTime() async {
    final millis = (await _prefs).getInt(_lastReminderEpochMsKey);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }
}
