import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Theme configuration for reading screen
class ReadingTheme {
  final Color bg;
  final Color text;
  final Color accent;
  final Color panelBg;
  final Color panelBorder;
  final Color textSecondary;
  final Color sliderTrack;
  final Color iconActive;
  final Color buttonBg;
  final Color buttonText;
  final Color buttonSecondaryBg;
  final Color buttonSecondaryText;

  const ReadingTheme({
    required this.bg,
    required this.text,
    required this.accent,
    required this.panelBg,
    required this.panelBorder,
    required this.textSecondary,
    required this.sliderTrack,
    required this.iconActive,
    required this.buttonBg,
    required this.buttonText,
    required this.buttonSecondaryBg,
    required this.buttonSecondaryText,
  });
}

/// Available reading theme modes
enum ReadingThemeMode { paper, sepia, dark, midnight }

/// Font family options
enum FontType { serif, sans, mono }

/// Word spacing options
enum WordSpacingType { normal, wide, wider }

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen>
    with TickerProviderStateMixin {
  // --- State ---
  double fontSize = 18;
  double lineHeight = 1.8;
  WordSpacingType wordSpacing = WordSpacingType.normal;
  FontType fontFamily = FontType.serif;
  double progress = 35;
  bool showControls = true;
  ReadingThemeMode themeMode = ReadingThemeMode.paper;
  bool isBookmarked = false;

  // Modal states
  bool showTOC = false;
  bool showSearch = false;
  bool showAppearanceMenu = false;

  // Animation controllers
  late AnimationController _controlsAnimController;
  late AnimationController _tocAnimController;
  late AnimationController _searchAnimController;

  late Animation<Offset> _topBarAnimation;
  late Animation<Offset> _bottomBarAnimation;
  late Animation<Offset> _tocAnimation;
  late Animation<Offset> _searchAnimation;
  late Animation<double> _overlayAnimation;

  // Search controller
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // --- Theme Configurations ---
  static const Map<ReadingThemeMode, ReadingTheme> themes = {
    ReadingThemeMode.paper: ReadingTheme(
      bg: Color(0xFFEBE8E0),
      text: Color(0xFF1F2937),
      accent: Color(0xFF1E3A2F),
      panelBg: Color(0xFFE6E2D8),
      panelBorder: Colors.transparent,
      textSecondary: Color(0xFF6B7280),
      sliderTrack: Color(0xFFD1CDC3),
      iconActive: Color(0xFF1E3A2F),
      buttonBg: Color(0xFF1E3A2F),
      buttonText: Colors.white,
      buttonSecondaryBg: Color(0xFFDCD8CE),
      buttonSecondaryText: Color(0xFF1E3A2F),
    ),
    ReadingThemeMode.sepia: ReadingTheme(
      bg: Color(0xFFF4ECD8),
      text: Color(0xFF5B4636),
      accent: Color(0xFF8B5E3C),
      panelBg: Color(0xFFE9E0C9),
      panelBorder: Color(0xFFD4C5A5),
      textSecondary: Color(0xFF8C7B6C),
      sliderTrack: Color(0xFFD4C5A5),
      iconActive: Color(0xFF8B5E3C),
      buttonBg: Color(0xFF8B5E3C),
      buttonText: Colors.white,
      buttonSecondaryBg: Color(0xFFDCCBA5),
      buttonSecondaryText: Color(0xFF5B4636),
    ),
    ReadingThemeMode.dark: ReadingTheme(
      bg: Color(0xFF1A1C1E),
      text: Color(0xFFE2E2E2),
      accent: Color(0xFF4A6B5D),
      panelBg: Color(0xFF2A2D30),
      panelBorder: Color(0xFF3F4246),
      textSecondary: Color(0xFF9CA3AF),
      sliderTrack: Color(0xFF3F4246),
      iconActive: Color(0xFF4A6B5D),
      buttonBg: Color(0xFF4A6B5D),
      buttonText: Colors.white,
      buttonSecondaryBg: Color(0xFF3F4246),
      buttonSecondaryText: Color(0xFFE2E2E2),
    ),
    ReadingThemeMode.midnight: ReadingTheme(
      bg: Colors.black,
      text: Color(0xFFA9A9A9),
      accent: Color(0xFF333333),
      panelBg: Color(0xFF121212),
      panelBorder: Color(0xFF333333),
      textSecondary: Color(0xFF4B5563),
      sliderTrack: Color(0xFF333333),
      iconActive: Color(0xFF666666),
      buttonBg: Color(0xFF333333),
      buttonText: Colors.white,
      buttonSecondaryBg: Color(0xFF222222),
      buttonSecondaryText: Color(0xFF888888),
    ),
  };

  ReadingTheme get currentTheme => themes[themeMode]!;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Controls animation (top & bottom bars)
    _controlsAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _topBarAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controlsAnimController,
      curve: Curves.easeOut,
    ));

    _bottomBarAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controlsAnimController,
      curve: Curves.easeOut,
    ));

    // TOC animation
    _tocAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _tocAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _tocAnimController,
      curve: Curves.easeOut,
    ));

    _overlayAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _tocAnimController,
      curve: Curves.easeOut,
    ));

    // Search animation
    _searchAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _searchAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _searchAnimController,
      curve: Curves.easeOut,
    ));

    // Initial state
    if (showControls) {
      _controlsAnimController.forward();
    }
  }

  @override
  void dispose() {
    _controlsAnimController.dispose();
    _tocAnimController.dispose();
    _searchAnimController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // --- Helper Methods ---
  double getWordSpacing() {
    switch (wordSpacing) {
      case WordSpacingType.wide:
        return 2.0;
      case WordSpacingType.wider:
        return 5.0;
      default:
        return 0.0;
    }
  }

  TextStyle getContentTextStyle() {
    TextStyle baseStyle;
    switch (fontFamily) {
      case FontType.sans:
        baseStyle = GoogleFonts.notoSans();
        break;
      case FontType.mono:
        baseStyle = GoogleFonts.jetBrainsMono();
        break;
      default:
        baseStyle = GoogleFonts.merriweather();
    }
    return baseStyle.copyWith(
      fontSize: fontSize,
      height: lineHeight,
      wordSpacing: getWordSpacing(),
      color: currentTheme.text,
    );
  }

  void _handleContentTap() {
    setState(() {
      showControls = !showControls;
      showAppearanceMenu = false;
      showSearch = false;
    });

    if (showControls) {
      _controlsAnimController.forward();
    } else {
      _controlsAnimController.reverse();
    }

    if (showSearch) {
      _searchAnimController.reverse();
    }
  }

  void _toggleTOC(bool show) {
    setState(() => showTOC = show);
    if (show) {
      _tocAnimController.forward();
    } else {
      _tocAnimController.reverse();
    }
  }

  void _toggleSearch(bool show) {
    setState(() => showSearch = show);
    if (show) {
      _searchAnimController.forward();
      _controlsAnimController.reverse();
      Future.delayed(const Duration(milliseconds: 350), () {
        _searchFocusNode.requestFocus();
      });
    } else {
      _searchAnimController.reverse();
      _searchFocusNode.unfocus();
      if (showControls) {
        _controlsAnimController.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: currentTheme.bg,
      body: Stack(
        children: [
          // Main Content
          GestureDetector(
            onTap: _handleContentTap,
            child: _buildMainContent(),
          ),

          // TOC Overlay
          _buildTOCOverlay(),

          // TOC Drawer
          _buildTOCDrawer(),

          // Top Bar
          _buildTopBar(),

          // Search Overlay
          _buildSearchOverlay(),

          // Bottom Control Panel
          _buildBottomPanel(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            children: [
              // Chapter Header
              const SizedBox(height: 40),
              Text(
                'CHƯƠNG 1',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  color: currentTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Khởi đầu',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: currentTheme.text,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: 64,
                height: 1,
                color: currentTheme.text.withOpacity(0.2),
              ),
              const SizedBox(height: 64),

              // Content paragraphs
              _buildParagraph(
                'Cậu tên là Santiago. Trời đã bắt đầu tối khi cậu lùa đàn cừu về đến ngôi nhà thờ cũ hoang phế. Mái vòm nhà thờ đã sập từ lâu và nơi xưa kia là phòng thay áo lễ nay sừng sững một cây dâu tằm to lớn.',
              ),
              _buildParagraph(
                'Cậu quyết định ngủ lại đấy. Cậu lùa lũ cừu qua khung cửa đã hư hại, rồi chắn lại bằng vài thanh gỗ để đêm đến chúng khỏi chui ra. Tuy vùng này không có chó sói nhưng đã có đêm một con cừu chui ra ngoài khiến hôm sau cậu mất cả ngày đi tìm.',
              ),
              _buildParagraph(
                'Cậu trải chiếc áo khoác trên nền đất, ngả lưng và dùng quyển sách đang đọc dở làm gối. Trước khi ngủ cậu tự nhủ sau này phải tìm những sách dày hơn để vừa đọc được lâu, vừa dùng làm gối tốt hơn.',
              ),
              _buildParagraph(
                'Khi thức dậy trời vẫn còn tối mịt. Nhìn lên cao cậu thấy sao trời lấp lánh qua những khoảng trống trên mái nhà thờ đổ nát.',
              ),
              _buildParagraph(
                '"Mình muốn ngủ tiếp tí nữa", cậu thầm nghĩ. Cậu lại vừa mơ giấc mơ y hệt cách đây một tuần và cũng lại thức giấc giữa cơn mơ.',
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        text,
        style: getContentTextStyle(),
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget _buildTOCOverlay() {
    return AnimatedBuilder(
      animation: _overlayAnimation,
      builder: (context, child) {
        if (_overlayAnimation.value == 0) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () => _toggleTOC(false),
          child: Container(
            color: Colors.black.withOpacity(0.5 * _overlayAnimation.value),
          ),
        );
      },
    );
  }

  Widget _buildTOCDrawer() {
    return SlideTransition(
      position: _tocAnimation,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.75,
          constraints: const BoxConstraints(maxWidth: 320),
          height: double.infinity,
          decoration: BoxDecoration(
            color: currentTheme.panelBg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(5, 0),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mục lục',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: currentTheme.text,
                        ),
                      ),
                      _buildIconButton(
                        icon: LucideIcons.x,
                        onPressed: () => _toggleTOC(false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Chapter List
                  Expanded(
                    child: ListView.builder(
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        final chapter = index + 1;
                        final isActive = chapter == 1;
                        return InkWell(
                          onTap: () => _toggleTOC(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: currentTheme.text.withOpacity(0.05),
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CHƯƠNG $chapter',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    letterSpacing: 1,
                                    color: currentTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  chapter == 1
                                      ? 'Khởi đầu'
                                      : 'Hành trình $chapter',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 16,
                                    fontWeight:
                                        isActive ? FontWeight.bold : FontWeight.normal,
                                    color: currentTheme.text.withOpacity(
                                      isActive ? 1.0 : 0.7,
                                    ),
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
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final isDark =
        themeMode == ReadingThemeMode.dark || themeMode == ReadingThemeMode.midnight;

    return SlideTransition(
      position: _topBarAnimation,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [Colors.black.withOpacity(0.5), Colors.transparent]
                  : [Colors.white.withOpacity(0.5), Colors.transparent],
            ),
          ),
          child: Row(
            children: [
              // Left: Back & TOC
              Row(
                children: [
                  _buildIconButton(
                    icon: LucideIcons.arrowLeft,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  _buildIconButton(
                    icon: LucideIcons.list,
                    onPressed: () => _toggleTOC(true),
                  ),
                ],
              ),

              // Center: Book Title (hidden on mobile)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ĐANG ĐỌC',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: currentTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Nhà Giả Kim',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: currentTheme.text,
                      ),
                    ),
                  ],
                ),
              ),

              // Right: Search & Bookmark
              Row(
                children: [
                  _buildIconButton(
                    icon: LucideIcons.search,
                    onPressed: () => _toggleSearch(true),
                  ),
                  _buildBookmarkButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchOverlay() {
    return SlideTransition(
      position: _searchAnimation,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: themeMode == ReadingThemeMode.dark || themeMode == ReadingThemeMode.midnight
                ? const Color(0xFF1A1A1A)
                : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.search,
                size: 20,
                color: currentTheme.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: TextStyle(
                    fontSize: 16,
                    color: currentTheme.text,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm trong sách...',
                    hintStyle: TextStyle(
                      color: currentTheme.textSecondary,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _toggleSearch(false),
                child: Text(
                  'Hủy',
                  style: TextStyle(
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

  Widget _buildBottomPanel() {
    return SlideTransition(
      position: _bottomBarAnimation,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Container(
                decoration: BoxDecoration(
                  color: currentTheme.panelBg,
                  borderRadius: BorderRadius.circular(32),
                  border: currentTheme.panelBorder != Colors.transparent
                      ? Border.all(color: currentTheme.panelBorder)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Appearance Menu
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 200),
                          crossFadeState: showAppearanceMenu
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          firstChild: _buildAppearanceMenu(),
                          secondChild: const SizedBox.shrink(),
                        ),

                        // Progress Bar
                        _buildProgressBar(),
                        const SizedBox(height: 24),

                        // Controls Row
                        _buildControlsRow(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppearanceMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Theme Selection
        _buildSectionLabel('Màu nền'),
        const SizedBox(height: 8),
        Row(
          children: ReadingThemeMode.values.map((t) {
            final isSelected = themeMode == t;
            Color bgColor;
            switch (t) {
              case ReadingThemeMode.paper:
                bgColor = const Color(0xFFEBE8E0);
                break;
              case ReadingThemeMode.sepia:
                bgColor = const Color(0xFFF4ECD8);
                break;
              case ReadingThemeMode.dark:
                bgColor = const Color(0xFF1A1C1E);
                break;
              case ReadingThemeMode.midnight:
                bgColor = Colors.black;
                break;
            }
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: t != ReadingThemeMode.midnight ? 12 : 0,
                ),
                child: GestureDetector(
                  onTap: () => setState(() => themeMode = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 48,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF3B82F6)
                            : currentTheme.text.withOpacity(0.1),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withOpacity(0.3),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Font & Font Size Row
        Row(
          children: [
            // Font Family
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('Font chữ'),
                  const SizedBox(height: 8),
                  _buildSegmentedControl(
                    options: [
                      ('serif', 'Có chân'),
                      ('sans', 'Sans'),
                      ('mono', 'Mono'),
                    ],
                    selected: fontFamily.name,
                    onSelected: (value) {
                      setState(() {
                        fontFamily = FontType.values.firstWhere(
                          (e) => e.name == value,
                        );
                      });
                    },
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
                  _buildSectionLabel('Cỡ chữ: ${fontSize.toInt()}'),
                  const SizedBox(height: 8),
                  _buildStepperControl(
                    onDecrease: () {
                      if (fontSize > 12) setState(() => fontSize--);
                    },
                    onIncrease: () {
                      if (fontSize < 32) setState(() => fontSize++);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Line Height & Word Spacing Row
        Row(
          children: [
            // Line Height
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('Dãn dòng'),
                  const SizedBox(height: 8),
                  _buildIconSegmentedControl(
                    options: [
                      (1.4, LucideIcons.alignJustify, 0.75),
                      (1.8, LucideIcons.alignJustify, 1.0),
                      (2.2, LucideIcons.alignJustify, 1.25),
                    ],
                    selected: lineHeight,
                    onSelected: (value) =>
                        setState(() => lineHeight = value),
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
                  _buildSectionLabel('Dãn từ'),
                  const SizedBox(height: 8),
                  _buildIconSegmentedControl2(
                    options: [
                      (WordSpacingType.normal, 16.0),
                      (WordSpacingType.wide, 20.0),
                      (WordSpacingType.wider, 24.0),
                    ],
                    selected: wordSpacing,
                    onSelected: (value) =>
                        setState(() => wordSpacing = value),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Divider(
          color: currentTheme.text.withOpacity(0.05),
          height: 1,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        color: currentTheme.textSecondary,
      ),
    );
  }

  Widget _buildSegmentedControl({
    required List<(String, String)> options,
    required String selected,
    required Function(String) onSelected,
  }) {
    final isDark =
        themeMode == ReadingThemeMode.dark || themeMode == ReadingThemeMode.midnight;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: options.map((option) {
          final isSelected = selected == option.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(option.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? currentTheme.bg : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    option.$2,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: currentTheme.text
                          .withOpacity(isSelected ? 1.0 : 0.6),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStepperControl({
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    final isDark =
        themeMode == ReadingThemeMode.dark || themeMode == ReadingThemeMode.midnight;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onDecrease,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.minus,
                  size: 16,
                  color: currentTheme.text,
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onIncrease,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.plus,
                  size: 16,
                  color: currentTheme.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconSegmentedControl({
    required List<(double, IconData, double)> options,
    required double selected,
    required Function(double) onSelected,
  }) {
    final isDark =
        themeMode == ReadingThemeMode.dark || themeMode == ReadingThemeMode.midnight;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: options.map((option) {
          final isSelected = selected == option.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(option.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? currentTheme.bg : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Transform.scale(
                    scaleY: option.$3,
                    child: Icon(
                      option.$2,
                      size: 16,
                      color: currentTheme.text
                          .withOpacity(isSelected ? 1.0 : 0.5),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIconSegmentedControl2({
    required List<(WordSpacingType, double)> options,
    required WordSpacingType selected,
    required Function(WordSpacingType) onSelected,
  }) {
    final isDark =
        themeMode == ReadingThemeMode.dark || themeMode == ReadingThemeMode.midnight;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: options.map((option) {
          final isSelected = selected == option.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(option.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? currentTheme.bg : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: SizedBox(
                    width: option.$2,
                    child: Icon(
                      LucideIcons.moveHorizontal,
                      size: 16,
                      color: currentTheme.text
                          .withOpacity(isSelected ? 1.0 : 0.5),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: [
        Text(
          '0%',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: currentTheme.iconActive.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onHorizontalDragUpdate: (details) {
                  final newProgress =
                      (details.localPosition.dx / constraints.maxWidth * 100)
                          .clamp(0.0, 100.0);
                  setState(() => progress = newProgress);
                },
                onTapDown: (details) {
                  final newProgress =
                      (details.localPosition.dx / constraints.maxWidth * 100)
                          .clamp(0.0, 100.0);
                  setState(() => progress = newProgress);
                },
                child: Container(
                  height: 20,
                  color: Colors.transparent,
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Track
                        Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: currentTheme.iconActive.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        // Progress
                        FractionallySizedBox(
                          widthFactor: progress / 100,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: currentTheme.accent,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                        // Thumb
                        Positioned(
                          left: constraints.maxWidth * (progress / 100) - 8,
                          top: -7,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: currentTheme.accent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: currentTheme.bg,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
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
            },
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '100%',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: currentTheme.iconActive.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildControlsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Aa Button
        GestureDetector(
          onTap: () => setState(() => showAppearanceMenu = !showAppearanceMenu),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: showAppearanceMenu
                  ? currentTheme.buttonBg
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Aa',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: showAppearanceMenu
                    ? currentTheme.buttonText
                    : currentTheme.iconActive,
              ),
            ),
          ),
        ),

        // Center: Chapter Info
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CHƯƠNG 1/18',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: currentTheme.iconActive,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Còn khoảng 5 phút đọc',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: currentTheme.textSecondary,
              ),
            ),
          ],
        ),

        // Right: Theme Toggle
        GestureDetector(
          onTap: () {
            setState(() {
              themeMode = themeMode == ReadingThemeMode.paper
                  ? ReadingThemeMode.dark
                  : ReadingThemeMode.paper;
            });
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: currentTheme.buttonSecondaryBg,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(
              LucideIcons.sun,
              size: 20,
              color: currentTheme.buttonSecondaryText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookmarkButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => isBookmarked = !isBookmarked),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Stack(
            children: [
              if (isBookmarked)
                Icon(
                  LucideIcons.bookmark,
                  size: 22,
                  color: currentTheme.text,
                  // Using a stack with smaller filled container to simulate fill
                ),
              Icon(
                LucideIcons.bookmark,
                size: 22,
                color: currentTheme.text,
              ),
              if (isBookmarked)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      decoration: BoxDecoration(
                        color: currentTheme.text,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(2),
                          topRight: Radius.circular(2),
                          bottomLeft: Radius.circular(1),
                          bottomRight: Radius.circular(1),
                        ),
                      ),
                      // Custom shape to fill bookmark
                      child: ClipPath(
                        clipper: _BookmarkClipper(),
                        child: Container(color: currentTheme.text),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 24,
            color: currentTheme.text,
          ),
        ),
      ),
    );
  }
}

/// Custom clipper to create bookmark fill shape
class _BookmarkClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width / 2, size.height * 0.7);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

