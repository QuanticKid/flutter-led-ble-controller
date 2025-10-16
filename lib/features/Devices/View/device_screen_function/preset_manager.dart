// preset_manager.dart v.1.3

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PresetManager {
  static const int presetCount = 5;
  static const String _keyPrefix = 'preset_color_';
  static const String _brightnessPrefix = 'preset_brightness_';
  static const String _activeIndexKey = 'active_preset_index';

  List<Color> _presets = List.generate(
    presetCount,
        (index) => _defaultColors[index],
  );

  List<double> _brightnessValues = List.generate(
    presetCount,
        (_) => 1.0,
  );

  int _activePresetIndex = -1;

  List<Color> get presets => _presets;
  int get activeIndex => _activePresetIndex;

  void setActiveIndex(int index) async {
    if (index >= 0 && index < presetCount) {
      _activePresetIndex = index;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_activeIndexKey, index);
    }
  }

  bool isActive(int index) => _activePresetIndex == index;

  static const List<Color> _defaultColors = [
    Colors.red, Colors.green, Colors.blue, Colors.yellow, Colors.purple,
  ];

  Color? getActivePreset() {
    if (_activePresetIndex < 0 || _activePresetIndex >= presetCount) return null;
    return _presets[_activePresetIndex];
  }

  double getActiveBrightness() {
    if (_activePresetIndex < 0 || _activePresetIndex >= presetCount) return 1.0;
    return _brightnessValues[_activePresetIndex];
  }

  Future<void> loadPresets() async {
    final prefs = await SharedPreferences.getInstance();

    _activePresetIndex = prefs.getInt(_activeIndexKey) ?? -1;

    for (int i = 0; i < presetCount; i++) {
      final r = prefs.getInt('${_keyPrefix}r_$i');
      final g = prefs.getInt('${_keyPrefix}g_$i');
      final b = prefs.getInt('${_keyPrefix}b_$i');
      final brightness = prefs.getDouble('${_brightnessPrefix}$i');

      if (r != null && g != null && b != null) {
        _presets[i] = Color.fromARGB(255, r, g, b);
      }

      if (brightness != null) {
        _brightnessValues[i] = brightness.clamp(0.0, 1.0);
      }
    }
  }

  Future<void> savePreset(int index, Color color, [double? brightness]) async {
    if (index < 0 || index >= presetCount) return;

    _presets[index] = color;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_keyPrefix}r_$index', color.red);
    await prefs.setInt('${_keyPrefix}g_$index', color.green);
    await prefs.setInt('${_keyPrefix}b_$index', color.blue);

    if (brightness != null) {
      _brightnessValues[index] = brightness;
      await prefs.setDouble('${_brightnessPrefix}$index', brightness);
    }
  }

  Color getPreset(int index) {
    if (index < 0 || index >= presetCount) return Colors.black;
    return _presets[index];
  }

  double getPresetBrightness(int index) {
    if (index < 0 || index >= presetCount) return 1.0;
    return _brightnessValues[index];
  }
}
