import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class InfoButton extends StatelessWidget {
  final ScanResult result;

  const InfoButton({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 26,
      backgroundColor: Colors.blueAccent,
      child: IconButton(
        icon: const Icon(Icons.info_outline, color: Colors.white),
        onPressed: () {
          final name = result.device.advName.isNotEmpty
              ? result.device.advName
              : "Без имени";
          final mac = result.device.remoteId.str;
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

          showDialog(
            context: context,
            builder: (dialogCtx) {
              return AlertDialog(
                title: const Text("Информация об устройстве"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("📛 Имя: $name"),
                    const SizedBox(height: 6),
                    Text("🔌 MAC: $mac"),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        signalIcon,
                        const SizedBox(width: 8),
                        Text("📶 Сигнал: $signalLabel"),
                      ],
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    child: const Text("Закрыть"),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
