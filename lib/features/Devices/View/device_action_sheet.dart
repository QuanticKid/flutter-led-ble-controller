import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'device_info_dialog.dart';

void showDeviceActions(
    BuildContext context,
    ScanResult result,
    BuildContext rootContext, {
      required VoidCallback onLink,
      required VoidCallback onUnlink,
    }) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final rssi = result.rssi;

      String signalLabel;
      Icon signalIcon;

      if (rssi >= -60) {
        signalLabel = "Отличный сигнал";
        signalIcon = const Icon(Icons.signal_cellular_4_bar, color: Colors.green);
      } else if (rssi >= -80) {
        signalLabel = "Хороший сигнал";
        signalIcon = const Icon(Icons.signal_cellular_0_bar, color: Colors.orange);
      } else {
        signalLabel = "Слабый сигнал";
        signalIcon = const Icon(Icons.signal_cellular_null, color: Colors.red);
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              result.device.advName.isNotEmpty
                  ? result.device.advName
                  : result.device.remoteId.str,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text("MAC: "),
                Text(result.device.remoteId.str),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                signalIcon,
                const SizedBox(width: 8),
                Text("Сигнал: $signalLabel"),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    // используем тот же context, что передаётся в билдер модалки:
                    final ctx = sheetContext;
                    try {
                      await result.device.connect().timeout(const Duration(seconds: 6));
                      onLink();
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('✅ Устройство подключено')),
                      );
                    } catch (e) {
                      debugPrint('Ошибка при подключении: $e');
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('❌ Не получилось подключиться, попробуйте ещё раз')),
                      );
                    } finally {
                      Navigator.of(ctx).pop();
                    }
                  },
                  icon: const Icon(Icons.link),
                  label: const Text('Связать'),
                ),

                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    try {
                      await result.device.disconnect();
                      onUnlink();
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        const SnackBar(content: Text('✅ Устройство отключено')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        SnackBar(content: Text('❌ Ошибка отключения: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.link_off),
                  label: const Text('Отвязать'),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
