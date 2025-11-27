import 'package:flutter/material.dart';

// MÀU NỀN CHUNG (Shared Background Colors)
// Các màu này được sử dụng chung cho tất cả các chủ đề (trừ màu chữ chính)
class SharedColors {
  // Light Mode Backgrounds
  static const Color backgroundLight = Color(0xFFD8CFBC);
  static const Color cardBackgroundLight = Color(0xFFF2F0E9);
  static const Color highlightAccent = Color(
    0xFF9A3412,
  ); // Màu điểm nhấn (giấc mơ)

  // Dark Mode Backgrounds
  static const Color backgroundDark = Color(0xFF000000); // Nền chính Dark Mode
  static const Color cardBackgroundDark = Color(
    0xFF000000,
  ); // Nền Card/Popup Dark Mode
  static const Color primaryTextDark = Color(
    0xFFE3DAC9,
  ); // Màu chữ chính trong Dark Mode
}

// --- 1. CHỦ ĐỀ CÀ PHÊ (Espresso Theme) ---
class CoffeeTheme {
  // MÀU CHÍNH (SÁNG)
  static const Color primaryTextLight = Color(0xFF2C1810);
  static const Color background = SharedColors.backgroundLight;
  static const Color cardBackground = SharedColors.cardBackgroundLight;
  static const Color accent = Color(0xFFB45309); // Accent (cho các nút)

  // MÀU CHÍNH (TỐI)
  static const Color darkPrimaryText = SharedColors.primaryTextDark;
  static const Color darkBackground = SharedColors.backgroundDark;
  static const Color darkCardBackground = SharedColors.cardBackgroundDark;
  static const Color darkAccent = Color(
    0xFF4A2C20,
  ); // Accent (tông trầm hơn cho Dark Mode)
}

// --- 2. CHỦ ĐỀ RỪNG GIÀ (Forest Theme) ---
class ForestTheme {
  // MÀU CHÍNH (SÁNG)
  static const Color primaryTextLight = Color(0xFF043222);
  static const Color background = SharedColors.backgroundLight;
  static const Color cardBackground = SharedColors.cardBackgroundLight;
  static const Color accent = Color(0xFF043222); // Accent (cho các nút)

  // MÀU CHÍNH (TỐI)
  static const Color darkPrimaryText = SharedColors.primaryTextDark;
  static const Color darkBackground = SharedColors.backgroundDark;
  static const Color darkCardBackground = SharedColors.cardBackgroundDark;
  static const Color darkAccent = Color(
    0xFF043222,
  ); // Giữ nguyên cho Dark Accent
}

// --- 3. CHỦ ĐỀ THAN CHÌ (Charcoal Theme) ---
class CharcoalTheme {
  // MÀU CHÍNH (SÁNG)
  static const Color primaryTextLight = Color(0xFF333333);
  static const Color background = SharedColors.backgroundLight;
  static const Color cardBackground = SharedColors.cardBackgroundLight;
  static const Color accent = Color(0xFF333333); // Accent (cho các nút)

  // MÀU CHÍNH (TỐI)
  static const Color darkPrimaryText = SharedColors.primaryTextDark;
  static const Color darkBackground = SharedColors.backgroundDark;
  static const Color darkCardBackground = SharedColors.cardBackgroundDark;
  static const Color darkAccent = Color(
    0xFF333333,
  ); // Giữ nguyên cho Dark Accent
}

// --- 4. CHỦ ĐỀ MỰC IN (Ink Theme) ---
class InkTheme {
  // MÀU CHÍNH (SÁNG)
  static const Color primaryTextLight = Color(0xFF1E293B);
  static const Color background = SharedColors.backgroundLight;
  static const Color cardBackground = SharedColors.cardBackgroundLight;
  static const Color accent = Color(0xFF1E293B); // Accent (cho các nút)

  // MÀU CHÍNH (TỐI)
  static const Color darkPrimaryText = SharedColors.primaryTextDark;
  static const Color darkBackground = SharedColors.backgroundDark;
  static const Color darkCardBackground = SharedColors.cardBackgroundDark;
  static const Color darkAccent = Color(
    0xFF1E293B,
  ); // Giữ nguyên cho Dark Accent
}

class ColorThemeModel {
  final String id;
  final String name;
  final Color textColor;
  final Color textLight;
  final Color highlight;
  final Color accentBg;
  final Color secondaryAccent;
  final Color border;
  final String hex;
  final String description;
  final Color background;
  final Color cardBackground;

  Color get backgroundColor => background;

  const ColorThemeModel({
    required this.id,
    required this.name,
    required this.textColor,
    required this.textLight,
    required this.highlight,
    required this.accentBg,
    required this.secondaryAccent,
    required this.border,
    required this.hex,
    required this.description,
    required this.background,
    required this.cardBackground,
  });
}

