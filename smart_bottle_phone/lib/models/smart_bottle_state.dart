import 'package:flutter_bluetooth_classic_serial/flutter_bluetooth_classic.dart';

import '../core/constants.dart';
import '../models/app_connection_status.dart';
import '../models/daily_intake.dart';
import '../models/smart_bottle_reading.dart';

class SmartBottleState {
  const SmartBottleState({
    required this.isLoading,
    required this.onboardingDone,
    required this.connectionStatus,
    required this.btEnabled,
    required this.pairedDevices,
    required this.connectedAddress,
    required this.pendingConnectAddress,
    required this.latestSyncedReading,
    required this.secondsToNextSync,
    required this.syncProgress,
    required this.todayDrankLiters,
    required this.goalLiters,
    required this.reminderEnabled,
    required this.reminderIntervalMinutes,
    required this.reminderStateText,
    required this.lastSyncTime,
    required this.weekly,
    required this.monthly,
    required this.last7Days,
    required this.watchSyncStatus,
    required this.error,
  });

  final bool isLoading;
  final bool onboardingDone;
  final AppConnectionStatus connectionStatus;
  final bool btEnabled;
  final List<BluetoothDevice> pairedDevices;
  final String? connectedAddress;
  final String? pendingConnectAddress;
  final SmartBottleReading? latestSyncedReading;
  final int secondsToNextSync;
  final double syncProgress;
  final double todayDrankLiters;
  final double goalLiters;
  final bool reminderEnabled;
  final double reminderIntervalMinutes;
  final String reminderStateText;
  final DateTime? lastSyncTime;
  final ReportSummary weekly;
  final ReportSummary monthly;
  final List<DailyIntake> last7Days;
  final WatchSyncStatus watchSyncStatus;
  final String? error;

  double get currentLiters {
    final level = latestSyncedReading?.levelPercent ?? 0;
    return (level / 100.0) * AppConstants.bottleCapacityLiters;
  }

  double get goalProgress {
    if (goalLiters <= 0) return 0;
    return (todayDrankLiters / goalLiters).clamp(0, 1);
  }

  SmartBottleState copyWith({
    bool? isLoading,
    bool? onboardingDone,
    AppConnectionStatus? connectionStatus,
    bool? btEnabled,
    List<BluetoothDevice>? pairedDevices,
    String? connectedAddress,
    bool clearConnectedAddress = false,
    String? pendingConnectAddress,
    bool clearPendingConnectAddress = false,
    SmartBottleReading? latestSyncedReading,
    bool clearLatestSyncedReading = false,
    int? secondsToNextSync,
    double? syncProgress,
    double? todayDrankLiters,
    double? goalLiters,
    bool? reminderEnabled,
    double? reminderIntervalMinutes,
    String? reminderStateText,
    DateTime? lastSyncTime,
    bool clearLastSyncTime = false,
    ReportSummary? weekly,
    ReportSummary? monthly,
    List<DailyIntake>? last7Days,
    WatchSyncStatus? watchSyncStatus,
    String? error,
    bool clearError = false,
  }) {
    return SmartBottleState(
      isLoading: isLoading ?? this.isLoading,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      btEnabled: btEnabled ?? this.btEnabled,
      pairedDevices: pairedDevices ?? this.pairedDevices,
      connectedAddress: clearConnectedAddress
          ? null
          : (connectedAddress ?? this.connectedAddress),
      pendingConnectAddress: clearPendingConnectAddress
          ? null
          : (pendingConnectAddress ?? this.pendingConnectAddress),
      latestSyncedReading: clearLatestSyncedReading
          ? null
          : (latestSyncedReading ?? this.latestSyncedReading),
      secondsToNextSync: secondsToNextSync ?? this.secondsToNextSync,
      syncProgress: syncProgress ?? this.syncProgress,
      todayDrankLiters: todayDrankLiters ?? this.todayDrankLiters,
      goalLiters: goalLiters ?? this.goalLiters,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderIntervalMinutes:
          reminderIntervalMinutes ?? this.reminderIntervalMinutes,
      reminderStateText: reminderStateText ?? this.reminderStateText,
      lastSyncTime: clearLastSyncTime
          ? null
          : (lastSyncTime ?? this.lastSyncTime),
      weekly: weekly ?? this.weekly,
      monthly: monthly ?? this.monthly,
      last7Days: last7Days ?? this.last7Days,
      watchSyncStatus: watchSyncStatus ?? this.watchSyncStatus,
      error: clearError ? null : (error ?? this.error),
    );
  }

  static const emptyReport = ReportSummary(
    averagePerUsedDay: 0,
    goalAchievedDays: 0,
    usedDays: 0,
    totalDrank: 0,
  );

  factory SmartBottleState.initial() => const SmartBottleState(
    isLoading: true,
    onboardingDone: false,
    connectionStatus: AppConnectionStatus.disconnected,
    btEnabled: false,
    pairedDevices: [],
    connectedAddress: null,
    pendingConnectAddress: null,
    latestSyncedReading: null,
    secondsToNextSync: AppConstants.syncWindowSeconds,
    syncProgress: 0,
    todayDrankLiters: 0,
    goalLiters: 2.5,
    reminderEnabled: false,
    reminderIntervalMinutes: 60,
    reminderStateText: 'Reminder off',
    lastSyncTime: null,
    weekly: emptyReport,
    monthly: emptyReport,
    last7Days: [],
    watchSyncStatus: WatchSyncStatus.empty,
    error: null,
  );
}
