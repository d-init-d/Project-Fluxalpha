import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/collection.dart';

class CollectionsService extends ChangeNotifier {
  static final CollectionsService _instance = CollectionsService._internal();
  factory CollectionsService() => _instance;
  CollectionsService._internal();

  SharedPreferences? _prefs;
  List<Collection> _collections = [];

  // Getter for all collections
  List<Collection> get getAllCollections => List.unmodifiable(_collections);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCollections();
  }

  Future<void> _loadCollections() async {
    if (_prefs == null) return;

    final collectionsJson = _prefs!.getString('book_collections');
    if (collectionsJson != null) {
      try {
        final List<dynamic> collectionsList = jsonDecode(collectionsJson);
        _collections = collectionsList
            .map((json) => Collection.fromJson(json))
            .toList();
      } catch (e) {
        // If there's an error parsing, start with empty list
        debugPrint('Error loading collections: $e');
        _collections = [];
      }
    } else {
      // First launch - optionally provide default collections
      _collections = [];
    }

    notifyListeners();
  }

  Future<void> _saveCollections() async {
    if (_prefs == null) return;

    final collectionsJson = jsonEncode(
      _collections.map((c) => c.toJson()).toList(),
    );
    await _prefs!.setString('book_collections', collectionsJson);
  }

  // Create a new collection
  Future<void> createCollection(String name, List<String> bookIds) async {
    final newCollection = Collection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      bookIds: bookIds,
      createdAt: DateTime.now(),
    );

    _collections.add(newCollection);
    await _saveCollections();
    notifyListeners();
  }

  // Delete a collection
  Future<void> deleteCollection(String id) async {
    _collections.removeWhere((c) => c.id == id);
    await _saveCollections();
    notifyListeners();
  }

  // Add a book to a collection
  Future<void> addBookToCollection(String collectionId, String bookId) async {
    final index = _collections.indexWhere((c) => c.id == collectionId);
    if (index != -1) {
      final collection = _collections[index];
      if (!collection.bookIds.contains(bookId)) {
        _collections[index] = collection.copyWith(
          bookIds: [...collection.bookIds, bookId],
        );
        await _saveCollections();
        notifyListeners();
      }
    }
  }

  // Remove a book from a collection
  Future<void> removeBookFromCollection(
    String collectionId,
    String bookId,
  ) async {
    final index = _collections.indexWhere((c) => c.id == collectionId);
    if (index != -1) {
      final collection = _collections[index];
      final updatedBookIds = collection.bookIds
          .where((id) => id != bookId)
          .toList();
      _collections[index] = collection.copyWith(bookIds: updatedBookIds);
      await _saveCollections();
      notifyListeners();
    }
  }

  // Get a specific collection by id
  Collection? getCollection(String id) {
    try {
      return _collections.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
}
