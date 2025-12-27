import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import '../models/chapter_data.dart';

/// Wrapper class for passing data to Isolate
class _EpubParseParams {
  final String filePath;
  
  _EpubParseParams(this.filePath);
}

/// Top-level function for Isolate (must be top-level or static)
Future<List<ChapterData>> _parseEpubWorker(_EpubParseParams params) async {
  try {
    final file = File(params.filePath);
    if (!await file.exists()) {
      debugPrint('[Isolate] parseEpub: File not found at ${params.filePath}');
      return [];
    }

    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Find OPF file
    final opfData = _findOpfFileWorker(archive);
    if (opfData == null) {
      debugPrint('[Isolate] parseEpub: OPF file not found');
      return [];
    }

    final manifestMap = _buildManifestMapWorker(opfData.content);
    final manifestTitles = _buildManifestTitleMapWorker(opfData.content);
    final spine = _buildSpineOrderWorker(opfData.content);
    final navLabels = _extractNavLabelsWorker(archive, opfData, manifestMap);

    final chapters = <ChapterData>[];
    for (final idref in spine) {
      final href = manifestMap[idref];
      if (href == null) continue;

      final normalizedHref = href.replaceAll('\\', '/');
      final fullPath = '${opfData.basePath}$normalizedHref';

      final archiveFile = _findArchiveFileWorker(archive, fullPath, normalizedHref);
      if (archiveFile == null) continue;

      try {
        final contentBytes = archiveFile.content as List<int>;
        final decodedContent = utf8.decode(contentBytes, allowMalformed: true);
        if (decodedContent.trim().isEmpty) continue;

        final normalizedKey = _normalizedHrefForComparisonWorker(normalizedHref: href);
        final navLabel = navLabels[normalizedKey];
        final manifestTitle = manifestTitles[normalizedKey];
        final derivedTitle = _deriveChapterTitleWorker(
          href: href,
          index: chapters.length + 1,
          navLabel: navLabel ?? manifestTitle,
          htmlContent: decodedContent,
        );

        chapters.add(
          ChapterData(
            id: idref,
            title: derivedTitle,
            content: decodedContent,
            href: href,
          ),
        );
      } catch (e) {
        debugPrint('[Isolate] Error processing chapter $idref: $e');
        continue;
      }
    }

    debugPrint('[Isolate] parseEpub: Successfully parsed ${chapters.length} chapters');
    return chapters;
  } catch (e) {
    debugPrint('[Isolate] parseEpub fatal error: $e');
    return [];
  }
}

/// Optimized EPUB parser using Isolate for performance
class OptimizedEpubParser {
  /// Parse EPUB file in separate Isolate to avoid blocking UI
  static Future<List<ChapterData>> parseEpubInIsolate(String filePath) async {
    try {
      debugPrint('[Parser] Starting EPUB parsing in Isolate: $filePath');
      
      final params = _EpubParseParams(filePath);
      final chapters = await compute(_parseEpubWorker, params);
      
      debugPrint('[Parser] Isolate parsing completed: ${chapters.length} chapters');
      return chapters;
    } catch (e) {
      debugPrint('[Parser] Error in parseEpubInIsolate: $e');
      return [];
    }
  }
}

// ========== Worker Helper Functions (must be top-level) ==========

class _OpfData {
  final String content;
  final String basePath;
  
  _OpfData(this.content, this.basePath);
}

_OpfData? _findOpfFileWorker(Archive archive) {
  for (final file in archive) {
    if (file.name.endsWith('.opf')) {
      final content = String.fromCharCodes(file.content as List<int>);
      final basePath = file.name.substring(0, file.name.lastIndexOf('/') + 1);
      return _OpfData(content, basePath);
    }
  }
  return null;
}

Map<String, String> _buildManifestMapWorker(String opfContent) {
  final manifestMap = <String, String>{};
  final manifestRegex = RegExp(
    r'<item\s+id="([^"]+)"[^>]*href="([^"]+)"',
    caseSensitive: false,
  );
  
  for (final match in manifestRegex.allMatches(opfContent)) {
    final id = match.group(1);
    final href = match.group(2);
    if (id != null && href != null) {
      manifestMap[id] = href;
    }
  }
  
  return manifestMap;
}

Map<String, String> _buildManifestTitleMapWorker(String opfContent) {
  final titleMap = <String, String>{};
  final titleRegex = RegExp(
    r'<item\s+[^>]*href="([^"]+)"[^>]*title="([^"]+)"',
    caseSensitive: false,
  );
  
  for (final match in titleRegex.allMatches(opfContent)) {
    final href = match.group(1);
    final title = match.group(2);
    if (href != null && title != null) {
      final normalized = _normalizedHrefForComparisonWorker(normalizedHref: href);
      titleMap[normalized] = title;
    }
  }
  
  return titleMap;
}

