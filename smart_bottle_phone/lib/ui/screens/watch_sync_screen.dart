import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../state/smart_bottle_controller.dart';

class WatchSyncScreen extends ConsumerStatefulWidget {
  const WatchSyncScreen({super.key});

  @override
  ConsumerState<WatchSyncScreen> createState() => _WatchSyncScreenState();
}

class _WatchSyncScreenState extends ConsumerState<WatchSyncScreen> {
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(smartBottleControllerProvider.notifier).refreshWatchStatus();
    });
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      ref.read(smartBottleControllerProvider.notifier).refreshWatchStatus();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smartBottleControllerProvider);
    final watch = state.watchSyncStatus;
    final isConnected = watch.reachable;

    return Scaffold(
      appBar: AppBar(title: const Text('Watch Sync Status')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Watch connection',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  isConnected
                      ? 'Currently connected'
                      : 'Currently not connected',
                  style: TextStyle(
                    color: isConnected
                        ? const Color(0xFF146C43)
                        : const Color(0xFF9B1C1C),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Last successful sync: ${watch.lastSync == null ? 'Never' : DateFormat('dd MMM yyyy, HH:mm:ss').format(watch.lastSync!)}',
                ),
                if (watch.lastError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Last error: ${watch.lastError}',
                    style: const TextStyle(color: Color(0xFFB42318)),
                  ),
                ],
                const SizedBox(height: 8),
                const Text(
                  'Status auto-updates every second.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF475467)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => ref
                        .read(smartBottleControllerProvider.notifier)
                        .refreshWatchStatus(),
                    child: const Text('Check Now'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
