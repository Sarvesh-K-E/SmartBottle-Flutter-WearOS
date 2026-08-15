import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestBluetoothPermissions() async {
    if (!Platform.isAndroid) return true;

    final permissions = <Permission>[
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
    ];

    final results = await permissions.request();
    return results.values.every(
      (status) =>
          status == PermissionStatus.granted ||
          status == PermissionStatus.limited ||
          status == PermissionStatus.provisional,
    );
  }
}
