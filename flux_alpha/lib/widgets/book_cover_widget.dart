import 'dart:io';
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/color_theme.dart';
import 'success_ribbon.dart';

// Note: Nếu muốn dùng ảnh thay vì vector, file gốc nằm ở: assets/images/bookmark_backup_ref.png

/// Reusable book cover widget with consistent styling across the app.
/// Displays book cover image with optional bookmark ribbon for read books.
class BookCoverWidget extends StatelessWidget {
  /// The book to display
  final Book book;

  /// Theme for styling
  final ColorThemeModel theme;

  /// Optional custom border radius (defaults to 10)
  final double? borderRadius;

  /// Optional overlay widgets to display on top of the cover
  final List<Widget>? overlayWidgets;

  const BookCoverWidget({
    super.key,
    required this.book,
    required this.theme,
    this.borderRadius,
    this.overlayWidgets,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? 10.0;

    // Determine cover image
    ImageProvider? coverImage;
    if (book.coverFilePath != null && book.coverFilePath!.isNotEmpty) {
      final coverFile = File(book.coverFilePath!);
      if (coverFile.existsSync()) {
        coverImage = FileImage(coverFile);
      }
    }

    return AspectRatio(
      aspectRatio: 2 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        child: Container(
          decoration: BoxDecoration(
            color: book.color,
            image: coverImage != null
                ? DecorationImage(
                    image: coverImage,
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      debugPrint('Error loading cover image: $exception');
                    },
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Custom overlay widgets (if provided)
              if (overlayWidgets != null) ...overlayWidgets!,

              // Bookmark ribbon for read books
              if (book.isRead)
                Positioned(
                  top: 0,
                  right: 0,
                  child: SuccessRibbon(
                    size: const Size(28, 36),
                    backgroundColor: theme.accentBg,
                    borderColor: theme.accentBg.withOpacity(0.3),
                    iconColor: Colors.white,
                    iconSize: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
