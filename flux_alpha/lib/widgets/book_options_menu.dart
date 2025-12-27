import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/color_theme.dart';
import '../models/font_theme.dart';
import '../models/book.dart';
import '../providers/book_provider.dart';
import '../utils/toast_helper.dart';
import 'book_metadata_modal.dart';

class BookOptionsMenu extends ConsumerWidget {
  final Book book;
  final ColorThemeModel theme;
  final FontThemeModel fontTheme;
  final bool isDarkMode;

  const BookOptionsMenu({
    super.key,
    required this.book,
    required this.theme,
    required this.fontTheme,
    required this.isDarkMode,
  });

  void _handleEditInfo(BuildContext context) {
    Navigator.of(context).pop(); // Close options menu
    showDialog(
      context: context,
      builder: (context) => BookMetadataModal(book: book),
    );
  }

  Future<void> _handleToggleReadStatus(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      await ref.read(bookListProvider.notifier).toggleReadStatus(book.id);
      if (context.mounted) {
        Navigator.of(context).pop(); // Close options menu
        showCustomToast(
          context,
          book.isRead ? 'Đã đánh dấu chưa đọc' : 'Đã đánh dấu đã đọc',
        );
      }
    } catch (e) {
      if (context.mounted) {
        showCustomToast(context, 'Lỗi khi cập nhật: $e', isError: true);
      }
    }
  }

  Future<void> _handleToggleFavorite(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      await ref.read(bookListProvider.notifier).toggleFavorite(book.id);
      if (context.mounted) {
        Navigator.of(context).pop(); // Close options menu
        showCustomToast(
          context,
          book.isFavorite ? 'Đã xóa khỏi yêu thích' : 'Đã thêm vào yêu thích',
        );
      }
    } catch (e) {
      if (context.mounted) {
        showCustomToast(context, 'Lỗi khi cập nhật: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backgroundColor = isDarkMode
        ? const Color(0xFF131B24)
        : theme.cardBackground;
    final textColor = isDarkMode ? const Color(0xFFE3DAC9) : theme.textColor;
    final textLight = isDarkMode ? Colors.grey[400]! : theme.textLight;
    final borderColor = isDarkMode
        ? const Color(0xFF2D3748)
        : const Color(0xFFC5BCAB);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Options list
          ListTile(
            leading: Icon(LucideIcons.edit, color: textColor, size: 20),
            title: Text(
              'Sửa thông tin sách',
              style: TextStyle(
                fontFamily: fontTheme.sansFont,
                fontSize: 16,
                color: textColor,
              ),
            ),
            onTap: () => _handleEditInfo(context),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 8,
            ),
          ),

          ListTile(
            leading: Icon(
              book.isRead ? LucideIcons.bookOpen : LucideIcons.bookMarked,
              color: textColor,
              size: 20,
            ),
            title: Text(
              book.isRead ? 'Đánh dấu chưa đọc' : 'Đánh dấu đã đọc',
              style: TextStyle(
                fontFamily: fontTheme.sansFont,
                fontSize: 16,
                color: textColor,
              ),
            ),
            onTap: () => _handleToggleReadStatus(context, ref),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 8,
            ),
          ),

          ListTile(
            leading: Icon(
              book.isFavorite ? LucideIcons.heartOff : LucideIcons.heart,
              color: textColor,
              size: 20,
            ),
            title: Text(
              book.isFavorite ? 'Xóa khỏi yêu thích' : 'Thêm vào yêu thích',
              style: TextStyle(
                fontFamily: fontTheme.sansFont,
                fontSize: 16,
                color: textColor,
              ),
            ),
            onTap: () => _handleToggleFavorite(context, ref),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 8,
            ),
          ),

          Divider(
            color: borderColor.withValues(alpha: 0.5),
            height: 1,
            indent: 24,
            endIndent: 24,
          ),

          ListTile(
            leading: Icon(LucideIcons.trash2, color: Colors.red, size: 20),
            title: Text(
              'Xóa sách',
              style: TextStyle(
                fontFamily: fontTheme.sansFont,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            onTap: () {
              Navigator.of(context).pop('delete');
            },
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 8,
            ),
          ),

          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
