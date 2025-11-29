import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import '../services/storage_service.dart';
import '../utils/toast_helper.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = false;

  Future<void> _pickFolder() async {
    try {
      setState(() {
        _isLoading = true;
      });

      debugPrint('[Welcome] Starting folder picker...');

      // Use file_picker to get directory path
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      // CRITICAL: Check if context is still mounted after async operation
      if (!mounted) {
        debugPrint('[Welcome] Context no longer mounted after folder picker');
        return;
      }

      if (selectedDirectory == null || selectedDirectory.isEmpty) {
        // User cancelled
        debugPrint('[Welcome] User cancelled folder selection');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      debugPrint('[Welcome] Picked path: $selectedDirectory');

      // Set the library path and create subdirectories
      debugPrint('[Welcome] Setting library path via StorageService...');
      final storageService = StorageService();

      try {
        await storageService.setLibraryPath(selectedDirectory);

        if (!mounted) {
          debugPrint(
            '[Welcome] Context no longer mounted after setLibraryPath',
          );
          return;
        }

        debugPrint('[Welcome] Library path set successfully');
      } catch (e, stackTrace) {
        debugPrint('[Welcome] Exception in setLibraryPath: $e');
        debugPrint('[Welcome] Stack trace: $stackTrace');

        if (!mounted) {
          debugPrint('[Welcome] Context no longer mounted after error');
          return;
        }

        // Extract error message from exception
        String errorMessage = 'Lỗi khi tạo thư mục';
        if (e is Exception) {
          errorMessage = e.toString().replaceFirst('Exception: ', '');
        } else {
          errorMessage = 'Lỗi không mong muốn: ${e.toString()}';
        }

        showCustomToast(context, errorMessage, isError: true);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Navigate to HomeScreen
      if (mounted) {
        debugPrint('[Welcome] Navigating to HomeScreen...');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        debugPrint('[Welcome] Context no longer mounted before navigation');
      }
    } catch (e, stackTrace) {
      debugPrint('[Welcome] CRITICAL ERROR in _pickFolder: $e');
      debugPrint('[Welcome] Stack trace: $stackTrace');

      if (mounted) {
        showCustomToast(
          context,
          'Lỗi không mong muốn: ${e.toString()}',
          isError: true,
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? const Color(0xFF131B24)
        : const Color(0xFFF5F1E8);
    final textColor = isDarkMode
        ? const Color(0xFFE3DAC9)
        : const Color(0xFF2D3748);
    final textLight = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final accentColor = isDarkMode
        ? const Color(0xFF059669)
        : const Color(0xFF043222);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Welcome Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.bookOpen,
                    size: 60,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 48),

                // Welcome Text
                Text(
                  'Chào mừng đến với Flux Alpha',
                  style: TextStyle(
                    fontFamily: 'MySerif',
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Description Text
                Text(
                  'Vui lòng chọn thư mục để lưu trữ sách của bạn',
                  style: TextStyle(
                    fontFamily: 'MySans',
                    fontSize: 18,
                    color: textLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Pick Folder Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _pickFolder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: accentColor.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 32,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.folderOpen, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                'Chọn thư mục',
                                style: const TextStyle(
                                  fontFamily: 'MySans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Info Text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: textColor.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.info, size: 20, color: textLight),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Thư mục bạn chọn sẽ chứa sách và bìa sách của bạn. Bạn có thể chọn bất kỳ thư mục nào trên máy tính.',
                          style: TextStyle(
                            fontFamily: 'MySans',
                            fontSize: 14,
                            color: textLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
