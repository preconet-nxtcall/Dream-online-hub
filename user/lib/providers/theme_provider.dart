import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  final ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme(bool isDark) {
    // Locked to Light Mode as per user requirement
    notifyListeners();
  }
}
