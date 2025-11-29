import 'package:flutter/material.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/color_theme.dart';
import '../models/font_theme.dart';
import '../models/book.dart';
import '../providers/book_provider.dart';
import '../utils/toast_helper.dart';

class EditBookMetadataModal extends ConsumerStatefulWidget {
  final Book book;
  final ColorThemeModel theme;
  final FontThemeModel fontTheme;
  final bool isDarkMode;

  const EditBookMetadataModal({
    super.key,
    required this.book,
    required this.theme,
    required this.fontTheme,
    required this.isDarkMode,
  });

  @override
  ConsumerState<EditBookMetadataModal> createState() =>
      _EditBookMetadataModalState();
}

class _EditBookMetadataModalState
    extends ConsumerState<EditBookMetadataModal> {
  late TextEditingController _titleController;
  late TextEditingController _authorController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book.title);
    _authorController = TextEditingController(text: widget.book.author);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_titleController.text.trim().isEmpty) {
      showCustomToast(context, 'Tiêu đề không được để trống', isError: true);
      return;
    }

    try {
      final updatedBook = widget.book.copyWith(
        title: _titleController.text.trim(),
        author: _authorController.text.trim().isEmpty
            ? 'Unknown'
            : _authorController.text.trim(),
      );

      await ref.read(bookListProvider.notifier).updateBook(updatedBook);

      if (mounted) {
        Navigator.of(context).pop();
        showCustomToast(context, 'Đã cập nhật thông tin sách');
      }
    } catch (e) {
      if (mounted) {
        showCustomToast(context, 'Lỗi khi cập nhật: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isDarkMode
        ? const Color(0xFF131B24)
        : widget.theme.cardBackground;
    final textColor = widget.isDarkMode
        ? const Color(0xFFE3DAC9)
        : widget.theme.textColor;
    final borderColor = widget.isDarkMode
        ? const Color(0xFF2D3748)
        : const Color(0xFFC5BCAB);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chỉnh sửa thông tin sách',
                style: TextStyle(fontFamily: widget.fontTheme.serifFont,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(LucideIcons.x, color: textColor, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Title field
          Text(
            'Tiêu đề',
            style: TextStyle(fontFamily: widget.fontTheme.sansFont,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            style: TextStyle(fontFamily: widget.fontTheme.sansFont,
              fontSize: 16,
              color: textColor,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: textColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Author field
          Text(
            'Tác giả',
            style: TextStyle(fontFamily: widget.fontTheme.sansFont,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _authorController,
            style: TextStyle(fontFamily: widget.fontTheme.sansFont,
              fontSize: 16,
              color: textColor,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: textColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: textColor,
                foregroundColor: backgroundColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.check, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Lưu',
                    style: TextStyle(fontFamily: widget.fontTheme.sansFont,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


