// файл main_view.dart v1.14
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:led_control_app/features/Devices/Logic/auto_connector.dart';
// import 'package:led_control_app/features/Devices/Logic/theme_manager.dart';
import 'package:led_control_app/features/Devices/View/device_screen.dart';
import 'package:led_control_app/features/Devices/View/devices_list_screen.dart';
import 'package:led_control_app/features/Devices/View/device_screen_function/bottom_bar.dart';
import 'package:led_control_app/features/Devices/View/device_action_buttons/appbar_screens/modes_screen.dart';
import 'package:led_control_app/features/Devices/View/device_action_buttons/appbar_screens/sensor_setting_screen.dart';
import 'package:led_control_app/features/Devices/View/device_action_buttons/appbar_screens/timer_screen.dart';



class MainView extends StatefulWidget {
  const MainView({Key? key}) : super(key: key);

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _characteristic;
  int _selectedIndex = 0;

  // закомментировали менеджер темы
  // final _themeManager = ThemeManager();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _attemptAutoConnect();
    // закомментировали загрузку темы
    // await _themeManager.load();
  }

  Future<void> _attemptAutoConnect() async {
    final enabled = await AutoConnector.loadAutoConnectEnabled();
    if (!enabled) return;
    final result = await AutoConnector.autoConnect();
    if (result != null) {
      final (device, characteristic) = result;
      if (_connectedDevice?.remoteId == device.remoteId) return;
      setState(() {
        _connectedDevice = device;
        _characteristic = characteristic;
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      // 0. Управление цветом
      DeviceScreen(
        device: _connectedDevice,
        characteristic: _characteristic,
        showAppBar: false,
      ),
      // 1. Режимы
      const ModesScreen(),
      // 2. Настройки датчиков
      const SensorSettingScreen(),
      // 3. Таймер
      TimerScreen(characteristic: _characteristic),
      // 4. BLE — список устройств
      DevicesListScreen(
        connectedDevice: _connectedDevice,
        connectedCharacteristic: _characteristic,
        onConnected: (device, characteristic) {
          if (_connectedDevice?.id == device.id) return;
          setState(() {
            _connectedDevice = device;
            _characteristic = characteristic;
          });
        },
        onDisconnected: () {
          setState(() {
            _connectedDevice = null;
            _characteristic = null;
          });
        },
      ),
    ];

    // Показываем AppBar только на экранaх 0 (цвет) и 4 (BLE)
    final showAppBar = _selectedIndex == 0 || _selectedIndex == 4;

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
        title: () {
          if (_selectedIndex == 0) return const Text('Color control');
          if (_selectedIndex == 4) return const Text('BLE — Devices');
          return const Text(
            'Device Page',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 20),
          );
        }(),
        centerTitle: true,
        leading: _selectedIndex == 1
            ? IconButton(
          icon: const Icon(Icons.lightbulb_outline),
          tooltip: 'Цвет',
          onPressed: () => _onTabTapped(0),
        )
            : null,
        actions: [
          // кнопка перехода на DevicesListScreen при index == 0 уже убрана,
          // так как навигация на BLE теперь происходит через BottomBar

          // полностью закомментировали кнопку смены темы
          /*
                IconButton(
                  icon: Icon(
                    _themeManager.isDark ? Icons.light_mode : Icons.dark_mode,
                  ),
                  tooltip: 'Тема',
                  onPressed: () async {
                    await _themeManager.toggle();
                    setState(() {});
                  },
                ),
                */
        ],
      )
          : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomBar(
        selectedIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
