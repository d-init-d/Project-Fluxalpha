import 'package:flutter/material.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final String? coverFilePath; // Path to cover image file on disk (nullable)
  final String filePath; // Local path to the book file
  final Color color; // Fallback color when no cover image
  final DateTime uploadDate; // When the book was added
  final double progress; // Reading progress (0.0 to 1.0)
  final int totalPages;
  final int currentPage;
  final String category;
  final DateTime lastRead;
  final bool isRead; // Whether the book has been marked as read

  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.coverFilePath,
    required this.filePath,
    required this.color,
    required this.uploadDate,
    this.progress = 0.0,
    this.totalPages = 0,
    this.currentPage = 0,
    this.category = 'Uncategorized',
    DateTime? lastRead,
    this.isRead = false,
  }) : lastRead = lastRead ?? uploadDate;

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'coverFilePath': coverFilePath,
      'filePath': filePath,
      'colorValue': color.value, // Store color as int
      'uploadDate': uploadDate.toIso8601String(),
      'progress': progress,
      'totalPages': totalPages,
      'currentPage': currentPage,
      'category': category,
      'lastRead': lastRead.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      coverFilePath: json['coverFilePath'] as String?,
      filePath: json['filePath'] as String,
      color: Color(json['colorValue'] as int),
      uploadDate: DateTime.parse(json['uploadDate'] as String),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 0,
      category: json['category'] as String? ?? 'Uncategorized',
      lastRead: json['lastRead'] != null
          ? DateTime.parse(json['lastRead'] as String)
          : DateTime.parse(json['uploadDate'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  // Copy with method for updates
  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? coverFilePath,
    String? filePath,
    Color? color,
    DateTime? uploadDate,
    double? progress,
    int? totalPages,
    int? currentPage,
    String? category,
    DateTime? lastRead,
    bool? isRead,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverFilePath: coverFilePath ?? this.coverFilePath,
      filePath: filePath ?? this.filePath,
      color: color ?? this.color,
      uploadDate: uploadDate ?? this.uploadDate,
      progress: progress ?? this.progress,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      category: category ?? this.category,
      lastRead: lastRead ?? this.lastRead,
      isRead: isRead ?? this.isRead,
    );
  }
}

