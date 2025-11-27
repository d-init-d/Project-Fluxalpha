import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the last known chapter for each book so home UI can show progress.
class ReadingPositionService extends ChangeNotifier {
  ReadingPositionService._internal();
  static final ReadingPositionService _instance =
      ReadingPositionService._internal();

  factory ReadingPositionService() => _instance;

  static const String _storageKey = 'reading_position_chapters';

  SharedPreferences? _prefs;
  bool _isInitialized = false;
  final Map<String, int> _bookChapters = {};

  Future<void> init() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    final stored = _prefs?.getString(_storageKey);
    if (stored != null) {
      try {
        final decoded = jsonDecode(stored) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          final parsed = (value as num?)?.toInt();
          if (parsed != null) {
            _bookChapters[key] = parsed;
          }
        });
      } catch (_) {
        _bookChapters.clear();
      }
    }
    _isInitialized = true;
  }

  int getCurrentChapter(String bookId) {
    if (bookId.isEmpty) return 1;
    return _bookChapters[bookId] ?? 1;
  }

  Future<void> setCurrentChapter(String bookId, int chapterNumber) async {
    if (bookId.isEmpty) return;
    await init();
    final normalized = chapterNumber < 1 ? 1 : chapterNumber;
    if (_bookChapters[bookId] == normalized) return;
    _bookChapters[bookId] = normalized;
    await _save();
    notifyListeners();
  }

  Future<void> clearChapter(String bookId) async {
    if (_bookChapters.remove(bookId) != null) {
      await _save();
      notifyListeners();
    }
  }

  Future<void> reset() async {
    if (_bookChapters.isEmpty) return;
    _bookChapters.clear();
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(_storageKey, jsonEncode(_bookChapters));
  }
}







