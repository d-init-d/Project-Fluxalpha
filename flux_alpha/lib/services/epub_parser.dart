import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;

import '../models/chapter_data.dart';

// Cached regex patterns for better performance
class _RegexCache {
  static final RegExp _manifestItemRegex = RegExp(
    r'<item\s+id="([^"]+)"[^>]*href="([^"]+)"',
    caseSensitive: false,
  );
  
  static final RegExp _manifestTitleRegex = RegExp(
    r'<item\s+[^>]*href="([^"]+)"[^>]*title="([^"]+)"',
    caseSensitive: false,
  );
  
  static final RegExp _spineItemRefRegex = RegExp(
    r'<itemref\s+idref="([^"]+)"',
    caseSensitive: false,
  );
  
  static final RegExp _spineTocRegex = RegExp(
    r'<spine[^>]*toc="([^"]+)"',
    caseSensitive: false,
  );
  
  static final RegExp _htmlExtensionRegex = RegExp(
    r'\.x?html$',
    caseSensitive: false,
  );
  
  static final RegExp _chapterHeadingRegex = RegExp(
    r'^(chương|chuong|chapter|section|lời nói đầu|loi noi dau)',
    caseSensitive: false,
  );
  
  static RegExp get manifestItem => _manifestItemRegex;
  static RegExp get manifestTitle => _manifestTitleRegex;
  static RegExp get spineItemRef => _spineItemRefRegex;
  static RegExp get spineToc => _spineTocRegex;
  static RegExp get htmlExtension => _htmlExtensionRegex;
  static RegExp get chapterHeading => _chapterHeadingRegex;
}

Future<List<ChapterData>> parseEpubInBackground(String filePath) async {
  try {
    final file = File(filePath);
    if (!await file.exists()) {
      debugPrint('parseEpubInBackground: File not found at $filePath');
      return [];
    }

    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final opfData = _findOpfFile(archive);
    if (opfData == null) {
      debugPrint('parseEpubInBackground: OPF file not found');
      return [];
    }

    final manifestMap = _buildManifestMap(opfData.content);
    final manifestTitles = _buildManifestTitleMap(opfData.content);
    final spine = _buildSpineOrder(opfData.content);
    final navLabels = _extractNavLabels(archive, opfData, manifestMap);

    final chapters = <ChapterData>[];
    for (final idref in spine) {
      final href = manifestMap[idref];
      if (href == null) continue;

      final normalizedHref = href.replaceAll('\\', '/');
      final fullPath = '${opfData.basePath}$normalizedHref';

      final archiveFile = _findArchiveFile(archive, fullPath, normalizedHref);
      if (archiveFile == null) continue;

      try {
        final contentBytes = archiveFile.content as List<int>;
        final decodedContent = utf8.decode(contentBytes, allowMalformed: true);
        if (decodedContent.trim().isEmpty) continue;

        final normalizedKey = normalizedHrefForComparison(normalizedHref: href);
        final navLabel = navLabels[normalizedKey];
        final manifestTitle = manifestTitles[normalizedKey];
        final derivedTitle = _deriveChapterTitle(
          href: href,
          index: chapters.length + 1,
          navLabel: navLabel ?? manifestTitle,
          htmlContent: decodedContent,
        );
        final isFrontMatter = _isFrontMatterTitle(derivedTitle);
        final translatedTitle = _translateSpecialTitle(derivedTitle);

        chapters.add(
          ChapterData(
            title: translatedTitle,
            content: decodedContent,
            showNumber: !isFrontMatter,
          ),
        );
      } catch (e) {
        debugPrint('parseEpubInBackground: error decoding chapter: $e');
      }
    }

    return chapters;
  } catch (e, stackTrace) {
    debugPrint('parseEpubInBackground error: $e\n$stackTrace');
    return [];
  }
}

class _OpfData {
  final String content;
  final String basePath;

  _OpfData(this.content, this.basePath);
}

_OpfData? _findOpfFile(Archive archive) {
  for (final file in archive) {
    if (file.name.toLowerCase().endsWith('.opf')) {
      final content = utf8.decode(file.content as List<int>, allowMalformed: true);
      final basePath = file.name.contains('/')
          ? file.name.substring(0, file.name.lastIndexOf('/') + 1)
          : '';
      return _OpfData(content, basePath);
    }
  }
  return null;
}

Map<String, String> _buildManifestMap(String opfContent) {
  final manifestMatches = _RegexCache.manifestItem.allMatches(opfContent);

  final manifestMap = <String, String>{};
  for (final match in manifestMatches) {
    final id = match.group(1);
    final href = match.group(2);
    if (id != null && href != null) {
      manifestMap[id] = href;
    }
  }
  return manifestMap;
}

Map<String, String> _buildManifestTitleMap(String opfContent) {
  final manifestMatches = _RegexCache.manifestTitle.allMatches(opfContent);

  final titleMap = <String, String>{};
  for (final match in manifestMatches) {
    final href = match.group(1);
    final title = match.group(2);
    if (href == null || title == null) continue;
    titleMap[normalizedHrefForComparison(normalizedHref: href)] =
        _sanitizeTitle(title);
  }
  return titleMap;
}

List<String> _buildSpineOrder(String opfContent) {
  final spineMatches = _RegexCache.spineItemRef.allMatches(opfContent);

  return spineMatches.map((match) => match.group(1)).whereType<String>().toList();
}

ArchiveFile? _findArchiveFile(
  Archive archive,
  String fullPath,
  String normalizedHref,
) {
  for (final file in archive) {
    final normalizedName = file.name.replaceAll('\\', '/');
    if (normalizedName == fullPath || normalizedName.endsWith(normalizedHref)) {
      return file;
    }
  }
  return null;
}

