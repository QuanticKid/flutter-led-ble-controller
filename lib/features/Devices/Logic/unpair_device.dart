import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';

Future<void> unpairDevice(BuildContext context, BluetoothDevice device) async {
  try {
    final connectionState = await device.connectionState.first;
    if (connectionState == BluetoothConnectionState.connected) {
      await device.disconnect();
      debugPrint("✅ Устройство отключено");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Устройство отключено')),
      );
    } else {
      debugPrint("⚠️ Устройство уже не подключено");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Устройство уже отключено')),
      );
    }
  } catch (e) {
    debugPrint("❌ Ошибка при отключении: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ошибка при отключении: $e')),
    );
  }
}