import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/color_theme.dart';
import '../models/font_theme.dart';

class ThemeState {
  final bool isDarkMode;
  final String colorThemeId;
  final String fontThemeId;

  const ThemeState({
    this.isDarkMode = false,
    this.colorThemeId = 'forest',
    this.fontThemeId = 'default',
  });

  ThemeState copyWith({
    bool? isDarkMode,
    String? colorThemeId,
    String? fontThemeId,
  }) {
    return ThemeState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      colorThemeId: colorThemeId ?? this.colorThemeId,
      fontThemeId: fontThemeId ?? this.fontThemeId,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('app_dark_mode') ?? false;
    final colorTheme = prefs.getString('app_color_theme') ?? 'forest';
    final fontTheme = prefs.getString('app_font_theme') ?? 'default';

    state = ThemeState(
      isDarkMode: isDark,
      colorThemeId: colorTheme,
      fontThemeId: fontTheme,
    );
  }

  Future<void> toggleDarkMode() async {
    final newValue = !state.isDarkMode;
    state = state.copyWith(isDarkMode: newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_dark_mode', newValue);
  }

  Future<void> setColorTheme(String themeId) async {
    state = state.copyWith(colorThemeId: themeId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_color_theme', themeId);
  }

  Future<void> setFontTheme(String themeId) async {
    state = state.copyWith(fontThemeId: themeId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_font_theme', themeId);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

// Helper providers for easy access
final colorThemeProvider = Provider<ColorThemeModel>((ref) {
  final state = ref.watch(themeProvider);
  return ColorThemes.getTheme(state.colorThemeId, state.isDarkMode);
});

final fontThemeProvider = Provider<FontThemeModel>((ref) {
  final state = ref.watch(themeProvider);
  return FontThemes.all[state.fontThemeId]!;
});
