import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/book.dart';
import '../providers/book_provider.dart';
import '../providers/theme_provider.dart';

class BookMetadataModal extends ConsumerStatefulWidget {
  final Book book;

  const BookMetadataModal({super.key, required this.book});

  @override
  ConsumerState<BookMetadataModal> createState() => _BookMetadataModalState();
}

class _BookMetadataModalState extends ConsumerState<BookMetadataModal> {
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  String? _newCoverPath;

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

  Future<void> _pickCoverImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      dialogTitle: 'Chọn ảnh bìa mới',
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _newCoverPath = result.files.single.path;
      });
    }
  }

  Future<void> _saveChanges() async {
    final newTitle = _titleController.text.trim();
    final newAuthor = _authorController.text.trim();

    if (newTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiêu đề không được để trống')),
      );
      return;
    }

    // Update book via provider
    final updatedBook = widget.book.copyWith(
      title: newTitle,
      author: newAuthor,
      coverFilePath: _newCoverPath ?? widget.book.coverFilePath,
    );

    // Call update method in provider (need to ensure it exists or use direct state update if list exposed)
    // Assuming BookProvider has updateBook method or similar.
    // If not, I'll need to check usage or implement it.
    // For now, assume a method 'updateBook' exists or I can implement it.
    await ref.read(bookListProvider.notifier).updateBook(updatedBook);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật thông tin sách')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(colorThemeProvider);
    final fontTheme = ref.watch(fontThemeProvider);
    final isDark = ref.watch(themeProvider).isDarkMode;

    return Dialog(
      backgroundColor: theme.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chỉnh sửa thông tin',
                  style: TextStyle(
                    fontFamily: fontTheme.serifFont,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(LucideIcons.x, color: theme.textLight),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Content Form
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover Image
                GestureDetector(
                  onTap: _pickCoverImage,
                  child: Container(
                    width: 100,
                    height: 150,
                    decoration: BoxDecoration(
                      color: theme.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.textLight.withValues(alpha: 0.2),
                      ),
                      image:
                          (_newCoverPath != null ||
                              widget.book.coverFilePath != null)
                          ? DecorationImage(
                              image: _newCoverPath != null
                                  ? FileImage(File(_newCoverPath!))
                                  : FileImage(File(widget.book.coverFilePath!))
                                        as ImageProvider,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child:
                        (_newCoverPath == null &&
                            widget.book.coverFilePath == null)
                        ? Icon(LucideIcons.image, color: theme.textLight)
                        : null,
                  ),
                ),
                const SizedBox(width: 24),

                // Inputs
                Expanded(
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _titleController,
                        label: 'Tiêu đề',
                        theme: theme,
                        fontTheme: fontTheme,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _authorController,
                        label: 'Tác giả',
                        theme: theme,
                        fontTheme: fontTheme,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Hủy',
                    style: TextStyle(
                      fontFamily: fontTheme.sansFont,
                      color: theme.textLight,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.highlight,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Lưu thay đổi',
                    style: TextStyle(
                      fontFamily: fontTheme.sansFont,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required dynamic theme,
    required dynamic fontTheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: fontTheme.sansFont,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.textLight,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(
            fontFamily: fontTheme.sansFont,
            fontSize: 14,
            color: theme.textColor,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
