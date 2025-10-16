// auto_connector.dart v1.3

import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AutoConnector {
  static const String targetName = "ESP32_RGB_Control";
  static const String _autoConnectKey = 'auto_connect_enabled';
  static bool _isConnecting = false;

  /// Сохраняет флаг авто-подключения
  static Future<void> saveAutoConnectEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoConnectKey, value);
  }

  /// Загружает флаг авто-подключения
  static Future<bool> loadAutoConnectEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoConnectKey) ?? false;
  }

  /// Автоматическое подключение:
  /// проверяет флаг, делает до 4 попыток.
  static Future<(BluetoothDevice, BluetoothCharacteristic)?> autoConnect() async {
    if (_isConnecting) {
      print('⚠️ Автоподключение уже выполняется.');
      return null;
    }

    final enabled = await loadAutoConnectEnabled();
    if (!enabled) {
      print('🚫 Автоподключение отключено через флаг');
      return null;
    }

    _isConnecting = true;
    try {
      for (int attempt = 1; attempt <= 4; attempt++) {
        print('🔁 Попытка автоподключения #$attempt');

        final result = await _tryConnectOnce();
        if (result != null) {
          return result;
        }

        print('⏳ Ожидание перед новой попыткой...');
        await Future.delayed(const Duration(seconds: 2));
      }

      print('❌ Автоподключение не удалось после 4 попыток');
      return null;
    } catch (e) {
      print('❌ Ошибка автоконнекта: $e');
      return null;
    } finally {
      _isConnecting = false;
    }
  }

  /// **Ручное** подключение: всегда сканирует и коннектится,
  /// игнорируя значение флага авто-подключения.
  static Future<(BluetoothDevice, BluetoothCharacteristic)?> manualConnect() async {
    if (_isConnecting) {
      print('⚠️ Подключение уже выполняется.');
      return null;
    }

    _isConnecting = true;
    try {
      return await _tryConnectOnce();
    } catch (e) {
      print(' error hand connect : $e');
      return null;
    } finally {
      _isConnecting = false;
    }
  }

  /// Внутренняя попытка скан + подключение один раз
  static Future<(BluetoothDevice, BluetoothCharacteristic)?> _tryConnectOnce() async {
    final completer = Completer<BluetoothDevice?>();
    StreamSubscription? subscription;

    try {
      // сначала проверяем уже подключённые
      final connectedDevices = await FlutterBluePlus.connectedDevices;
      for (final device in connectedDevices) {
        if (device.advName == targetName || device.platformName == targetName) {
            print('Connected by name yet: $targetName');
          return await _connectToDevice(device);
        }
      }

      // запускаем скан
      subscription = FlutterBluePlus.onScanResults.listen((results) {
        for (var result in results) {
          final name = result.device.advName;
          print('Finded!: $name [${result.device.remoteId.str}]');

          if (name == targetName) {
            completer.complete(result.device);
            break;
          }
        }
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));

      final device = await completer.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () => null,
      );

      await FlutterBluePlus.stopScan();
      await subscription.cancel();

      if (device == null) {
        print(' Device "$targetName" not finded');
        return null;
      }

      return await _connectToDevice(device);
    } catch (e) {
      print('error while connecting: $e');
      return null;
    } finally {
      await FlutterBluePlus.stopScan();
      await subscription?.cancel();
    }
  }

  /// Открывает подключение к заданному устройству и возвращает линию данных
  static Future<(BluetoothDevice, BluetoothCharacteristic)?> _connectToDevice(
      BluetoothDevice device) async {
    try {
      await device.disconnect(); // очистка старого состояния
      await device.connect().timeout(const Duration(seconds: 6));
      final services =
      await device.discoverServices().timeout(const Duration(seconds: 6));

      const serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
      const characteristicUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';

      final service = services.firstWhere(
            (s) => s.serviceUuid.str == serviceUuid,
        orElse: () => throw Exception('servic is not find'),
      );

      final characteristic = service.characteristics.firstWhere(
            (c) => c.characteristicUuid.str == characteristicUuid,
        orElse: () => throw Exception('Char is nof find'),
      );

      print(' Successful connect  "$targetName"');
      return (device, characteristic);
    } catch (e) {
      print(' error while connecting : $e');
      try {
        await device.disconnect();
      } catch (_) {}
      return null;
    }
  }
}