class ColorThemes {
  static ColorThemeModel getTheme(String themeId, bool isDarkMode) {
    switch (themeId) {
      case 'espresso':
        return _createTheme(
          id: 'espresso',
          name: 'Cà Phê',
          lightPrimary: CoffeeTheme.primaryTextLight,
          lightAccent: CoffeeTheme.accent,
          lightTextLight: const Color(0xFF5D4037),
          darkAccent: CoffeeTheme.darkAccent,
          lightBackground: CoffeeTheme.background,
          lightCardBackground: CoffeeTheme.cardBackground,
          darkBackground: CoffeeTheme.darkBackground,
          darkCardBackground: CoffeeTheme.darkCardBackground,
          darkPrimaryText: CoffeeTheme.darkPrimaryText,
          hex: '#2C1810',
          description: 'Ấm áp & Cổ điển',
          isDarkMode: isDarkMode,
        );
      case 'charcoal':
        return _createTheme(
          id: 'charcoal',
          name: 'Than Chì',
          lightPrimary: CharcoalTheme.primaryTextLight,
          lightAccent: CharcoalTheme.accent,
          lightTextLight: const Color(0xFF666666),
          darkAccent: CharcoalTheme.darkAccent,
          lightBackground: CharcoalTheme.background,
          lightCardBackground: CharcoalTheme.cardBackground,
          darkBackground: CharcoalTheme.darkBackground,
          darkCardBackground: CharcoalTheme.darkCardBackground,
          darkPrimaryText: CharcoalTheme.darkPrimaryText,
          hex: '#333333',
          description: 'Tối giản & Hiện đại',
          isDarkMode: isDarkMode,
        );
      case 'ink':
        return _createTheme(
          id: 'ink',
          name: 'Mực In',
          lightPrimary: InkTheme.primaryTextLight,
          lightAccent: InkTheme.accent,
          lightTextLight: const Color(0xFF64748B),
          darkAccent: InkTheme.darkAccent,
          lightBackground: InkTheme.background,
          lightCardBackground: InkTheme.cardBackground,
          darkBackground: InkTheme.darkBackground,
          darkCardBackground: InkTheme.darkCardBackground,
          darkPrimaryText: InkTheme.darkPrimaryText,
          hex: '#1E293B',
          description: 'Tri thức & Tinh tế',
          isDarkMode: isDarkMode,
        );
      case 'forest':
      default:
        return _createTheme(
          id: 'forest',
          name: 'Rừng Già',
          lightPrimary: ForestTheme.primaryTextLight,
          lightAccent: ForestTheme.accent,
          lightTextLight: const Color(0xFF4A635D),
          darkAccent: ForestTheme.darkAccent,
          lightBackground: ForestTheme.background,
          lightCardBackground: ForestTheme.cardBackground,
          darkBackground: ForestTheme.darkBackground,
          darkCardBackground: ForestTheme.darkCardBackground,
          darkPrimaryText: ForestTheme.darkPrimaryText,
          hex: '#043222',
          description: 'Tự nhiên & Sâu sắc',
          isDarkMode: isDarkMode,
        );
    }
  }

  static ColorThemeModel _createTheme({
    required String id,
    required String name,
    required Color lightPrimary,
    required Color lightAccent,
    required Color lightTextLight,
    required Color darkAccent,
    required Color lightBackground,
    required Color lightCardBackground,
    required Color darkBackground,
    required Color darkCardBackground,
    required Color darkPrimaryText,
    required String hex,
    required String description,
    required bool isDarkMode,
  }) {
    if (isDarkMode) {
      return ColorThemeModel(
        id: id,
        name: name,
        textColor: darkPrimaryText,
        textLight: Colors.grey[400]!, // Derived for dark mode
        highlight: Colors.amber, // Highlight color for Dark Mode (usually yellow/amber is good for contrast)
        accentBg: darkAccent,
        secondaryAccent: darkAccent.withOpacity(0.8),
        border: const Color(0xFF2D3748),
        hex: hex,
        description: description,
        background: darkBackground,
        cardBackground: darkCardBackground,
      );
    } else {
      return ColorThemeModel(
        id: id,
        name: name,
        textColor: lightPrimary,
        textLight: lightTextLight,
        highlight: lightAccent, // Highlight matches theme accent color in Light Mode
        accentBg: lightAccent,
        secondaryAccent: lightAccent.withOpacity(0.8),
        border: lightPrimary,
        hex: hex,
        description: description,
        background: lightBackground,
        cardBackground: lightCardBackground,
      );
    }
  }

  static const Map<String, String> themeNames = {
    'forest': 'Rừng Già',
    'charcoal': 'Than Chì',
    'espresso': 'Cà Phê',
    'ink': 'Mực In',
  };
}
