import 'package:flutter/material.dart';

import '../models/annotation.dart';
import '../models/saved_bookmark.dart';

class SavedContentService extends ChangeNotifier {
  static final SavedContentService _instance = SavedContentService._internal();

  factory SavedContentService() => _instance;

  SavedContentService._internal();

  final List<Highlight> _highlights = [];
  final List<Note> _notes = [];
  final List<SavedBookmark> _bookmarks = [];

  List<Highlight> get highlights => List.unmodifiable(_highlights);
  List<Note> get notes => List.unmodifiable(_notes);
  List<SavedBookmark> get bookmarks => List.unmodifiable(_bookmarks);

  int get totalCount => _highlights.length + _notes.length + _bookmarks.length;

  void addHighlight(Highlight highlight) {
    _highlights.removeWhere((h) => h.id == highlight.id);
    _highlights.insert(0, highlight);
    notifyListeners();
  }

  void removeHighlight(String id) {
    _highlights.removeWhere((h) => h.id == id);
    notifyListeners();
  }

  void addNote(Note note) {
    _notes.insert(0, note);
    notifyListeners();
  }

  void removeNote(String id) {
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void addBookmark(SavedBookmark bookmark) {
    _bookmarks.removeWhere((b) => b.id == bookmark.id);
    _bookmarks.insert(0, bookmark);
    notifyListeners();
  }

  void removeBookmark(String id) {
    _bookmarks.removeWhere((b) => b.id == id);
    notifyListeners();
  }
}

