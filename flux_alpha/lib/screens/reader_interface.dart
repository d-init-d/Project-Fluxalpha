import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:lucide_icons/lucide_icons.dart';

import '../models/chapter_data.dart';

// --- Theme Configurations ---
class ReaderTheme {
  final Color bg;
  final Color text;
  final Color accent;
  final Color panelBg;
  final Color panelBorder;
  final Color textSecondary;
  final Color
  selection; // Note: Flutter selection color is usually handled by the widget theme, but we can use it for highlights
  final Color sliderTrack;
  final Color iconActive;
  final Color buttonBg;
  final Color buttonText; // Added for button text color
  final Color buttonSecondaryBg;
  final Color buttonSecondaryText; // Added for secondary button text color

  const ReaderTheme({
    required this.bg,
    required this.text,
    required this.accent,
    required this.panelBg,
    required this.panelBorder,
    required this.textSecondary,
    required this.selection,
    required this.sliderTrack,
    required this.iconActive,
    required this.buttonBg,
    required this.buttonText,
    required this.buttonSecondaryBg,
    required this.buttonSecondaryText,
  });

  static const paper = ReaderTheme(
    bg: Color(0xFFEBE8E0),
    text: Color(0xFF1F2937),
    accent: Color(0xFF1E3A2F),
    panelBg: Color(0xFFE6E2D8),
    panelBorder: Colors.transparent,
    textSecondary: Color(0xFF6B7280),
    selection: Color(0x331E3A2F), // 20% opacity
    sliderTrack: Color(0xFFD1CDC3),
    iconActive: Color(0xFF1E3A2F),
    buttonBg: Color(0xFF1E3A2F),
    buttonText: Colors.white,
    buttonSecondaryBg: Color(0xFFDCD8CE),
    buttonSecondaryText: Color(0xFF1E3A2F),
  );

  static const sepia = ReaderTheme(
    bg: Color(0xFFF4ECD8),
    text: Color(0xFF5B4636),
    accent: Color(0xFF8B5E3C),
    panelBg: Color(0xFFE9E0C9),
    panelBorder: Color(0xFFD4C5A5),
    textSecondary: Color(0xFF8C7B6C),
    selection: Color(0x338B5E3C), // 20% opacity
    sliderTrack: Color(0xFFD4C5A5),
    iconActive: Color(0xFF8B5E3C),
    buttonBg: Color(0xFF8B5E3C),
    buttonText: Colors.white,
    buttonSecondaryBg: Color(0xFFDCCBA5),
    buttonSecondaryText: Color(0xFF5B4636),
  );

  static const dark = ReaderTheme(
    bg: Color(0xFF1a1c1e),
    text: Color(0xFFe2e2e2),
    accent: Color(0xFF4a6b5d),
    panelBg: Color(0xFF2a2d30),
    panelBorder: Color(0xFF3f4246),
    textSecondary: Color(0xFF9CA3AF), // gray-400
    selection: Color(0x4D4a6b5d), // 30% opacity
    sliderTrack: Color(0xFF3f4246),
    iconActive: Color(0xFF4a6b5d),
    buttonBg: Color(0xFF4a6b5d),
    buttonText: Colors.white,
    buttonSecondaryBg: Color(0xFF3f4246),
    buttonSecondaryText: Color(0xFFe2e2e2),
  );

  static const midnight = ReaderTheme(
    bg: Colors.black,
    text: Color(0xFFa9a9a9),
    accent: Color(0xFF333333),
    panelBg: Color(0xFF121212),
    panelBorder: Color(0xFF333333),
    textSecondary: Color(0xFF4B5563), // gray-600
    selection: Color(0x33FFFFFF), // white/20
    sliderTrack: Color(0xFF333333),
    iconActive: Color(0xFF666666),
    buttonBg: Color(0xFF333333),
    buttonText: Colors.white,
    buttonSecondaryBg: Color(0xFF222222),
    buttonSecondaryText: Color(0xFF888888),
  );

  static ReaderTheme getTheme(String mode) {
    switch (mode) {
      case 'sepia':
        return sepia;
      case 'dark':
        return dark;
      case 'midnight':
        return midnight;
      default:
        return paper;
    }
  }
}

class ReaderInterface extends StatefulWidget {
  final Map<String, dynamic>? book;
  final List<ChapterData> chapters;
  final int initialChapterIndex;
  final VoidCallback onClose;
  final bool darkMode; // Keeping darkMode as optional initial state

