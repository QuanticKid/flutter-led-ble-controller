import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleScanner {
  final StreamController<List<ScanResult>> _scanResultsController =
  StreamController.broadcast();

  Stream<List<ScanResult>> get scanResultsStream => _scanResultsController.stream;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  bool _isScanning = false;

  Future<void> startScan({bool withTimeout = true}) async {
    if (_isScanning) {
      print("🔁 Сканирование уже запущено, повторный вызов отклонён");
      return;
    }

    final isSupported = await FlutterBluePlus.isSupported;
    if (!isSupported) {
      print("❌ Flutter BLE не поддерживается");
      return;
    }

    final state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      print("❌ Bluetooth выключен");
      return;
    }

    _isScanning = true;

    _scanSubscription = FlutterBluePlus.onScanResults.listen(
          (results) {
        print("📡 Сканирование: получено ${results.length} результатов");
        _scanResultsController.add(results);
      },
      onError: (e) async {
        print("⚠️ Ошибка сканирования: $e");
        _isScanning = false;
        await FlutterBluePlus.stopScan();
      },
      cancelOnError: true,
    );

    try {
      if (withTimeout) {
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      } else {
        await FlutterBluePlus.startScan();
      }
    } catch (e) {
      print("❌ Ошибка запуска сканирования: $e");
      _isScanning = false;
    }
  }

  Future<void> stopScan() async {
    if (!_isScanning) return;
    _isScanning = false;

    try {
      await FlutterBluePlus.stopScan();
      print("🛑 Сканирование остановлено");
    } catch (e) {
      print("⚠️ Ошибка при остановке сканирования: $e");
    }

    if (_scanSubscription != null) {
      await _scanSubscription!.cancel();
      _scanSubscription = null;
    }
  }

  void dispose() {
    _scanSubscription?.cancel();
    _scanResultsController.close();
  }
}
