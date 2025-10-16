// файл: lib/features/Devices/View/devices_list_screen.dart v1.22

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:led_control_app/features/Devices/Logic/auto_connector.dart';
import '../Logic/light_controller.dart';

/// Экран BLE — устройства: только автоподключение и карточка с одним устройством.
class DevicesListScreen extends StatefulWidget {
  final BluetoothDevice? connectedDevice;
  final BluetoothCharacteristic? connectedCharacteristic;
  final void Function(BluetoothDevice device, BluetoothCharacteristic characteristic)? onConnected;
  final VoidCallback? onDisconnected;

  const DevicesListScreen({
    Key? key,
    this.connectedDevice,
    this.connectedCharacteristic,
    this.onConnected,
    this.onDisconnected,
  }) : super(key: key);

  @override
  _DevicesListScreenState createState() => _DevicesListScreenState();
}

class _DevicesListScreenState extends State<DevicesListScreen> {
  bool _useAutoConnect = false;

  // Нотификатор текущего состояния подключения для синхронизации с Modal
  late final ValueNotifier<bool> _connectedNotifier;

  @override
  void initState() {
    super.initState();
    _connectedNotifier = ValueNotifier(widget.connectedDevice != null);
    AutoConnector.loadAutoConnectEnabled().then((value) {
      setState(() => _useAutoConnect = value);
    });
  }

  @override
  void didUpdateWidget(covariant DevicesListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Обновляем нотификатор при изменении внешнего состояния подключения
    _connectedNotifier.value = widget.connectedDevice != null;
  }

  @override
  void dispose() {
    _connectedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        // Блок автоподключения
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Use Auto Connect',
                  style: TextStyle(fontSize: 16)),
              Switch(
                value: _useAutoConnect,
                onChanged: (value) async {
                  setState(() => _useAutoConnect = value);
                  await AutoConnector.saveAutoConnectEnabled(value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Секция с единственным устройством
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.lightbulb, color: Colors.blueAccent),
              title: Row(
                children: [
                  const Expanded(
                    child: Text(AutoConnector.targetName),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                    onPressed: () {}, // Пока ничего не делает
                    tooltip: 'Rename',
                  ),
                ],
              ),
              onTap: () => _showDeviceSheet(context),
            ),
          ),
        ),
      ],
    );
  }


  void _showDeviceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        bool processing = false;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final device = widget.connectedDevice;
            final isConnected = device != null;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isConnected ? 'Device connected' : 'Device not connected',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Имя устройства
                  Text('Name: ${AutoConnector.targetName}'),

                  // MAC, если подключено
                  if (isConnected)
                    Text('MAC: ${device!.id}'),

                  const SizedBox(height: 12),

                  // --- Новый блок: RSSI ---
                  if (isConnected)
                    FutureBuilder<int>(
                      future: device!.readRssi(), // запрашиваем RSSI
                      builder: (ctx2, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Text('📶 Загрузка сигнала...');
                        } else if (snap.hasError) {
                          return const Text('📶 Ошибка чтения уровня сигнала');
                        } else {
                          final rssi = snap.data!;
                          IconData icon;
                          String label;
                          if (rssi >= -60) {
                            icon = Icons.signal_cellular_4_bar;
                            label = 'Excellent signal ($rssi dBm)';
                          } else if (rssi >= -80) {
                            icon = Icons.signal_cellular_0_bar;
                            label = 'Good signal ($rssi dBm)';
                          } else {
                            icon = Icons.signal_cellular_null;
                            label = 'Weak signal ($rssi dBm)';
                          }
                          return Row(
                            children: [
                              Icon(icon, size: 20),
                              const SizedBox(width: 8),
                              Text(' $label'),
                            ],
                          );
                        }
                      },
                    ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: processing
                        ? null
                        : () async {
                      setModalState(() => processing = true);
                      if (!isConnected) {
                        final result = await AutoConnector.manualConnect();
                        if (result != null) {
                          widget.onConnected?.call(result.$1, result.$2);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Device connected')),
                          );
                        } else {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Not successful . . . Try again')),
                          );
                        }
                      } else {
                        await LightController.disconnectDevice(device!);
                        widget.onDisconnected?.call();
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Device disconnected')),
                        );
                      }
                      setModalState(() => processing = false);
                      Navigator.of(ctx).pop();
                    },
                    child: Text(isConnected ? 'Disconnect' : 'Connect'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

}