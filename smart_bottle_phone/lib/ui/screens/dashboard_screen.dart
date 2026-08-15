import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_connection_status.dart';
import '../../state/smart_bottle_controller.dart';
import '../widgets/digital_water_gauge.dart';
import '../widgets/metric_card.dart';
import '../widgets/status_chip.dart';
import 'bluetooth_connection_screen.dart';
import 'goal_settings_screen.dart';
import 'reminder_settings_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(smartBottleControllerProvider);

    final reading = state.latestSyncedReading;
    final levelLiters = state.currentLiters;

    final conn = switch (state.connectionStatus) {
      AppConnectionStatus.connected => ('Connected', const Color(0xFF188B4C)),
      AppConnectionStatus.connecting => ('Connecting', const Color(0xFFEA9B06)),
      AppConnectionStatus.reconnecting => (
        'Reconnecting',
        const Color(0xFFEA9B06),
      ),
      AppConnectionStatus.error => ('Error', const Color(0xFFB42318)),
      AppConnectionStatus.disconnected => (
        'Disconnected',
        const Color(0xFF667085),
      ),
    };

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF007DB8), Color(0xFF56C7EE), Color(0xFFD8F5FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref
              .read(smartBottleControllerProvider.notifier)
              .refreshPairedDevices(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Smart Bottle Dashboard',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    StatusChip(label: 'Bluetooth: ${conn.$1}', color: conn.$2),
                    const SizedBox(width: 8),
                    StatusChip(
                      label: state.reminderEnabled
                          ? 'Reminder ON'
                          : 'Reminder OFF',
                      color: state.reminderEnabled
                          ? const Color(0xFF155EEF)
                          : const Color(0xFF667085),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next sync in ${state.secondsToNextSync}s',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          minHeight: 12,
                          value: state.syncProgress,
                          backgroundColor: const Color(0xFFE6ECF5),
                          color: const Color(0xFF1E84CE),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Synced Water Level',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          DigitalWaterGauge(
                            levelPercent: reading?.levelPercent ?? 0,
                            liters: levelLiters,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: levelLiters),
                              duration: const Duration(milliseconds: 500),
                              builder: (context, value, child) {
                                return Text(
                                  '${value.toStringAsFixed(2)} L out of 2.00 L',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: const Color(0xFF0A8BC7),
                                        fontWeight: FontWeight.w800,
                                      ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              MetricCard(
                title: 'Temperature',
                value: reading == null
                    ? '--.- C'
                    : '${reading.temperatureC.toStringAsFixed(1)} C',
                subtitle: 'Synced every 30 seconds',
                icon: Icons.thermostat_rounded,
                color: const Color(0xFFD04D4D),
              ),
              const SizedBox(height: 12),
              MetricCard(
                title: 'TDS',
                value: reading == null ? '--- ppm' : '${reading.tdsPpm} ppm',
                subtitle: 'Synced every 30 seconds',
                icon: Icons.science_rounded,
                color: const Color(0xFF185ABD),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hydration Goal',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Today: ${state.todayDrankLiters.toStringAsFixed(2)} L / ${state.goalLiters.toStringAsFixed(2)} L',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          minHeight: 12,
                          value: state.goalProgress,
                          backgroundColor: const Color(0xFFE6ECF5),
                          color: const Color(0xFF2EBD85),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(state.reminderStateText),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = (constraints.maxWidth - 8) / 2;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: width,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const BluetoothConnectionScreen(),
                              ),
                            );
                          },
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Bluetooth'),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ReminderSettingsScreen(),
                              ),
                            );
                          },
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Reminder'),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const GoalSettingsScreen(),
                              ),
                            );
                          },
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Goal'),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (state.error != null) ...[
                const SizedBox(height: 12),
                Card(
                  color: const Color(0xFFFFECEC),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: Color(0xFFB42318)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
