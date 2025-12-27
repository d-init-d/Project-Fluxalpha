import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../models/annotation.dart';
import '../models/saved_bookmark.dart';

/// Search result types
enum SearchResultType { BOOK_TITLE, BOOK_AUTHOR, ANNOTATION, BOOKMARK }

/// Single search result
class SearchResult {
  final SearchResultType type;
  final String bookId;
  final String title;
  final String snippet;
  final double relevanceScore;

  // Optional fields for navigation
  final String? chapterId;
  final int? paragraphIndex;
  final Annotation? annotation;
  final SavedBookmark? bookmark;

  SearchResult({
    required this.type,
    required this.bookId,
    required this.title,
    required this.snippet,
    required this.relevanceScore,
    this.chapterId,
    this.paragraphIndex,
    this.annotation,
    this.bookmark,
  });
}

/// Global search service
class SearchService {
  /// Search across all data
  Future<List<SearchResult>> search({
    required String query,
    required List<Book> books,
    Map<String, List<Annotation>>? annotations,
    Map<String, List<SavedBookmark>>? bookmarks,
  }) async {
    if (query.trim().isEmpty) return [];

    final normalizedQuery = _normalizeText(query);
    final results = <SearchResult>[];

    // Search in books (title & author)
    for (final book in books) {
      final titleScore = _calculateScore(
        _normalizeText(book.title),
        normalizedQuery,
      );

      if (titleScore > 0) {
        results.add(
          SearchResult(
            type: SearchResultType.BOOK_TITLE,
            bookId: book.id,
            title: book.title,
            snippet: _highlightQuery(book.title, query),
            relevanceScore: titleScore,
          ),
        );
      }

      final authorScore = _calculateScore(
        _normalizeText(book.author),
        normalizedQuery,
      );

      if (authorScore > 0) {
        results.add(
          SearchResult(
            type: SearchResultType.BOOK_AUTHOR,
            bookId: book.id,
            title: '${book.title} - ${book.author}',
            snippet: 'Tác giả: ${_highlightQuery(book.author, query)}',
            relevanceScore: authorScore * 0.8, // Author slightly less relevant
          ),
        );
      }
    }

    // Search in annotations
    if (annotations != null) {
      for (final entry in annotations.entries) {
        final bookId = entry.key;
        final book = books.firstWhere(
          (b) => b.id == bookId,
          orElse: () => Book(
            id: bookId,
            title: 'Unknown',
            author: 'Unknown',
            filePath: '',
            color: const Color(0xFF000000),
            uploadDate: DateTime.now(),
          ),
        );

        for (final annotation in entry.value) {
          final textScore = _calculateScore(
            _normalizeText(annotation.selectedText),
            normalizedQuery,
          );

          final noteScore = annotation.note != null
              ? _calculateScore(
                  _normalizeText(annotation.note!),
                  normalizedQuery,
                )
              : 0.0;

          final score = textScore > noteScore ? textScore : noteScore;

          if (score > 0) {
            final searchText = textScore > noteScore
                ? annotation.selectedText
                : annotation.note!;

            results.add(
              SearchResult(
                type: SearchResultType.ANNOTATION,
                bookId: bookId,
                title: book.title,
                snippet: _truncateWithHighlight(searchText, query, 100),
                relevanceScore: score * 0.9,
                annotation: annotation,
              ),
            );
          }
        }
      }
    }

    // Search in bookmarks
    if (bookmarks != null) {
      for (final entry in bookmarks.entries) {
        final bookId = entry.key;
        final book = books.firstWhere(
          (b) => b.id == bookId,
          orElse: () => Book(
            id: bookId,
            title: 'Unknown',
            author: 'Unknown',
            filePath: '',
            color: const Color(0xFF000000),
            uploadDate: DateTime.now(),
          ),
        );

        for (final bookmark in entry.value) {
          if (bookmark.note == null) continue;

          final score = _calculateScore(
            _normalizeText(bookmark.note!),
            normalizedQuery,
          );

          if (score > 0) {
            results.add(
              SearchResult(
                type: SearchResultType.BOOKMARK,
                bookId: bookId,
                title: book.title,
                snippet: _truncateWithHighlight(bookmark.note!, query, 100),
                relevanceScore: score * 0.85,
                bookmark: bookmark,
              ),
            );
          }
        }
      }
    }

    // Sort by relevance score (descending)
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    // Limit to top 100 results
    return results.take(100).toList();
  }

  /// Normalize text for comparison (lowercase, remove diacritics)
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
        .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
        .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
        .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
        .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
        .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
        .replaceAll(RegExp(r'[đ]'), 'd')
        .trim();
  }

  /// Calculate relevance score
  double _calculateScore(String text, String query) {
    if (text.isEmpty || query.isEmpty) return 0.0;

    // Exact match = highest score
    if (text == query) return 1.0;

    // Contains whole query = high score
    if (text.contains(query)) {
      final position = text.indexOf(query);
      final positionScore = 1.0 - (position / text.length * 0.3);
      return 0.8 * positionScore;
    }

    // Partial word matches
    final textWords = text.split(RegExp(r'\s+'));
    final queryWords = query.split(RegExp(r'\s+'));

    var matchedWords = 0;
    for (final queryWord in queryWords) {
      for (final textWord in textWords) {
        if (textWord.contains(queryWord) || queryWord.contains(textWord)) {
          matchedWords++;
          break;
        }
      }
    }

    if (matchedWords > 0) {
      return 0.5 * (matchedWords / queryWords.length);
    }

    return 0.0;
  }

  /// Highlight query in text
  String _highlightQuery(String text, String query) {
    final normalizedText = _normalizeText(text);
    final normalizedQuery = _normalizeText(query);

    final index = normalizedText.indexOf(normalizedQuery);
    if (index == -1) return text;

    final start = index;
    final end = index + query.length;

    return '${text.substring(0, start)}**${text.substring(start, end)}**${text.substring(end)}';
  }

  /// Truncate text and highlight query
  String _truncateWithHighlight(String text, String query, int maxLength) {
    final normalizedText = _normalizeText(text);
    final normalizedQuery = _normalizeText(query);

    final index = normalizedText.indexOf(normalizedQuery);

    if (index == -1) {
      // Query not found, just truncate
      return text.length <= maxLength
          ? text
          : '${text.substring(0, maxLength)}...';
    }

    // Calculate snippet range to show query in context
    final contextBefore = 40;
    final contextAfter = maxLength - contextBefore - query.length;

    final start = (index - contextBefore).clamp(0, text.length);
    final end = (index + query.length + contextAfter).clamp(0, text.length);

    var snippet = text.substring(start, end);

    if (start > 0) snippet = '...$snippet';
    if (end < text.length) snippet = '$snippet...';

    return _highlightQuery(snippet, query);
  }
}
