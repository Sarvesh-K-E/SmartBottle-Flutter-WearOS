import 'dart:async';

import 'package:flutter_bluetooth_classic_serial/flutter_bluetooth_classic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../models/app_connection_status.dart';
import '../models/smart_bottle_reading.dart';
import '../models/smart_bottle_state.dart';
import '../repositories/history_repository.dart';
import '../repositories/settings_repository.dart';
import '../services/background_tasks.dart';
import '../services/bluetooth_classic_service.dart';
import '../services/permission_service.dart';
import '../services/reminder_service.dart';
import '../services/sync_window_aggregator.dart';
import '../services/watch_bridge_service.dart';

final smartBottleControllerProvider =
    StateNotifierProvider<SmartBottleController, SmartBottleState>(
      (ref) => SmartBottleController(),
    );

class SmartBottleController extends StateNotifier<SmartBottleState> {
  SmartBottleController({
    BluetoothClassicService? bluetoothService,
    SyncWindowAggregator? aggregator,
    HistoryRepository? historyRepository,
    SettingsRepository? settingsRepository,
    PermissionService? permissionService,
    WatchBridgeService? watchBridgeService,
    ReminderService? reminderService,
    BackgroundReminderScheduler? backgroundScheduler,
  }) : _bluetoothService = bluetoothService ?? BluetoothClassicService(),
       _aggregator = aggregator ?? SyncWindowAggregator(),
       _historyRepository = historyRepository ?? HistoryRepository(),
       _settingsRepository = settingsRepository ?? SettingsRepository(),
       _permissionService = permissionService ?? PermissionService(),
       _watchBridgeService = watchBridgeService ?? WatchBridgeService(),
       _reminderService =
           reminderService ??
           ReminderService(
             settingsRepository: settingsRepository ?? SettingsRepository(),
           ),
       _backgroundScheduler =
           backgroundScheduler ?? BackgroundReminderScheduler(),
       super(SmartBottleState.initial()) {
    _initialize();
  }

  final BluetoothClassicService _bluetoothService;
  final SyncWindowAggregator _aggregator;
  final HistoryRepository _historyRepository;
  final SettingsRepository _settingsRepository;
  final PermissionService _permissionService;
  final WatchBridgeService _watchBridgeService;
  final ReminderService _reminderService;
  final BackgroundReminderScheduler _backgroundScheduler;

  StreamSubscription<AppConnectionStatus>? _connectionSub;
  StreamSubscription<SmartBottleReading>? _readingSub;
  StreamSubscription<String>? _errorSub;
  StreamSubscription<SyncTick>? _tickSub;
  StreamSubscription<SmartBottleReading>? _resultSub;
  StreamSubscription<Map<String, dynamic>>? _watchMessageSub;

  double? _previousSyncedLevelLiters;

  Future<void> _initialize() async {
    await _historyRepository.init();

    final onboardingDone = await _settingsRepository.isOnboardingDone();
    final goalLiters = await _settingsRepository.getGoalLiters();
    final reminderEnabled = await _settingsRepository.isReminderEnabled();
    final reminderMinutes = await _settingsRepository
        .getReminderIntervalMinutes();
    final connectedAddress = await _settingsRepository.getConnectedAddress();

    final btEnabled = await _bluetoothService.isBluetoothEnabled();

    await _bluetoothService.setupListeners();
    _subscribeToStreams();

    final paired = btEnabled
        ? await _safeGetPairedDevices()
        : <BluetoothDevice>[];
    final todayDrank = await _historyRepository.getTodayDrank(DateTime.now());

    final latestPercent = await _settingsRepository
        .getLatestSyncedLevelPercent();
    if (latestPercent != null) {
      _previousSyncedLevelLiters =
          (latestPercent / 100.0) * AppConstants.bottleCapacityLiters;
    }

    final watchStatus = await _watchBridgeService.initialize();
    _watchMessageSub = _watchBridgeService.incomingMessages.listen((message) {
      if (message['type'] == 'watch_ping') {
        _pushWatchState();
      }
    });

    await _refreshReports(goalLiters);

    state = state.copyWith(
      isLoading: false,
      onboardingDone: onboardingDone,
      goalLiters: goalLiters,
      reminderEnabled: reminderEnabled,
      reminderIntervalMinutes: reminderMinutes,
      clearConnectedAddress: true,
      clearPendingConnectAddress: true,
      btEnabled: btEnabled,
      pairedDevices: paired,
      todayDrankLiters: todayDrank,
      watchSyncStatus: watchStatus,
      reminderStateText: reminderEnabled
          ? 'Reminder active every ${reminderMinutes.toStringAsFixed(0)} min'
          : 'Reminder off',
      clearError: true,
    );

    _aggregator.start();

    if (connectedAddress != null && btEnabled) {
      await connectToDevice(connectedAddress, silent: true);
    }

    if (reminderEnabled) {
      await _backgroundScheduler.start();
    } else {
      await _backgroundScheduler.stop();
    }
  }

