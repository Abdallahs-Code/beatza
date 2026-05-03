
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'user_theme_preference';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ThemeMode _themeMode = ThemeMode.dark; 

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  
  Future<void> init() async {
    try {
      final savedTheme = await _storage.read(key: _themeKey);
      if (savedTheme != null) {
        _themeMode = savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark;
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load theme preference: $e');
    }
    notifyListeners();
  }

  
  Future<void> setTheme(ThemeMode mode) async {
    try {
      final value = mode == ThemeMode.dark ? 'dark' : 'light';
      await _storage.write(key: _themeKey, value: value);
      _themeMode = mode;
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Failed to save theme preference: $e');
    }
  }

  
  Future<void> syncThemeFromApi(String? apiTheme) async {
    if (apiTheme == null || apiTheme.trim().isEmpty) return;

    final normalized = apiTheme.trim().toLowerCase();
    if (normalized == 'light') {
      await setTheme(ThemeMode.light);
    } else {
      
      await setTheme(ThemeMode.dark);
    }
  }

  
  Future<void> toggleTheme() async {
    await setTheme(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }
}
