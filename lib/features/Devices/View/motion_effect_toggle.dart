import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class MotionEffectToggle extends StatefulWidget {
  final BluetoothCharacteristic? characteristic; // ⚡ Делаем characteristic nullable

  const MotionEffectToggle({super.key, required this.characteristic});

  @override
  State<MotionEffectToggle> createState() => _MotionEffectToggleState();
}

class _MotionEffectToggleState extends State<MotionEffectToggle> {
  bool isEnabled = false;

  void _toggleEffect(bool value) async {
    setState(() => isEnabled = value);

    // ⚡ Проверяем, есть ли характеристика
    if (widget.characteristic == null) {
      debugPrint('⚠️ Нет подключённого устройства, команда не отправлена.');
      return;
    }

    try {
      await widget.characteristic!.write([value ? 0xA1 : 0xA0]);
      debugPrint('📡 Отправлено BLE: ${value ? '0xA1' : '0xA0'}');
    } catch (e) {
      debugPrint('⚠️ Ошибка при отправке BLE команды: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text('Альтернативная подсветка по движению'),
      value: isEnabled,
      onChanged: _toggleEffect,
    );
  }
}
