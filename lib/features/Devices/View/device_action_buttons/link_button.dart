// lib/features/Devices/View/device_action_buttons/link_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:led_control_app/features/Devices/View/device_screen.dart';

class LinkButton extends StatelessWidget {
  final ScanResult result;
  final BuildContext rootContext;
  final VoidCallback? onConnected;

  const LinkButton({
    super.key,
    required this.result,
    required this.rootContext,
    this.onConnected,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        Navigator.pop(context); // Закрываем шторку

        try {
          await Future.delayed(const Duration(milliseconds: 400));

          try {
            await result.device.connect();
          } catch (e) {
            if (e.toString().contains('android-code: 133')) {
              debugPrint("⚠️ Повторное подключение после ошибки 133...");
              await result.device.disconnect();
              await Future.delayed(const Duration(seconds: 1));
              await result.device.connect();
            } else {
              rethrow;
            }
          }

          final services = await result.device.discoverServices();

          final service = services.firstWhere(
                (s) => s.serviceUuid.str == '4fafc201-1fb5-459e-8fcc-c5c9c331914b',
          );

          final characteristic = service.characteristics.firstWhere(
                (c) => c.characteristicUuid.str == 'beb5483e-36e1-4688-b7f5-ea07361b26a8',
          );

          Navigator.of(rootContext).push(
            MaterialPageRoute(
              builder: (_) => DeviceScreen(
                device: result.device,
                characteristic: characteristic,
              ),
            ),
          );

          Future.delayed(const Duration(milliseconds: 300), () {
            if (rootContext.mounted) {
              ScaffoldMessenger.of(rootContext).showSnackBar(
                const SnackBar(content: Text('✅ Устройство подключено')),
              );
            }
          });

          onConnected?.call();
        } catch (e) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (rootContext.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('❌ Ошибка подключения: $e')),
              );
            }
          });
        }
      },
      icon: const Icon(Icons.link),
      label: const Text('Связать'),
    );
  }
}
