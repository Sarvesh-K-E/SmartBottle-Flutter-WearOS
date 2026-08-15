import 'package:flutter/material.dart';

import 'bluetooth_connection_screen.dart';
import 'goal_settings_screen.dart';
import 'reminder_settings_screen.dart';
import 'watch_sync_screen.dart';

class SettingsHelpScreen extends StatelessWidget {
  const SettingsHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Help')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.bluetooth_rounded),
                  title: const Text('Bluetooth pairing / connection'),
                  subtitle: const Text('Connect to your HC-05 module'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BluetoothConnectionScreen(),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.flag_rounded),
                  title: const Text('Goal settings'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const GoalSettingsScreen(),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.alarm_rounded),
                  title: const Text('Reminder settings'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ReminderSettingsScreen(),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.watch_rounded),
                  title: const Text('Watch sync status'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WatchSyncScreen()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
