import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReadingSettingsService extends ChangeNotifier {
  static final ReadingSettingsService _instance =
      ReadingSettingsService._internal();
  factory ReadingSettingsService() => _instance;
  ReadingSettingsService._internal();

  SharedPreferences? _prefs;

  // Reading settings
  double _fontSize = 18.0;
  double _lineSpacing = 1.5;
  double _wordSpacing = 0.0;
  Color _backgroundColor = const Color(0xFFFFFBF0); // Sepia color
  String _fontFamily = 'Lora';

  // Getters
  double get fontSize => _fontSize;
  double get lineSpacing => _lineSpacing;
  double get wordSpacing => _wordSpacing;
  Color get backgroundColor => _backgroundColor;
  String get fontFamily => _fontFamily;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (_prefs == null) return;

    final settingsJson = _prefs!.getString('reading_settings');
    if (settingsJson != null) {
      try {
        final Map<String, dynamic> settings = jsonDecode(settingsJson);
        _fontSize = settings['fontSize']?.toDouble() ?? 18.0;
        _lineSpacing = settings['lineSpacing']?.toDouble() ?? 1.5;
        _wordSpacing = settings['wordSpacing']?.toDouble() ?? 0.0;
        _backgroundColor = Color(settings['backgroundColor'] ?? 0xFFFFFBF0);
        _fontFamily = settings['fontFamily'] ?? 'Lora';
      } catch (e) {
        // If there's an error parsing, use defaults
        _fontSize = 18.0;
        _lineSpacing = 1.5;
        _wordSpacing = 0.0;
        _backgroundColor = const Color(0xFFFFFBF0);
        _fontFamily = 'Lora';
      }
    }

    notifyListeners();
  }

  Future<void> _saveSettings() async {
    if (_prefs == null) return;

    final Map<String, dynamic> settings = {
      'fontSize': _fontSize,
      'lineSpacing': _lineSpacing,
      'wordSpacing': _wordSpacing,
      'backgroundColor': _backgroundColor.value,
      'fontFamily': _fontFamily,
    };

    await _prefs!.setString('reading_settings', jsonEncode(settings));
  }

  // Setters with persistence
  Future<void> setFontSize(double size) async {
    _fontSize = size;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setLineSpacing(double spacing) async {
    _lineSpacing = spacing;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setWordSpacing(double spacing) async {
    _wordSpacing = spacing;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setBackgroundColor(Color color) async {
    _backgroundColor = color;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setFontFamily(String family) async {
    _fontFamily = family;
    await _saveSettings();
    notifyListeners();
  }

  // Batch update method for efficiency
  Future<void> updateSettings({
    double? fontSize,
    double? lineSpacing,
    double? wordSpacing,
    Color? backgroundColor,
    String? fontFamily,
  }) async {
    bool hasChanges = false;

    if (fontSize != null && fontSize != _fontSize) {
      _fontSize = fontSize;
      hasChanges = true;
    }
    if (lineSpacing != null && lineSpacing != _lineSpacing) {
      _lineSpacing = lineSpacing;
      hasChanges = true;
    }
    if (wordSpacing != null && wordSpacing != _wordSpacing) {
      _wordSpacing = wordSpacing;
      hasChanges = true;
    }
    if (backgroundColor != null && backgroundColor != _backgroundColor) {
      _backgroundColor = backgroundColor;
      hasChanges = true;
    }
    if (fontFamily != null && fontFamily != _fontFamily) {
      _fontFamily = fontFamily;
      hasChanges = true;
    }

    if (hasChanges) {
      await _saveSettings();
      notifyListeners();
    }
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    _fontSize = 18.0;
    _lineSpacing = 1.5;
    _wordSpacing = 0.0;
    _backgroundColor = const Color(0xFFFFFBF0);
    _fontFamily = 'Lora';
    await _saveSettings();
    notifyListeners();
  }
}
