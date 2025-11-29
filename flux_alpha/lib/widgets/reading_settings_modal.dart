import 'package:flutter/material.dart';
import '../models/color_theme.dart';
import '../models/font_theme.dart';

/// Reading Settings Modal - Minimalist Design
///
/// Sections:
/// 1. MÀU NỀN (Background Colors) - 4 theme options
/// 2. FONT CHỮ | CỠ CHỮ (Font Type | Font Size)
/// 3. DẪN DÒNG | DẪN TỪ (Line Spacing | Word Spacing)
class ReadingSettingsModal extends StatefulWidget {
  final ColorThemeModel activeColor;
  final FontThemeModel activeFont;
  final bool darkMode;
  final double fontSize;
  final Function(double) setFontSize;
  final VoidCallback toggleTheme;

  // Reading settings
  final int selectedBackgroundColor;
  final String selectedFontType;
  final double lineSpacing;
  final double wordSpacing;

  // Callbacks for settings changes
  final Function(int) onBackgroundColorChanged;
  final Function(String) onFontTypeChanged;
  final Function(double) onLineSpacingChanged;
  final Function(double) onWordSpacingChanged;

  const ReadingSettingsModal({
    super.key,
    required this.activeColor,
    required this.activeFont,
    required this.darkMode,
    required this.fontSize,
    required this.setFontSize,
    required this.toggleTheme,
    required this.selectedBackgroundColor,
    required this.selectedFontType,
    required this.lineSpacing,
    required this.wordSpacing,
    required this.onBackgroundColorChanged,
    required this.onFontTypeChanged,
    required this.onLineSpacingChanged,
    required this.onWordSpacingChanged,
  });

  @override
  State<ReadingSettingsModal> createState() => _ReadingSettingsModalState();
}

class _ReadingSettingsModalState extends State<ReadingSettingsModal> {
  late int _selectedBg;
  late String _selectedFont;
  late double _lineSpacing;
  late double _wordSpacing;

  // Background color options
  static const List<Color> backgroundColors = [
    Color(0xFFFFFDF8), // Paper white
    Color(0xFFF5F0E6), // Cream/Beige
    Color(0xFF4A4A4A), // Dark grey
    Color(0xFF000000), // True black (AMOLED)
  ];

  @override
  void initState() {
    super.initState();
    _selectedBg = widget.selectedBackgroundColor;
    _selectedFont = widget.selectedFontType;
    _lineSpacing = widget.lineSpacing;
    _wordSpacing = widget.wordSpacing;
  }

