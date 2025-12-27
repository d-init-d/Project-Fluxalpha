import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Backup data structure
class BackupData {
  final String appVersion;
  final DateTime createdAt;
  final List<Map<String, dynamic>> books;
  final Map<String, dynamic> readingPositions;
  final Map<String, dynamic> annotations;
  final Map<String, dynamic> bookmarks;
  final Map<String, dynamic> settings;
  final Map<String, dynamic> readingStats;

  BackupData({
    required this.appVersion,
    required this.createdAt,
    required this.books,
    required this.readingPositions,
    required this.annotations,
    required this.bookmarks,
    required this.settings,
    required this.readingStats,
  });

  Map<String, dynamic> toJson() {
    return {
      'appVersion': appVersion,
      'createdAt': createdAt.toIso8601String(),
      'books': books,
      'readingPositions': readingPositions,
      'annotations': annotations,
      'bookmarks': bookmarks,
      'settings': settings,
      'readingStats': readingStats,
    };
  }

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      appVersion: json['appVersion'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      books: List<Map<String, dynamic>>.from(json['books'] as List),
      readingPositions: json['readingPositions'] as Map<String, dynamic>,
      annotations: json['annotations'] as Map<String, dynamic>,
      bookmarks: json['bookmarks'] as Map<String, dynamic>,
      settings: json['settings'] as Map<String, dynamic>,
      readingStats: json['readingStats'] as Map<String, dynamic>,
    );
  }
}

/// Backup/Restore service
class BackupService {
  static const int maxBackupSizeBytes = 100 * 1024 * 1024; // 100MB

