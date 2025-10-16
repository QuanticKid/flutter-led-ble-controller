import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Логика включения/выключения ленты и отправки цвета
class PowerToggleController {
  final BluetoothCharacteristic characteristic;

  bool _isPowerOn = true;
  int _cachedR = 0;
  int _cachedG = 0;
  int _cachedB = 0;

  PowerToggleController({required this.characteristic});

  /// Инициализация: загрузка сохранённого состояния и кэша
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isPowerOn = prefs.getBool('power_on') ?? true;
    _cachedR = prefs.getInt('cached_r') ?? 0;
    _cachedG = prefs.getInt('cached_g') ?? 0;
    _cachedB = prefs.getInt('cached_b') ?? 0;

    // При инициализации сразу отправляем либо закэшированный цвет, либо 0,0,0
    if (_isPowerOn) {
      _sendColor(_cachedR, _cachedG, _cachedB);
    } else {
      _sendColor(0, 0, 0);
    }
  }

  /// Переключает питание ленты
  Future<void> togglePower(bool isOn) async {
    _isPowerOn = isOn;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('power_on', _isPowerOn);

    // При включении отправляем последний закэшированный цвет, при выключении - 0
    if (_isPowerOn) {
      _sendColor(_cachedR, _cachedG, _cachedB);
    } else {
      _sendColor(0, 0, 0);
    }
  }

  /// Обновляет цвет: всегда кэширует, и при включённом питании отправляет
  Future<void> updateColor(int r, int g, int b) async {
    _cachedR = r;
    _cachedG = g;
    _cachedB = b;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cached_r', r);
    await prefs.setInt('cached_g', g);
    await prefs.setInt('cached_b', b);

    if (_isPowerOn) {
      _sendColor(r, g, b);
    }
  }

  /// Фактическая отправка через BLE
  void _sendColor(int r, int g, int b) {
    try {
      characteristic.write([r, g, b]);
      debugPrint('📡 Отправка цвета: R=$r, G=$g, B=$b');
    } catch (e) {
      debugPrint('⚠️ Ошибка при отправке цвета: \$e');
    }
  }

  /// Текущее состояние питания
  bool get isPowerOn => _isPowerOn;
}
