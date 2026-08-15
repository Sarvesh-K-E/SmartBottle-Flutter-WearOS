import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/notification_service.dart';
import '../../state/smart_bottle_controller.dart';

class ReminderSettingsScreen extends ConsumerStatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  ConsumerState<ReminderSettingsScreen> createState() =>
      _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState
    extends ConsumerState<ReminderSettingsScreen> {
  late final TextEditingController _intervalController;
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(smartBottleControllerProvider);
    _enabled = state.reminderEnabled;
    _intervalController = TextEditingController(
      text: state.reminderIntervalMinutes.toStringAsFixed(0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(smartBottleControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Reminder Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _enabled,
                    onChanged: (value) => setState(() => _enabled = value),
                    title: const Text('Enable hydration reminders'),
                    subtitle: const Text(
                      'Reminder triggers if water level has not changed by >5% in your interval.',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _intervalController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Interval (minutes)',
                      hintText: 'Any positive value is allowed',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Note: Android background scheduling can be delayed by battery optimization/doze. The app uses periodic background work for best practical reliability.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () async {
                      final parsed = double.tryParse(
                        _intervalController.text.trim(),
                      );
                      if (parsed == null || parsed <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Enter a valid positive interval.'),
                          ),
                        );
                        return;
                      }

                      await NotificationService.instance
                          .requestAndroidNotificationPermission();
                      await notifier.setReminderSettings(
                        enabled: _enabled,
                        intervalMinutes: parsed,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reminder settings saved.'),
                        ),
                      );
                    },
                    child: const Text('Save Reminder Settings'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _intervalController.dispose();
    super.dispose();
  }
}
