// lib/features/Devices/View/device_screen.dart
// версия v.1.55

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:led_control_app/features/Devices/Logic/light_controller.dart';
import 'package:led_control_app/features/Devices/View/device_screen_function/interactive_color_wheel.dart';
import 'package:led_control_app/features/Devices/View/device_screen_function/color_spectrum_picker.dart';
import 'package:led_control_app/features/Devices/View/device_screen_function/preset_color_box.dart';
import 'package:led_control_app/features/Devices/View/device_screen_function/preset_manager.dart';
import 'package:led_control_app/features/Devices/View/device_screen_function/sensors_color_box.dart';
import 'package:led_control_app/features/Devices/View/device_screen_function/rgb_value_table.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice? device;
  final BluetoothCharacteristic? characteristic;
  final bool showAppBar;

  const DeviceScreen({
    Key? key,
    this.device,
    this.characteristic,
    this.showAppBar = true,
  }) : super(key: key);

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen>
    with AutomaticKeepAliveClientMixin {

  final PresetManager _presetManager = PresetManager();
  final _wheelKey = GlobalKey<InteractiveColorWheelState>();

  double red = 0, green = 0, blue = 0;
  double _brightness = 1.0;
  bool _motionSensorEnabled = false;
  bool _lightSensorEnabled = false;
  Color? _pendingColor;
  bool _useSpectrumWithWhite = false;

  @override
  bool get wantKeepAlive => true;

  Future<void> _savePickerMode(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useSpectrumWithWhite', v);
  }

  Future<void> _loadPickerMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _useSpectrumWithWhite = prefs.getBool('useSpectrumWithWhite') ?? false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPickerMode();

    if (widget.characteristic != null) {
      LightController.init(widget.characteristic!).then((_) async {
        final col = LightController.currentColor;
        setState(() {
          red   = col[0].toDouble();
          green = col[1].toDouble();
          blue  = col[2].toDouble();
        });

        await _presetManager.loadPresets();
        final prefs = await SharedPreferences.getInstance();
        if (_presetManager.activeIndex != -1) {
          _applyPreset(_presetManager.activeIndex);
        } else {
          setState(() {
            red         = prefs.getInt('custom_r')?.toDouble()   ?? red;
            green       = prefs.getInt('custom_g')?.toDouble()   ?? green;
            blue        = prefs.getInt('custom_b')?.toDouble()   ?? blue;
            _brightness = prefs.getDouble('custom_brightness')   ?? _brightness;
          });
          LightController.updateLocalColor(red.toInt(), green.toInt(), blue.toInt());
        }
      });
    } else {
      _presetManager.loadPresets().then((_) async {
        final prefs = await SharedPreferences.getInstance();
        if (_presetManager.activeIndex != -1) {
          _applyPreset(_presetManager.activeIndex);
        } else {
          setState(() {
            red         = prefs.getInt('custom_r')?.toDouble()   ?? red;
            green       = prefs.getInt('custom_g')?.toDouble()   ?? green;
            blue        = prefs.getInt('custom_b')?.toDouble()   ?? blue;
            _brightness = prefs.getDouble('custom_brightness')   ?? _brightness;
          });
          LightController.updateLocalColor(red.toInt(), green.toInt(), blue.toInt());
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant DeviceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.characteristic == null && widget.characteristic != null) {
      LightController.init(widget.characteristic!).then((_) {
        if (_pendingColor != null) {
          LightController.updateLocalColor(
            _pendingColor!.red,
            _pendingColor!.green,
            _pendingColor!.blue,
          );
          _pendingColor = null;
        }
      });
    }
  }

  void _applyPreset(int index) {
    final color = _presetManager.getPreset(index);
    final brightness = _presetManager.getPresetBrightness(index);
    setState(() {
      red = color.red.toDouble();
      green = color.green.toDouble();
      blue = color.blue.toDouble();
      _brightness = brightness;
      _presetManager.setActiveIndex(index);
    });
    _wheelKey.currentState?.setColorFromOutside(color);
    LightController.updateLocalColor(red.toInt(), green.toInt(), blue.toInt());
  }

  void updateColor({double? r, double? g, double? b}) async {
    setState(() {
      if (r != null) red = r;
      if (g != null) green = g;
      if (b != null) blue = b;
    });
    final newColor = Color.fromARGB(255, red.toInt(), green.toInt(), blue.toInt());
    if (widget.characteristic != null) {
      LightController.updateLocalColor(red.toInt(), green.toInt(), blue.toInt());
    } else {
      _pendingColor = newColor;
    }

    final active = _presetManager.activeIndex;
    if (active != -1) {
      _presetManager.savePreset(active, newColor, _brightness);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('custom_r', red.toInt());
      await prefs.setInt('custom_g', green.toInt());
      await prefs.setInt('custom_b', blue.toInt());
      await prefs.setDouble('custom_brightness', _brightness);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final content = Column(
      children: [
        Expanded(
          flex: 3,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: _useSpectrumWithWhite
                    ? SizedBox(
                  width: 260,
                  height: 260,
                  child: ColorSpectrumPicker(
                    color: Color.fromARGB(255, red.toInt(), green.toInt(), blue.toInt()),
                    brightness: _brightness,
                    onColorChanged: (c) => updateColor(
                      r: c.red.toDouble(),
                      g: c.green.toDouble(),
                      b: c.blue.toDouble(),
                    ),
                  ),
                )
                    : InteractiveColorWheel(
                  key: _wheelKey,
                  brightness: _brightness,
                  onColorChanged: (c) => updateColor(
                    r: c.red.toDouble(),
                    g: c.green.toDouble(),
                    b: c.blue.toDouble(),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  iconSize: 28,
                  icon: _useSpectrumWithWhite
                      ? const Icon(Icons.circle_outlined)
                      : const Icon(Icons.gradient),
                  onPressed: () {
                    setState(() => _useSpectrumWithWhite = !_useSpectrumWithWhite);
                    _savePickerMode(_useSpectrumWithWhite);
                  },
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Switch(
                  value: LightController.powerOn,
                  onChanged: (v) async {
                    await LightController.setPower(v);
                    setState(() {});
                  },
                ),
              ),
              Positioned(
                left: 16,
                bottom: 76,
                child: RgbValueTable(
                  r: red.toInt(),
                  g: green.toInt(),
                  b: blue.toInt(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.wb_sunny_outlined, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: _brightness,
                            min: 0,
                            max: 1,
                            onChanged: (v) {
                              setState(() => _brightness = v);
                              final oldColor = Color.fromARGB(
                                255,
                                red.toInt(),
                                green.toInt(),
                                blue.toInt(),
                              );
                              final hsv = HSVColor.fromColor(oldColor);
                              final newColor = HSVColor.fromAHSV(
                                1,
                                hsv.hue,
                                hsv.saturation,
                                v,
                              ).toColor();
                              updateColor(
                                r: newColor.red.toDouble(),
                                g: newColor.green.toDouble(),
                                b: newColor.blue.toDouble(),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    PresetManager.presetCount,
                        (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: PresetColorBox(
                        color: _presetManager.getPreset(i),
                        isActive: _presetManager.activeIndex == i,
                        onTap: () => _applyPreset(i),
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Activity Sensor',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                          PresetColorBox(
                            color: Colors.cyan,
                            isActive: false,
                            onTap: () {},
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Switch(
                            value: _motionSensorEnabled,
                            onChanged: (v) => setState(() => _motionSensorEnabled = v),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Light Sensor',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                          PresetColorBox(
                            color: Colors.orange,
                            isActive: false,
                            onTap: () {},
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Switch(
                            value: _lightSensorEnabled,
                            onChanged: (v) => setState(() => _lightSensorEnabled = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(title: const Text('Color control')),
        body: content,
      );
    } else {
      return content;
    }
  }
}
