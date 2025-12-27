import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/theme_provider.dart';
import '../services/storage_service.dart';
import '../services/backup_service.dart';
import '../models/color_theme.dart';
import '../models/font_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  // Navigation
  int _selectedIndex = 0;
  final List<String> _tabs = ['Chung', 'Giao diện', 'Phím tắt', 'Thông tin'];
  final List<IconData> _icons = [
    LucideIcons.settings,
    LucideIcons.palette,
    LucideIcons.keyboard,
    LucideIcons.info,
  ];

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // App info
  String _appVersion = '...';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _animationController.forward();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      });
    } catch (e) {
      setState(() {
        _appVersion = '0.1.0 (Dev)';
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(colorThemeProvider);
    final isDark = ref.watch(themeProvider).isDarkMode;
    final fontTheme = ref.watch(fontThemeProvider);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
          child: Row(
            children: [
              Text(
                'Cài đặt',
                style: TextStyle(
                  fontFamily: fontTheme.serifFont,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
        ),

        // Tabs với animated indicator
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.textColor.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: List.generate(_tabs.length, (index) {
              final isSelected = _selectedIndex == index;
              return InkWell(
                onTap: () => _switchTab(index),
                hoverColor: theme.highlight.withValues(alpha: 0.05),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected
                            ? theme.highlight
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _icons[index],
                        size: 16,
                        color: isSelected ? theme.highlight : theme.textLight,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _tabs[index],
                        style: TextStyle(
                          fontFamily: fontTheme.sansFont,
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? theme.textColor : theme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),

        // Content với animation
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: _buildContent(
                  index: _selectedIndex,
                  theme: theme,
                  isDark: isDark,
                  fontTheme: fontTheme,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent({
    required int index,
    required ColorThemeModel theme,
    required bool isDark,
    required FontThemeModel fontTheme,
  }) {
    switch (index) {
      case 0:
        return _buildGeneralSettings(theme, fontTheme);
      case 1:
        return _buildAppearanceSettings(theme, fontTheme, isDark);
      case 2:
        return _buildShortcutsSettings(theme, fontTheme);
      case 3:
        return _buildAboutSettings(theme, fontTheme);
      default:
        return const SizedBox();
    }
  }

  // ============================================
  // GENERAL SETTINGS TAB
  // ============================================
  Widget _buildGeneralSettings(
    ColorThemeModel theme,
    FontThemeModel fontTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Thư viện', theme, fontTheme),
        _buildAnimatedSettingCard(
          theme: theme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Đường dẫn thư viện gốc',
                style: TextStyle(
                  fontFamily: fontTheme.sansFont,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.textColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.folder, size: 16, color: theme.textLight),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        StorageService().rootLibraryPath ?? 'Chưa thiết lập',
                        style: TextStyle(
                          fontFamily: fontTheme.sansFont,
                          fontSize: 13,
                          color: theme.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                onPressed: _pickLibraryFolder,
                icon: LucideIcons.folderOpen,
                label: 'Thay đổi thư mục',
                theme: theme,
                fontTheme: fontTheme,
                isPrimary: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Data Backup/Restore Section
        _buildSectionTitle('Sao lưu dữ liệu', theme, fontTheme),
        _buildAnimatedSettingCard(
          theme: theme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.database, size: 18, color: theme.highlight),
                  const SizedBox(width: 8),
                  Text(
                    'Backup & Restore',
                    style: TextStyle(
                      fontFamily: fontTheme.sansFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Sao lưu toàn bộ dữ liệu (sách, tiến độ, ghi chú, cài đặt) thành file JSON. Bạn có thể khôi phục dữ liệu từ file backup bất cứ lúc nào.',
                style: TextStyle(
                  fontFamily: fontTheme.sansFont,
                  fontSize: 13,
                  color: theme.textLight,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildActionButton(
                    onPressed: _exportBackup,
                    icon: LucideIcons.download,
                    label: 'Export Backup',
                    theme: theme,
                    fontTheme: fontTheme,
                    isPrimary: true,
                  ),
                  _buildActionButton(
                    onPressed: () => _importBackup(context, theme, fontTheme),
                    icon: LucideIcons.upload,
                    label: 'Import Backup',
                    theme: theme,
                    fontTheme: fontTheme,
                    isPrimary: false,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================
  // APPEARANCE SETTINGS TAB
  // ============================================
  Widget _buildAppearanceSettings(
    ColorThemeModel theme,
    FontThemeModel fontTheme,
    bool isDark,
  ) {
    final currentColorThemeId = ref.watch(themeProvider).colorThemeId;
    final currentFontThemeId = ref.watch(themeProvider).fontThemeId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dark Mode Toggle
        _buildSectionTitle('Chế độ hiển thị', theme, fontTheme),
        _buildAnimatedSettingCard(
          theme: theme,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isDark ? LucideIcons.moon : LucideIcons.sun,
                          size: 18,
                          color: theme.highlight,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Chế độ tối (Dark Mode)',
                          style: TextStyle(
                            fontFamily: fontTheme.sansFont,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sử dụng giao diện tối cho toàn ứng dụng',
                      style: TextStyle(
                        fontFamily: fontTheme.sansFont,
                        fontSize: 12,
                        color: theme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isDark,
                onChanged: (value) {
                  ref.read(themeProvider.notifier).toggleDarkMode();
                },
                activeTrackColor: theme.highlight,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Color Theme Picker
        _buildSectionTitle('Chủ đề màu sắc', theme, fontTheme),
        _buildAnimatedSettingCard(
          theme: theme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chọn tone màu chủ đạo cho ứng dụng',
                style: TextStyle(
                  fontFamily: fontTheme.sansFont,
                  fontSize: 13,
                  color: theme.textLight,
                ),
              ),
              const SizedBox(height: 16),
              _buildColorThemePicker(
                currentColorThemeId,
                theme,
                fontTheme,
                isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Font Theme Picker
        _buildSectionTitle('Bộ font chữ', theme, fontTheme),
        _buildAnimatedSettingCard(
          theme: theme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chọn bộ font chữ cho giao diện và nội dung',
                style: TextStyle(
                  fontFamily: fontTheme.sansFont,
                  fontSize: 13,
                  color: theme.textLight,
                ),
              ),
              const SizedBox(height: 16),
              _buildFontThemePicker(currentFontThemeId, theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorThemePicker(
    String currentThemeId,
    ColorThemeModel theme,
    FontThemeModel fontTheme,
    bool isDark,
  ) {
    final colorThemes = ['forest', 'espresso', 'charcoal', 'ink'];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colorThemes.map((themeId) {
        final colorTheme = ColorThemes.getTheme(themeId, isDark);
        final isSelected = currentThemeId == themeId;

        return InkWell(
          onTap: () {
            ref.read(themeProvider.notifier).setColorTheme(themeId);
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 140,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.highlight.withValues(alpha: 0.1)
                  : theme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? theme.highlight
                    : theme.textColor.withValues(alpha: 0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Color preview
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorTheme.highlight,
                        colorTheme.highlight.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(
                            LucideIcons.check,
                            color: Colors.white,
                            size: 24,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  colorTheme.name,
                  style: TextStyle(
                    fontFamily: fontTheme.sansFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  colorTheme.description,
                  style: TextStyle(
                    fontFamily: fontTheme.sansFont,
                    fontSize: 11,
                    color: theme.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFontThemePicker(
    String currentFontThemeId,
    ColorThemeModel theme,
  ) {
    return Column(
      children: FontThemes.all.entries.map((entry) {
        final fontTheme = entry.value;
        final isSelected = currentFontThemeId == fontTheme.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              ref.read(themeProvider.notifier).setFontTheme(fontTheme.id);
            },
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.highlight.withValues(alpha: 0.1)
                    : theme.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? theme.highlight
                      : theme.textColor.withValues(alpha: 0.1),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        LucideIcons.check,
                        color: theme.highlight,
                        size: 20,
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fontTheme.name,
                          style: TextStyle(
                            fontFamily: fontTheme.sansFont,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fontTheme.description,
                          style: TextStyle(
                            fontFamily: fontTheme.sansFont,
                            fontSize: 12,
                            color: theme.textLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Font preview
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Aa',
                                style: TextStyle(
                                  fontFamily: fontTheme.serifFont,
                                  fontSize: 20,
                                  color: theme.textColor,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Aa',
                                style: TextStyle(
                                  fontFamily: fontTheme.sansFont,
                                  fontSize: 20,
                                  color: theme.textColor,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Aa',
                                style: TextStyle(
                                  fontFamily: fontTheme.monoFont,
                                  fontSize: 20,
                                  color: theme.textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================
  // SHORTCUTS SETTINGS TAB
  // ============================================
  Widget _buildShortcutsSettings(
    ColorThemeModel theme,
    FontThemeModel fontTheme,
  ) {
    // Mock shortcuts data
    final shortcuts = [
      {
        'name': 'Mở cửa sổ nhanh',
        'keys': 'Ctrl + Shift + Space',
        'action': 'toggle_window',
      },
      {'name': 'Tìm kiếm sách', 'keys': 'Ctrl + F', 'action': 'search'},
      {'name': 'Thêm bookmark', 'keys': 'Ctrl + D', 'action': 'bookmark'},
      {'name': 'Highlight văn bản', 'keys': 'Ctrl + H', 'action': 'highlight'},
      {'name': 'Ghi chú nhanh', 'keys': 'Ctrl + N', 'action': 'note'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Phím tắt toàn cục', theme, fontTheme),
        _buildAnimatedSettingCard(
          theme: theme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tùy chỉnh các phím tắt để thao tác nhanh hơn',
                style: TextStyle(
                  fontFamily: fontTheme.sansFont,
                  fontSize: 13,
                  color: theme.textLight,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              ...shortcuts.map(
                (shortcut) => _buildShortcutItem(
                  name: shortcut['name']!,
                  keys: shortcut['keys']!,
                  theme: theme,
                  fontTheme: fontTheme,
                ),
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                onPressed: () {
                  // Reset shortcuts to defaults
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Đã khôi phục phím tắt mặc định',
                        style: TextStyle(fontFamily: fontTheme.sansFont),
                      ),
                      backgroundColor: theme.highlight,
                    ),
                  );
                },
                icon: LucideIcons.refreshCw,
                label: 'Khôi phục mặc định',
                theme: theme,
                fontTheme: fontTheme,
                isPrimary: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutItem({
    required String name,
    required String keys,
    required ColorThemeModel theme,
    required FontThemeModel fontTheme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontFamily: fontTheme.sansFont,
                fontSize: 13,
                color: theme.textColor,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: theme.textColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  keys,
                  style: TextStyle(
                    fontFamily: fontTheme.monoFont,
                    fontSize: 12,
                    color: theme.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(LucideIcons.edit2, size: 16, color: theme.textLight),
                onPressed: () {
                  // TODO: Open edit shortcut dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Tính năng đang phát triển',
                        style: TextStyle(fontFamily: fontTheme.sansFont),
                      ),
                    ),
                  );
                },
                tooltip: 'Chỉnh sửa',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================
  // ABOUT SETTINGS TAB
  // ============================================
  Widget _buildAboutSettings(ColorThemeModel theme, FontThemeModel fontTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Về ứng dụng', theme, fontTheme),
        _buildAnimatedSettingCard(
          theme: theme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App icon and name
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.highlight,
                          theme.highlight.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      LucideIcons.bookOpen,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Flux Alpha',
                          style: TextStyle(
                            fontFamily: fontTheme.serifFont,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Trải nghiệm đọc sách thế hệ mới',
                          style: TextStyle(
                            fontFamily: fontTheme.sansFont,
                            fontSize: 13,
                            color: theme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Version info
              _buildInfoRow(
                icon: LucideIcons.tag,
                label: 'Phiên bản',
                value: _appVersion,
                theme: theme,
                fontTheme: fontTheme,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: LucideIcons.code,
                label: 'Build',
                value: 'Flutter 3.10+',
                theme: theme,
                fontTheme: fontTheme,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: LucideIcons.copyright,
                label: 'Bản quyền',
                value: '© 2024 dmn05',
                theme: theme,
                fontTheme: fontTheme,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Links section
        _buildSectionTitle('Liên kết', theme, fontTheme),
        _buildAnimatedSettingCard(
          theme: theme,
          child: Column(
            children: [
              _buildLinkItem(
                icon: LucideIcons.github,
                label: 'Mã nguồn GitHub',
                url: 'https://github.com/dmn05/flux-alpha',
                theme: theme,
                fontTheme: fontTheme,
              ),
              const Divider(height: 24),
              _buildLinkItem(
                icon: LucideIcons.bug,
                label: 'Báo lỗi',
                url: 'https://github.com/dmn05/flux-alpha/issues',
                theme: theme,
                fontTheme: fontTheme,
              ),
              const Divider(height: 24),
              _buildLinkItem(
                icon: LucideIcons.mail,
                label: 'Liên hệ',
                url: 'mailto:contact@example.com',
                theme: theme,
                fontTheme: fontTheme,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Credits
        _buildSectionTitle('Tín dụng', theme, fontTheme),
        _buildAnimatedSettingCard(
          theme: theme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Flux Alpha được phát triển với ❤️ bởi dmn05',
                style: TextStyle(
                  fontFamily: fontTheme.sansFont,
                  fontSize: 13,
                  color: theme.textLight,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Cảm ơn cộng đồng Flutter và các thư viện mã nguồn mở đã hỗ trợ dự án này.',
                style: TextStyle(
                  fontFamily: fontTheme.sansFont,
                  fontSize: 13,
                  color: theme.textLight,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ColorThemeModel theme,
    required FontThemeModel fontTheme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.textLight),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontFamily: fontTheme.sansFont,
            fontSize: 13,
            color: theme.textLight,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontFamily: fontTheme.sansFont,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLinkItem({
    required IconData icon,
    required String label,
    required String url,
    required ColorThemeModel theme,
    required FontThemeModel fontTheme,
  }) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Không thể mở liên kết: $url',
                  style: TextStyle(fontFamily: fontTheme.sansFont),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.highlight),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: fontTheme.sansFont,
                  fontSize: 14,
                  color: theme.textColor,
                ),
              ),
            ),
            Icon(LucideIcons.externalLink, size: 16, color: theme.textLight),
          ],
        ),
      ),
    );
  }

  // ============================================
  // HELPER WIDGETS
  // ============================================
  Widget _buildSectionTitle(
    String title,
    ColorThemeModel theme,
    FontThemeModel fontTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontFamily: fontTheme.sansFont,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: theme.textLight,
        ),
      ),
    );
  }

  Widget _buildAnimatedSettingCard({
    required ColorThemeModel theme,
    required Widget child,
  }) {
    return MouseRegion(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.textColor.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required ColorThemeModel theme,
    required FontThemeModel fontTheme,
    required bool isPrimary,
  }) {
    if (isPrimary) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.highlight,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.textColor,
          side: BorderSide(color: theme.textColor.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  // ============================================
  // ACTIONS
  // ============================================
  Future<void> _pickLibraryFolder() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Chọn thư mục thư viện',
      lockParentWindow: true,
    );

    if (result != null) {
      await StorageService().setLibraryPath(result);
      if (mounted) {
        setState(() {}); // Rebuild to update path
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã cập nhật thư mục thư viện'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _exportBackup() async {
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang tạo backup...'),
          duration: Duration(seconds: 2),
        ),
      );

      final backupService = BackupService();
      final filePath = await backupService.exportBackup();

      if (!mounted) return;

      if (filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã lưu backup tại:\n$filePath'),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi khi tạo backup: $e'),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _importBackup(
    BuildContext context,
    ColorThemeModel theme,
    FontThemeModel fontTheme,
  ) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardBackground,
        title: Text(
          'Import Backup',
          style: TextStyle(
            fontFamily: fontTheme.serifFont,
            color: theme.textColor,
          ),
        ),
        content: Text(
          'Bạn muốn gộp dữ liệu (merge) hay ghi đè hoàn toàn (overwrite)?',
          style: TextStyle(
            fontFamily: fontTheme.sansFont,
            color: theme.textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: Text(
              'Hủy',
              style: TextStyle(
                fontFamily: fontTheme.sansFont,
                color: theme.textLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('merge'),
            child: Text(
              'Merge (Gộp)',
              style: TextStyle(
                fontFamily: fontTheme.sansFont,
                color: theme.highlight,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('overwrite'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(
              'Overwrite (Ghi đè)',
              style: TextStyle(
                fontFamily: fontTheme.sansFont,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (choice == null || choice == 'cancel') return;

    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang import backup...'),
          duration: Duration(seconds: 2),
        ),
      );

      final backupService = BackupService();
      final success = await backupService.importBackup(
        mergeData: choice == 'merge',
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Import backup thành công! Vui lòng khởi động lại ứng dụng.',
            ),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi khi import backup: $e'),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
