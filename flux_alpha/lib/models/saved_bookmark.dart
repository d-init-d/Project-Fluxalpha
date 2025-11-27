import 'package:flutter/material.dart';

class SavedBookmark {
  final String id;
  final String bookTitle;
  final String chapterLabel;
  final double progressPercent;
  final DateTime createdAt;

  SavedBookmark({
    required this.id,
    required this.bookTitle,
    required this.chapterLabel,
    required this.progressPercent,
    required this.createdAt,
  });

  String get formattedProgress => '${progressPercent.toStringAsFixed(0)}%';

  Color get badgeColor => const Color(0xFF15803D);
}

