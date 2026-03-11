import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:el_warsha/core/constants/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'isDarkMode';
  ThemeMode _themeMode = ThemeMode.dark; // Default to dark

  ThemeProvider() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  // Theme getter for convenience
  ThemeData get currentTheme => isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
  
  // Expose colors based on current mode
  Color get bg => isDarkMode ? AppTheme.darkBg : AppTheme.lightBg;
  Color get card => isDarkMode ? AppTheme.darkCard : AppTheme.lightCard;
  Color get primaryText => isDarkMode ? AppTheme.darkPrimaryText : AppTheme.lightPrimaryText;
  Color get textSecondary => isDarkMode ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
  Color get accentColor => AppTheme.accentOrange; // renamed and mapped for global use

  void toggleTheme() async {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDarkMode);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey) ?? true; // Default true (Dark)
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
