import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import '../utils/path_helper.dart';

/// Book metadata extracted from local files
class LocalBookMetadata {
  final String title;
  final String author;
  final String? coverFilePath; // Path to saved cover image file
  final int? totalPages;

  LocalBookMetadata({
    required this.title,
    required this.author,
    this.coverFilePath,
    this.totalPages,
  });
}

/// Service to extract metadata from local EPUB and PDF files
class LocalMetadataService {
  /// Saves cover image bytes to disk and returns the file path
  static Future<String?> _saveCoverToDisk(
    Uint8List? coverBytes,
    String bookId,
  ) async {
    if (coverBytes == null || coverBytes.isEmpty) {
      debugPrint('[Cover] No cover bytes to save');
      return null;
    }

    try {
      // Ensure the covers directory exists
      await PathHelper.ensureDirectoriesExist();
      final coversDir = Directory(PathHelper.getCoversDirectory());

      // Double-check directory exists before writing
      if (!await coversDir.exists()) {
        debugPrint('[Cover] Creating covers directory: ${coversDir.path}');
        await coversDir.create(recursive: true);
      }

      // Determine file extension from image data
      String extension = 'jpg';
      if (coverBytes.length >= 4) {
        // Check PNG signature
        if (coverBytes[0] == 0x89 &&
            coverBytes[1] == 0x50 &&
            coverBytes[2] == 0x4E &&
            coverBytes[3] == 0x47) {
          extension = 'png';
        }
        // JPEG signature
        else if (coverBytes[0] == 0xFF && coverBytes[1] == 0xD8) {
          extension = 'jpg';
        }
      }

      final coverFile = File('${coversDir.path}/$bookId.$extension');
      await coverFile.writeAsBytes(coverBytes);

      return coverFile.path;
    } catch (e) {
      debugPrint('Error saving cover to disk: $e');
      return null;
    }
  }

  /// Extracts metadata from an EPUB file
  static Future<LocalBookMetadata> extractEpubMetadata(
    String filePath,
    String bookId,
  ) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();

      // EPUB is a ZIP archive, extract it
      final archive = ZipDecoder().decodeBytes(bytes);

      // Find and parse OPF file for metadata
      String? opfContent;
      for (final file in archive) {
        if (file.name.endsWith('.opf')) {
          opfContent = String.fromCharCodes(file.content as List<int>);
          break;
        }
      }

      // Extract title and author from OPF (simplified parsing)
      String title = '';
      String author = 'Unknown';

      if (opfContent != null) {
        // Simple XML parsing for title
        final titleMatch = RegExp(
          r'<dc:title[^>]*>([^<]+)</dc:title>',
        ).firstMatch(opfContent);
        if (titleMatch != null) {
          title = titleMatch.group(1)?.trim() ?? '';
        }

        // Simple XML parsing for author
        final authorMatch = RegExp(
          r'<dc:creator[^>]*>([^<]+)</dc:creator>',
        ).firstMatch(opfContent);
        if (authorMatch != null) {
          author = authorMatch.group(1)?.trim() ?? 'Unknown';
        }
      }

      // Fallback to filename if title is empty
      if (title.isEmpty) {
        final fileName = filePath.split(Platform.pathSeparator).last;
        title = fileName.substring(0, fileName.lastIndexOf('.'));
      }

