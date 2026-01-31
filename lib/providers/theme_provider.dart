import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences has not been provided.');
});

final themeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

final accentColorProvider = NotifierProvider<AccentColorNotifier, Color>(
  AccentColorNotifier.new,
);

final folderStyleProvider = NotifierProvider<FolderStyleNotifier, FolderStyle>(
  FolderStyleNotifier.new,
);

enum FolderStyle { classic, solid, neon, outline }

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _prefKey = 'settings.themeMode';

  @override
  ThemeMode build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final stored = prefs.getString(_prefKey);
    switch (stored) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> update(ThemeMode mode) async {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_prefKey, value);
  }
}

class AccentColorNotifier extends Notifier<Color> {
  static const _prefKey = 'settings.accentColor';

  @override
  Color build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final storedValue = prefs.getInt(_prefKey);
    if (storedValue != null) {
      return Color(storedValue);
    }
    return const Color(0xFF1E88E5);
  }

  Future<void> update(Color color) async {
    state = color;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_prefKey, color.value);
  }
}

class FolderStyleNotifier extends Notifier<FolderStyle> {
  static const _prefKey = 'settings.folderStyle';

  @override
  FolderStyle build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final stored = prefs.getString(_prefKey);
    return FolderStyle.values.firstWhere(
      (e) => e.name == stored,
      orElse: () => FolderStyle.classic,
    );
  }

  Future<void> update(FolderStyle style) async {
    state = style;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_prefKey, style.name);
  }
}
