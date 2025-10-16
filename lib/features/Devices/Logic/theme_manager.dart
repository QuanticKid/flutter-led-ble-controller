// lib/features/Devices/Logic/theme_manager.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager extends ChangeNotifier {
  static final _instance = ThemeManager._();
  factory ThemeManager() => _instance;
  ThemeManager._();

  static const _key = 'darkMode';
  bool _isDark = false;
  bool get isDark => _isDark;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _isDark = p.getBool(_key) ?? false;
    notifyListeners();
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, _isDark);
    notifyListeners();
  }

  ThemeData get light => ThemeData.light().copyWith(
    sliderTheme: const SliderThemeData(
      activeTrackColor: Colors.green,
      thumbColor: Colors.green,
      inactiveTrackColor: Colors.grey,
    ),
  );
  ThemeData get dark => ThemeData.dark().copyWith(
    sliderTheme: const SliderThemeData(
      activeTrackColor: Colors.green,
      thumbColor: Colors.green,
      inactiveTrackColor: Colors.grey,
    ),
  );
}
