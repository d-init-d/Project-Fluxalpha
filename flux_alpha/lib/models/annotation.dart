import 'package:flutter/material.dart';

/// Represents a highlighted text segment in a book
class Highlight {
  final String id;
  final int paragraphIndex;
  final int startOffset;
  final int endOffset;
  final String selectedText;
  final Color color;
  final DateTime createdAt;
  final String bookTitle;

  Highlight({
    required this.id,
    required this.paragraphIndex,
    required this.startOffset,
    required this.endOffset,
    required this.selectedText,
    required this.color,
    required this.createdAt,
    required this.bookTitle,
  });

  // Copy with method for easy updates
  Highlight copyWith({
    String? id,
    int? paragraphIndex,
    int? startOffset,
    int? endOffset,
    String? selectedText,
    Color? color,
    DateTime? createdAt,
    String? bookTitle,
  }) {
    return Highlight(
      id: id ?? this.id,
      paragraphIndex: paragraphIndex ?? this.paragraphIndex,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      selectedText: selectedText ?? this.selectedText,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      bookTitle: bookTitle ?? this.bookTitle,
    );
  }

  // Convert to JSON for potential persistence
  Map<String, dynamic> toJson() => {
    'id': id,
    'paragraphIndex': paragraphIndex,
    'startOffset': startOffset,
    'endOffset': endOffset,
    'selectedText': selectedText,
    'color': color.value,
    'createdAt': createdAt.toIso8601String(),
    'bookTitle': bookTitle,
  };

  // Create from JSON
  factory Highlight.fromJson(Map<String, dynamic> json) => Highlight(
    id: json['id'],
    paragraphIndex: json['paragraphIndex'],
    startOffset: json['startOffset'],
    endOffset: json['endOffset'],
    selectedText: json['selectedText'],
    color: Color(json['color']),
    createdAt: DateTime.parse(json['createdAt']),
    bookTitle: json['bookTitle'] ?? 'Chưa rõ',
  );
}

/// Represents a note taken on a text segment
class Note {
  final String id;
  final String? highlightId; // Optional link to a highlight
  final String content;
  final String selectedText;
  final int paragraphIndex;
  final int startOffset; // Start position in paragraph
  final int endOffset; // End position in paragraph
  final DateTime createdAt;
  final String bookTitle;

  Note({
    required this.id,
    this.highlightId,
    required this.content,
    required this.selectedText,
    required this.paragraphIndex,
    required this.startOffset,
    required this.endOffset,
    required this.createdAt,
    required this.bookTitle,
  });

  // Copy with method
  Note copyWith({
    String? id,
    String? highlightId,
    String? content,
    String? selectedText,
    int? paragraphIndex,
    int? startOffset,
    int? endOffset,
    DateTime? createdAt,
    String? bookTitle,
  }) {
    return Note(
      id: id ?? this.id,
      highlightId: highlightId ?? this.highlightId,
      content: content ?? this.content,
      selectedText: selectedText ?? this.selectedText,
      paragraphIndex: paragraphIndex ?? this.paragraphIndex,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      createdAt: createdAt ?? this.createdAt,
      bookTitle: bookTitle ?? this.bookTitle,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'highlightId': highlightId,
    'content': content,
    'selectedText': selectedText,
    'paragraphIndex': paragraphIndex,
    'startOffset': startOffset,
    'endOffset': endOffset,
    'createdAt': createdAt.toIso8601String(),
    'bookTitle': bookTitle,
  };

  // Create from JSON
  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'],
    highlightId: json['highlightId'],
    content: json['content'],
    selectedText: json['selectedText'],
    paragraphIndex: json['paragraphIndex'],
    startOffset: json['startOffset'],
    endOffset: json['endOffset'],
    createdAt: DateTime.parse(json['createdAt']),
    bookTitle: json['bookTitle'] ?? 'Chưa rõ',
  );
}
