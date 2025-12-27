import 'package:flutter/material.dart';
import '../models/book.dart';

/// Collection types
enum CollectionType {
  READING,
  FINISHED,
  NOT_STARTED,
  RECENTLY_ADDED,
  MOST_READ,
  FAVORITES,
}

/// Smart collection model
class SmartCollection {
  final String id;
  final CollectionType type;
  final String name;
  final IconData icon;
  final Color color;

  SmartCollection({
    required this.id,
    required this.type,
    required this.name,
    required this.icon,
    required this.color,
  });
}

/// Service for managing smart collections
class CollectionService {
  /// Get all available smart collections
  static List<SmartCollection> getAllCollections() {
    return [
      SmartCollection(
        id: 'reading',
        type: CollectionType.READING,
        name: 'Đang đọc',
        icon: Icons.book_outlined,
        color: const Color(0xFF2196F3),
      ),
      SmartCollection(
        id: 'finished',
        type: CollectionType.FINISHED,
        name: 'Đã đọc xong',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF4CAF50),
      ),
      SmartCollection(
        id: 'not_started',
        type: CollectionType.NOT_STARTED,
        name: 'Chưa đọc',
        icon: Icons.fiber_new_outlined,
        color: const Color(0xFF9E9E9E),
      ),
      SmartCollection(
        id: 'recently_added',
        type: CollectionType.RECENTLY_ADDED,
        name: 'Mới thêm',
        icon: Icons.access_time,
        color: const Color(0xFFFF9800),
      ),
      SmartCollection(
        id: 'most_read',
        type: CollectionType.MOST_READ,
        name: 'Đọc nhiều nhất',
        icon: Icons.trending_up,
        color: const Color(0xFFE91E63),
      ),
      SmartCollection(
        id: 'favorites',
        type: CollectionType.FAVORITES,
        name: 'Yêu thích',
        icon: Icons.favorite_outline,
        color: const Color(0xFFF44336),
      ),
    ];
  }

  /// Filter books by collection type
  static List<Book> filterBooksByCollection(
    List<Book> books,
    CollectionType type,
  ) {
    switch (type) {
      case CollectionType.READING:
        return books
            .where((book) => book.progress > 0 && book.progress < 1.0)
            .toList();

      case CollectionType.FINISHED:
        return books.where((book) => book.progress >= 1.0).toList();

      case CollectionType.NOT_STARTED:
        return books.where((book) => book.progress == 0).toList();

      case CollectionType.RECENTLY_ADDED:
        final sorted = List<Book>.from(books)
          ..sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
        return sorted.take(20).toList();

      case CollectionType.MOST_READ:
        final sorted = List<Book>.from(books)
          ..sort((a, b) {
            // Sort by progress first, then by last read date
            final progressDiff = b.progress.compareTo(a.progress);
            if (progressDiff != 0) return progressDiff;
            return b.lastRead.compareTo(a.lastRead);
          });
        return sorted.take(20).toList();

      case CollectionType.FAVORITES:
        return books.where((book) => book.isFavorite).toList();
    }
  }

  /// Get count for a collection
  static int getCollectionCount(List<Book> books, CollectionType type) {
    return filterBooksByCollection(books, type).length;
  }

  /// Group books by author
  static Map<String, List<Book>> groupBooksByAuthor(List<Book> books) {
    final grouped = <String, List<Book>>{};

    for (final book in books) {
      final author = book.author.trim().isEmpty ? 'Unknown' : book.author;
      grouped.putIfAbsent(author, () => []).add(book);
    }

    // Sort authors alphabetically
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Map.fromEntries(sortedEntries);
  }

  /// Get suggested collections for a book
  static List<CollectionType> getSuggestedCollections(Book book) {
    final suggestions = <CollectionType>[];

    if (book.isFavorite) {
      suggestions.add(CollectionType.FAVORITES);
    }

    if (book.progress > 0 && book.progress < 1.0) {
      suggestions.add(CollectionType.READING);
    } else if (book.progress >= 1.0) {
      suggestions.add(CollectionType.FINISHED);
    } else {
      suggestions.add(CollectionType.NOT_STARTED);
    }

    final daysSinceAdded = DateTime.now().difference(book.uploadDate).inDays;
    if (daysSinceAdded <= 7) {
      suggestions.add(CollectionType.RECENTLY_ADDED);
    }

    if (book.progress >= 0.5) {
      suggestions.add(CollectionType.MOST_READ);
    }

    return suggestions;
  }
}
