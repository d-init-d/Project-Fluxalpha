import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'dart:io';
import '../models/color_theme.dart';
import '../models/font_theme.dart';
import '../models/book.dart';
import '../providers/book_provider.dart';
import '../services/local_metadata_service.dart';
import '../utils/toast_helper.dart';
import '../utils/path_helper.dart';

class UploadBookModal extends ConsumerStatefulWidget {
  final ColorThemeModel theme;
  final FontThemeModel fontTheme;
  final bool isDarkMode;

  const UploadBookModal({
    super.key,
    required this.theme,
    required this.fontTheme,
    required this.isDarkMode,
  });

  @override
  ConsumerState<UploadBookModal> createState() => _UploadBookModalState();
}

class _UploadBookModalState extends ConsumerState<UploadBookModal> {
  List<File> _selectedFiles = [];
  bool _isDragging = false;
  bool _isLoading = false;
  bool _isDragOver = false;

  final List<String> _allowedExtensions = ['pdf', 'epub'];

  // Color palette for books without covers
  final List<Color> _bookColors = [
    const Color(0xFFA62626), // Deep Red
    const Color(0xFFD35400), // Burnt Orange
    const Color(0xFFB7791F), // Ochre/Gold
    const Color(0xFF1E3A8A), // Royal Blue
    const Color(0xFFD69E2E), // Goldenrod
    const Color(0xFF2D3748), // Dark Slate
    const Color(0xFF312E81), // Indigo
    const Color(0xFF059669), // Emerald
    const Color(0xFF7C3AED), // Purple
  ];

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        allowMultiple: true,
      );

      if (result != null) {
        _processFiles(
          result.paths
              .where((path) => path != null)
              .map((path) => File(path!))
              .toList(),
        );
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
      if (mounted) {
        showCustomToast(context, 'Lỗi khi chọn file: $e', isError: true);
      }
    }
  }

  void _processFiles(List<File> files) {
    // Filter only valid extensions
    final validFiles = files.where((file) {
      final extension = file.path.split('.').last.toLowerCase();
      return _allowedExtensions.contains(extension);
    }).toList();

    if (validFiles.isEmpty) {
      if (mounted) {
        showCustomToast(
          context,
          'Không có file hợp lệ. Chỉ hỗ trợ PDF và EPUB',
          isError: true,
        );
      }
      return;
    }

    setState(() {
      _selectedFiles = validFiles;
    });
  }

  Future<void> _handleConfirm() async {
    if (_selectedFiles.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final bookNotifier = ref.read(bookListProvider.notifier);
      final now = DateTime.now();

      // Ensure directories exist
      await PathHelper.ensureDirectoriesExist();
      debugPrint(
        '[Storage] Using library at: ${PathHelper.getLibraryDirectory()}',
      );

      // Create Book instances from selected files
      for (var i = 0; i < _selectedFiles.length; i++) {
        final originalFile = _selectedFiles[i];
        final fileName = originalFile.path.split(Platform.pathSeparator).last;

        // Normalize paths to use consistent separators
        final sourcePath = originalFile.path
            .replaceAll('/', Platform.pathSeparator)
            .replaceAll('\\', Platform.pathSeparator);
        final booksDir = PathHelper.getBooksDirectory()
            .replaceAll('/', Platform.pathSeparator)
            .replaceAll('\\', Platform.pathSeparator);
        final destinationPath = '$booksDir${Platform.pathSeparator}$fileName';

        // Check if source and destination are the same (file already in library)
        final normalizedSource = File(sourcePath).absolute.path;
        final normalizedDest = File(destinationPath).absolute.path;

        if (normalizedSource == normalizedDest) {
          debugPrint(
            '[Upload] File already in library, skipping copy: $fileName',
          );
          // Use existing file path
          final file = File(normalizedSource);

          // Continue with metadata extraction
          final bookId =
              DateTime.now().millisecondsSinceEpoch.toString() + i.toString();
          LocalBookMetadata metadata;
          try {
            metadata = await LocalMetadataService.extractMetadata(
              file.path,
              bookId,
            );
          } catch (e) {
            debugPrint('Error extracting metadata for $fileName: $e');
            final titleWithoutExt = fileName.substring(
              0,
              fileName.lastIndexOf('.'),
            );
            metadata = LocalBookMetadata(
              title: titleWithoutExt,
              author: 'Unknown',
              coverFilePath: null,
              totalPages: null,
            );
          }

          final book = Book(
            id: bookId,
            title: metadata.title,
            author: metadata.author,
            coverFilePath: metadata.coverFilePath,
            filePath: file.path,
            color: _bookColors[i % _bookColors.length],
            uploadDate: now,
            progress: 0.0,
            totalPages: metadata.totalPages ?? 0,
            category: _getCategoryFromExtension(fileName),
          );

          await bookNotifier.addBook(book);
          continue; // Skip to next file
        }

        // Copy file to library with error handling
        File? file;
        try {
          debugPrint(
            '[Upload] Copying file from $normalizedSource to $normalizedDest',
          );
          final copiedFile = await originalFile.copy(destinationPath);
          file = File(copiedFile.path);
          debugPrint('[Upload] File copied successfully: $fileName');
        } on FileSystemException catch (e) {
          debugPrint('[Upload] FileSystemException when copying $fileName: $e');
          debugPrint('[Upload] Error code: ${e.osError?.errorCode}');

          // Check for OS Error 32 (File is locked)
          if (e.osError?.errorCode == 32) {
            if (mounted) {
              showCustomToast(
                context,
                'File đang mở bởi ứng dụng khác. Vui lòng đóng file và thử lại.',
                isError: true,
              );
            }
            // Abort adding this book - don't add broken entry
            continue;
          }

          // Other file system errors
          if (mounted) {
            showCustomToast(
              context,
              'Lỗi khi sao chép file "$fileName": ${e.message}',
              isError: true,
            );
          }
          // Abort adding this book
          continue;
        } catch (e) {
          debugPrint('[Upload] Unexpected error copying $fileName: $e');
          if (mounted) {
            showCustomToast(
              context,
              'Lỗi không mong muốn khi sao chép file "$fileName": $e',
              isError: true,
            );
          }
          // Abort adding this book
          continue;
        }

        // Extract metadata from local file
        final bookId =
            DateTime.now().millisecondsSinceEpoch.toString() + i.toString();
        LocalBookMetadata metadata;
        try {
          metadata = await LocalMetadataService.extractMetadata(
            file.path,
            bookId,
          );
        } catch (e) {
          debugPrint('Error extracting metadata for $fileName: $e');
          // Fallback to filename
          final titleWithoutExt = fileName.substring(
            0,
            fileName.lastIndexOf('.'),
          );
          metadata = LocalBookMetadata(
            title: titleWithoutExt,
            author: 'Unknown',
            coverFilePath: null,
            totalPages: null,
          );
        }

        // Create book with extracted metadata
        final book = Book(
          id: bookId,
          title: metadata.title,
          author: metadata.author,
          coverFilePath: metadata.coverFilePath,
          filePath: file.path,
          color: _bookColors[i % _bookColors.length],
          uploadDate: now,
          progress: 0.0,
          totalPages: metadata.totalPages ?? 0,
          category: _getCategoryFromExtension(fileName),
        );

        // Add book to provider (this automatically saves to SharedPreferences)
        await bookNotifier.addBook(book);
      }

      if (mounted) {
        Navigator.of(context).pop();
        showCustomToast(
          context,
          'Đã thêm ${_selectedFiles.length} sách thành công',
        );
      }
    } catch (e) {
      debugPrint('Error adding books: $e');
      if (mounted) {
        showCustomToast(
          context,
          'Có lỗi xảy ra khi thêm sách: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getCategoryFromExtension(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'PDF';
      case 'epub':
        return 'EPUB';
      default:
        return 'Uncategorized';
    }
  }

  void _handleCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isDarkMode
        ? const Color(0xFF131B24)
        : widget.theme.cardBackground;
    final textColor = widget.isDarkMode
        ? const Color(0xFFE3DAC9)
        : widget.theme.textColor;
    final textLight = widget.isDarkMode
        ? Colors.grey[400]!
        : widget.theme.textLight;
    final borderColor = widget.isDarkMode
        ? const Color(0xFF2D3748)
        : const Color(0xFFC5BCAB);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tải sách lên',
                      style: TextStyle(
                        fontFamily: widget.fontTheme.serifFont,
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hỗ trợ PDF và EPUB',
                      style: TextStyle(
                        fontFamily: widget.fontTheme.sansFont,
                        fontSize: 14,
                        color: textLight,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _handleCancel,
                  icon: Icon(LucideIcons.x, color: textColor, size: 24),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Drag & Drop Area
            DropTarget(
              onDragDone: (detail) {
                setState(() {
                  _isDragOver = false;
                });
                final files = detail.files
                    .map((file) => File(file.path))
                    .toList();
                _processFiles(files);
              },
              onDragEntered: (detail) {
                setState(() {
                  _isDragOver = true;
                });
              },
              onDragExited: (detail) {
                setState(() {
                  _isDragOver = false;
                });
              },
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _pickFiles,
                  borderRadius: BorderRadius.circular(16),
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isDragging = true),
                    onExit: (_) => setState(() => _isDragging = false),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(48),
                      decoration: BoxDecoration(
                        color: _isDragOver
                            ? textColor.withOpacity(0.05)
                            : backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isDragOver
                              ? textColor
                              : (_isDragging
                                    ? textColor.withOpacity(0.6)
                                    : borderColor.withOpacity(0.5)),
                          width: _isDragOver ? 3 : 2,
                          style: BorderStyle.solid,
                          strokeAlign: BorderSide.strokeAlignInside,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Upload Icon
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: textColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              LucideIcons.upload,
                              size: 40,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Main text
                          Text(
                            _selectedFiles.isEmpty
                                ? 'Kéo thả file vào đây'
                                : '${_selectedFiles.length} file đã chọn',
                            style: TextStyle(
                              fontFamily: widget.fontTheme.sansFont,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Sub text
                          Text(
                            'hoặc nhấn để chọn từ thiết bị',
                            style: TextStyle(
                              fontFamily: widget.fontTheme.sansFont,
                              fontSize: 14,
                              color: textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Selected files list (if any)
            if (_selectedFiles.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 120),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _selectedFiles.length,
                  itemBuilder: (context, index) {
                    final file = _selectedFiles[index];
                    final fileName = file.path
                        .split(Platform.pathSeparator)
                        .last;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.fileText,
                            size: 16,
                            color: textLight,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              fileName,
                              style: TextStyle(
                                fontFamily: widget.fontTheme.sansFont,
                                fontSize: 12,
                                color: textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: _handleCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: borderColor, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Hủy',
                      style: TextStyle(
                        fontFamily: widget.fontTheme.sansFont,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Confirm Button
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: (_selectedFiles.isEmpty || _isLoading)
                        ? null
                        : _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: textColor,
                      foregroundColor: backgroundColor,
                      disabledBackgroundColor: textColor.withOpacity(0.3),
                      disabledForegroundColor: backgroundColor.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                backgroundColor,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.check, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Xác nhận',
                                style: TextStyle(
                                  fontFamily: widget.fontTheme.sansFont,
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
          ],
        ),
      ),
    );
  }
}
