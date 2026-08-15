import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/smart_bottle_controller.dart';

class GoalSettingsScreen extends ConsumerStatefulWidget {
  const GoalSettingsScreen({super.key});

  @override
  ConsumerState<GoalSettingsScreen> createState() => _GoalSettingsScreenState();
}

class _GoalSettingsScreenState extends ConsumerState<GoalSettingsScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final current = ref.read(smartBottleControllerProvider).goalLiters;
    _controller = TextEditingController(text: current.toStringAsFixed(2));
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(smartBottleControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Goal Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set your daily hydration goal (liters)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Goal (L)',
                      hintText: 'Example: 2.50',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () async {
                      final parsed = double.tryParse(_controller.text.trim());
                      if (parsed == null || parsed <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Enter a valid positive number.'),
                          ),
                        );
                        return;
                      }
                      await notifier.setGoalLiters(parsed);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Goal saved.')),
                      );
                    },
                    child: const Text('Save Goal'),
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
    _controller.dispose();
    super.dispose();
  }
}
