import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';

// StateNotifier for managing book list
class BookListNotifier extends StateNotifier<List<Book>> {
  static const String _storageKey = 'books_list';

  BookListNotifier() : super([]) {
    _loadBooks();
  }

  // Load books from SharedPreferences
  Future<void> _loadBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? booksJson = prefs.getString(_storageKey);

      if (booksJson != null) {
        final List<dynamic> booksList = json.decode(booksJson);
        state = booksList.map((json) => Book.fromJson(json)).toList();
      } else {
        // Start with empty list - no dummy books
        state = [];
      }
    } catch (e) {
      // On error, start with empty list
      state = [];
    }
  }

  // Save books to SharedPreferences
  Future<void> _saveBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String booksJson = json.encode(
        state.map((book) => book.toJson()).toList(),
      );
      await prefs.setString(_storageKey, booksJson);
    } catch (e) {
      // Handle save error silently
    }
  }

  // Add a new book
  Future<void> addBook(Book book) async {
    state = [...state, book];
    await _saveBooks();
  }

  // Add multiple books
  Future<void> addBooks(List<Book> books) async {
    state = [...state, ...books];
    await _saveBooks();
  }

  // Remove a book by id
  Future<void> removeBook(String id) async {
    state = state.where((book) => book.id != id).toList();
    await _saveBooks();
  }

  // Update a book
  Future<void> updateBook(Book updatedBook) async {
    state = [
      for (final book in state)
        if (book.id == updatedBook.id) updatedBook else book,
    ];
    await _saveBooks();
  }

  // Update book progress
  Future<void> updateProgress(
    String id,
    double progress,
    int currentPage,
  ) async {
    state = [
      for (final book in state)
        if (book.id == id)
          book.copyWith(
            progress: progress,
            currentPage: currentPage,
            lastRead: DateTime.now(),
          )
        else
          book,
    ];
    await _saveBooks();
  }

  // Mark a book as opened by updating its lastRead timestamp
  // If the book hasn't been started (progress = 0), set it to 0.01 to mark as "currently reading"
  Future<void> markBookOpened(String id) async {
    final now = DateTime.now();
    state = [
      for (final book in state)
        if (book.id == id)
          book.copyWith(
            lastRead: now,
            progress: book.progress == 0 ? 0.01 : book.progress,
          )
        else
          book,
    ];
    await _saveBooks();
  }

  // Get books by category
  List<Book> getBooksByCategory(String category) {
    if (category == 'Tất cả') return state;
    return state.where((book) => book.category == category).toList();
  }

  // Get currently reading books
  List<Book> getCurrentlyReading() {
    return state
        .where((book) => book.progress > 0 && book.progress < 1.0)
        .toList();
  }

  // Get finished books
  List<Book> getFinishedBooks() {
    return state.where((book) => book.progress >= 1.0).toList();
  }

  // Get recently added books
  List<Book> getRecentlyAdded({int limit = 10}) {
    final sorted = List<Book>.from(state)
      ..sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
    return sorted.take(limit).toList();
  }

  // Clear all books (for testing)
  Future<void> clearAll() async {
    state = [];
    await _saveBooks();
  }

  // Toggle read status
  Future<void> toggleReadStatus(String id) async {
    state = [
      for (final book in state)
        if (book.id == id) book.copyWith(isRead: !book.isRead) else book,
    ];
    await _saveBooks();
  }

  // Delete a book by id and its local files
  Future<void> deleteBook(String id) async {
    debugPrint('[Delete] Attempting to delete book with id: $id');

    try {
      // Find the book to get its file path
      final book = state.firstWhere((b) => b.id == id);
      debugPrint('[Delete] Found book: ${book.title}');
      debugPrint('[Delete] Book file path: ${book.filePath}');
      debugPrint('[Delete] Cover file path: ${book.coverFilePath ?? "null"}');

      // Try to delete the book file if it exists
      try {
        final file = File(book.filePath);
        if (await file.exists()) {
          debugPrint('[Delete] Book file exists, attempting deletion...');
          await file.delete();
          debugPrint('[Delete] Book file deleted successfully');
        } else {
          debugPrint('[Delete] Book file does not exist, skipping');
        }
      } catch (e) {
        // If file deletion fails, continue with removing from list
        debugPrint('[Delete] Error deleting book file: $e');
      }

      // Try to delete cover image file if it exists
      if (book.coverFilePath != null) {
        try {
          final coverFile = File(book.coverFilePath!);
          if (await coverFile.exists()) {
            debugPrint('[Delete] Cover file exists, attempting deletion...');
            await coverFile.delete();
            debugPrint('[Delete] Cover file deleted successfully');
          } else {
            debugPrint('[Delete] Cover file does not exist, skipping');
          }
        } catch (e) {
          debugPrint('[Delete] Error deleting cover file: $e');
        }
      } else {
        debugPrint('[Delete] No cover file path, skipping cover deletion');
      }

      // ALWAYS remove book from list and update SharedPreferences
      // Even if file deletion fails, we still want to remove it from UI
      debugPrint(
        '[Delete] Removing book from list and updating SharedPreferences...',
      );
      state = state.where((book) => book.id != id).toList();
      await _saveBooks();
      debugPrint(
        '[Delete] Success: Book removed from list and SharedPreferences updated',
      );
    } catch (e) {
      debugPrint('[Delete] Error: Failed to delete book - $e');
      // Even on error, try to remove from list if possible
      try {
        state = state.where((book) => book.id != id).toList();
        await _saveBooks();
        debugPrint(
          '[Delete] Success: Book removed from list despite file deletion errors',
        );
      } catch (removeError) {
        debugPrint(
          '[Delete] Error: Failed to remove book from list - $removeError',
        );
        rethrow;
      }
    }
  }
}

// Provider definition
final bookListProvider = StateNotifierProvider<BookListNotifier, List<Book>>((
  ref,
) {
  return BookListNotifier();
});

// Convenience providers for filtered lists
final currentlyReadingBooksProvider = Provider<List<Book>>((ref) {
  final books = ref.watch(bookListProvider);
  return books
      .where((book) => book.progress > 0 && book.progress < 1.0)
      .toList();
});

final finishedBooksProvider = Provider<List<Book>>((ref) {
  final books = ref.watch(bookListProvider);
  return books.where((book) => book.progress >= 1.0).toList();
});

final recentlyAddedBooksProvider = Provider<List<Book>>((ref) {
  final books = ref.watch(bookListProvider);
  final sorted = List<Book>.from(books)
    ..sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
  return sorted.take(10).toList();
});

final mostRecentlyReadBookProvider = Provider<Book?>((ref) {
  final books = ref.watch(bookListProvider);
  if (books.isEmpty) return null;

  final readingBooks = books
      .where((book) => book.progress > 0 && book.progress < 1.0)
      .toList();

  final candidates =
      readingBooks.isNotEmpty ? readingBooks : List<Book>.from(books);
  if (candidates.isEmpty) return null;

  candidates.sort((a, b) => b.lastRead.compareTo(a.lastRead));
  return candidates.first;
});
