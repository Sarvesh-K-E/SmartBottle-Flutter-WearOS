import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_classic_serial/flutter_bluetooth_classic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_connection_status.dart';
import '../../state/smart_bottle_controller.dart';
import 'main_shell_screen.dart';

class BluetoothConnectionScreen extends ConsumerStatefulWidget {
  const BluetoothConnectionScreen({super.key, this.firstSetup = false});

  final bool firstSetup;

  @override
  ConsumerState<BluetoothConnectionScreen> createState() =>
      _BluetoothConnectionScreenState();
}

class _BluetoothConnectionScreenState
    extends ConsumerState<BluetoothConnectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref
          .read(smartBottleControllerProvider.notifier)
          .requestPermissionsAndRefreshBluetooth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smartBottleControllerProvider);
    final notifier = ref.read(smartBottleControllerProvider.notifier);
    final devicesByAddress = <String, BluetoothDevice>{};
    for (final device in state.pairedDevices) {
      final cleanedAddress = device.address.trim();
      if (cleanedAddress.isEmpty) {
        continue;
      }
      final cleanedName = device.name.trim();
      if (cleanedName.isEmpty && cleanedAddress == '--') {
        continue;
      }
      devicesByAddress[cleanedAddress] = BluetoothDevice(
        name: cleanedName.isEmpty ? 'Unknown Device' : cleanedName,
        address: cleanedAddress,
        paired: device.paired,
      );
    }
    final devices = devicesByAddress.values.toList()
      ..sort((a, b) {
        final aConnected = state.connectedAddress == a.address;
        final bConnected = state.connectedAddress == b.address;
        if (aConnected != bConnected) {
          return aConnected ? -1 : 1;
        }

        final aIsHc05 = a.name.toUpperCase().contains('HC-05');
        final bIsHc05 = b.name.toUpperCase().contains('HC-05');
        if (aIsHc05 != bIsHc05) {
          return aIsHc05 ? -1 : 1;
        }
        return a.name.compareTo(b.name);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('HC-05 Connection')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () =>
                      notifier.requestPermissionsAndRefreshBluetooth(),
                  child: const Text('Enable / Refresh'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => notifier.refreshPairedDevices(),
                  child: const Text('Reload Devices'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.bluetooth_searching_rounded),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Status: ${state.connectionStatus.name.toUpperCase()}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (state.connectionStatus == AppConnectionStatus.connected)
                    FilledButton(
                      onPressed: notifier.disconnect,
                      child: const Text('Disconnect'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (!state.btEnabled)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF0A8BC7), width: 1.2),
              ),
              child: const Text(
                'Turn on Bluetooth',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          if (state.btEnabled && devices.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No paired devices found. Pair HC-05 first in Android Bluetooth settings, then tap Reload Devices.',
                ),
              ),
            ),
          if (state.btEnabled)
            ...devices.map((device) {
              final isConnected =
                  state.connectionStatus == AppConnectionStatus.connected &&
                  state.connectedAddress == device.address;
              final isConnecting =
                  (state.connectionStatus == AppConnectionStatus.connecting ||
                      state.connectionStatus ==
                          AppConnectionStatus.reconnecting) &&
                  state.pendingConnectAddress == device.address;
              final isHC05 = device.name.toUpperCase().contains('HC-05');

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isHC05
                                  ? Icons.water_drop_rounded
                                  : Icons.devices_rounded,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                device.name.isNotEmpty
                                    ? device.name
                                    : 'Unknown Device',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (isHC05)
                              const Text(
                                'HC-05',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0A8BC7),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(device.address),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: isConnecting
                                ? null
                                : () =>
                                      notifier.connectToDevice(device.address),
                            child: Text(
                              isConnected
                                  ? 'Connected'
                                  : (isConnecting
                                        ? 'Connecting...'
                                        : 'Connect'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          if (widget.firstSetup) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.dashboard_rounded),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainShellScreen()),
                  (route) => false,
                );
              },
              label: const Text('Go To Dashboard'),
            ),
          ],
        ],
      ),
    );
  }
}
