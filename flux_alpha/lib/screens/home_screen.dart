import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flux_alpha/screens/library_screen.dart';
import '../models/annotation.dart';
import '../models/book.dart';
import '../models/chapter_data.dart';
import '../models/color_theme.dart';
import '../models/font_theme.dart';
import '../models/saved_bookmark.dart';
import '../providers/book_provider.dart';
import '../providers/language_provider.dart';
import '../l10n/app_localizations.dart';
import '../services/reading_stats_service.dart';
import '../services/saved_content_service.dart';
import '../services/reading_position_service.dart';
import '../services/storage_service.dart';
import '../widgets/book_cover_widget.dart';
import 'book_reader_screen.dart';
import 'reader_interface.dart';
import 'welcome_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _activeTab = 0;
  bool _showNotifications = false;
  bool _showProfileMenu = false;

  // Settings Panel State
  bool _darkMode = false;
  bool _scheduleDarkMode = false;
  String _currentColorTheme = 'forest';
  String _currentFontTheme = 'default';
  TimeOfDay _darkModeStartTime = const TimeOfDay(hour: 20, minute: 0);

  TimeOfDay _darkModeEndTime = const TimeOfDay(hour: 7, minute: 0);

  // Reader State
  Book? _readingBook;
  List<ChapterData> _readingChapters = [];

  // Services
  final ReadingStatsService _statsService = ReadingStatsService();
  final SavedContentService _savedContentService = SavedContentService();
  final ReadingPositionService _positionService = ReadingPositionService();

  void _onStatsUpdate() {
    if (mounted) {
      // Schedule setState to run after the current build phase completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _handleOpenBook(Book? book) {
    if (book == null) return;
    setState(() {
      _readingBook = book;
      _readingChapters =
          []; // Reset chapters, they will be loaded by BookReaderScreen
    });
  }

  // Theme Accessor
  ColorThemeModel get _theme =>
      ColorThemes.getTheme(_currentColorTheme, _darkMode);

  FontThemeModel get _fontTheme => FontThemes.all[_currentFontTheme]!;

  List<Book> _getRecentlyOpenedBooks(List<Book> books, {int limit = 8}) {
    final recent =
        books.where((book) => book.lastRead.isAfter(book.uploadDate)).toList()
          ..sort((a, b) => b.lastRead.compareTo(a.lastRead));
    return recent.take(limit).toList();
  }

  String _formatRelativeTime(DateTime lastRead) {
    final now = DateTime.now();
    final difference = now.difference(lastRead);

    if (difference.inMinutes < 1) {
      return 'vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks tuần trước';
    }
  }

  // Deprecated hardcoded colors - mapped to theme
  // _theme.textColor -> _theme.textColor
  // _theme.highlight -> _theme.highlight
  // _theme.background -> _theme.background
  // _theme.cardBackground -> _theme.cardBackground
  // _theme.textLight -> _theme.textLight

  @override
  void initState() {
    super.initState();
    _updateWindowTitleBar();
    _statsService.addListener(_onStatsUpdate);
    _positionService.addListener(_onPositionUpdate);
    _initializeReadingPositions();
  }

  Future<void> _initializeReadingPositions() async {
    await _positionService.init();
    if (mounted) {
      setState(() {});
    }
  }

  void _onPositionUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _statsService.removeListener(_onStatsUpdate);
    _positionService.removeListener(_onPositionUpdate);
    super.dispose();
  }

  // Update Windows title bar color based on dark mode
  Future<void> _updateWindowTitleBar() async {
    if (Platform.isWindows) {
      try {
        // Set window background color based on dark mode
        final bgColor = _theme.background;
        await windowManager.setBackgroundColor(bgColor);

        // Update window title bar color (if supported)
        await windowManager.setTitleBarStyle(
          _darkMode ? TitleBarStyle.normal : TitleBarStyle.normal,
        );
      } catch (e) {
        // Window manager operations may not be supported on all platforms
        debugPrint('Window manager update failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _darkMode ? const Color(0xFF090F15) : _theme.background,
      endDrawer: _buildSettingsDrawer(),
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _activeTab == 1
                      ? _buildLibraryTab()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 0,
                          ),
                          child: Column(
                            children: [
                              if (_activeTab == 0) _buildHomeTab(),
                              if (_activeTab == 2) _buildStatsTab(),
                              if (_activeTab == 3) _buildSavedTab(),
                              const SizedBox(
                                height: 100,
                              ), // Space for floating nav
                            ],
                          ),
                        ),
                ),
              ],
            ),

            // Floating Bottom Navigation
            _buildFloatingNav(),

            // Notifications Overlay
            if (_showNotifications) _buildNotificationsOverlay(),

            // Profile menu backdrop (dismiss when tapping outside)
            if (_showProfileMenu)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => setState(() => _showProfileMenu = false),
                  child: const SizedBox(),
                ),
              ),

            // Profile Menu
            _buildProfileMenu(),

            // Reader Interface Overlay
            if (_readingBook != null)
              ReaderInterface(
                book: _readingBook!.toJson(),
                chapters: _readingChapters,
                initialChapterIndex: 0,
                onClose: () => setState(() => _readingBook = null),
              ),
          ],
        ),
      ),
    );
  }

  // === HEADER ===
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: _theme.background.withValues(alpha: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo & Greeting
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _theme.textColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    'F',
                    style: GoogleFonts.getFont(
                      _fontTheme.serifFont,
                      color: _theme.cardBackground,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.greeting,
                    style: GoogleFonts.getFont(
                      _fontTheme.sansFont,
                      fontSize: 10,
                      color: _theme.textLight,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'Minh Nhật',
                    style: GoogleFonts.getFont(
                      _fontTheme.serifFont,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _theme.textColor,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Actions
          Row(
            children: [
              // Notifications Bell
              Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showNotifications = !_showNotifications;
                      });
                    },
                    icon: Icon(
                      LucideIcons.bell,
                      color: _showNotifications
                          ? Colors.white
                          : _theme.textColor,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: _showNotifications
                          ? _theme.textColor
                          : Colors.transparent,
                    ),
                  ),
                  if (!_showNotifications)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _theme.highlight,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _theme.background,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Profile Avatar
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _showProfileMenu = !_showProfileMenu;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _theme.cardBackground,
                        width: 2,
                      ),
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://api.dicebear.com/7.x/avataaars/svg?seed=Felix',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // === HOME TAB ===
  Widget _buildHomeTab() {
    final books = ref.watch(bookListProvider);
    final recentBook = ref.watch(mostRecentlyReadBookProvider);
    final recentBooks = _getRecentlyOpenedBooks(books);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        _buildHeroSection(recentBook),
        const SizedBox(height: 64),
        _buildRecentlyRead(recentBooks),
        const SizedBox(height: 32),
        _buildQuickStatsRow(),
        const SizedBox(height: 32),
        _buildStatsAndNotes(),
      ],
    );
  }

  // Quick Stats Row - giống React code
  Widget _buildQuickStatsRow() {
    final cardBg = _darkMode ? const Color(0xFF131B24) : _theme.cardBackground;
    final borderColor = _darkMode
        ? const Color(0xFF2D3748)
        : const Color(0xFFC5BCAB);
    final textColor = _darkMode ? const Color(0xFFE3DAC9) : _theme.textColor;

    // Get today's reading time formatted
    final todayMinutes = _statsService.todayReadingMinutes;
    String todayTimeValue;
    if (todayMinutes >= 60) {
      final hours = todayMinutes ~/ 60;
      final mins = todayMinutes % 60;
      todayTimeValue = mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    } else {
      todayTimeValue = '$todayMinutes ${AppLocalizations.of(context)!.minutes}';
    }

    return Row(
      children: [
        // Today's reading time
        Expanded(
          child: _buildQuickStatCard(
            icon: LucideIcons.clock,
            value: todayTimeValue,
            label: AppLocalizations.of(context)!.today,
            cardBg: cardBg,
            borderColor: borderColor,
            textColor: textColor,
          ),
        ),
        const SizedBox(width: 12),
        // Books read
        Expanded(
          child: _buildQuickStatCard(
            icon: LucideIcons.book,
            value: '${_statsService.booksRead}',
            label: AppLocalizations.of(context)!.books_read,
            cardBg: cardBg,
            borderColor: borderColor,
            textColor: textColor,
          ),
        ),
        const SizedBox(width: 12),
        // Streak
        Expanded(
          child: _buildQuickStatCard(
            icon: LucideIcons.zap,
            value:
                '${_statsService.currentStreak} ${AppLocalizations.of(context)!.days}',
            label: AppLocalizations.of(context)!.streak,
            cardBg: cardBg,
            borderColor: borderColor,
            textColor: textColor,
          ),
        ),
        const SizedBox(width: 12),
        // Add goal button
        Expanded(
          child: _buildAddGoalCard(
            cardBg: cardBg,
            borderColor: borderColor,
            textColor: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _theme.textColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 16, color: _theme.cardBackground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.getFont(
                    _fontTheme.sansFont,
                    fontSize: 10,
                    color: _theme.textLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.getFont(
                    _fontTheme.sansFont,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddGoalCard({
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // TODO: Implement add goal functionality
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _theme.textLight.withValues(alpha: 0.5),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Icon(
                  LucideIcons.plus,
                  size: 16,
                  color: _theme.textLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.add_goal,
                  style: GoogleFonts.getFont(
                    _fontTheme.sansFont,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hero Section with 3D Book
  Widget _buildHeroSection(Book? recentBook) {
    final subtitle = recentBook != null
        ? "Bạn đang phiêu lưu dở ở chương ${_positionService.getCurrentChapter(recentBook.id)} của cuốn '${recentBook.title}'. Hãy đọc tiếp ngay!"
        : 'Chào mừng bạn đến với flux.alpha. Hãy mở thư viện để bắt đầu hành trình đọc!';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left: Text Content
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: GoogleFonts.getFont(
                    _fontTheme.serifFont,
                    fontSize: 48,
                    height: 1.2,
                    color: _theme.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    TextSpan(
                      text: AppLocalizations.of(context)!.books_are_dreams,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                subtitle,
                style: GoogleFonts.getFont(
                  _fontTheme.sansFont,
                  fontSize: 16,
                  color: _theme.textLight,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  if (recentBook != null) {
                    _handleOpenBook(recentBook);
                  } else {
                    setState(() => _activeTab = 1); // Switch to Library tab
                  }
                },
                icon: Icon(
                  recentBook != null
                      ? LucideIcons.chevronRight
                      : LucideIcons.library,
                  size: 18,
                ),
                label: Text(
                  recentBook != null
                      ? AppLocalizations.of(context)!.continue_reading_btn
                      : 'Khám phá thư viện',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _theme.textColor,
                  side: BorderSide(color: _theme.textColor),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 32),

        // Right: 3D Book
        Expanded(flex: 2, child: _build3DBook(recentBook)),
      ],
    );
  }

  Widget _build3DBook(Book? recentBook) {
    ImageProvider coverImage = const NetworkImage(
      'https://images.unsplash.com/photo-1618365908648-e71bd5716cba?auto=format&fit=crop&q=80&w=600',
    );
    if (recentBook?.coverFilePath != null &&
        recentBook!.coverFilePath!.isNotEmpty) {
      final coverFile = File(recentBook.coverFilePath!);
      if (coverFile.existsSync()) {
        coverImage = FileImage(coverFile);
      }
    }

    final displayAuthor = recentBook?.author ?? 'J.K. Rowling';
    final displayTitle = recentBook?.title ?? 'Harry Potter\n& Hòn đá phù thủy';
    final progressValue = (recentBook?.progress ?? 0.52)
        .clamp(0.0, 1.0)
        .toDouble();
    final progressText = '${(progressValue * 100).round()}%';
    final lastReadText = recentBook != null
        ? 'Lần cuối đọc: ${_formatRelativeTime(recentBook.lastRead)}'
        : 'Chưa có lịch sử đọc - mở thư viện để thêm sách mới.';
    final themeColor = _theme.accentBg;

    const double coverAspectRatio = 2 / 3;
    const double coverHeight = 280.0;
    final double coverWidth = coverHeight * coverAspectRatio;
    const double overlayHeight = 82.0;
    // Keep the hero book card upright (no rotation) for a clear portrait look.
    const double tiltAngle = 0.0;

    final overlayBrightness = ThemeData.estimateBrightnessForColor(themeColor);
    final overlayPrimary = overlayBrightness == Brightness.dark
        ? Colors.white
        : Colors.black87;
    final overlaySecondary = overlayBrightness == Brightness.dark
        ? Colors.white70
        : Colors.black54;

    Widget buildHeroBookCard() {
      return SizedBox(
        width: coverWidth,
        height: coverHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: coverImage,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: overlayHeight + 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayAuthor,
                        style: GoogleFonts.getFont(
                          _fontTheme.serifFont,
                          color: Colors.white70,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        displayTitle,
                        style: GoogleFonts.getFont(
                          _fontTheme.serifFont,
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: overlayHeight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: themeColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.progress,
                              style: GoogleFonts.getFont(
                                _fontTheme.sansFont,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: overlayPrimary,
                              ),
                            ),
                            Text(
                              progressText,
                              style: GoogleFonts.getFont(
                                _fontTheme.sansFont,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: overlayPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: progressValue,
                            backgroundColor: overlayPrimary.withValues(
                              alpha: 0.2,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              overlayPrimary,
                            ),
                            minHeight: 5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          lastReadText,
                          style: GoogleFonts.getFont(
                            _fontTheme.sansFont,
                            fontSize: 10,
                            color: overlaySecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: coverHeight + 120,
      width: coverWidth + 160,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Background blurs
          Positioned(
            top: 4,
            left: 0,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFC5BCAB).withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 8,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFB5C9C3).withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Tilted Book Card
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _handleOpenBook(recentBook),
              borderRadius: BorderRadius.circular(32),
              child: Transform.rotate(
                angle: tiltAngle,
                child: buildHeroBookCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Recently Read Section
  Widget _buildRecentlyRead(List<Book> recentBooks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.recently_read,
                  style: GoogleFonts.getFont(
                    _fontTheme.serifFont,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: _theme.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.continue_journey,
                  style: GoogleFonts.getFont(
                    _fontTheme.sansFont,
                    fontSize: 14,
                    color: _theme.textLight,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.chevronLeft, size: 16),
                  style: IconButton.styleFrom(
                    shape: const CircleBorder(),
                    side: BorderSide(color: _theme.textColor),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.chevronRight, size: 16),
                  style: IconButton.styleFrom(
                    shape: const CircleBorder(),
                    side: BorderSide(color: _theme.textColor),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentBooks.length + 1,
            itemBuilder: (context, index) {
              return index == recentBooks.length
                  ? _buildAddMoreCard()
                  : _buildBookCard(recentBooks[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookCard(Book book) {
    final progress = book.progress.clamp(0.0, 1.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await ref.read(bookListProvider.notifier).markBookOpened(book.id);
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BookReaderScreen(book: book),
            ),
          );
        },
        borderRadius: BorderRadius.circular(10),
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.only(right: 24),
          child: BookCoverWidget(
            book: book,
            theme: _theme,
            overlayWidgets: [
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
              // Book info at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: GoogleFonts.getFont(
                          _fontTheme.serifFont,
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.author,
                        style: GoogleFonts.getFont(
                          _fontTheme.sansFont,
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _theme.highlight,
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddMoreCard() {
    return Container(
      margin: const EdgeInsets.only(right: 24),
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: _theme.textColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            onTap: () {
              setState(() {
                _activeTab = 1;
              });
            },
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.plus,
                    size: 32,
                    color: _theme.textColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.explore_more,
                    style: GoogleFonts.getFont(
                      _fontTheme.sansFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _theme.textColor.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.open_library,
                    style: GoogleFonts.getFont(
                      _fontTheme.sansFont,
                      fontSize: 10,
                      color: _theme.textColor.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Stats and Notes Grid
  Widget _buildStatsAndNotes() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildReadingCalendar()),
          const SizedBox(width: 24),
          Expanded(child: _buildNotesCard()),
        ],
      ),
    );
  }

  Widget _buildReadingCalendar() {
    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    // Dynamic colors based on dark mode
    final cardBg = _darkMode ? const Color(0xFF131B24) : _theme.cardBackground;
    final borderColor = _darkMode
        ? const Color(0xFF2D3748)
        : const Color(0xFFC5BCAB);
    final textColor = _darkMode ? const Color(0xFFE3DAC9) : _theme.textColor;
    final iconBg = _darkMode ? const Color(0xFF1C2530) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.reading_schedule,
                style: GoogleFonts.getFont(
                  _fontTheme.serifFont,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Icon(LucideIcons.settings, size: 18, color: _theme.textLight),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isActive = index == 2;
              return Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive ? _theme.textColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      days[index],
                      style: GoogleFonts.getFont(
                        _fontTheme.sansFont,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isActive
                            ? _theme.cardBackground.withValues(alpha: 0.7)
                            : _theme.textLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${11 + index}',
                      style: GoogleFonts.getFont(
                        _fontTheme.sansFont,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isActive ? _theme.cardBackground : textColor,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.only(top: 24),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: borderColor, style: BorderStyle.solid),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    LucideIcons.clock,
                    color: _theme.textColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.todays_goal,
                        style: GoogleFonts.getFont(
                          _fontTheme.sansFont,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.goal_msg,
                        style: GoogleFonts.getFont(
                          _fontTheme.sansFont,
                          fontSize: 12,
                          color: _theme.textLight,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    // Dynamic colors based on dark mode
    final cardBg = _darkMode ? const Color(0xFF131B24) : _theme.cardBackground;
    final borderColor = _darkMode
        ? const Color(0xFF2D3748)
        : const Color(0xFFC5BCAB);
    final textColor = _darkMode ? const Color(0xFFE3DAC9) : _theme.textColor;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.notes_highlight,
                style: GoogleFonts.getFont(
                  _fontTheme.serifFont,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Icon(LucideIcons.penTool, size: 18, color: _theme.textLight),
            ],
          ),
          const SizedBox(height: 24),
          // No hardcoded notes - will be populated from actual data
        ],
      ),
    );
  }

  // === LIBRARY TAB ===
  Widget _buildLibraryTab() {
    return LibraryScreen(
      theme: _theme,
      fontTheme: _fontTheme,
      isDarkMode: _darkMode,
    );
  }

  // === STATS TAB ===
  Widget _buildStatsTab() {
    final cardBg = _darkMode ? const Color(0xFF131B24) : _theme.cardBackground;
    final borderColor = _darkMode
        ? const Color(0xFF2D3748)
        : const Color(0xFFC5BCAB);
    final textColor = _darkMode ? Colors.white : _theme.textColor;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.stats,
                    style: GoogleFonts.getFont(
                      _fontTheme.serifFont,
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.reading_habit,
                    style: GoogleFonts.getFont(
                      _fontTheme.sansFont,
                      fontSize: 14,
                      color: _theme.textLight,
                    ),
                  ),
                ],
              ),
              // Settings Icon Trigger
              IconButton(
                onPressed: () {
                  _scaffoldKey.currentState?.openEndDrawer();
                },
                icon: Icon(
                  LucideIcons.settings,
                  size: 20,
                  color: _theme.textLight,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: _darkMode
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Today's Reading Summary Card
          _buildTodayReadingCard(cardBg, borderColor, textColor),
          const SizedBox(height: 24),

          // Stat Cards Grid
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard(
                LucideIcons.book,
                '${_statsService.booksRead}',
                AppLocalizations.of(context)!.books_read,
                cardBg,
                borderColor,
                textColor,
                false,
              ),
              _buildStatCard(
                LucideIcons.clock,
                _statsService.getFormattedTotalTime(),
                AppLocalizations.of(context)!.reading_hours,
                cardBg,
                borderColor,
                textColor,
                false,
              ),
              _buildStatCard(
                LucideIcons.zap,
                '${_statsService.currentStreak}',
                AppLocalizations.of(context)!.streak,
                cardBg,
                borderColor,
                textColor,
                _statsService.currentStreak > 0,
              ),
              _buildStatCard(
                LucideIcons.fileText,
                _statsService.getFormattedPages(),
                AppLocalizations.of(context)!.pages,
                cardBg,
                borderColor,
                textColor,
                false,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Activity Chart
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.activity_week,
                      style: GoogleFonts.getFont(
                        _fontTheme.serifFont,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _theme.textColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.this_week,
                        style: GoogleFonts.getFont(
                          _fontTheme.sansFont,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _theme.textLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tổng: ${_statsService.weeklyTotalMinutes ~/ 60}h ${_statsService.weeklyTotalMinutes % 60} phút đọc',
                  style: GoogleFonts.getFont(
                    _fontTheme.sansFont,
                    fontSize: 13,
                    color: _theme.textLight,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 192,
                  child: Builder(
                    builder: (context) {
                      final weeklyMinutes = _statsService.weeklyReadingMinutes;
                      final maxMinutes = weeklyMinutes.reduce(
                        (a, b) => a > b ? a : b,
                      );
                      final normalizedMax = maxMinutes > 0 ? maxMinutes : 60;
                      final todayIndex = DateTime.now().weekday - 1;
                      final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(7, (index) {
                          final percentage =
                              (weeklyMinutes[index] / normalizedMax * 100)
                                  .clamp(5, 100)
                                  .toInt();
                          return _buildBarChart(
                            percentage,
                            days[index],
                            index == todayIndex,
                            textColor,
                          );
                        }),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Monthly Goal Progress
          _buildMonthlyGoalCard(cardBg, borderColor, textColor),
          const SizedBox(height: 32),

          // Achievements
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.achievements,
                  style: GoogleFonts.getFont(
                    _fontTheme.serifFont,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                // Bookworm achievement - Read 7 days in a row
                _buildAchievementRow(
                  icon: LucideIcons.trophy,
                  title: AppLocalizations.of(context)!.bookworm,
                  description: AppLocalizations.of(context)!.read_7_days,
                  currentValue: _statsService.currentStreak.clamp(0, 7),
                  targetValue: 7,
                  textColor: textColor,
                ),
                const SizedBox(height: 16),
                // Book collector achievement - Read 5 books
                _buildAchievementRow(
                  icon: LucideIcons.library,
                  title: 'Nhà sưu tập sách',
                  description: 'Đọc xong 5 cuốn sách',
                  currentValue: _statsService.booksRead.clamp(0, 5),
                  targetValue: 5,
                  textColor: textColor,
                ),
                const SizedBox(height: 16),
                // Page turner achievement - Read 100 pages
                _buildAchievementRow(
                  icon: LucideIcons.bookOpen,
                  title: 'Mọt sách',
                  description: 'Đọc 100 trang sách',
                  currentValue: _statsService.totalPages.clamp(0, 100),
                  targetValue: 100,
                  textColor: textColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    Color cardBg,
    Color borderColor,
    Color textColor,
    bool hasHotBadge,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 20, color: _theme.textLight),
              if (hasHotBadge)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.yellow[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'HOT',
                    style: GoogleFonts.getFont(
                      _fontTheme.sansFont,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellow[800],
                    ),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.getFont(
                  _fontTheme.serifFont,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.getFont(
                  _fontTheme.sansFont,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _theme.textLight,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(
    int height,
    String day,
    bool isActive,
    Color textColor,
  ) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                height: (height / 100) * 192,
                decoration: BoxDecoration(
                  color: isActive
                      ? _theme.highlight
                      : _theme.textColor.withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            day,
            style: GoogleFonts.getFont(
              _fontTheme.sansFont,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _theme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementRow({
    required IconData icon,
    required String title,
    required String description,
    required int currentValue,
    required int targetValue,
    required Color textColor,
  }) {
    final progress = targetValue > 0 ? currentValue / targetValue : 0.0;
    final isCompleted = currentValue >= targetValue;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isCompleted
                ? _theme.highlight.withValues(alpha: 0.2)
                : _theme.textColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            isCompleted ? LucideIcons.checkCircle : icon,
            size: 24,
            color: isCompleted ? _theme.highlight : _theme.textColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.getFont(
                  _fontTheme.sansFont,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.getFont(
                  _fontTheme.sansFont,
                  fontSize: 12,
                  color: _theme.textLight,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: _darkMode
                      ? const Color(0xFF2D3748)
                      : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted
                        ? _theme.highlight
                        : _theme.highlight.withValues(alpha: 0.7),
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '$currentValue/$targetValue',
          style: GoogleFonts.getFont(
            _fontTheme.sansFont,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isCompleted ? _theme.highlight : _theme.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildTodayReadingCard(
    Color cardBg,
    Color borderColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_theme.textColor, _theme.textColor.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _theme.textColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hôm nay',
                  style: GoogleFonts.getFont(
                    _fontTheme.sansFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _statsService.getFormattedTodayTime(),
                      style: GoogleFonts.getFont(
                        _fontTheme.serifFont,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _statsService.todayReadingMinutes >= 60 ? '' : 'phút',
                        style: GoogleFonts.getFont(
                          _fontTheme.sansFont,
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress to daily goal
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _statsService.dailyProgress.clamp(0.0, 1.0),
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(_statsService.dailyProgress * 100).clamp(0, 100).toInt()}%',
                      style: GoogleFonts.getFont(
                        _fontTheme.sansFont,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _statsService.dailyProgress >= 1.0
                      ? '🎉 Đã đạt mục tiêu ${_statsService.dailyGoalMinutes} phút/ngày!'
                      : 'Còn ${_statsService.getRemainingMinutesToGoal()} phút nữa để đạt mục tiêu ${_statsService.dailyGoalMinutes} phút/ngày',
                  style: GoogleFonts.getFont(
                    _fontTheme.sansFont,
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Circular progress
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: _statsService.dailyProgress.clamp(0.0, 1.0),
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _statsService.dailyProgress >= 1.0
                          ? LucideIcons.checkCircle
                          : LucideIcons.target,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_statsService.todayReadingMinutes}/${_statsService.dailyGoalMinutes}',
                      style: GoogleFonts.getFont(
                        _fontTheme.sansFont,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyGoalCard(
    Color cardBg,
    Color borderColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mục tiêu tháng này',
                style: GoogleFonts.getFont(
                  _fontTheme.serifFont,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _theme.highlight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Tháng ${DateTime.now().month}',
                  style: GoogleFonts.getFont(
                    _fontTheme.sansFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _theme.highlight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Goals grid
          Row(
            children: [
              Expanded(
                child: _buildGoalItem(
                  'Sách đọc',
                  '${_statsService.monthlyBooksRead}/${_statsService.monthlyBookGoal}',
                  _statsService.monthlyBookProgress.clamp(0.0, 1.0),
                  LucideIcons.book,
                  textColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGoalItem(
                  'Giờ đọc',
                  _statsService.getFormattedMonthlyTime(),
                  _statsService.monthlyHoursProgress.clamp(0.0, 1.0),
                  LucideIcons.clock,
                  textColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGoalItem(
                  'Trang sách',
                  _statsService.getFormattedMonthlyPages(),
                  _statsService.monthlyPagesProgress.clamp(0.0, 1.0),
                  LucideIcons.fileText,
                  textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem(
    String label,
    String value,
    double progress,
    IconData icon,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _darkMode
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: _theme.textLight),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.getFont(
              _fontTheme.serifFont,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.getFont(
              _fontTheme.sansFont,
              fontSize: 12,
              color: _theme.textLight,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: _theme.textColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(_theme.highlight),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  // === SAVED TAB ===
  String _savedTabFilter = 'all'; // 'all', 'bookmarks', 'highlights', 'notes'

  Widget _buildSavedTab() {
    final cardBg = _darkMode ? const Color(0xFF131B24) : _theme.cardBackground;
    final borderColor = _darkMode
        ? const Color(0xFF2D3748)
        : const Color(0xFFC5BCAB);
    final textColor = _darkMode ? Colors.white : _theme.textColor;

    return AnimatedBuilder(
      animation: _savedContentService,
      builder: (context, _) {
        final bookmarks = _savedContentService.bookmarks;
        final highlights = _savedContentService.highlights;
        final notes = _savedContentService.notes;
        final totalSaved = _savedContentService.totalCount;

        bool hasDataForFilter;
        switch (_savedTabFilter) {
          case 'bookmarks':
            hasDataForFilter = bookmarks.isNotEmpty;
            break;
          case 'highlights':
            hasDataForFilter = highlights.isNotEmpty;
            break;
          case 'notes':
            hasDataForFilter = notes.isNotEmpty;
            break;
          default:
            hasDataForFilter = totalSaved > 0;
        }

        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.saved,
                        style: GoogleFonts.getFont(
                          _fontTheme.serifFont,
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalSaved mục đã lưu',
                        style: GoogleFonts.getFont(
                          _fontTheme.sansFont,
                          fontSize: 14,
                          color: _theme.textLight,
                        ),
                      ),
                    ],
                  ),
                  // Search button
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      LucideIcons.search,
                      size: 20,
                      color: _theme.textLight,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: _darkMode
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Filter tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'Tất cả', LucideIcons.layers),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'bookmarks',
                      'Đánh dấu',
                      LucideIcons.bookmark,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'highlights',
                      'Highlight',
                      LucideIcons.highlighter,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip('notes', 'Ghi chú', LucideIcons.penTool),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (!hasDataForFilter)
                _buildSavedEmptyState(
                  textColor,
                  message: _savedTabFilter == 'bookmarks'
                      ? 'Chưa có trang nào được đánh dấu'
                      : _savedTabFilter == 'highlights'
                      ? 'Chưa có đoạn highlight'
                      : _savedTabFilter == 'notes'
                      ? 'Chưa có ghi chú nào'
                      : 'Chưa có mục nào được lưu',
                )
              else ...[
                if (_savedTabFilter == 'all' || _savedTabFilter == 'bookmarks')
                  _buildBookmarksSection(
                    cardBg,
                    borderColor,
                    textColor,
                    bookmarks,
                  ),
                if (_savedTabFilter == 'all' || _savedTabFilter == 'highlights')
                  _buildHighlightsSection(
                    cardBg,
                    borderColor,
                    textColor,
                    highlights,
                  ),
                if (_savedTabFilter == 'all' || _savedTabFilter == 'notes')
                  _buildNotesSection(cardBg, borderColor, textColor, notes),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String filter, String label, IconData icon) {
    final isSelected = _savedTabFilter == filter;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _savedTabFilter = filter),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? _theme.textColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? _theme.textColor
                  : _theme.textLight.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? (_darkMode ? Colors.black : _theme.cardBackground)
                    : _theme.textLight,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.getFont(
                  _fontTheme.sansFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? (_darkMode ? Colors.black : _theme.cardBackground)
                      : _theme.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedEmptyState(Color textColor, {required String message}) {
    final borderColor = _theme.textLight.withValues(alpha: 0.2);
    final bgColor = _darkMode
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.02);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(LucideIcons.bookmarkMinus, size: 32, color: _theme.textLight),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.getFont(
              _fontTheme.sansFont,
              fontSize: 14,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksSection(
    Color cardBg,
    Color borderColor,
    Color textColor,
    List<SavedBookmark> bookmarks,
  ) {
    if (bookmarks.isEmpty) return const SizedBox.shrink();

    final items = (_savedTabFilter == 'all' ? bookmarks.take(2) : bookmarks)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_savedTabFilter == 'all')
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(LucideIcons.bookmark, size: 18, color: _theme.textLight),
                const SizedBox(width: 8),
                Text(
                  'Đánh dấu trang',
                  style: GoogleFonts.getFont(
                    _fontTheme.sansFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _theme.textLight,
                  ),
                ),
              ],
            ),
          ),
        ...items.map((bookmark) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _theme.highlight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LucideIcons.bookOpen,
                    color: _theme.highlight,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bookmark.bookTitle,
                        style: GoogleFonts.getFont(
                          _fontTheme.serifFont,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${bookmark.chapterLabel} • ${bookmark.formattedProgress}',
                        style: GoogleFonts.getFont(
                          _fontTheme.sansFont,
                          fontSize: 12,
                          color: _theme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatSavedDate(bookmark.createdAt),
                      style: GoogleFonts.getFont(
                        _fontTheme.sansFont,
                        fontSize: 11,
                        color: _theme.textLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: _theme.textLight,
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHighlightsSection(
    Color cardBg,
    Color borderColor,
    Color textColor,
    List<Highlight> highlights,
  ) {
    if (highlights.isEmpty) return const SizedBox.shrink();

    final items = (_savedTabFilter == 'all' ? highlights.take(2) : highlights)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_savedTabFilter == 'all')
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(
                  LucideIcons.highlighter,
                  size: 18,
                  color: _theme.textLight,
                ),
                const SizedBox(width: 8),
                Text(
                  'Highlight',
                  style: GoogleFonts.getFont(
                    _fontTheme.sansFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _theme.textLight,
                  ),
                ),
              ],
            ),
          ),
        ...items.map((highlight) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: highlight.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      highlight.bookTitle,
                      style: GoogleFonts.getFont(
                        _fontTheme.sansFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _theme.textLight,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatSavedDate(highlight.createdAt),
                      style: GoogleFonts.getFont(
                        _fontTheme.sansFont,
                        fontSize: 11,
                        color: _theme.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: highlight.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(color: highlight.color, width: 3),
                    ),
                  ),
                  child: Text(
                    '"${highlight.selectedText}"',
                    style: GoogleFonts.getFont(
                      _fontTheme.serifFont,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: textColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildNotesSection(
    Color cardBg,
    Color borderColor,
    Color textColor, [
    List<Note> notes = const [],
  ]) {
    if (notes.isEmpty) return const SizedBox.shrink();

    final items = (_savedTabFilter == 'all' ? notes.take(2) : notes).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_savedTabFilter == 'all')
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(LucideIcons.penTool, size: 18, color: _theme.textLight),
                const SizedBox(width: 8),
                Text(
                  'Ghi chú',
                  style: GoogleFonts.getFont(
                    _fontTheme.sansFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _theme.textLight,
                  ),
                ),
              ],
            ),
          ),
        ...items.map((note) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.fileText,
                      size: 16,
                      color: _theme.highlight,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      note.bookTitle,
                      style: GoogleFonts.getFont(
                        _fontTheme.sansFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _theme.textLight,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatSavedDate(note.createdAt),
                      style: GoogleFonts.getFont(
                        _fontTheme.sansFont,
                        fontSize: 11,
                        color: _theme.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '"${note.selectedText}"',
                  style: GoogleFonts.getFont(
                    _fontTheme.serifFont,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: _theme.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _darkMode
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.messageSquare,
                        size: 14,
                        color: _theme.textLight,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          note.content,
                          style: GoogleFonts.getFont(
                            _fontTheme.sansFont,
                            fontSize: 13,
                            color: textColor,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  String _formatSavedDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';

    return '${date.day}/${date.month}/${date.year}';
  }

  // === FLOATING BOTTOM NAVIGATION ===
  Widget _buildFloatingNav() {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _darkMode
                ? const Color(0xFFE3DAC9).withValues(alpha: 0.95)
                : _theme.textColor.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: _darkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFF4A635D).withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNavItem(
                0,
                LucideIcons.home,
                AppLocalizations.of(context)!.home,
              ),
              _buildNavItem(
                1,
                LucideIcons.book,
                AppLocalizations.of(context)!.library,
              ),
              _buildNavItem(
                2,
                LucideIcons.barChart2,
                AppLocalizations.of(context)!.stats,
              ),
              _buildNavItem(
                3,
                LucideIcons.bookmark,
                AppLocalizations.of(context)!.saved,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _activeTab == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _activeTab = index;
            });
          },
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isActive ? 20 : 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? (_darkMode
                        ? Colors.black.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.15))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isActive
                      ? (_darkMode ? Colors.black : Colors.white)
                      : (_darkMode
                            ? Colors.black.withValues(alpha: 0.5)
                            : _theme.cardBackground.withValues(alpha: 0.6)),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isActive ? 8 : 0,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: isActive
                      ? Text(
                          label,
                          style: GoogleFonts.getFont(
                            _fontTheme.sansFont,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _darkMode ? Colors.black : Colors.white,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // === NOTIFICATIONS OVERLAY ===
  Widget _buildNotificationsOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showNotifications = false;
          });
        },
        child: Container(
          color: Colors.black.withValues(alpha: 0.2),
          child: Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping the panel
              child: Container(
                margin: const EdgeInsets.only(top: 80, right: 24),
                width: 360,
                height: 500,
                decoration: BoxDecoration(
                  color: _theme.cardBackground.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC5BCAB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.notifications,
                            style: GoogleFonts.getFont(
                              _fontTheme.serifFont,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _theme.textColor,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _showNotifications = false;
                              });
                            },
                            icon: const Icon(LucideIcons.x, size: 18),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      color: const Color(0xFFC5BCAB).withValues(alpha: 0.3),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildNotificationItem(
                            LucideIcons.trophy,
                            'Mục tiêu hoàn thành!',
                            'Bạn đã đạt 30 phút đọc sách hôm nay.',
                            '2 giờ trước',
                            isUnread: true,
                          ),
                          _buildNotificationItem(
                            LucideIcons.book,
                            'Sách mới: "Tâm lý học"',
                            'Cuốn sách bạn quan tâm đã có mặt.',
                            '5 giờ trước',
                            isUnread: true,
                          ),
                          _buildNotificationItem(
                            LucideIcons.zap,
                            'Cập nhật hệ thống',
                            'Flux Alpha v2.1 đã sẵn sàng.',
                            '1 ngày trước',
                            isUnread: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    IconData icon,
    String title,
    String description,
    String time, {
    bool isUnread = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0DED5)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F3F1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 18, color: _theme.textColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.getFont(
                          _fontTheme.sansFont,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _theme.textColor,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _theme.highlight,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.getFont(
                    _fontTheme.sansFont,
                    fontSize: 12,
                    color: _theme.textLight,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: GoogleFonts.getFont(
                    _fontTheme.sansFont,
                    fontSize: 10,
                    color: _theme.textLight.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === SETTINGS DRAWER ===
  Widget _buildSettingsDrawer() {
    final drawerBg = _darkMode ? const Color(0xFF131B24) : Colors.white;
    final borderColor = _darkMode ? const Color(0xFF2D3748) : Colors.grey[200]!;
    final textColor = _darkMode ? Colors.white : Colors.grey[800]!;
    final textLight = _darkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = _darkMode ? const Color(0xFF1E293B) : Colors.grey[50]!;

    return Container(
      width: 320,
      color: drawerBg,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.settings, size: 20, color: textColor),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.settings,
                        style: GoogleFonts.getFont(
                          _fontTheme.sansFont,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(LucideIcons.x, size: 20, color: textColor),
                    style: IconButton.styleFrom(
                      backgroundColor: _darkMode
                          ? const Color(0xFF1E293B)
                          : Colors.grey[100],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Section: Dark Mode
                  Row(
                    children: [
                      Icon(LucideIcons.moon, size: 14, color: textLight),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.dark_mode,
                        style: GoogleFonts.getFont(
                          _fontTheme.sansFont,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textLight,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildToggleRow(
                    AppLocalizations.of(context)!.enable_dark_mode,
                    _darkMode,
                    (value) {
                      setState(() => _darkMode = value);
                      _updateWindowTitleBar();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildToggleRow(
                    AppLocalizations.of(context)!.auto_schedule,
                    _scheduleDarkMode,
                    (value) => setState(() => _scheduleDarkMode = value),
                  ),
                  if (_scheduleDarkMode) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.turn_on_at,
                                style: GoogleFonts.getFont(
                                  _fontTheme.sansFont,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: textLight,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: _darkModeStartTime,
                                  );
                                  if (time != null) {
                                    setState(() => _darkModeStartTime = time);
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    border: Border.all(color: borderColor),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _darkModeStartTime.format(context),
                                    style: GoogleFonts.getFont(
                                      _fontTheme.sansFont,
                                      fontSize: 14,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.turn_off_at,
                                style: GoogleFonts.getFont(
                                  _fontTheme.sansFont,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: textLight,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: _darkModeEndTime,
                                  );
                                  if (time != null) {
                                    setState(() => _darkModeEndTime = time);
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    border: Border.all(color: borderColor),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _darkModeEndTime.format(context),
                                    style: GoogleFonts.getFont(
                                      _fontTheme.sansFont,
                                      fontSize: 14,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Section: Language
                  Row(
                    children: [
                      Icon(LucideIcons.globe, size: 14, color: textLight),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.language,
                        style: GoogleFonts.getFont(
                          _fontTheme.sansFont,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textLight,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            ref
                                .read(languageProvider.notifier)
                                .setLocale(const Locale('vi'));
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color:
                                  AppLocalizations.of(
                                        context,
                                      )!.locale.languageCode ==
                                      'vi'
                                  ? cardBg
                                  : Colors.transparent,
                              border: Border.all(
                                color:
                                    AppLocalizations.of(
                                          context,
                                        )!.locale.languageCode ==
                                        'vi'
                                    ? (_darkMode
                                          ? Colors.white
                                          : Colors.grey[400]!)
                                    : borderColor,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                AppLocalizations.of(context)!.vietnamese,
                                style: GoogleFonts.getFont(
                                  _fontTheme.sansFont,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            ref
                                .read(languageProvider.notifier)
                                .setLocale(const Locale('en'));
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color:
                                  AppLocalizations.of(
                                        context,
                                      )!.locale.languageCode ==
                                      'en'
                                  ? cardBg
                                  : Colors.transparent,
                              border: Border.all(
                                color:
                                    AppLocalizations.of(
                                          context,
                                        )!.locale.languageCode ==
                                        'en'
                                    ? (_darkMode
                                          ? Colors.white
                                          : Colors.grey[400]!)
                                    : borderColor,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                AppLocalizations.of(context)!.english,
                                style: GoogleFonts.getFont(
                                  _fontTheme.sansFont,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Section: Appearance
                  Row(
                    children: [
                      Icon(LucideIcons.palette, size: 14, color: textLight),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.appearance,
                        style: GoogleFonts.getFont(
                          _fontTheme.sansFont,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textLight,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Color Theme Selector
                  Text(
                    AppLocalizations.of(context)!.main_color,
                    style: GoogleFonts.getFont(
                      _fontTheme.sansFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: _darkMode ? 0.5 : 1.0,
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.5,
                      children: ColorThemes.themeNames.entries.map((entry) {
                        final themeId = entry.key;
                        // final themeName = entry.value; // Unused
                        final theme = ColorThemes.getTheme(themeId, _darkMode);
                        final isSelected =
                            !_darkMode && _currentColorTheme == themeId;

                        String localizedName;
                        switch (themeId) {
                          case 'forest':
                            localizedName = AppLocalizations.of(
                              context,
                            )!.theme_forest;
                            break;
                          case 'charcoal':
                            localizedName = AppLocalizations.of(
                              context,
                            )!.theme_charcoal;
                            break;
                          case 'espresso':
                            localizedName = AppLocalizations.of(
                              context,
                            )!.theme_espresso;
                            break;
                          case 'ink':
                            localizedName = AppLocalizations.of(
                              context,
                            )!.theme_ink;
                            break;
                          default:
                            localizedName = theme.name;
                        }

                        return InkWell(
                          onTap: _darkMode
                              ? null
                              : () => setState(
                                  () => _currentColorTheme = themeId,
                                ),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? cardBg : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? (_darkMode
                                          ? Colors.white
                                          : Colors.grey[400]!)
                                    : borderColor,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: theme.accentBg,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _darkMode
                                          ? Colors.grey[600]!
                                          : Colors.grey[300]!,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    localizedName,
                                    style: GoogleFonts.getFont(
                                      _fontTheme.sansFont,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Font Theme Selector
                  Text(
                    AppLocalizations.of(context)!.font_style,
                    style: GoogleFonts.getFont(
                      _fontTheme.sansFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...FontThemes.all.entries.map((entry) {
                    final theme = entry.value;
                    final isSelected = _currentFontTheme == theme.id;

                    String localizedName;
                    String localizedDesc;
                    switch (theme.id) {
                      case 'default':
                        localizedName = AppLocalizations.of(
                          context,
                        )!.font_default;
                        localizedDesc = AppLocalizations.of(
                          context,
                        )!.desc_font_default;
                        break;
                      case 'contemporary':
                        localizedName = AppLocalizations.of(
                          context,
                        )!.font_contemporary;
                        localizedDesc = AppLocalizations.of(
                          context,
                        )!.desc_font_contemporary;
                        break;
                      case 'vintage':
                        localizedName = AppLocalizations.of(
                          context,
                        )!.font_vintage;
                        localizedDesc = AppLocalizations.of(
                          context,
                        )!.desc_font_vintage;
                        break;
                      case 'academic':
                        localizedName = AppLocalizations.of(
                          context,
                        )!.font_academic;
                        localizedDesc = AppLocalizations.of(
                          context,
                        )!.desc_font_academic;
                        break;
                      case 'bold':
                        localizedName = AppLocalizations.of(context)!.font_bold;
                        localizedDesc = AppLocalizations.of(
                          context,
                        )!.desc_font_bold;
                        break;
                      default:
                        localizedName = theme.name;
                        localizedDesc = theme.description;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () =>
                            setState(() => _currentFontTheme = theme.id),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? cardBg : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? (_darkMode
                                        ? Colors.white
                                        : Colors.grey[400]!)
                                  : borderColor,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      localizedName,
                                      style: GoogleFonts.getFont(
                                        theme.serifFont,
                                        fontSize: 14,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      localizedDesc,
                                      style: GoogleFonts.getFont(
                                        theme.sansFont,
                                        fontSize: 10,
                                        color: textLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 32),

                  // Section: Storage
                  Row(
                    children: [
                      Icon(LucideIcons.folder, size: 14, color: textLight),
                      const SizedBox(width: 6),
                      Text(
                        'Lưu trữ',
                        style: GoogleFonts.getFont(
                          _fontTheme.sansFont,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textLight,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current Location Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Vị trí hiện tại',
                              style: GoogleFonts.getFont(
                                _fontTheme.sansFont,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          StorageService().rootLibraryPath ??
                              'Chưa được thiết lập',
                          style: GoogleFonts.getFont(
                            _fontTheme.sansFont,
                            fontSize: 12,
                            color: textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        // Change Folder Button
                        InkWell(
                          onTap: () {
                            Navigator.pop(context); // Close drawer
                            _showChangeLibraryConfirmation(context);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: _theme.accentBg.withValues(alpha: 0.1),
                              border: Border.all(
                                color: _theme.accentBg,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.folderOpen,
                                  size: 16,
                                  color: _theme.accentBg,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Thay đổi thư mục',
                                  style: GoogleFonts.getFont(
                                    _fontTheme.sansFont,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _theme.accentBg,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Section: Account (Placeholder)
                  Row(
                    children: [
                      Icon(LucideIcons.user, size: 14, color: textLight),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.account,
                        style: GoogleFonts.getFont(
                          _fontTheme.sansFont,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textLight,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.profile,
                      style: GoogleFonts.getFont(
                        _fontTheme.sansFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.security,
                      style: GoogleFonts.getFont(
                        _fontTheme.sansFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final textColor = _darkMode ? Colors.grey[300]! : Colors.grey[700]!;
    final activeColor = _theme.accentBg;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.getFont(
            _fontTheme.sansFont,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onChanged(!value),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 48,
              height: 24,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: value ? activeColor : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedAlign(
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // === PROFILE MENU ===
  Widget _buildProfileMenu() {
    if (!_showProfileMenu) return const SizedBox.shrink();

    final cardBg = _darkMode ? const Color(0xFF131B24) : _theme.cardBackground;
    final borderColor = _darkMode
        ? const Color(0xFF2D3748)
        : const Color(0xFFC5BCAB);
    final textColor = _darkMode ? Colors.white : _theme.textColor;
    final hoverColor = _darkMode
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);

    return Positioned(
      top: 80,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 256,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: borderColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage(
                            'https://api.dicebear.com/7.x/avataaars/svg?seed=Felix',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Minh Nhật',
                            style: GoogleFonts.getFont(
                              _fontTheme.sansFont,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Text(
                            'minhnhat@flux.io',
                            style: GoogleFonts.getFont(
                              _fontTheme.sansFont,
                              fontSize: 12,
                              color: _theme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildProfileMenuItem(
                LucideIcons.user,
                AppLocalizations.of(context)!.profile,
                () {},
                hoverColor,
                textColor,
              ),
              _buildProfileMenuItem(
                LucideIcons.settings,
                AppLocalizations.of(context)!.settings,
                () {
                  setState(() => _showProfileMenu = false);
                  _scaffoldKey.currentState?.openEndDrawer();
                },
                hoverColor,
                textColor,
              ),
              _buildProfileMenuItem(
                LucideIcons.helpCircle,
                AppLocalizations.of(context)!.help,
                () {},
                hoverColor,
                textColor,
              ),
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: borderColor.withValues(alpha: 0.5),
              ),
              _buildProfileMenuItem(
                LucideIcons.logOut,
                AppLocalizations.of(context)!.logout,
                () {},
                Colors.red.withValues(alpha: 0.1),
                Colors.red[600]!,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem(
    IconData icon,
    String label,
    VoidCallback onTap,
    Color hoverColor,
    Color textColor,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.getFont(
                _fontTheme.sansFont,
                fontSize: 14,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === CHANGE LIBRARY CONFIRMATION ===
  void _showChangeLibraryConfirmation(BuildContext context) {
    final drawerBg = _darkMode ? const Color(0xFF131B24) : Colors.white;
    final textColor = _darkMode ? Colors.white : Colors.grey[800]!;
    final textLight = _darkMode ? Colors.grey[400]! : Colors.grey[600]!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: drawerBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Xác nhận thay đổi',
          style: GoogleFonts.getFont(
            _fontTheme.serifFont,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        content: Text(
          'Bạn có chắc muốn đổi thư mục không? App sẽ khởi động lại quy trình chọn thư mục.',
          style: GoogleFonts.getFont(
            _fontTheme.sansFont,
            fontSize: 14,
            color: textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Hủy',
              style: GoogleFonts.getFont(
                _fontTheme.sansFont,
                fontSize: 14,
                color: textLight,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              await _changeLibraryLocation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _theme.textColor,
              foregroundColor: _theme.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Xác nhận',
              style: GoogleFonts.getFont(
                _fontTheme.sansFont,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === CHANGE LIBRARY LOCATION ===
  Future<void> _changeLibraryLocation() async {
    try {
      // Clear the saved library path from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('custom_library_path');

      debugPrint('[Settings] Cleared library path from SharedPreferences');

      // Navigate to WelcomeScreen and remove all previous routes
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('[Settings] Error changing library location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi khi thay đổi thư mục: $e',
              style: GoogleFonts.getFont(_fontTheme.sansFont, fontSize: 14),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
