import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleDeviceManager {
  BluetoothCharacteristic? _characteristic;

  double redValue = 0;
  double greenValue = 0;
  double blueValue = 0;

  /// Подключается к устройству с повторной попыткой и читает начальное значение RGB.
  Future<BluetoothCharacteristic?> connectAndRead(BluetoothDevice device) async {
    // Очистка предыдущего соединения, если оно осталось открытым
    try {
      await device.disconnect();
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      print('⚠️ Ошибка при попытке предварительного disconnect: $e');
    }

    // Первая попытка подключения
    bool connected = await _tryConnect(device);
    // Если неудачно, подождать и попробовать ещё раз
    if (!connected) {
      await Future.delayed(const Duration(microseconds: 1500));
      connected = await _tryConnect(device);
      if (!connected) {
        print('❌ Не удалось подключиться после повторной попытки');
        return null;
      }
    }

    // Обнаружение сервисов на устройстве
    List<BluetoothService> services;
    try {
      services = await device.discoverServices();
      print('📱 Найдено сервисов: ${services.length}');
    } catch (e) {
      print('❌ Ошибка при обнаружении сервисов: $e');
      return null;
    }

    const serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
    const characteristicUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';

    try {
      // Поиск нужного сервиса
      final service = services.firstWhere(
            (s) => s.serviceUuid.str == serviceUuid,
      );
      // Поиск нужной характеристики внутри сервиса
      final characteristic = service.characteristics.firstWhere(
            (c) => c.characteristicUuid.str == characteristicUuid,
      );

      _characteristic = characteristic;

      // Чтение текущего значения
      final value = await characteristic.read();
      print('🎨 Прочитанное значение: $value');

      if (value.length != 3) {
        print('❌ Некорректное количество байт (ожидалось 3)');
        return null;
      }

      // Распаковка RGB (порядок байт: [G, R, B])
      redValue = value[1].toDouble();
      greenValue = value[0].toDouble();
      blueValue = value[2].toDouble();

      return characteristic;
    } catch (e) {
      print('❌ Ошибка при получении характеристики: $e');
      return null;
    }
  }

  /// Пытается подключиться к BLE-устройству и возвращает результат.
  Future<bool> _tryConnect(BluetoothDevice device) async {
    try {
      await device.connect();
      print('✅ Подключение успешно');
      return true;
    } catch (e) {
      print('⚠️ Ошибка при подключении: $e');
      return false;
    }
  }

  /// Отключает устройство.
  Future<void> disconnect(BluetoothDevice device) async {
    try {
      await device.disconnect();
      print('📴 Отключение выполнено');
    } catch (e) {
      print('⚠️ Ошибка при отключении: $e');
    }
  }

  /// Возвращает последний полученный characteristic для записи.
  BluetoothCharacteristic? get characteristic => _characteristic;
}