  Color get _primaryColor => widget.activeColor.accentBg;
  Color get _textColor => widget.activeColor.textColor;
  Color get _textLight => widget.activeColor.textLight;
  Color get _cardBg =>
      widget.darkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF2F0E9);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          _buildDragHandle(),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 1: MÀU NỀN (Background Colors)
                _buildSectionLabel('MÀU NỀN'),
                const SizedBox(height: 12),
                _buildBackgroundColorSection(),

                const SizedBox(height: 28),

                // Section 2: FONT CHỮ | CỠ CHỮ
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Font Type
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('FONT CHỮ'),
                          const SizedBox(height: 12),
                          _buildFontTypeSection(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Right: Font Size
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel(
                            'CỠ CHỮ: ${widget.fontSize.toInt()}',
                          ),
                          const SizedBox(height: 12),
                          _buildFontSizeSection(),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Section 3: DẪN DÒNG | DẪN TỪ
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Line Spacing
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('DẪN DÒNG'),
                          const SizedBox(height: 12),
                          _buildLineSpacingSection(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Right: Word Spacing
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('DẪN TỪ'),
                          const SizedBox(height: 12),
                          _buildWordSpacingSection(),
                        ],
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

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: _textLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: widget.activeFont.sansFont,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _textLight,
        letterSpacing: 0.8,
      ),
    );
  }

  // ============================================
  // SECTION 1: Background Colors
  // ============================================
  Widget _buildBackgroundColorSection() {
    return Row(
      children: List.generate(4, (index) {
        final isSelected = _selectedBg == index;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < 3 ? 10 : 0),
            child: _buildClickTarget(
              onTap: () {
                setState(() => _selectedBg = index);
                widget.onBackgroundColorChanged(index);
              },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: backgroundColors[index],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? _primaryColor : Colors.transparent,
                    width: isSelected ? 3 : 0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ============================================
  // SECTION 2: Font Type
  // ============================================
  Widget _buildFontTypeSection() {
    return Row(
      children: [
        _buildFontTypeButton('serif', 'Có chân'),
        const SizedBox(width: 8),
        _buildFontTypeButton('sans', 'Sans'),
        const SizedBox(width: 8),
        _buildFontTypeButton('mono', 'Mono'),
      ],
    );
  }

  Widget _buildFontTypeButton(String type, String label) {
    final isSelected = _selectedFont == type;
    return Expanded(
      child: _buildClickTarget(
        onTap: () {
          if (_selectedFont != type) {
            setState(() => _selectedFont = type);
          }
          widget.onFontTypeChanged(type);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? _primaryColor.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? _primaryColor : Colors.transparent,
              width: isSelected ? 1.5 : 0,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: widget.activeFont.sansFont,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? _primaryColor : _textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // SECTION 2: Font Size
  // ============================================
  Widget _buildFontSizeSection() {
    return Row(
      children: [
        // Minus button
        _buildFontSizeButton(
          icon: Icons.remove,
          onTap: () {
            if (widget.fontSize > 14) {
              widget.setFontSize(widget.fontSize - 1);
            }
          },
        ),
        const Spacer(),
        // Plus button
        _buildFontSizeButton(
          icon: Icons.add,
          onTap: () {
            if (widget.fontSize < 28) {
              widget.setFontSize(widget.fontSize + 1);
            }
          },
        ),
      ],
    );
  }

  Widget _buildFontSizeButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _buildClickTarget(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _textLight.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: _textColor),
      ),
    );
  }

  // ============================================
  // SECTION 3: Line Spacing
  // ============================================
  Widget _buildLineSpacingSection() {
    return Row(
      children: [
        _buildLineSpacingButton(1.2),
        const SizedBox(width: 8),
        _buildLineSpacingButton(1.5),
        const SizedBox(width: 8),
        _buildLineSpacingButton(1.8),
      ],
    );
  }

  Widget _buildLineSpacingButton(double spacing) {
    final isSelected = (_lineSpacing - spacing).abs() < 0.1;

    // Determine number of lines and gap based on spacing
    final gapHeight = spacing == 1.2 ? 3.0 : (spacing == 1.5 ? 5.0 : 7.0);

    return Expanded(
      child: _buildClickTarget(
        onTap: () {
          setState(() => _lineSpacing = spacing);
          widget.onLineSpacingChanged(spacing);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? _primaryColor.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? _primaryColor : Colors.transparent,
              width: isSelected ? 1.5 : 0,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [_buildLineIcon(gapHeight, isSelected)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineIcon(double gap, bool isSelected) {
    final lineColor = isSelected ? _primaryColor : _textLight;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          margin: EdgeInsets.only(bottom: index < 2 ? gap : 0),
          width: 24,
          height: 2,
          decoration: BoxDecoration(
            color: lineColor,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  // ============================================
  // SECTION 3: Word Spacing
  // ============================================
  Widget _buildWordSpacingSection() {
    return Row(
      children: [
        _buildWordSpacingButton(0.0),
        const SizedBox(width: 8),
        _buildWordSpacingButton(2.0),
        const SizedBox(width: 8),
        _buildWordSpacingButton(4.0),
      ],
    );
  }

  Widget _buildWordSpacingButton(double spacing) {
    final isSelected = (_wordSpacing - spacing).abs() < 0.1;

    // Determine dot gap based on spacing
    final dotGap = spacing == 0.0 ? 6.0 : (spacing == 2.0 ? 12.0 : 20.0);

    return Expanded(
      child: _buildClickTarget(
        onTap: () {
          setState(() => _wordSpacing = spacing);
          widget.onWordSpacingChanged(spacing);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? _primaryColor.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? _primaryColor : Colors.transparent,
              width: isSelected ? 1.5 : 0,
            ),
          ),
          child: Center(child: _buildDotsIcon(dotGap, isSelected)),
        ),
      ),
    );
  }

  Widget _buildDotsIcon(double gap, bool isSelected) {
    final dotColor = isSelected ? _primaryColor : _textLight;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        SizedBox(width: gap),
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
      ],
    );
  }

  Widget _buildClickTarget({
    required VoidCallback onTap,
    required Widget child,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      ),
    );
  }
}

/// Extension method to show the modal
void showReadingSettingsModal({
  required BuildContext context,
  required ColorThemeModel activeColor,
  required FontThemeModel activeFont,
  required bool darkMode,
  required double fontSize,
  required Function(double) setFontSize,
  required VoidCallback toggleTheme,
  required int selectedBackgroundColor,
  required String selectedFontType,
  required double lineSpacing,
  required double wordSpacing,
  required Function(int) onBackgroundColorChanged,
  required Function(String) onFontTypeChanged,
  required Function(double) onLineSpacingChanged,
  required Function(double) onWordSpacingChanged,
  VoidCallback? onDismiss,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => ReadingSettingsModal(
      activeColor: activeColor,
      activeFont: activeFont,
      darkMode: darkMode,
      fontSize: fontSize,
      setFontSize: setFontSize,
      toggleTheme: toggleTheme,
      selectedBackgroundColor: selectedBackgroundColor,
      selectedFontType: selectedFontType,
      lineSpacing: lineSpacing,
      wordSpacing: wordSpacing,
      onBackgroundColorChanged: onBackgroundColorChanged,
      onFontTypeChanged: onFontTypeChanged,
      onLineSpacingChanged: onLineSpacingChanged,
      onWordSpacingChanged: onWordSpacingChanged,
    ),
  ).whenComplete(() {
    onDismiss?.call();
  });
}
