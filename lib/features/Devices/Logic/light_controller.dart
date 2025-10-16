// light_controller.dart v.1.3

import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LightController {
  static BluetoothCharacteristic? _characteristic;
  static int r = 0, g = 0, b = 0;
  static Timer? _debounceTimer;

  static bool _powerOn = true;
  static const _powerKey = 'led_power_state';

  /// Инициализация контроллера: загрузка состояния питания и сохранённого цвета
  static Future<void> init(BluetoothCharacteristic characteristic) async {
    _characteristic = characteristic;
    final prefs = await SharedPreferences.getInstance();
    _powerOn = prefs.getBool(_powerKey) ?? true;
    r = prefs.getInt('r') ?? 0;
    g = prefs.getInt('g') ?? 0;
    b = prefs.getInt('b') ?? 0;
  }

  static bool get powerOn => _powerOn;

  static Future<void> setPower(bool on) async {
    _powerOn = on;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_powerKey, _powerOn);
    _sendColor();
  }

  static void updateLocalColor(int red, int green, int blue) {
    r = red;
    g = green;
    b = blue;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), _sendColor);
  }

  static Future<void> setColor(int red, int green, int blue) async {
    r = red;
    g = green;
    b = blue;
    _sendColor();
    await _saveColor();
  }

  static Future<void> _saveColor() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('r', r);
    await prefs.setInt('g', g);
    await prefs.setInt('b', b);
  }

  static void _sendColor() {
    if (_characteristic == null) {
      print('ℹ️ Нет подключения — цвет сохранён локально');
      return;
    }
    final data = _powerOn ? [r, g, b] : [0, 0, 0];
    try {
      _characteristic!.write(data);
      print(' Colour send: R=${data[0]}, G=${data[1]}, B=${data[2]}');
    } catch (e) {
      print('⚠ error color sending: $e');
    }
  }

  /// Корректное отключение: обнуляем characteristic, чтобы _sendColor
  /// дальше работал в «офлайн»-режиме
  static Future<void> disconnectDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
      // даём BLE-стеку пару сотен мс на очистку
      await Future.delayed(const Duration(milliseconds: 300));
      _characteristic = null;
      print('📴 Устройство отключено (LightController._characteristic сброшена)');
    } catch (e) {
      print('⚠️ Ошибка при отключении: $e');
    }
  }

  static void sendRaw(List<int> bytes) {
    if (_characteristic != null) {
      try {
        _characteristic!.write(bytes);
        print('📤 sendRaw: $bytes');
      } catch (e) {
        print('⚠️ Ошибка при sendRaw: $e');
      }
    } else {
      print('ℹ️ BLE-характеристика не инициализирована');
    }
  }


  static List<int> get currentColor => [r, g, b];
}
