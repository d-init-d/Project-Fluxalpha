import '../services/storage_service.dart';

class PathHelper {
  /// Get the root library directory from StorageService
  /// Throws StateError if library path is not set (setup needed)
  static String getLibraryDirectory() {
    final storageService = StorageService();
    final path = storageService.rootLibraryPath;
    if (path == null) {
      throw StateError(
        'Library path not set. User must complete first-run setup.',
      );
    }
    return path;
  }

  /// Get the Books directory from StorageService
  /// Throws StateError if library path is not set (setup needed)
  static String getBooksDirectory() {
    final storageService = StorageService();
    final path = storageService.booksDirectory;
    if (path == null) {
      throw StateError(
        'Library path not set. User must complete first-run setup.',
      );
    }
    return path;
  }

  /// Get the Covers directory from StorageService
  /// Throws StateError if library path is not set (setup needed)
  static String getCoversDirectory() {
    final storageService = StorageService();
    final path = storageService.coversDirectory;
    if (path == null) {
      throw StateError(
        'Library path not set. User must complete first-run setup.',
      );
    }
    return path;
  }

  /// Ensure all directories exist
  /// Uses StorageService to ensure directories are created
  static Future<void> ensureDirectoriesExist() async {
    final storageService = StorageService();
    await storageService.ensureDirectoriesExist();
  }
}