Map<String, String> _extractNavLabels(
  Archive archive,
  _OpfData opfData,
  Map<String, String> manifestMap,
) {
  final labels = <String, String>{};

  String? tocHref;
  final tocMatch = _RegexCache.spineToc.firstMatch(opfData.content);
  if (tocMatch != null) {
    tocHref = manifestMap[tocMatch.group(1)!];
  }
  tocHref ??= _findFirstNcxHref(manifestMap);
  if (tocHref == null) return labels;

  final normalizedTocHref = tocHref.replaceAll('\\', '/');
  final fullPath = '${opfData.basePath}$normalizedTocHref';
  final tocFile =
      _findArchiveFile(archive, fullPath, normalizedTocHref);
  if (tocFile == null) return labels;

  try {
    final tocContent =
        utf8.decode(tocFile.content as List<int>, allowMalformed: true);
    final document = html_parser.parse(tocContent);
    final navPoints = document.getElementsByTagName('navpoint');
    final tocDirectory = _extractDirectory(normalizedTocHref);

    for (final navPoint in navPoints) {
      final labelsNodes = navPoint.getElementsByTagName('text');
      final contentNodes = navPoint.getElementsByTagName('content');
      if (labelsNodes.isEmpty || contentNodes.isEmpty) continue;

      final rawLabel = _sanitizeTitle(labelsNodes.first.text);
      if (rawLabel.isEmpty) continue;

      final src = contentNodes.first.attributes['src'];
      if (src == null || src.isEmpty) continue;

      final withoutFragment = src.split('#').first;
      final normalizedSrc = withoutFragment.replaceAll('\\', '/');
      final resolved =
          _normalizeRelativePath(tocDirectory, normalizedSrc);
      final normalizedKey =
          normalizedHrefForComparison(normalizedHref: resolved);
      labels[normalizedKey] = rawLabel;
    }
  } catch (e) {
    debugPrint('parseEpubInBackground: unable to parse toc: $e');
  }

  return labels;
}

String? _findFirstNcxHref(Map<String, String> manifestMap) {
  for (final entry in manifestMap.entries) {
    if (entry.value.toLowerCase().endsWith('.ncx')) {
      return entry.value;
    }
  }
  return null;
}

String normalizedHrefForComparison({required String normalizedHref}) {
  return normalizedHref.replaceAll('\\', '/').trim();
}

String _extractDirectory(String path) {
  final normalized = path.replaceAll('\\', '/');
  final lastSlash = normalized.lastIndexOf('/');
  if (lastSlash == -1) {
    return '';
  }
  return normalized.substring(0, lastSlash + 1);
}

String _normalizeRelativePath(String baseDir, String targetPath) {
  final buffer = <String>[];
  final combined = (baseDir + targetPath).split('/');
  for (final segment in combined) {
    if (segment.isEmpty || segment == '.') continue;
    if (segment == '..') {
      if (buffer.isNotEmpty) {
        buffer.removeLast();
      }
      continue;
    }
    buffer.add(segment);
  }
  return buffer.join('/');
}

String _deriveChapterTitle({
  required String href,
  required int index,
  String? navLabel,
  required String htmlContent,
}) {
  final metadataTitle = _sanitizeTitle(navLabel);
  if (metadataTitle.isNotEmpty) {
    return metadataTitle;
  }

  final heading = _extractHeadingFromHtml(htmlContent);
  if (heading != null && heading.isNotEmpty) {
    return heading;
  }

  final fileName = href.split('/').last;
  final withoutExtension = fileName.replaceAll(
    _RegexCache.htmlExtension,
    '',
  );
  final cleaned = withoutExtension.replaceAll('_', ' ').trim();
  if (cleaned.isEmpty) {
    return 'Chương $index';
  }
  return cleaned[0].toUpperCase() + cleaned.substring(1);
}

String? _extractHeadingFromHtml(String htmlContent) {
  final document = html_parser.parse(htmlContent);
  final body = document.body;
  if (body == null) return null;

  const selectors = [
    'h1',
    'h2',
    '.chapter-title',
    '.ChapterTitle',
    '.chapterTitle',
  ];

  for (final selector in selectors) {
    final element = body.querySelector(selector);
    if (element == null) continue;
    final text = element.text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isNotEmpty) {
      return text;
    }
  }

  final fallbackElements = body.querySelectorAll('p, div, span, h3, h4');
  for (final element in fallbackElements) {
    final text = element.text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) continue;
    if (_looksLikeChapterHeading(text)) {
      return text;
    }
  }
  return null;
}

bool _looksLikeChapterHeading(String text) {
  final normalized = text.toLowerCase();
  return _RegexCache.chapterHeading.hasMatch(normalized);
}

String _sanitizeTitle(String? rawTitle) {
  if (rawTitle == null) return '';
  final unescaped = html_parser.parseFragment(rawTitle).text;
  if (unescaped == null) return '';
  return unescaped.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _translateSpecialTitle(String title) {
  final normalized = title.toLowerCase();
  for (final entry in _specialTitleTranslations.entries) {
    if (normalized.contains(entry.key)) {
      return entry.value;
    }
  }
  return title;
}

bool _isFrontMatterTitle(String title) {
  final normalized = title.toLowerCase();
  for (final keyword in _frontMatterKeywords) {
    if (normalized.contains(keyword)) {
      return true;
    }
  }
  return false;
}

const Map<String, String> _specialTitleTranslations = {
  'cover': 'Bìa',
  'front cover': 'Bìa trước',
  'back cover': 'Bìa sau',
  'jacket': 'Giới thiệu',
  'titlepage': 'Trang tiêu đề',
  'title page': 'Trang tiêu đề',
};

const List<String> _frontMatterKeywords = [
  'cover',
  'front cover',
  'back cover',
  'jacket',
  'titlepage',
  'title page',
];

