import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class UnlinkButton extends StatelessWidget {
  final BluetoothDevice device;

  const UnlinkButton({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        Navigator.of(context).pop(); // закрыть модальное окно

        await Future.delayed(const Duration(milliseconds: 100)); // чуть позже покажем снекбар

        try {
          await device.disconnect();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Устройство отключено')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Ошибка при отключении: $e')),
          );
        }
      },
      icon: const Icon(Icons.link_off),
      label: const Text("Отвязать"),
    );
  }
}