  /// Export all app data to JSON file
  Future<String?> exportBackup() async {
    try {
      debugPrint('[Backup] Starting export...');

      // Get app version
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = packageInfo.version;

      // Collect data from all services
      final books = await _collectBooks();
      final positions = await _collectReadingPositions();
      final annotations = await _collectAnnotations();
      final bookmarks = await _collectBookmarks();
      final settings = await _collectSettings();
      final stats = await _collectReadingStats();

      // Create backup data
      final backup = BackupData(
        appVersion: appVersion,
        createdAt: DateTime.now(),
        books: books,
        readingPositions: positions,
        annotations: annotations,
        bookmarks: bookmarks,
        settings: settings,
        readingStats: stats,
      );

      // Serialize to JSON
      final jsonString = json.encode(backup.toJson());
      final jsonBytes = utf8.encode(jsonString);

      // Check file size
      if (jsonBytes.length > maxBackupSizeBytes) {
        debugPrint('[Backup] Error: Backup size exceeds 100MB');
        throw Exception('Backup quá lớn (> 100MB). Vui lòng liên hệ hỗ trợ.');
      }

      debugPrint('[Backup] Data collected, size: ${jsonBytes.length} bytes');

      // Let user choose save location
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final defaultFileName = 'flux_alpha_backup_$timestamp.json';

      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Lưu backup',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputPath == null) {
        debugPrint('[Backup] User cancelled save');
        return null;
      }

      // Write to file
      final file = File(outputPath);
      await file.writeAsString(jsonString);

      debugPrint('[Backup] Export successful: $outputPath');
      return outputPath;
    } catch (e) {
      debugPrint('[Backup] Export error: $e');
      rethrow;
    }
  }

  /// Import backup from JSON file
  Future<bool> importBackup({required bool mergeData}) async {
    try {
      debugPrint('[Backup] Starting import...');

      // Let user pick backup file
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Chọn file backup',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        debugPrint('[Backup] User cancelled import');
        return false;
      }

      final filePath = result.files.single.path!;
      final file = File(filePath);

      // Validate file size
      final fileSize = await file.length();
      if (fileSize > maxBackupSizeBytes) {
        throw Exception('File backup quá lớn (> 100MB)');
      }

      debugPrint('[Backup] Reading file: $filePath');

      // Read and parse JSON
      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      // Validate backup structure
      _validateBackupStructure(jsonData);

      final backup = BackupData.fromJson(jsonData);

      debugPrint('[Backup] Backup version: ${backup.appVersion}');
      debugPrint('[Backup] Created at: ${backup.createdAt}');

      // Restore data
      if (mergeData) {
        await _mergeBackupData(backup);
      } else {
        await _overwriteBackupData(backup);
      }

      debugPrint('[Backup] Import successful');
      return true;
    } catch (e) {
      debugPrint('[Backup] Import error: $e');
      rethrow;
    }
  }

  /// Validate backup JSON structure
  void _validateBackupStructure(Map<String, dynamic> json) {
    final requiredKeys = [
      'appVersion',
      'createdAt',
      'books',
      'readingPositions',
      'annotations',
      'bookmarks',
      'settings',
      'readingStats',
    ];

    for (final key in requiredKeys) {
      if (!json.containsKey(key)) {
        throw Exception('Invalid backup: missing "$key"');
      }
    }
  }

  // ========== Data Collection ==========

  Future<List<Map<String, dynamic>>> _collectBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final booksJson = prefs.getString('books_list');
    if (booksJson == null) return [];

    final List<dynamic> booksList = json.decode(booksJson);
    return List<Map<String, dynamic>>.from(booksList);
  }

  Future<Map<String, dynamic>> _collectReadingPositions() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final positions = <String, dynamic>{};

    for (final key in keys) {
      if (key.startsWith('reading_position_')) {
        final value = prefs.getString(key);
        if (value != null) {
          positions[key] = json.decode(value);
        }
      }
    }

    return positions;
  }

  Future<Map<String, dynamic>> _collectAnnotations() async {
    final prefs = await SharedPreferences.getInstance();
    final annotationsJson = prefs.getString('saved_annotations');
    if (annotationsJson == null) return {};

    return json.decode(annotationsJson) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _collectBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = prefs.getString('saved_bookmarks');
    if (bookmarksJson == null) return {};

    return json.decode(bookmarksJson) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _collectSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = <String, dynamic>{};

    // Reading settings
    settings['fontSize'] = prefs.getDouble('reading_fontSize');
    settings['lineHeight'] = prefs.getDouble('reading_lineHeight');
    settings['wordSpacing'] = prefs.getDouble('reading_wordSpacing');
    settings['backgroundColor'] = prefs.getInt('reading_backgroundColor');
    settings['fontFamily'] = prefs.getString('reading_fontFamily');

    // Theme settings
    settings['isDarkMode'] = prefs.getBool('theme_isDarkMode');
    settings['colorThemeId'] = prefs.getString('theme_colorThemeId');
    settings['fontThemeId'] = prefs.getString('theme_fontThemeId');

    // Library path
    settings['libraryPath'] = prefs.getString('custom_library_path');

    return settings;
  }

  Future<Map<String, dynamic>> _collectReadingStats() async {
    final prefs = await SharedPreferences.getInstance();
    final stats = <String, dynamic>{};

    // Daily stats
    stats['dailyReadingTime'] = prefs.getInt('stats_dailyReadingTime');
    stats['dailyPagesRead'] = prefs.getInt('stats_dailyPagesRead');
    stats['dailyBooksCompleted'] = prefs.getInt('stats_dailyBooksCompleted');
    stats['lastDailyResetDate'] = prefs.getString('stats_lastDailyResetDate');

    // Monthly stats
    stats['monthlyReadingTime'] = prefs.getInt('stats_monthlyReadingTime');
    stats['monthlyPagesRead'] = prefs.getInt('stats_monthlyPagesRead');
    stats['monthlyBooksCompleted'] = prefs.getInt(
      'stats_monthlyBooksCompleted',
    );
    stats['lastMonthlyResetDate'] = prefs.getString(
      'stats_lastMonthlyResetDate',
    );

    // Goals
    stats['dailyReadingTimeGoal'] = prefs.getInt('stats_dailyReadingTimeGoal');
    stats['dailyPagesGoal'] = prefs.getInt('stats_dailyPagesGoal');
    stats['monthlyReadingTimeGoal'] = prefs.getInt(
      'stats_monthlyReadingTimeGoal',
    );
    stats['monthlyPagesGoal'] = prefs.getInt('stats_monthlyPagesGoal');

    return stats;
  }

  // ========== Data Restoration ==========

  Future<void> _mergeBackupData(BackupData backup) async {
    final prefs = await SharedPreferences.getInstance();

    // Merge books (avoid duplicates by file path)
    final currentBooksJson = prefs.getString('books_list');
    final currentBooks = currentBooksJson != null
        ? List<Map<String, dynamic>>.from(json.decode(currentBooksJson))
        : <Map<String, dynamic>>[];

    final currentPaths = currentBooks.map((b) => b['filePath']).toSet();
    final newBooks = backup.books
        .where((b) => !currentPaths.contains(b['filePath']))
        .toList();

    final mergedBooks = [...currentBooks, ...newBooks];
    await prefs.setString('books_list', json.encode(mergedBooks));

    // Merge other data (positions, annotations, bookmarks)
    await _restoreReadingPositions(backup.readingPositions, merge: true);
    await _restoreAnnotations(backup.annotations, merge: true);
    await _restoreBookmarks(backup.bookmarks, merge: true);

    // Settings are not merged, user keeps current settings
    debugPrint('[Backup] Merge completed');
  }

  Future<void> _overwriteBackupData(BackupData backup) async {
    final prefs = await SharedPreferences.getInstance();

    // Overwrite books
    await prefs.setString('books_list', json.encode(backup.books));

    // Overwrite all data
    await _restoreReadingPositions(backup.readingPositions, merge: false);
    await _restoreAnnotations(backup.annotations, merge: false);
    await _restoreBookmarks(backup.bookmarks, merge: false);
    await _restoreSettings(backup.settings);
    await _restoreReadingStats(backup.readingStats);

    debugPrint('[Backup] Overwrite completed');
  }

  Future<void> _restoreReadingPositions(
    Map<String, dynamic> positions, {
    required bool merge,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (!merge) {
      // Clear existing positions
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('reading_position_')) {
          await prefs.remove(key);
        }
      }
    }

    // Restore positions
    for (final entry in positions.entries) {
      await prefs.setString(entry.key, json.encode(entry.value));
    }
  }

  Future<void> _restoreAnnotations(
    Map<String, dynamic> annotations, {
    required bool merge,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (merge) {
      final currentJson = prefs.getString('saved_annotations');
      if (currentJson != null) {
        final current = json.decode(currentJson) as Map<String, dynamic>;
        // Merge: combine annotations from both
        annotations.forEach((key, value) {
          if (current.containsKey(key)) {
            // Merge lists
            final currentList = List.from(current[key]);
            final newList = List.from(value);
            current[key] = [...currentList, ...newList];
          } else {
            current[key] = value;
          }
        });
        await prefs.setString('saved_annotations', json.encode(current));
        return;
      }
    }

    await prefs.setString('saved_annotations', json.encode(annotations));
  }

  Future<void> _restoreBookmarks(
    Map<String, dynamic> bookmarks, {
    required bool merge,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (merge) {
      final currentJson = prefs.getString('saved_bookmarks');
      if (currentJson != null) {
        final current = json.decode(currentJson) as Map<String, dynamic>;
        bookmarks.forEach((key, value) {
          if (current.containsKey(key)) {
            final currentList = List.from(current[key]);
            final newList = List.from(value);
            current[key] = [...currentList, ...newList];
          } else {
            current[key] = value;
          }
        });
        await prefs.setString('saved_bookmarks', json.encode(current));
        return;
      }
    }

    await prefs.setString('saved_bookmarks', json.encode(bookmarks));
  }

  Future<void> _restoreSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();

    // Restore reading settings
    if (settings['fontSize'] != null) {
      await prefs.setDouble('reading_fontSize', settings['fontSize']);
    }
    if (settings['lineHeight'] != null) {
      await prefs.setDouble('reading_lineHeight', settings['lineHeight']);
    }
    if (settings['wordSpacing'] != null) {
      await prefs.setDouble('reading_wordSpacing', settings['wordSpacing']);
    }
    if (settings['backgroundColor'] != null) {
      await prefs.setInt(
        'reading_backgroundColor',
        settings['backgroundColor'],
      );
    }
    if (settings['fontFamily'] != null) {
      await prefs.setString('reading_fontFamily', settings['fontFamily']);
    }

    // Restore theme settings
    if (settings['isDarkMode'] != null) {
      await prefs.setBool('theme_isDarkMode', settings['isDarkMode']);
    }
    if (settings['colorThemeId'] != null) {
      await prefs.setString('theme_colorThemeId', settings['colorThemeId']);
    }
    if (settings['fontThemeId'] != null) {
      await prefs.setString('theme_fontThemeId', settings['fontThemeId']);
    }

    // Note: Library path is NOT restored to avoid breaking file references
  }

  Future<void> _restoreReadingStats(Map<String, dynamic> stats) async {
    final prefs = await SharedPreferences.getInstance();

    if (stats['dailyReadingTime'] != null) {
      await prefs.setInt('stats_dailyReadingTime', stats['dailyReadingTime']);
    }
    if (stats['dailyPagesRead'] != null) {
      await prefs.setInt('stats_dailyPagesRead', stats['dailyPagesRead']);
    }
    if (stats['dailyBooksCompleted'] != null) {
      await prefs.setInt(
        'stats_dailyBooksCompleted',
        stats['dailyBooksCompleted'],
      );
    }
    if (stats['lastDailyResetDate'] != null) {
      await prefs.setString(
        'stats_lastDailyResetDate',
        stats['lastDailyResetDate'],
      );
    }

    if (stats['monthlyReadingTime'] != null) {
      await prefs.setInt(
        'stats_monthlyReadingTime',
        stats['monthlyReadingTime'],
      );
    }
    if (stats['monthlyPagesRead'] != null) {
      await prefs.setInt('stats_monthlyPagesRead', stats['monthlyPagesRead']);
    }
    if (stats['monthlyBooksCompleted'] != null) {
      await prefs.setInt(
        'stats_monthlyBooksCompleted',
        stats['monthlyBooksCompleted'],
      );
    }
    if (stats['lastMonthlyResetDate'] != null) {
      await prefs.setString(
        'stats_lastMonthlyResetDate',
        stats['lastMonthlyResetDate'],
      );
    }

    // Restore goals
    if (stats['dailyReadingTimeGoal'] != null) {
      await prefs.setInt(
        'stats_dailyReadingTimeGoal',
        stats['dailyReadingTimeGoal'],
      );
    }
    if (stats['dailyPagesGoal'] != null) {
      await prefs.setInt('stats_dailyPagesGoal', stats['dailyPagesGoal']);
    }
    if (stats['monthlyReadingTimeGoal'] != null) {
      await prefs.setInt(
        'stats_monthlyReadingTimeGoal',
        stats['monthlyReadingTimeGoal'],
      );
    }
    if (stats['monthlyPagesGoal'] != null) {
      await prefs.setInt('stats_monthlyPagesGoal', stats['monthlyPagesGoal']);
    }
  }
}