  const ReaderInterface({
    super.key,
    required this.book,
    required this.chapters,
    this.initialChapterIndex = 0,
    required this.onClose,
    this.darkMode = false,
  });

  @override
  State<ReaderInterface> createState() => _ReaderInterfaceState();
}

class _ReaderInterfaceState extends State<ReaderInterface>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  // --- States ---
  late double _fontSize;
  double _lineHeight = 1.8;
  String _wordSpacing = 'normal'; // 'normal', 'wide', 'wider'
  String _fontFamily = 'serif'; // 'serif', 'sans', 'mono'
  double _progress =
      35; // Initial mock value from React code, but we'll update it
  bool _showControls = true;
  String _themeMode = 'paper'; // 'paper', 'sepia', 'dark', 'midnight'
  bool _isBookmarked = false;

  // Modal States
  bool _showTOC = false;
  bool _showSearch = false;
  bool _showAppearanceMenu = false;

  late int _currentChapterIndex;
  _RenderedChapter? _renderedChapter;

  final TextEditingController _searchController = TextEditingController();

  ReaderTheme get _currentTheme => ReaderTheme.getTheme(_themeMode);

  @override
  void initState() {
    super.initState();
    _fontSize = 18;
    _currentChapterIndex = _clampChapterIndex(widget.initialChapterIndex);
    _renderedChapter = _prepareChapter();
    _scrollController.addListener(_onScroll);

    // Initialize theme mode based on widget props if needed, or default to paper
    // The React code defaults to 'paper', so we'll stick to that unless user passed dark mode
    if (widget.darkMode) {
      _themeMode = 'dark';
    }
  }

  @override
  void didUpdateWidget(covariant ReaderInterface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapters != widget.chapters ||
        oldWidget.initialChapterIndex != widget.initialChapterIndex) {
      _currentChapterIndex = _clampChapterIndex(widget.initialChapterIndex);
      _renderedChapter = _prepareChapter();
      _resetScroll();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  int _clampChapterIndex(int index) {
    if (widget.chapters.isEmpty) return 0;
    return index.clamp(0, widget.chapters.length - 1);
  }

  void _resetScroll() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    setState(() {
      _progress = 0;
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;

    if (maxScroll <= 0) {
      setState(() => _progress = 0);
      return;
    }

    setState(() {
      _progress = (current / maxScroll) * 100;
    });
  }

  _RenderedChapter? _prepareChapter() {
    if (widget.chapters.isEmpty) return null;
    final chapter = widget.chapters[_currentChapterIndex];
    // Simple parsing to remove scripts/styles and extract title if needed
    // In a real app, this might be more complex or done in background
    final document = html_parser.parse(chapter.content);
    final body = document.body;
    if (body == null) {
      return _RenderedChapter(
        title: chapter.title,
        html: '<p>${chapter.content}</p>',
        wordCount: _countWords(chapter.content),
      );
    }

    body
        .querySelectorAll('script, style')
        .forEach((element) => element.remove());

    // Try to find a heading in the content to use as title, or remove it if it duplicates
    // The React code shows "Khởi đầu" (Start) as title.
    // We will use the chapter title from metadata.

    // Clean up content
    final processedHtml = body.innerHtml.trim().isEmpty
        ? '<p></p>'
        : body.innerHtml.trim();
    final plainText = body.text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final wordCount = _countWords(plainText);

    return _RenderedChapter(
      title: chapter.title,
      html: processedHtml,
      wordCount: wordCount,
    );
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  void _handleContentClick() {
    setState(() {
      _showControls = !_showControls;
      _showAppearanceMenu = false;
      _showSearch = false;
    });
  }

  void _handleSliderChange(double value) {
    setState(() => _progress = value);
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(maxScroll * (value / 100));
    }
  }

  double _getWordSpacingValue() {
    switch (_wordSpacing) {
      case 'wide':
        return 2.0;
      case 'wider':
        return 5.0;
      default:
        return 0.0;
    }
  }

  String get _fontFamilyName {
    switch (_fontFamily) {
      case 'sans':
        return 'Manrope'; // Assuming Manrope is the sans font in the app
      case 'mono':
        return 'JetBrains Mono'; // Or any mono font available
      default:
        return 'Playfair Display'; // Assuming Playfair is the serif font
    }
  }

  int get _estimatedMinutes {
    final words = _renderedChapter?.wordCount ?? 0;
    if (words == 0) return 1;
    return (words / 220).ceil().clamp(1, 60);
  }

  @override
  Widget build(BuildContext context) {
    final theme = _currentTheme;

    return Scaffold(
      backgroundColor: theme.bg,
      body: Stack(
        children: [
          // Main Content
          GestureDetector(
            onTap: _handleContentClick,
            child: Container(
              color: theme.bg,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 80,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 720,
                    ), // max-w-2xl
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Chapter Header (React: text-center mb-16 pt-10)
                        const SizedBox(height: 40),
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'CHƯƠNG ${_currentChapterIndex + 1}',
                                style: GoogleFonts.getFont(
                                  _fontFamily == 'mono'
                                      ? 'JetBrains Mono'
                                      : (_fontFamily == 'sans'
                                            ? 'Manrope'
                                            : 'Playfair Display'),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 3, // tracking-[0.2em]
                                  color: theme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_renderedChapter != null)
                                Text(
                                  _renderedChapter!.title,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.getFont(
                                    _fontFamilyName,
                                    fontSize: 48, // text-5xl
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                    color: theme.text,
                                  ),
                                ),
                              const SizedBox(height: 32),
                              Container(
                                width: 64,
                                height: 1,
                                color: theme.text.withValues(alpha: 0.2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Content
                        if (_renderedChapter == null)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: theme.panelBg,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              'Không thể hiển thị nội dung.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.getFont(
                                _fontFamilyName,
                                fontSize: 16,
                                color: theme.text,
                              ),
                            ),
                          )
                        else
                          HtmlWidget(
                            _renderedChapter!.html,
                            renderMode: RenderMode.column,
                            textStyle: GoogleFonts.getFont(
                              _fontFamilyName,
                              fontSize: _fontSize,
                              height: _lineHeight,
                              wordSpacing: _getWordSpacingValue(),
                              color: theme.text,
                            ),
                            customStylesBuilder: (element) {
                              if (element.localName == 'p') {
                                return {
                                  'margin': '0 0 1.5em 0',
                                  'text-align': 'justify',
                                };
                              }
                              return {'text-align': 'justify'};
                            },
                          ),

                        // Chapter Navigation Buttons
                        const SizedBox(height: 48),
                        Container(
                          width: double.infinity,
                          height: 1,
                          color: theme.text.withValues(alpha: 0.15),
                        ),
                        const SizedBox(height: 32),
                        _buildChapterNavigationButtons(theme),
                        const SizedBox(height: 180),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // TOC Backdrop
          if (_showTOC)
            GestureDetector(
              onTap: () => setState(() => _showTOC = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),

          // Table of Contents
          _buildTableOfContents(theme),

          // Top Bar
          _buildTopBar(theme),

          // Search Overlay
          _buildSearchOverlay(theme),

          // Bottom Control Panel
          _buildBottomControls(theme),
        ],
      ),
    );
  }

  Widget _buildTableOfContents(ReaderTheme theme) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: 0,
      bottom: 0,
      left: _showTOC ? 0 : -300, // w-3/4 max-w-xs -> approx 300
      width: 300,
      child: Container(
        decoration: BoxDecoration(
          color: theme.panelBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(5, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mục lục',
                      style: GoogleFonts.getFont(
                        'Playfair Display',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.text,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _showTOC = false),
                      icon: Icon(LucideIcons.x, color: theme.text, size: 20),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: widget.chapters.isEmpty
                      ? 10
                      : widget.chapters.length,
                  itemBuilder: (context, index) {
                    final isActive = index == _currentChapterIndex;
                    final title = widget.chapters.isEmpty
                        ? (index == 0 ? 'Khởi đầu' : 'Hành trình ${index + 1}')
                        : widget.chapters[index].title;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _currentChapterIndex = index;
                          _showTOC = false;
                          _renderedChapter = _prepareChapter();
                          _resetScroll();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: theme.text.withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CHƯƠNG ${index + 1}',
                              style: GoogleFonts.getFont(
                                'Manrope',
                                fontSize: 10,
                                color: theme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              title,
                              style: GoogleFonts.getFont(
                                'Playfair Display',
                                fontSize: 16,
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isActive
                                    ? theme.text
                                    : theme.text.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(ReaderTheme theme) {
    final isDark = _themeMode == 'dark' || _themeMode == 'midnight';

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      top: _showControls && !_showSearch ? 0 : -120,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDark
                  ? Colors.black.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.5),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: Back & TOC buttons
                Row(
                  children: [
                    IconButton(
                      onPressed: widget.onClose,
                      icon: Icon(
                        LucideIcons.arrowLeft,
                        color: theme.text,
                        size: 24,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _showTOC = true),
                      icon: Icon(LucideIcons.list, color: theme.text, size: 24),
                    ),
                  ],
                ),

                // Center: Book title
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ĐANG ĐỌC',
                        style: GoogleFonts.getFont(
                          'Manrope',
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                          color: theme.textSecondary,
                        ),
                      ),
                      Text(
                        widget.book?['title'] ?? 'Nhà Giả Kim',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.getFont(
                          'Playfair Display',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.text,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right: Search & Bookmark
                Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _showSearch = true),
                      icon: Icon(
                        LucideIcons.search,
                        color: theme.text,
                        size: 22,
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          setState(() => _isBookmarked = !_isBookmarked),
                      icon: Icon(
                        LucideIcons.bookmark,
                        color: _isBookmarked ? theme.accent : theme.text,
                        size: 22,
                        // fill: _isBookmarked ? theme.accent : Colors.transparent, // Icon doesn't support fill directly usually, depends on package
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchOverlay(ReaderTheme theme) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      top: _showSearch ? 0 : -80,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.panelBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Icon(LucideIcons.search, color: theme.textSecondary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: _showSearch,
                  style: GoogleFonts.getFont(
                    'Manrope',
                    fontSize: 16,
                    color: theme.text,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm trong sách...',
                    hintStyle: TextStyle(color: theme.textSecondary),
                    border: InputBorder.none,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showSearch = false;
                    _searchController.clear();
                  });
                },
                child: Text(
                  'Hủy',
                  style: GoogleFonts.getFont(
                    'Manrope',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterNavigationButtons(ReaderTheme theme) {
    final totalChapters = widget.chapters.isEmpty ? 18 : widget.chapters.length;
    final hasPrevious = _currentChapterIndex > 0;
    final hasNext = _currentChapterIndex < totalChapters - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Previous Chapter Button
        if (hasPrevious)
          GestureDetector(
            onTap: () {
              setState(() {
                _currentChapterIndex--;
                _renderedChapter = _prepareChapter();
                _resetScroll();
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.arrowLeft, size: 18, color: theme.text),
                const SizedBox(width: 8),
                Text(
                  'Chương trước',
                  style: GoogleFonts.getFont(
                    'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: theme.text,
                  ),
                ),
              ],
            ),
          )
        else
          const SizedBox.shrink(),

        // Next Chapter Button
        if (hasNext)
          GestureDetector(
            onTap: () {
              setState(() {
                _currentChapterIndex++;
                _renderedChapter = _prepareChapter();
                _resetScroll();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: theme.buttonBg,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Chương tiếp theo',
                    style: GoogleFonts.getFont(
                      'Manrope',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.buttonText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    LucideIcons.arrowRight,
                    size: 18,
                    color: theme.buttonText,
                  ),
                ],
              ),
            ),
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildBottomControls(ReaderTheme theme) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      left: 0,
      right: 0,
      bottom: _showControls ? 0 : -300,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: theme.panelBg,
              borderRadius: BorderRadius.circular(24),
              border: theme.panelBorder != Colors.transparent
                  ? Border.all(color: theme.panelBorder)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Appearance Menu (Expandable)
                if (_showAppearanceMenu) _buildAppearanceMenu(theme),

                // Progress Bar
                _buildProgressBar(theme),

                const SizedBox(height: 16),

                // Main Controls Row - More compact
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left: Aa Button
                    GestureDetector(
                      onTap: () => setState(
                        () => _showAppearanceMenu = !_showAppearanceMenu,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _showAppearanceMenu
                              ? theme.buttonBg
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Aa',
                          style: GoogleFonts.getFont(
                            'Playfair Display',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _showAppearanceMenu
                                ? theme.buttonText
                                : theme.iconActive,
                          ),
                        ),
                      ),
                    ),

                    // Center: Chapter Info
                    Column(
                      children: [
                        Text(
                          'CHƯƠNG ${_currentChapterIndex + 1}/${widget.chapters.isEmpty ? 18 : widget.chapters.length}',
                          style: GoogleFonts.getFont(
                            'Manrope',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: theme.iconActive,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Còn khoảng $_estimatedMinutes phút đọc',
                          style: GoogleFonts.getFont(
                            'Manrope',
                            fontSize: 10,
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    // Right: TOC Button
                    GestureDetector(
                      onTap: () => setState(() => _showTOC = true),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.buttonSecondaryBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          LucideIcons.list,
                          size: 18,
                          color: theme.buttonSecondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(ReaderTheme theme) {
    return Row(
      children: [
        Text(
          '0%',
          style: GoogleFonts.getFont(
            'Manrope',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: theme.iconActive.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Track
              Container(
                height: 2,
                decoration: BoxDecoration(
                  color: theme.iconActive.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              // Progress
              FractionallySizedBox(
                widthFactor: _progress / 100,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: theme.accent,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              // Slider (invisible but interactive)
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                  overlayShape: SliderComponentShape.noOverlay,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  thumbColor: theme.accent,
                ),
                child: Slider(
                  min: 0,
                  max: 100,
                  value: _progress.clamp(0, 100),
                  onChanged: widget.chapters.isEmpty
                      ? null
                      : _handleSliderChange,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '100%',
          style: GoogleFonts.getFont(
            'Manrope',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: theme.iconActive.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceMenu(ReaderTheme theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.text.withValues(alpha: 0.05)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Theme Colors
          _buildSectionLabel('Màu nền', theme),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildThemeButton('paper', const Color(0xFFEBE8E0), theme),
              const SizedBox(width: 12),
              _buildThemeButton('sepia', const Color(0xFFF4ECD8), theme),
              const SizedBox(width: 12),
              _buildThemeButton('dark', const Color(0xFF1a1c1e), theme),
              const SizedBox(width: 12),
              _buildThemeButton('midnight', Colors.black, theme),
            ],
          ),

          const SizedBox(height: 24),

          // 2. Font & Size
          Row(
            children: [
              // Font Family
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('Font chữ', theme),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.text.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildFontButton('serif', 'Có chân', theme),
                          _buildFontButton('sans', 'Sans', theme),
                          _buildFontButton('mono', 'Mono', theme),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Font Size
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('Cỡ chữ: ${_fontSize.toInt()}', theme),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.text.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (_fontSize > 12) {
                                  setState(() => _fontSize--);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Icon(
                                  LucideIcons.minus,
                                  size: 16,
                                  color: theme.text,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (_fontSize < 32) {
                                  setState(() => _fontSize++);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Icon(
                                  LucideIcons.plus,
                                  size: 16,
                                  color: theme.text,
                                ),
                              ),
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

          const SizedBox(height: 24),

          // 3. Line Height & Word Spacing
          Row(
            children: [
              // Line Height
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('Dãn dòng', theme),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.text.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildLineHeightButton(1.4, theme),
                          _buildLineHeightButton(1.8, theme),
                          _buildLineHeightButton(2.2, theme),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Word Spacing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('Dãn từ', theme),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.text.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildWordSpacingButton('normal', theme),
                          _buildWordSpacingButton('wide', theme),
                          _buildWordSpacingButton('wider', theme),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, ReaderTheme theme) {
    return Text(
      text,
      style: GoogleFonts.getFont(
        'Manrope',
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        color: theme.textSecondary,
      ),
    );
  }

  Widget _buildThemeButton(String mode, Color color, ReaderTheme theme) {
    final isSelected = _themeMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _themeMode = mode),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF3B82F6)
                  : theme.text.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildFontButton(String font, String label, ReaderTheme theme) {
    final isSelected = _fontFamily == font;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _fontFamily = font),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.bg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.getFont(
                'Manrope',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? theme.text
                    : theme.text.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineHeightButton(double value, ReaderTheme theme) {
    final isSelected = _lineHeight == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _lineHeight = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.bg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Transform.scale(
              scaleY: value == 1.4
                  ? 0.75
                  : value == 2.2
                  ? 1.25
                  : 1.0,
              child: Icon(
                LucideIcons.alignJustify,
                size: 16,
                color: isSelected
                    ? theme.text
                    : theme.text.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWordSpacingButton(String value, ReaderTheme theme) {
    final isSelected = _wordSpacing == value;
    final iconWidth = value == 'normal'
        ? 16.0
        : value == 'wide'
        ? 20.0
        : 24.0;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _wordSpacing = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.bg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: SizedBox(
              width: iconWidth,
              child: Icon(
                LucideIcons.moveHorizontal,
                size: 16,
                color: isSelected
                    ? theme.text
                    : theme.text.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RenderedChapter {
  final String title;
  final String html;
  final int wordCount;

  _RenderedChapter({
    required this.title,
    required this.html,
    required this.wordCount,
  });
}
