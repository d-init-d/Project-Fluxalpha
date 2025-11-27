import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:pdfrx/pdfrx.dart';

import '../models/book.dart';
import '../models/chapter_data.dart';
import '../services/epub_parser.dart';
import 'reader_interface.dart';

class BookReaderScreen extends StatefulWidget {
  final Book book;

  const BookReaderScreen({super.key, required this.book});

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ChapterData> _chapters = [];
  final int _currentChapterIndex = 0;

  // Reading Settings

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    try {
      if (widget.book.filePath.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Đường dẫn file không hợp lệ.';
        });
        return;
      }

      final file = File(widget.book.filePath);
      if (!await file.exists()) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'File sách không tồn tại trên thiết bị.';
        });
        return;
      }

      final extension = widget.book.filePath.split('.').last.toLowerCase();

      if (extension == 'epub') {
        await _loadEpub();
      } else if (extension == 'pdf') {
        // PDF will be handled directly in build method
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Định dạng file không được hỗ trợ: $extension';
        });
      }
    } catch (e) {
      debugPrint('Error loading book: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể mở sách: $e';
      });
    }
  }

  Future<void> _loadEpub() async {
    try {
      final result = await compute(parseEpubInBackground, widget.book.filePath);

      if (result.isEmpty) {
        // Fallback: try to open with system default reader
        _openEpubWithSystemReader();
        return;
      }

      if (mounted) {
        setState(() {
          _chapters = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading EPUB: $e');
      // Fallback: try to open with system default reader
      _openEpubWithSystemReader();
    }
  }

  Future<void> _openEpubWithSystemReader() async {
    try {
      final result = await OpenFile.open(widget.book.filePath);
      if (result.type != ResultType.done) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'Không thể mở file EPUB. Vui lòng cài đặt ứng dụng đọc EPUB (ví dụ: Microsoft Edge, Calibre).';
          });
        }
      } else {
        // File opened successfully, close this screen
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('Error opening EPUB with system reader: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không thể mở file EPUB: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final extension = widget.book.filePath.split('.').last.toLowerCase();

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F2E9), // Cream/Beige background
        appBar: AppBar(
          title: Text(widget.book.title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Đang tải sách...',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.book.title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Quay lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (extension == 'pdf') {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F2E9), // Cream/Beige background
        appBar: AppBar(
          title: Text(widget.book.title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: PdfViewer.file(
          widget.book.filePath,
          params: PdfViewerParams(
            onPageChanged: (page) {
              debugPrint('PDF page changed: ${page ?? 0}');
            },
          ),
        ),
      );
    } else if (extension == 'epub') {
      if (_chapters.isEmpty && !_isLoading && _errorMessage == null) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.book.title),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: const Center(
            child: Text('Không tìm thấy nội dung trong file EPUB'),
          ),
        );
      }

      return Scaffold(
        backgroundColor: const Color(0xFFF5F2E9), // Cream/Beige background
        body: ReaderInterface(
          book: widget.book.toJson(),
          chapters: _chapters,
          initialChapterIndex: _currentChapterIndex,
          onClose: () => Navigator.of(context).pop(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(child: Text('Định dạng file không được hỗ trợ')),
    );
  }
}
