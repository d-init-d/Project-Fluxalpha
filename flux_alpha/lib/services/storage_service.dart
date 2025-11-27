import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton service for managing the root library path
/// Handles first-run setup and persistent storage of user-selected library location
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _prefsKey = 'custom_library_path';
  String? _rootLibraryPath;
  bool _isInitialized = false;

  /// Initialize the service by reading from SharedPreferences
  /// Returns true if library path is already set, false if setup is needed
  Future<bool> init() async {
    if (_isInitialized) {
      return _rootLibraryPath != null;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPath = prefs.getString(_prefsKey);

      if (savedPath != null && savedPath.isNotEmpty) {
        // Verify the path still exists
        final dir = Directory(savedPath);
        if (await dir.exists()) {
          _rootLibraryPath = savedPath;
          _isInitialized = true;
          return true;
        } else {
          // Path no longer exists, clear it
          await prefs.remove(_prefsKey);
        }
      }

      _isInitialized = true;
      return false; // Setup needed
    } catch (e) {
      // On error, assume setup is needed
      _isInitialized = true;
      return false;
    }
  }

  /// Get the root library path
  /// Returns null if not set (setup needed)
  String? get rootLibraryPath => _rootLibraryPath;

  /// Check if setup is needed
  bool get needsSetup => _rootLibraryPath == null;

  /// Set the root library path and create necessary subdirectories
  /// Throws an exception with a clear error message on failure
  /// Returns true on success
  Future<bool> setLibraryPath(String path) async {
    try {
      debugPrint('[Storage] Setting library path: $path');

      // Validate path is not empty
      if (path.isEmpty) {
        throw Exception('Đường dẫn thư mục không hợp lệ (rỗng)');
      }

      final dir = Directory(path);
      
      // Check if path exists or can be created
      bool pathExists = await dir.exists();
      debugPrint('[Storage] Path exists: $pathExists');

      if (!pathExists) {
        debugPrint('[Storage] Creating root directory...');
        try {
          await dir.create(recursive: true);
          debugPrint('[Storage] Root directory created successfully');
        } catch (e) {
          debugPrint('[Storage] Failed to create root directory: $e');
          throw Exception('Không thể tạo thư mục. Kiểm tra quyền truy cập: ${e.toString()}');
        }
      }

      // Verify the directory is writable by attempting to create a test file
      try {
        final testFile = File('${dir.path}/.flux_test');
        await testFile.writeAsString('test');
        await testFile.delete();
        debugPrint('[Storage] Directory is writable');
      } catch (e) {
        debugPrint('[Storage] Directory is not writable: $e');
        throw Exception('Thư mục không có quyền ghi. Vui lòng chọn thư mục khác.');
      }

      // Create subdirectories
      debugPrint('[Storage] Creating subdirectories...');
      final booksDir = Directory('$path/Books');
      final coversDir = Directory('$path/Covers');

      try {
        if (!await booksDir.exists()) {
          debugPrint('[Storage] Creating Books directory...');
          await booksDir.create(recursive: true);
          debugPrint('[Storage] Books directory created');
        } else {
          debugPrint('[Storage] Books directory already exists');
        }
      } catch (e) {
        debugPrint('[Storage] Failed to create Books directory: $e');
        throw Exception('Không thể tạo thư mục Books: ${e.toString()}');
      }

      try {
        if (!await coversDir.exists()) {
          debugPrint('[Storage] Creating Covers directory...');
          await coversDir.create(recursive: true);
          debugPrint('[Storage] Covers directory created');
        } else {
          debugPrint('[Storage] Covers directory already exists');
        }
      } catch (e) {
        debugPrint('[Storage] Failed to create Covers directory: $e');
        throw Exception('Không thể tạo thư mục Covers: ${e.toString()}');
      }

      // Save to SharedPreferences
      debugPrint('[Storage] Saving path to SharedPreferences...');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefsKey, path);
        debugPrint('[Storage] Path saved to SharedPreferences');
      } catch (e) {
        debugPrint('[Storage] Failed to save to SharedPreferences: $e');
        throw Exception('Không thể lưu cài đặt: ${e.toString()}');
      }

      // Update internal state
      _rootLibraryPath = path;
      debugPrint('[Storage] Library path set successfully: $path');
      return true;
    } catch (e) {
      debugPrint('[Storage] ERROR in setLibraryPath: $e');
      // Re-throw with clear error message
      rethrow;
    }
  }

  /// Get the Books directory path
  String? get booksDirectory {
    if (_rootLibraryPath == null) return null;
    return '$_rootLibraryPath/Books';
  }

  /// Get the Covers directory path
  String? get coversDirectory {
    if (_rootLibraryPath == null) return null;
    return '$_rootLibraryPath/Covers';
  }

  /// Ensure all directories exist
  Future<void> ensureDirectoriesExist() async {
    if (_rootLibraryPath == null) {
      throw StateError('Library path not set. Call setLibraryPath first.');
    }

    final dir = Directory(_rootLibraryPath!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final booksDir = Directory(booksDirectory!);
    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }

    final coversDir = Directory(coversDirectory!);
    if (!await coversDir.exists()) {
      await coversDir.create(recursive: true);
    }
  }
}