  void _subscribeToStreams() {
    _connectionSub = _bluetoothService.connectionStream.listen((status) {
      switch (status) {
        case AppConnectionStatus.connected:
          state = state.copyWith(
            connectionStatus: status,
            connectedAddress: _bluetoothService.currentTargetAddress,
            clearPendingConnectAddress: true,
          );
          break;
        case AppConnectionStatus.connecting:
        case AppConnectionStatus.reconnecting:
          state = state.copyWith(
            connectionStatus: status,
            pendingConnectAddress: _bluetoothService.currentTargetAddress,
            clearConnectedAddress: true,
          );
          break;
        case AppConnectionStatus.disconnected:
        case AppConnectionStatus.error:
          state = state.copyWith(
            connectionStatus: status,
            clearConnectedAddress: true,
            clearPendingConnectAddress: true,
          );
          break;
      }
    });

    _readingSub = _bluetoothService.readingStream.listen((reading) {
      _aggregator.addReading(reading);
    });

    _errorSub = _bluetoothService.errorStream.listen((error) {
      state = state.copyWith(
        error: error,
        connectionStatus: AppConnectionStatus.error,
      );
    });

    _tickSub = _aggregator.tickStream.listen((tick) {
      state = state.copyWith(
        secondsToNextSync: tick.secondsRemaining,
        syncProgress: tick.progress,
      );
    });

    _resultSub = _aggregator.resultStream.listen(_handleSyncedReading);
  }

  Future<List<BluetoothDevice>> _safeGetPairedDevices() async {
    try {
      return await _bluetoothService.getPairedDevices();
    } catch (e) {
      state = state.copyWith(error: 'Failed to read paired devices: $e');
      return [];
    }
  }

  Future<void> markOnboardingDone() async {
    await _settingsRepository.setOnboardingDone(true);
    state = state.copyWith(onboardingDone: true);
  }

  Future<void> requestPermissionsAndRefreshBluetooth() async {
    final granted = await _permissionService.requestBluetoothPermissions();
    if (!granted) {
      state = state.copyWith(clearError: true);
      return;
    }

    final enabled = await _bluetoothService.isBluetoothEnabled();
    if (!enabled) {
      final enabledNow = await _bluetoothService.enableBluetooth();
      if (!enabledNow) {
        state = state.copyWith(
          error: 'Bluetooth is disabled. Please enable it and try again.',
        );
      }
    }

    final btEnabled = await _bluetoothService.isBluetoothEnabled();
    final devices = btEnabled
        ? await _safeGetPairedDevices()
        : <BluetoothDevice>[];
    state = state.copyWith(btEnabled: btEnabled, pairedDevices: devices);
  }

  Future<void> refreshPairedDevices() async {
    final devices = await _safeGetPairedDevices();
    state = state.copyWith(pairedDevices: devices, clearError: true);
  }

  Future<void> connectToDevice(String address, {bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(
        connectionStatus: AppConnectionStatus.connecting,
        pendingConnectAddress: address,
        clearConnectedAddress: true,
        clearError: true,
      );
    }

    final success = await _bluetoothService.connect(address);
    if (success) {
      await _settingsRepository.setConnectedAddress(address);
      state = state.copyWith(
        pendingConnectAddress: address,
        clearConnectedAddress: true,
        connectionStatus: AppConnectionStatus.connecting,
      );
    } else {
      state = state.copyWith(
        connectionStatus: AppConnectionStatus.error,
        clearConnectedAddress: true,
        clearPendingConnectAddress: true,
        error:
            'Could not connect to $address. Check that HC-05 is powered and paired in Android settings.',
      );
    }
  }