      // Extract cover image with improved logic
      Uint8List? coverBytes;
      try {
        // Strategy 1: Look for metadata meta name="cover"
        String? coverId;
        if (opfContent != null) {
          // Try with double quotes first
          var coverMetaMatch = RegExp(
            r'<meta[^>]*name="cover"[^>]*content="([^"]+)"',
            caseSensitive: false,
          ).firstMatch(opfContent);
          
          // If not found, try with single quotes
          coverMetaMatch ??= RegExp(
              r"<meta[^>]*name='cover'[^>]*content='([^']+)'",
              caseSensitive: false,
            ).firstMatch(opfContent);
          
          if (coverMetaMatch != null) {
            coverId = coverMetaMatch.group(1);
            debugPrint('[Cover] Found cover ID from meta tag: $coverId');
          }
        }

        // Strategy 2: Look for manifest items with id containing "cover" (case insensitive)
        if (coverId == null && opfContent != null) {
          final manifestMatches = RegExp(
            r'<item id="([^"]+)"[^>]*href="([^"]+)"',
            caseSensitive: false,
          ).allMatches(opfContent);
          
          for (final match in manifestMatches) {
            final id = match.group(1)?.toLowerCase() ?? '';
            if (id.contains('cover')) {
              coverId = match.group(1);
              debugPrint('[Cover] Found cover ID from manifest: $coverId');
              break;
            }
          }
        }

        // Strategy 3: If we have a cover ID, find the file in manifest
        String? coverHref;
        if (coverId != null && opfContent != null) {
          final escapedCoverId = coverId.replaceAll(RegExp(r'[.*+?^${}()|[\]\\]'), r'\$&');
          final manifestMatch = RegExp(
            r'<item id="' + escapedCoverId + r'"[^>]*href="([^"]+)"',
            caseSensitive: false,
          ).firstMatch(opfContent);
          if (manifestMatch != null) {
            coverHref = manifestMatch.group(1);
            debugPrint('[Cover] Found cover href: $coverHref');
          }
        }

        // Find cover image in archive
        if (coverHref != null) {
          // Normalize path separators
          final normalizedHref = coverHref.replaceAll('\\', '/');
          for (final file in archive) {
            final normalizedName = file.name.replaceAll('\\', '/');
            if (normalizedName.endsWith(normalizedHref) ||
                normalizedName.contains(normalizedHref)) {
              coverBytes = file.content;
              debugPrint('[Cover] Found cover image: ${file.name}');
              break;
            }
          }
        }

        // Strategy 4: Fallback - Look for first image in images/ folder
        if (coverBytes == null) {
          debugPrint('[Cover] Trying fallback: looking for first image in images/ folder');
          final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
          for (final file in archive) {
            final name = file.name.toLowerCase();
            if ((name.contains('images/') || name.contains('image/')) &&
                imageExtensions.any((ext) => name.endsWith(ext))) {
              coverBytes = file.content;
              debugPrint('[Cover] Found fallback cover image: ${file.name}');
              break;
            }
          }
        }

        // Strategy 5: Last resort - any image file with "cover" in name
        if (coverBytes == null) {
          debugPrint('[Cover] Trying last resort: any file with "cover" in name');
          for (final file in archive) {
            final name = file.name.toLowerCase();
            if (name.contains('cover') &&
                (name.endsWith('.jpg') ||
                    name.endsWith('.jpeg') ||
                    name.endsWith('.png') ||
                    name.endsWith('.gif') ||
                    name.endsWith('.webp'))) {
              coverBytes = file.content;
              debugPrint('[Cover] Found cover by name match: ${file.name}');
              break;
            }
          }
        }
      } catch (e) {
        debugPrint('Error extracting EPUB cover: $e');
      }

      // Save cover to disk and get file path
      final coverFilePath = await _saveCoverToDisk(coverBytes, bookId);

      return LocalBookMetadata(
        title: title,
        author: author,
        coverFilePath: coverFilePath,
        totalPages: null, // EPUB doesn't have fixed pages
      );
    } catch (e) {
      debugPrint('Error extracting EPUB metadata: $e');
      // Fallback to filename
      final fileName = filePath.split(Platform.pathSeparator).last;
      final titleWithoutExt = fileName.substring(0, fileName.lastIndexOf('.'));
      return LocalBookMetadata(
        title: titleWithoutExt,
        author: 'Unknown',
        coverFilePath: null,
        totalPages: null,
      );
    }
  }

  /// Extracts metadata from a PDF file
  static Future<LocalBookMetadata> extractPdfMetadata(
    String filePath,
    String bookId,
  ) async {
    try {
      // Extract title from filename (PDFs don't always have embedded metadata)
      final fileName = filePath.split(Platform.pathSeparator).last;
      final title = fileName.substring(0, fileName.lastIndexOf('.'));

      // For PDF, we'll use filename as title
      // PDF page count and cover rendering would require additional packages
      // For now, we'll keep it simple
      Uint8List? coverBytes;
      int? totalPages;

      // Save cover to disk if available
      final coverFilePath = await _saveCoverToDisk(coverBytes, bookId);

      return LocalBookMetadata(
        title: title,
        author: 'Unknown', // PDFs often don't have author in metadata
        coverFilePath: coverFilePath,
        totalPages: totalPages,
      );
    } catch (e) {
      debugPrint('Error extracting PDF metadata: $e');
      // Fallback to filename
      final fileName = filePath.split(Platform.pathSeparator).last;
      final titleWithoutExt = fileName.substring(0, fileName.lastIndexOf('.'));
      return LocalBookMetadata(
        title: titleWithoutExt,
        author: 'Unknown',
        coverFilePath: null,
        totalPages: null,
      );
    }
  }

  /// Extracts metadata based on file extension
  static Future<LocalBookMetadata> extractMetadata(
    String filePath,
    String bookId,
  ) async {
    final extension = filePath.split('.').last.toLowerCase();

    if (extension == 'epub') {
      return await extractEpubMetadata(filePath, bookId);
    } else if (extension == 'pdf') {
      return await extractPdfMetadata(filePath, bookId);
    } else {
      // Fallback for unknown file types
      final fileName = filePath.split(Platform.pathSeparator).last;
      final titleWithoutExt = fileName.substring(0, fileName.lastIndexOf('.'));
      return LocalBookMetadata(
        title: titleWithoutExt,
        author: 'Unknown',
        coverFilePath: null,
        totalPages: null,
      );
    }
  }
}