List<String> _buildSpineOrderWorker(String opfContent) {
  final spine = <String>[];
  final spineRegex = RegExp(
    r'<itemref\s+idref="([^"]+)"',
    caseSensitive: false,
  );
  
  for (final match in spineRegex.allMatches(opfContent)) {
    final idref = match.group(1);
    if (idref != null) {
      spine.add(idref);
    }
  }
  
  return spine;
}

Map<String, String> _extractNavLabelsWorker(
  Archive archive,
  _OpfData opfData,
  Map<String, String> manifestMap,
) {
  final navLabels = <String, String>{};
  
  // Find TOC file
  final tocRegex = RegExp(r'<spine[^>]*toc="([^"]+)"', caseSensitive: false);
  final tocMatch = tocRegex.firstMatch(opfData.content);
  
  if (tocMatch != null) {
    final tocId = tocMatch.group(1);
    final tocHref = manifestMap[tocId];
    
    if (tocHref != null) {
      final normalizedHref = tocHref.replaceAll('\\', '/');
      final fullPath = '${opfData.basePath}$normalizedHref';
      final tocFile = _findArchiveFileWorker(archive, fullPath, normalizedHref);
      
      if (tocFile != null) {
        final tocContent = String.fromCharCodes(tocFile.content as List<int>);
        final navPointRegex = RegExp(
          r'<navPoint[^>]*>.*?<text>([^<]+)</text>.*?<content\s+src="([^"#]+)',
          caseSensitive: false,
          dotAll: true,
        );
        
        for (final match in navPointRegex.allMatches(tocContent)) {
          final label = match.group(1)?.trim();
          final src = match.group(2);
          
          if (label != null && src != null) {
            final normalized = _normalizedHrefForComparisonWorker(normalizedHref: src);
            navLabels[normalized] = label;
          }
        }
      }
    }
  }
  
  return navLabels;
}

ArchiveFile? _findArchiveFileWorker(Archive archive, String fullPath, String normalizedHref) {
  final normalizedFullPath = fullPath.replaceAll('\\', '/');
  
  for (final file in archive) {
    final normalizedName = file.name.replaceAll('\\', '/');
    if (normalizedName == normalizedFullPath || 
        normalizedName.endsWith(normalizedHref) ||
        normalizedName.contains(normalizedHref)) {
      return file;
    }
  }
  
  return null;
}

String _normalizedHrefForComparisonWorker({required String normalizedHref}) {
  return normalizedHref.replaceAll('\\', '/').toLowerCase();
}

String _deriveChapterTitleWorker({
  required String href,
  required int index,
  String? navLabel,
  required String htmlContent,
}) {
  // Priority 1: Use navLabel from TOC
  if (navLabel != null && navLabel.trim().isNotEmpty) {
    return navLabel.trim();
  }
  
  // Priority 2: Extract title from HTML
  try {
    final doc = html_parser.parse(htmlContent);
    
    // Try <title> tag
    final titleElement = doc.querySelector('title');
    if (titleElement != null) {
      final title = titleElement.text.trim();
      if (title.isNotEmpty && title.length < 100) {
        return title;
      }
    }
    
    // Try <h1>, <h2> tags
    for (final tag in ['h1', 'h2', 'h3']) {
      final headingElement = doc.querySelector(tag);
      if (headingElement != null) {
        final heading = headingElement.text.trim();
        if (heading.isNotEmpty && heading.length < 100) {
          return heading;
        }
      }
    }
    
    // Try first <p> if it looks like a chapter title
    final firstP = doc.querySelector('p');
    if (firstP != null) {
      final text = firstP.text.trim();
      final chapterRegex = RegExp(
        r'^(chương|chuong|chapter|section)',
        caseSensitive: false,
      );
      if (chapterRegex.hasMatch(text) && text.length < 100) {
        return text;
      }
    }
  } catch (e) {
    debugPrint('[Isolate] Error extracting title from HTML: $e');
  }
  
  // Priority 3: Derive from filename
  final fileName = href.split('/').last.replaceAll(RegExp(r'\.(x?html|xml)$'), '');
  if (fileName.isNotEmpty && fileName != 'index' && fileName.length < 50) {
    return fileName;
  }
  
  // Fallback: Generic chapter number
  return 'Chương $index';
}