  Future<void> disconnect() async {
    await _bluetoothService.disconnect();
    state = state.copyWith(
      connectionStatus: AppConnectionStatus.disconnected,
      clearConnectedAddress: true,
      clearPendingConnectAddress: true,
    );
    await _settingsRepository.setConnectedAddress(null);
  }

  Future<void> _handleSyncedReading(SmartBottleReading reading) async {
    await _historyRepository.addSyncedReading(
      timestamp: reading.timestamp,
      levelPercent: reading.levelPercent,
      temperatureC: reading.temperatureC,
      tdsPpm: reading.tdsPpm,
    );

    final currentLevelLiters =
        (reading.levelPercent / 100.0) * AppConstants.bottleCapacityLiters;
    final previous = _previousSyncedLevelLiters;

    var todayDrank = await _historyRepository.getTodayDrank(DateTime.now());
    if (previous != null) {
      final drop = previous - currentLevelLiters;
      if (drop > AppConstants.drinkDeltaNoiseLiters) {
        todayDrank = await _historyRepository.addDrinking(
          DateTime.now(),
          drop,
          state.goalLiters,
        );
      }
    }

    _previousSyncedLevelLiters = currentLevelLiters;

    await _settingsRepository.saveLatestSyncedLevel(
      levelPercent: reading.levelPercent,
      at: reading.timestamp,
    );

    final reminderResult = await _reminderService.evaluateOnSyncedReading(
      reading: reading,
      reminderEnabled: state.reminderEnabled,
      intervalMinutes: state.reminderIntervalMinutes,
    );

    if (reminderResult.shouldNotify) {
      await _watchBridgeService.sendReminderMessage();
    }

    await _refreshReports(state.goalLiters);

    state = state.copyWith(
      latestSyncedReading: reading,
      todayDrankLiters: todayDrank,
      lastSyncTime: DateTime.now(),
      reminderStateText: reminderResult.stateText,
      clearError: true,
    );

    await _pushWatchState();
  }

  Future<void> _refreshReports(double goalLiters) async {
    final weeklyData = await _historyRepository.fetchLastDays(7);
    final monthlyData = await _historyRepository.fetchLastDays(30);

    state = state.copyWith(
      last7Days: weeklyData,
      weekly: _historyRepository.computeSummary(weeklyData, goalLiters),
      monthly: _historyRepository.computeSummary(monthlyData, goalLiters),
    );
  }

  Future<void> setGoalLiters(double liters) async {
    if (liters <= 0) return;
    await _settingsRepository.setGoalLiters(liters);
    state = state.copyWith(goalLiters: liters);
    await _refreshReports(liters);
    await _pushWatchState();
  }

  Future<void> setReminderSettings({
    required bool enabled,
    required double intervalMinutes,
  }) async {
    if (intervalMinutes <= 0) return;

    await _settingsRepository.setReminderEnabled(enabled);
    await _settingsRepository.setReminderIntervalMinutes(intervalMinutes);

    if (enabled) {
      await _backgroundScheduler.start();
    } else {
      await _backgroundScheduler.stop();
    }

    state = state.copyWith(
      reminderEnabled: enabled,
      reminderIntervalMinutes: intervalMinutes,
      reminderStateText: enabled
          ? 'Reminder active every ${intervalMinutes.toStringAsFixed(0)} min'
          : 'Reminder off',
    );
  }

  Future<void> refreshWatchStatus() async {
    final updated = await _watchBridgeService.refreshStatus(
      state.watchSyncStatus,
    );
    state = state.copyWith(watchSyncStatus: updated);
  }

  Future<void> _pushWatchState() async {
    final reading = state.latestSyncedReading;
    if (reading == null) return;

    final status = await _watchBridgeService.sendSyncedReading(
      reading: reading,
      todayDrank: state.todayDrankLiters,
      goalLiters: state.goalLiters,
      nextSyncSeconds: state.secondsToNextSync,
      btState: state.connectionStatus,
      previous: state.watchSyncStatus,
    );

    state = state.copyWith(watchSyncStatus: status);
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    _readingSub?.cancel();
    _errorSub?.cancel();
    _tickSub?.cancel();
    _resultSub?.cancel();
    _watchMessageSub?.cancel();

    _bluetoothService.dispose();
    _aggregator.dispose();
    _historyRepository.close();
    _watchBridgeService.dispose();
    super.dispose();
  }
}
