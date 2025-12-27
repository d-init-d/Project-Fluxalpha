import 'package:flutter/material.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/color_theme.dart';
import '../models/font_theme.dart';
import '../models/book.dart';
import '../providers/book_provider.dart';
import '../widgets/upload_book_modal.dart';
import '../widgets/book_cover_widget.dart';
import 'book_reader_screen.dart';
import '../widgets/book_options_menu.dart';
import '../utils/toast_helper.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  final ColorThemeModel theme;
  final FontThemeModel fontTheme;
  final bool isDarkMode;

  const LibraryScreen({
    super.key,
    required this.theme,
    required this.fontTheme,
    required this.isDarkMode,
  });

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _selectedCategory = 'Tất cả';
  final List<String> _categories = [
    'Tất cả',
    'Đang đọc',
    'Đã đọc xong',
    'Yêu thích',
    'Bộ sưu tập',
  ];

  final List<Map<String, dynamic>> _collections = [
    {
      'title': 'Sách kinh điển',
      'count': 12,
      'color': const Color(0xFF2C3E50),
      'preview_images': [
        'https://covers.openlibrary.org/b/id/10523474-L.jpg',
        'https://covers.openlibrary.org/b/id/12678693-L.jpg',
        'https://covers.openlibrary.org/b/id/12833521-L.jpg',
      ],
    },
    {
      'title': 'Phát triển bản thân',
      'count': 8,
      'color': const Color(0xFF27AE60),
      'preview_images': [
        'https://covers.openlibrary.org/b/id/12646271-L.jpg',
        'https://covers.openlibrary.org/b/id/10580430-L.jpg',
      ],
    },
    {
      'title': 'Khoa học viễn tưởng',
      'count': 15,
      'color': const Color(0xFF8E44AD),
      'preview_images': ['https://covers.openlibrary.org/b/id/12833521-L.jpg'],
    },
    {
      'title': 'Lịch sử Việt Nam',
      'count': 5,
      'color': const Color(0xFFC0392B),
      'preview_images': [],
    },
  ];

  // Books are now managed by BookProvider

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : widget.theme.textColor;
    final textLight = widget.isDarkMode
        ? Colors.grey[400]!
        : widget.theme.textLight;

    final borderColor = widget.isDarkMode
        ? const Color(0xFF2D3748)
        : const Color(0xFFC5BCAB);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),

          // Title & Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thư viện của tôi',
                style: TextStyle(
                  fontFamily: widget.fontTheme.serifFont,
                  fontSize: 42,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.theme.textColor, width: 2),
                ),
                child: IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (context) => UploadBookModal(
                        theme: widget.theme,
                        fontTheme: widget.fontTheme,
                        isDarkMode: widget.isDarkMode,
                      ),
                    );
                  },
                  icon: Icon(LucideIcons.plus, color: widget.theme.textColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Consumer(
            builder: (context, ref, child) {
              final totalBooks = ref.watch(bookListProvider).length;
              final currentlyReading = ref
                  .watch(currentlyReadingBooksProvider)
                  .length;
              return Text(
                '$totalBooks cuốn sách • $currentlyReading đang đọc',
                style: TextStyle(
                  fontFamily: widget.fontTheme.sansFont,
                  fontSize: 14,
                  color: textLight,
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          // Import Section Removed
          // _buildImportSection(borderColor, textColor, textLight),
          // const SizedBox(height: 32),

          // Tabs & Filter
          _buildTabsAndFilter(textColor, borderColor),
          const SizedBox(height: 24),

          // Book Grid
          // Content
          _selectedCategory == 'Bộ sưu tập'
              ? _buildCollectionsGrid(textColor, textLight)
              : Consumer(
                  builder: (context, ref, child) {
                    final allBooks = ref.watch(bookListProvider);
                    final books = _getFilteredBooks(allBooks);

                    if (books.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.bookOpen,
                                size: 64,
                                color: textLight,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Chưa có sách nào',
                                style: TextStyle(
                                  fontFamily: widget.fontTheme.serifFont,
                                  fontSize: 20,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Nhấn nút + để thêm sách mới',
                                style: TextStyle(
                                  fontFamily: widget.fontTheme.sansFont,
                                  fontSize: 14,
                                  color: textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 100),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 0.55,
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 32,
                          ),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              final book = books[index];
                              await ref
                                  .read(bookListProvider.notifier)
                                  .markBookOpened(book.id);
                              if (!mounted) return;
                              // Open book reader
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      BookReaderScreen(book: book),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: _buildBookCard(
                              books[index],
                              textColor,
                              textLight,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildTabsAndFilter(Color textColor, Color borderColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Tabs
        Row(
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _selectedCategory = category),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  margin: const EdgeInsets.only(right: 24),
                  padding: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected
                            ? widget.theme.textColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontFamily: widget.fontTheme.sansFont,
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected ? textColor : widget.theme.textLight,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        // Filter & Sort
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(LucideIcons.filter, size: 16, color: textColor),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    'Sắp xếp: Tên A-Z',
                    style: TextStyle(
                      fontFamily: widget.fontTheme.sansFont,
                      fontSize: 12,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(LucideIcons.chevronDown, size: 16, color: textColor),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper method to filter books based on selected category
  List<Book> _getFilteredBooks(List<Book> allBooks) {
    switch (_selectedCategory) {
      case 'Tất cả':
        return allBooks;
      case 'Đang đọc':
        return allBooks.where((book) => !book.isRead).toList();
      case 'Đã đọc xong':
        return allBooks.where((book) => book.isRead).toList();
      case 'Yêu thích':
        return allBooks.where((book) => book.isFavorite).toList();
      default:
        return allBooks;
    }
  }

  Widget _buildBookCard(Book book, Color textColor, Color textLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BookCoverWidget(
          book: book,
          theme: widget.theme,
          overlayWidgets: [
            // Semi-transparent black overlay for read books
            if (book.isRead)
              Container(
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.3)),
              ),
            // Favorite badge
            if (book.isFavorite)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.heart,
                    color: Colors.redAccent,
                    size: 14,
                  ),
                ),
              ),
            // Status badge for completed books
            if (book.progress >= 1.0)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'XONG',
                    style: TextStyle(
                      fontFamily: widget.fontTheme.sansFont,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: TextStyle(
                      fontFamily: widget.fontTheme.serifFont,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    style: TextStyle(
                      fontFamily: widget.fontTheme.sansFont,
                      fontSize: 12,
                      color: textLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 3-dot menu button
            IconButton(
              icon: const Icon(Icons.more_vert, size: 20),
              color: textLight,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                _showBookOptionsMenu(book);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: book.progress,
            backgroundColor: textColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(widget.theme.highlight),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  void _showBookOptionsMenu(Book book) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BookOptionsMenu(
        book: book,
        theme: widget.theme,
        fontTheme: widget.fontTheme,
        isDarkMode: widget.isDarkMode,
      ),
    );

    if (result == 'delete') {
      if (!mounted) return;
      _handleDeleteBook(book);
    }
  }

  Future<void> _handleDeleteBook(Book book) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode
            ? const Color(0xFF131B24)
            : widget.theme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Xóa sách',
          style: TextStyle(
            fontFamily: widget.fontTheme.serifFont,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: widget.isDarkMode
                ? const Color(0xFFE3DAC9)
                : widget.theme.textColor,
          ),
        ),
        content: Text(
          'Bạn có chắc muốn xóa sách này không?',
          style: TextStyle(
            fontFamily: widget.fontTheme.sansFont,
            fontSize: 16,
            color: widget.isDarkMode
                ? Colors.grey[400]
                : widget.theme.textLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Hủy',
              style: TextStyle(
                fontFamily: widget.fontTheme.sansFont,
                fontSize: 16,
                color: widget.isDarkMode
                    ? Colors.grey[400]
                    : widget.theme.textLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              'Đồng ý',
              style: TextStyle(
                fontFamily: widget.fontTheme.sansFont,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;

      try {
        await ref.read(bookListProvider.notifier).deleteBook(book.id);
        if (mounted) {
          showCustomToast(context, 'Đã xóa sách');
        }
      } catch (e) {
        if (mounted) {
          showCustomToast(context, 'Lỗi khi xóa sách: $e', isError: true);
        }
      }
    }
  }

  Widget _buildCollectionsGrid(Color textColor, Color textLight) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: _collections.length,
      itemBuilder: (context, index) {
        return _buildCollectionCard(_collections[index], textColor, textLight);
      },
    );
  }

  Widget _buildCollectionCard(
    Map<String, dynamic> collection,
    Color textColor,
    Color textLight,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                // Preview images stack effect
                if (collection['preview_images'] != null &&
                    (collection['preview_images'] as List).isNotEmpty)
                  ...List.generate(
                    (collection['preview_images'] as List).length > 3
                        ? 3
                        : (collection['preview_images'] as List).length,
                    (index) {
                      return Positioned(
                        left: index * 20.0,
                        top: 0,
                        bottom: 0,
                        width: 60, // Fixed width for book spine look
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(2, 0),
                              ),
                            ],
                            image: DecorationImage(
                              image: NetworkImage(
                                collection['preview_images'][index],
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                if ((collection['preview_images'] as List).isEmpty)
                  Center(
                    child: Icon(
                      LucideIcons.library,
                      size: 40,
                      color: textLight.withOpacity(0.5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            collection['title'],
            style: TextStyle(
              fontFamily: widget.fontTheme.serifFont,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${collection['count']} cuốn sách',
            style: TextStyle(
              fontFamily: widget.fontTheme.sansFont,
              fontSize: 12,
              color: textLight,
            ),
          ),
        ],
      ),
    );
  }
}
