import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // This will be handled by the MaterialApp
      return false; // Default to light if system
    }
    return _themeMode == ThemeMode.dark;
  }

  bool get isInitialized => _isInitialized;

  // Initialize SharedPreferences and load saved theme
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    final savedTheme = _prefs.getString('themeMode') ?? 'system';
    _themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.toString() == 'ThemeMode.$savedTheme',
      orElse: () => ThemeMode.system,
    );
    _isInitialized = true;
    notifyListeners();
  }

  // Set theme mode and persist
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _prefs.setString('themeMode', mode.toString().split('.').last);
    notifyListeners();
  }

  // Toggle between light and dark (when not in system mode)
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }
}
