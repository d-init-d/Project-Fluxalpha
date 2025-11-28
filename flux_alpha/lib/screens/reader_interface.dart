import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';

import '../models/chapter_data.dart';
import '../models/annotation.dart';

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

  // --- Style State (using ValueNotifier for optimized rebuilds) ---
  final ValueNotifier<double> _fontSizeNotifier = ValueNotifier<double>(18);
  final ValueNotifier<double> _lineHeightNotifier = ValueNotifier<double>(1.8);
  final ValueNotifier<String> _wordSpacingNotifier = ValueNotifier<String>('normal');
  final ValueNotifier<String> _fontFamilyNotifier = ValueNotifier<String>('serif');
  final ValueNotifier<String> _themeModeNotifier = ValueNotifier<String>('paper');
  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0);

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

  // Text Selection States
  TextSelection? _currentSelection;
  String? _selectedText;
  OverlayEntry? _selectionMenuOverlay;
  final List<Highlight> _highlights = [];
  final List<Note> _notes = [];

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
      _themeModeNotifier.value = 'dark';
    }

    // Sync initial values to notifiers
    _fontSizeNotifier.value = _fontSize;
    _lineHeightNotifier.value = _lineHeight;
    _wordSpacingNotifier.value = _wordSpacing;
    _fontFamilyNotifier.value = _fontFamily;

    // Preload all fonts immediately for instant switching
    _preloadFonts();
  }

  /// Preload all fonts to ensure instant switching
  void _preloadFonts() {
    // Trigger font loading by creating TextStyles
    // MySerif (Playfair Display)
    const TextStyle(fontFamily: 'MySerif', fontSize: 18);
    const TextStyle(fontFamily: 'MySerif', fontSize: 18, fontWeight: FontWeight.bold);
    
    // MySans (Manrope)
    const TextStyle(fontFamily: 'MySans', fontSize: 18);
    const TextStyle(fontFamily: 'MySans', fontSize: 18, fontWeight: FontWeight.bold);
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
    _fontSizeNotifier.dispose();
    _lineHeightNotifier.dispose();
    _wordSpacingNotifier.dispose();
    _fontFamilyNotifier.dispose();
    _themeModeNotifier.dispose();
    _progressNotifier.dispose();
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
    _progress = 0;
    _progressNotifier.value = 0;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;

    if (maxScroll <= 0) {
      _progress = 0;
      _progressNotifier.value = 0;
      return;
    }

    final newProgress = (current / maxScroll) * 100;
    // Only update if change is significant (reduces rebuilds)
    if ((_progress - newProgress).abs() > 0.5) {
      _progress = newProgress;
      _progressNotifier.value = newProgress;
    }
  }

  _RenderedChapter? _prepareChapter() {
    if (widget.chapters.isEmpty) return null;
    final chapter = widget.chapters[_currentChapterIndex];
    // Simple parsing to remove scripts/styles and extract title if needed
    // In a real app, this might be more complex or done in background
    final document = html_parser.parse(chapter.content);
    final body = document.body;
    if (body == null) {
      final paragraphs = _splitIntoParagraphs('<p>${chapter.content}</p>');
      return _RenderedChapter(
        title: chapter.title,
        html: '<p>${chapter.content}</p>',
        paragraphs: paragraphs,
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

    // Split HTML into paragraphs for virtualization
    final paragraphs = _splitIntoParagraphs(processedHtml);

    return _RenderedChapter(
      title: chapter.title,
      html: processedHtml,
      paragraphs: paragraphs,
      wordCount: wordCount,
    );
  }

  /// Splits HTML content into individual paragraphs for lazy rendering
  List<String> _splitIntoParagraphs(String html) {
    if (html.trim().isEmpty) return ['<p></p>'];
    
    final document = html_parser.parse(html);
    final body = document.body;
    if (body == null) return [html];
    
    final paragraphs = <String>[];
    
    // Extract all paragraph elements and other block-level elements
    final elements = body.children;
    
    for (final element in elements) {
      final tagName = element.localName?.toLowerCase() ?? '';
      
      // Handle paragraph tags
      if (tagName == 'p') {
        final paragraphHtml = element.outerHtml;
        if (paragraphHtml.trim().isNotEmpty) {
          paragraphs.add(paragraphHtml);
        }
      }
      // Handle other block-level elements (div, h1-h6, etc.)
      else if (['div', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'blockquote', 'pre'].contains(tagName)) {
        final elementHtml = element.outerHtml;
        if (elementHtml.trim().isNotEmpty) {
          paragraphs.add(elementHtml);
        }
      }
      // For other elements, wrap them in a paragraph
      else if (element.text.trim().isNotEmpty) {
        paragraphs.add('<p>${element.outerHtml}</p>');
      }
    }
    
    // If no paragraphs found, split by newlines or create a single paragraph
    if (paragraphs.isEmpty) {
      // Fallback: try splitting by <p> tags using regex
      final pMatches = RegExp(r'<p[^>]*>.*?</p>', dotAll: true).allMatches(html);
      if (pMatches.isNotEmpty) {
        for (final match in pMatches) {
          final paragraph = match.group(0) ?? '';
          if (paragraph.trim().isNotEmpty) {
            paragraphs.add(paragraph);
          }
        }
      } else {
        // Last resort: split by double newlines or create single paragraph
        final lines = html.split(RegExp(r'\n\s*\n'));
        if (lines.length > 1) {
          for (final line in lines) {
            final trimmed = line.trim();
            if (trimmed.isNotEmpty) {
              paragraphs.add('<p>$trimmed</p>');
            }
          }
        } else {
          paragraphs.add(html);
        }
      }
    }
    
    // Ensure at least one paragraph
    if (paragraphs.isEmpty) {
      paragraphs.add('<p></p>');
    }
    
    return paragraphs;
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  /// Builds a SliverList for paragraph-based virtualization
  /// This ensures only visible paragraphs are rendered, making style changes instant (60FPS)
  Widget _buildVirtualizedParagraphs() {
    if (_renderedChapter == null || _renderedChapter!.paragraphs.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    // Use SliverList for lazy rendering - only visible paragraphs are built
    return ListenableBuilder(
      listenable: Listenable.merge([
        _fontSizeNotifier,
        _lineHeightNotifier,
        _wordSpacingNotifier,
        _fontFamilyNotifier,
        _themeModeNotifier,
      ]),
      builder: (context, _) {
        // Get current values from notifiers
        final fontSize = _fontSizeNotifier.value;
        final lineHeight = _lineHeightNotifier.value;
        final wordSpacing = _wordSpacingNotifier.value;
        final fontFamily = _fontFamilyNotifier.value;
        final themeMode = _themeModeNotifier.value;
        
        final currentTheme = ReaderTheme.getTheme(themeMode);
        final wordSpacingValue = wordSpacing == 'wide' ? 2.0 : (wordSpacing == 'wider' ? 5.0 : 0.0);
        
        // Create textStyle with current settings
        final textStyle = _getPreloadedTextStyle(
          fontSize: fontSize,
          height: lineHeight,
          wordSpacing: wordSpacingValue,
          color: currentTheme.text,
          fontFamily: fontFamily,
        );
        
        // Get the actual font family name for customStylesBuilder
        final fontFamilyName = _getFontFamilyName(fontFamily);
        
        // SliverList with virtualization - only renders visible items
        return SliverList(
          // CRITICAL: Disable automatic keep-alives to prevent memory bloat
          delegate: SliverChildBuilderDelegate(
            // Item builder - renders only the visible paragraph
            (context, index) {
              final paragraphHtml = _renderedChapter!.paragraphs[index];
              
              // Wrap each paragraph in RepaintBoundary for isolated paint operations
              // Center and constrain to maxWidth for proper layout
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: RepaintBoundary(
                    key: ValueKey('paragraph_${_currentChapterIndex}_$index'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24.0), // Paragraph spacing
                      child: HtmlWidget(
                        paragraphHtml,
                        // Stable key per paragraph
                        key: ValueKey('para_${_currentChapterIndex}_$index'),
                        renderMode: RenderMode.column,
                        // Direct textStyle injection for instant updates
                        textStyle: textStyle,
                        // Rebuild triggers for style changes
                        rebuildTriggers: [fontSize, lineHeight, wordSpacingValue, fontFamily, themeMode],
                        // Disable unnecessary features
                        onTapUrl: null,
                        onTapImage: null,
                        customStylesBuilder: (element) {
                          final styles = <String, String>{};

                          // Apply font-family directly in CSS
                          styles['font-family'] = fontFamilyName;
                          
                          // Apply word-spacing if needed
                          if (wordSpacingValue > 0) {
                            styles['word-spacing'] = '${wordSpacingValue}px';
                          }
                          
                          // Apply line-height directly in CSS
                          styles['line-height'] = '${lineHeight}';
                          
                          // Apply font-size directly in CSS for immediate updates
                          styles['font-size'] = '${fontSize}px';

                          // Paragraph specific styles
                          if (element.localName == 'p') {
                            styles['margin'] = '0';
                            styles['text-align'] = 'justify';
                          } else {
                            styles['text-align'] = 'justify';
                          }

                          return styles;
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
            // Item count is the number of paragraphs
            childCount: _renderedChapter!.paragraphs.length,
            // CRITICAL: Disable automatic keep-alives to prevent memory bloat
            addAutomaticKeepAlives: false,
            // Disable repaint boundaries at delegate level (we add them per item)
            addRepaintBoundaries: false,
          ),
        );
      },
    );
  }

  void _handleContentClick() {
    setState(() {
      _showControls = !_showControls;
      _showAppearanceMenu = false;
      _showSearch = false;
    });
    _hideSelectionMenu();
  }

  void _handleTextSelection(
    TextSelection selection,
    String selectedText,
    Offset? position,
  ) {
    print(
      '_handleTextSelection called: selection=$selection, text="$selectedText", position=$position',
    );
    if (selection.isValid && selectedText.trim().isNotEmpty) {
      setState(() {
        _currentSelection = selection;
        _selectedText = selectedText.trim();
      });
      print('Showing menu for: "$_selectedText" at $position');
      _showSelectionMenu(position);
    } else {
      print('Hiding menu - invalid selection or empty text');
      _hideSelectionMenu();
    }
  }

  void _showSelectionMenu(Offset? position) {
    print('_showSelectionMenu called with position: $position');
    _hideSelectionMenu();
    if (position == null) return;

    final overlay = Overlay.of(context);
    _selectionMenuOverlay = OverlayEntry(
      builder: (context) {
        print('Building selection menu overlay');
        return _buildSelectionMenu(position);
      },
    );
    overlay.insert(_selectionMenuOverlay!);
    print('Menu overlay inserted');
  }

  void _hideSelectionMenu() {
    _selectionMenuOverlay?.remove();
    _selectionMenuOverlay = null;
    setState(() {
      _currentSelection = null;
      _selectedText = null;
    });
  }

  void _handleHighlight() {
    if (_selectedText == null || _currentSelection == null) return;

    final highlight = Highlight(
      id: const Uuid().v4(),
      paragraphIndex: 0, // TODO: Calculate actual paragraph index
      startOffset: _currentSelection!.start,
      endOffset: _currentSelection!.end,
      selectedText: _selectedText!,
      color: _currentTheme.accent,
      createdAt: DateTime.now(),
      bookTitle: widget.book?['title'] ?? 'Chưa rõ',
    );

    setState(() {
      _highlights.add(highlight);
    });

    _hideSelectionMenu();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã highlight: "${_selectedText!.substring(0, _selectedText!.length > 30 ? 30 : _selectedText!.length)}${_selectedText!.length > 30 ? '...' : ''}"',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: _currentTheme.accent,
      ),
    );
  }

  void _handleTakeNote() {
    if (_selectedText == null || _currentSelection == null) return;

    showDialog(
      context: context,
      builder: (context) => _NoteDialog(
        selectedText: _selectedText!,
        theme: _currentTheme,
        onSave: (noteContent) {
          final note = Note(
            id: const Uuid().v4(),
            content: noteContent,
            selectedText: _selectedText!,
            paragraphIndex: 0, // TODO: Calculate actual paragraph index
            startOffset: _currentSelection!.start,
            endOffset: _currentSelection!.end,
            createdAt: DateTime.now(),
            bookTitle: widget.book?['title'] ?? 'Chưa rõ',
          );

          setState(() {
            _notes.add(note);
          });

          _hideSelectionMenu();
        },
      ),
    );
  }

  void _handleCopy() {
    if (_selectedText == null) return;

    Clipboard.setData(ClipboardData(text: _selectedText!));
    _hideSelectionMenu();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đã sao chép'),
        duration: const Duration(seconds: 1),
        backgroundColor: _currentTheme.accent,
      ),
    );
  }

  Widget _buildSelectionMenu(Offset position) {
    print('_buildSelectionMenu called, _selectedText: "$_selectedText"');
    if (_selectedText == null || _selectedText!.isEmpty) {
      print('_buildSelectionMenu returning empty - no selected text');
      return const SizedBox.shrink();
    }

    // Calculate menu position (centered above the selection)
    // We'll use a fixed width for the menu for simplicity in calculation, or let it size itself
    // but we need to offset it so it's centered.
    // Assuming menu height is around 60px including arrow.

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 0,
      child: Stack(
        children: [
          // Invisible tap area to close menu when tapping outside
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideSelectionMenu,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Menu positioned above selection
          Positioned(
            left: position.dx - 150, // Center horizontally (approx)
            top: position.dy - 70, // Position above
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Menu container
                  Container(
                    width: 300, // Fixed width for stability
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF2D2D2D,
                      ), // Dark background like image
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Highlight button (Red/Orange like image)
                        _buildMenuButton(
                          icon: LucideIcons
                              .circle, // Using circle to mimic the dot
                          label: '',
                          onTap: _handleHighlight,
                          color: const Color(0xFFD35400), // Burnt orange
                          isIconOnly: true,
                        ),
                        // Divider
                        Container(
                          width: 1,
                          height: 20,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        // Take Note button
                        _buildMenuButton(
                          icon: LucideIcons.pencil,
                          label: '',
                          onTap: _handleTakeNote,
                          color: Colors.white,
                          isIconOnly: true,
                        ),
                        // Divider
                        Container(
                          width: 1,
                          height: 20,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        // Copy button
                        _buildMenuButton(
                          icon: LucideIcons.copy,
                          label: '',
                          onTap: _handleCopy,
                          color: Colors.white,
                          isIconOnly: true,
                        ),
                      ],
                    ),
                  ),
                  // Arrow pointing down
                  CustomPaint(
                    size: const Size(12, 8),
                    painter: _ArrowPainter(color: const Color(0xFF2D2D2D)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    bool isIconOnly = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: isIconOnly
              ? Icon(icon, size: 20, color: color)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'MySans',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _handleSliderChange(double value) {
    _progress = value;
    _progressNotifier.value = value;
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

  String _getFontFamilyName(String fontFamily) {
    switch (fontFamily) {
      case 'sans':
        return 'MySans';
      case 'mono':
        return 'monospace'; // Fallback to system monospace
      default:
        return 'MySerif';
    }
  }

  /// Get preloaded TextStyle for current font family
  TextStyle _getPreloadedTextStyle({
    double? fontSize,
    double? height,
    double? wordSpacing,
    Color? color,
    FontWeight? fontWeight,
    String? fontFamily,
  }) {
    final size = fontSize ?? _fontSize;
    final lineHeight = height ?? _lineHeight;
    final spacing = wordSpacing ?? _getWordSpacingValue();
    final family = fontFamily ?? _fontFamily;
    
    switch (family) {
      case 'sans':
        return TextStyle(
          fontFamily: 'MySans',
          fontSize: size,
          height: lineHeight,
          wordSpacing: spacing,
          color: color,
          fontWeight: fontWeight,
        );
      case 'mono':
        // Fallback to system monospace if JetBrains Mono not available
        return TextStyle(
          fontFamily: 'monospace',
          fontSize: size,
          height: lineHeight,
          wordSpacing: spacing,
          color: color,
          fontWeight: fontWeight,
        );
      default:
        return TextStyle(
          fontFamily: 'MySerif',
          fontSize: size,
          height: lineHeight,
          wordSpacing: spacing,
          color: color,
          fontWeight: fontWeight,
        );
    }
  }

  int get _estimatedMinutes {
    final words = _renderedChapter?.wordCount ?? 0;
    if (words == 0) return 1;
    return (words / 220).ceil().clamp(1, 60);
  }

  @override
  Widget build(BuildContext context) {
    // Use ValueListenableBuilder for theme to prevent full rebuilds
    return ValueListenableBuilder<String>(
      valueListenable: _themeModeNotifier,
      builder: (context, themeMode, _) {
        final theme = ReaderTheme.getTheme(themeMode);
        
        return Scaffold(
          backgroundColor: theme.bg,
          body: Stack(
        children: [
          // Main Content
          GestureDetector(
            onTap: _handleContentClick,
            child: Container(
              color: theme.bg,
              child: SelectionArea(
                selectionControls: CustomTextSelectionControls(
                  onSelectionChanged: _handleTextSelection,
                  theme: theme,
                ),
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // Padding and constraints wrapper
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 80,
                      ),
                      sliver: SliverToBoxAdapter(
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
                                ValueListenableBuilder<String>(
                                  valueListenable: _fontFamilyNotifier,
                                  builder: (context, fontFamily, _) {
                                    return Center(
                                      child: Column(
                                        children: [
                                          Text(
                                            'CHƯƠNG ${_currentChapterIndex + 1}',
                                            style: TextStyle(
                                              fontFamily: _getFontFamilyName(fontFamily),
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
                                              style: TextStyle(
                                                fontFamily: _getFontFamilyName(fontFamily),
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
                                    );
                                  },
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Virtualized Content - SliverList for paragraph-based rendering
                    if (_renderedChapter == null)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        sliver: SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 720),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: theme.panelBg,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  'Không thể hiển thị nội dung.',
                                  textAlign: TextAlign.center,
                                  style: _getPreloadedTextStyle(
                                    fontSize: 16,
                                    color: theme.text,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        sliver: _buildVirtualizedParagraphs(),
                      ),

                    // Chapter Navigation Buttons
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 720),
                            child: Column(
                              children: [
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
                  ],
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
      },
    );
  }

  Widget _buildTableOfContents(ReaderTheme theme) {
    final screenHeight = MediaQuery.of(context).size.height;
    final tocHeight =
        screenHeight * 0.5; // 50% chiều cao màn hình - nhỏ hơn để bằng menu bar
    // Tính toán vị trí bottom dựa trên chiều cao menu bar (khoảng 120-150px với padding)
    final menuBarHeight = 150.0; // Ước tính chiều cao menu bar
    final bottomPosition = _showTOC ? menuBarHeight : -tocHeight;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: 0,
      right: 0,
      bottom: bottomPosition,
      height: tocHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
        ), // Cùng padding với menu bar
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 672, // Cùng maxWidth với menu bar
            ),
            child: Container(
              decoration: BoxDecoration(
                color: theme.panelBg,
                borderRadius: BorderRadius.circular(
                  32,
                ), // Bo góc tất cả các góc giống menu bar
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.text.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Mục lục',
                            style: TextStyle(
                              fontFamily: 'MySerif',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.text,
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _showTOC = false),
                            icon: Icon(
                              LucideIcons.x,
                              color: theme.text,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // List of chapters
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: widget.chapters.isEmpty
                            ? 10
                            : widget.chapters.length,
                        itemBuilder: (context, index) {
                          final isActive = index == _currentChapterIndex;
                          final title = widget.chapters.isEmpty
                              ? (index == 0
                                    ? 'Khởi đầu'
                                    : 'Hành trình ${index + 1}')
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
                                    style: TextStyle(
                                      fontFamily: 'MySans',
                                      fontSize: 10,
                                      color: theme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontFamily: 'MySerif',
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
                        style: TextStyle(
                          fontFamily: 'MySans',
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
                        style: TextStyle(
                          fontFamily: 'MySerif',
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
                  style: TextStyle(
                    fontFamily: 'MySans',
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
                  style: TextStyle(
                    fontFamily: 'MySans',
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
                  style: TextStyle(
                    fontFamily: 'MySans',
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
                    style: TextStyle(
                      fontFamily: 'MySans',
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
          padding: const EdgeInsets.all(24), // p-6 = 24px
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 672,
              ), // max-w-2xl = 672px
              child: Container(
                padding: const EdgeInsets.all(24), // p-6 = 24px
                decoration: BoxDecoration(
                  color: theme.panelBg,
                  borderRadius: BorderRadius.circular(32), // rounded-[32px]
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
                              style: TextStyle(
                                fontFamily: 'MySerif',
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
                              style: TextStyle(
                                fontFamily: 'MySans',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                color: theme.iconActive,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Còn khoảng $_estimatedMinutes phút đọc',
                              style: TextStyle(
                                fontFamily: 'MySans',
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
        ),
      ),
    );
  }

  Widget _buildProgressBar(ReaderTheme theme) {
    return ValueListenableBuilder<double>(
      valueListenable: _progressNotifier,
      builder: (context, progress, _) {
        return Row(
          children: [
            Text(
              '0%',
              style: TextStyle(
                fontFamily: 'MySans',
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
                    widthFactor: progress / 100,
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
                      value: progress.clamp(0, 100),
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
              style: TextStyle(
                fontFamily: 'MySans',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.iconActive.withValues(alpha: 0.7),
              ),
            ),
          ],
        );
      },
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
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  if (_fontSize > 12) {
                                    // Update notifier immediately for instant visual feedback
                                    _fontSize--;
                                    _fontSizeNotifier.value = _fontSize;
                                    setState(() {});
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Icon(
                                    LucideIcons.minus,
                                    size: 16,
                                    color: theme.text,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  if (_fontSize < 32) {
                                    // Update notifier immediately for instant visual feedback
                                    _fontSize++;
                                    _fontSizeNotifier.value = _fontSize;
                                    setState(() {});
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Icon(
                                    LucideIcons.plus,
                                    size: 16,
                                    color: theme.text,
                                  ),
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
      style: TextStyle(
        fontFamily: 'MySans',
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
        onTap: () {
          setState(() {
            _themeMode = mode;
            _themeModeNotifier.value = mode;
          });
        },
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Update notifier immediately for instant visual feedback
            _fontFamilyNotifier.value = font;
            setState(() {
              _fontFamily = font;
            });
          },
          borderRadius: BorderRadius.circular(8),
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
                style: TextStyle(
                  fontFamily: 'MySans',
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
      ),
    );
  }

  Widget _buildLineHeightButton(double value, ReaderTheme theme) {
    final isSelected = _lineHeight == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          // Update notifier immediately for instant visual feedback
          _lineHeightNotifier.value = value;
          setState(() {
            _lineHeight = value;
          });
        },
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
        onTap: () {
          // Update notifier immediately for instant visual feedback
          _wordSpacingNotifier.value = value;
          setState(() {
            _wordSpacing = value;
          });
        },
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
  final String html; // Keep for backward compatibility if needed
  final List<String> paragraphs; // Split paragraphs for virtualization
  final int wordCount;

  _RenderedChapter({
    required this.title,
    required this.html,
    required this.paragraphs,
    required this.wordCount,
  });
}

// Custom Text Selection Controls
class CustomTextSelectionControls extends TextSelectionControls {
  final Function(TextSelection, String, Offset?) onSelectionChanged;
  final ReaderTheme theme;

  CustomTextSelectionControls({
    required this.onSelectionChanged,
    required this.theme,
  });

  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueListenable<ClipboardStatus>? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    print('buildToolbar called!');
    // Get selected text
    final selection = delegate.textEditingValue.selection;
    final selectedText = selection.isValid
        ? delegate.textEditingValue.text.substring(
            selection.start,
            selection.end,
          )
        : '';

    print('buildToolbar - selection: $selection, text: "$selectedText"');

    // Notify parent about selection immediately - don't wait for post frame
    // This ensures the menu appears as soon as text is selected
    if (selectedText.trim().isNotEmpty) {
      print(
        'buildToolbar - calling onSelectionChanged with text: "$selectedText"',
      );
      // Call immediately, then also in post frame to ensure it's processed
      // Pass the global position

      Offset? position;
      if (endpoints.isNotEmpty) {
        // Calculate midpoint of the selection
        // endpoints are relative to the globalEditableRegion's top-left
        // globalEditableRegion is the rect of the render object in global coordinates

        final TextSelectionPoint start = endpoints.first;
        // If we have multiple endpoints (multi-line selection), we might want to use the first line's start
        // or calculate a bounding box. For simplicity, let's use the start of the selection.

        // Adjust position to be global
        position = globalEditableRegion.topLeft + start.point;
      }

      onSelectionChanged(selection, selectedText, position);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onSelectionChanged(selection, selectedText, position);
      });
    } else {
      // Clear selection if empty
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onSelectionChanged(const TextSelection.collapsed(offset: -1), '', null);
      });
    }

    // Return empty toolbar - we'll use our custom overlay instead
    return const SizedBox.shrink();
  }

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    return Offset.zero;
  }

  @override
  Size getHandleSize(double textLineHeight) {
    return Size.zero;
  }

  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
  ]) {
    return const SizedBox.shrink();
  }

  @override
  bool canSelectAll(TextSelectionDelegate delegate) {
    return false;
  }

  @override
  bool canCopy(TextSelectionDelegate delegate) {
    return delegate.textEditingValue.selection.isValid;
  }

  @override
  bool canCut(TextSelectionDelegate delegate) {
    return false;
  }

  @override
  bool canPaste(TextSelectionDelegate delegate) {
    return false;
  }

  @override
  void handleCopy(TextSelectionDelegate delegate) {
    // Handled by our custom menu
  }
}

// Arrow Painter for menu
class _ArrowPainter extends CustomPainter {
  final Color color;

  _ArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Note Dialog
class _NoteDialog extends StatefulWidget {
  final String selectedText;
  final ReaderTheme theme;
  final Function(String) onSave;

  const _NoteDialog({
    required this.selectedText,
    required this.theme,
    required this.onSave,
  });

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: widget.theme.panelBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ghi chú',
                  style: TextStyle(
                    fontFamily: 'MySerif',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.theme.text,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(LucideIcons.x, color: widget.theme.text, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Selected text preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.theme.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '"${widget.selectedText}"',
                style: TextStyle(
                  fontFamily: 'MySans',
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: widget.theme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Note input
            TextField(
              controller: _noteController,
              autofocus: true,
              maxLines: 5,
              style: TextStyle(
                fontFamily: 'MySans',
                fontSize: 16,
                color: widget.theme.text,
              ),
              decoration: InputDecoration(
                hintText: 'Nhập ghi chú của bạn...',
                hintStyle: TextStyle(color: widget.theme.textSecondary),
                filled: true,
                fillColor: widget.theme.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.theme.text.withValues(alpha: 0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.theme.text.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: widget.theme.accent, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Hủy',
                    style: TextStyle(
                      fontFamily: 'MySans',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: widget.theme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final noteContent = _noteController.text.trim();
                    if (noteContent.isNotEmpty) {
                      widget.onSave(noteContent);
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.theme.buttonBg,
                    foregroundColor: widget.theme.buttonText,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Lưu',
                    style: TextStyle(
                      fontFamily: 'MySans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
