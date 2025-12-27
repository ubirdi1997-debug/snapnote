import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  static const String _themeBoxName = 'settings';
  static const String _themeKey = 'theme_mode';
  Box? _settingsBox;

  ThemeMode get themeMode => _themeMode;

  Future<void> init() async {
    _settingsBox = await Hive.openBox(_themeBoxName);
    _loadTheme();
  }

  void _loadTheme() {
    if (_settingsBox != null) {
      final themeIndex = _settingsBox!.get(_themeKey, defaultValue: 0) as int;
      _themeMode = ThemeMode.values[themeIndex];
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _settingsBox?.put(_themeKey, mode.index);
  }
}

