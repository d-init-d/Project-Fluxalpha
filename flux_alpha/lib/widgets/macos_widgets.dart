import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/macos_design_tokens.dart';

/// macOS-style Card with vibrancy effect
///
/// Features:
/// - Rounded corners (14px - macOS Big Sur style)
/// - Subtle shadow
/// - Optional blur background (vibrancy)
/// - Thin border with low opacity
class MacOSCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final bool enableVibrancy;
  final bool showBorder;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const MacOSCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.enableVibrancy = false,
    this.showBorder = true,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        backgroundColor ??
        (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF2F0E9));

    Widget card = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: enableVibrancy
            ? bgColor.withOpacity(MacOSDesignTokens.vibrancyOpacity)
            : bgColor,
        borderRadius: MacOSDesignTokens.borderRadiusXL,
        border: showBorder
            ? MacOSDesignTokens.subtleBorder(
                isDark ? Colors.white : Colors.black,
                isDark: isDark,
              )
            : null,
        boxShadow: MacOSDesignTokens.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: MacOSDesignTokens.borderRadiusXL,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(MacOSDesignTokens.spacingLG),
          child: child,
        ),
      ),
    );

    if (enableVibrancy) {
      card = ClipRRect(
        borderRadius: MacOSDesignTokens.borderRadiusXL,
        child: BackdropFilter(
          filter: MacOSDesignTokens.vibrancyFilter,
          child: card,
        ),
      );
    }

    if (onTap != null) {
      return _MacOSCardHover(
        onTap: onTap!,
        borderRadius: MacOSDesignTokens.borderRadiusXL,
        child: card,
      );
    }

    return card;
  }
}

/// Internal widget for hover effect
class _MacOSCardHover extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final BorderRadius borderRadius;

  const _MacOSCardHover({
    required this.child,
    required this.onTap,
    required this.borderRadius,
  });

  @override
  State<_MacOSCardHover> createState() => _MacOSCardHoverState();
}

class _MacOSCardHoverState extends State<_MacOSCardHover> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: MacOSDesignTokens.durationFast,
          transform: Matrix4.identity()..scale(_isHovered ? 1.01 : 1.0),
          transformAlignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}

/// macOS-style Segmented Control
///
/// Features:
/// - Horizontal pill-shaped segments
/// - Smooth sliding indicator
/// - Subtle background
class MacOSSegmentedControl<T> extends StatelessWidget {
  final List<T> segments;
  final T selectedSegment;
  final ValueChanged<T> onSegmentSelected;
  final String Function(T) labelBuilder;
  final Color? accentColor;
  final Color? backgroundColor;

  const MacOSSegmentedControl({
    super.key,
    required this.segments,
    required this.selectedSegment,
    required this.onSegmentSelected,
    required this.labelBuilder,
    this.accentColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        backgroundColor ??
        (isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.05));
    final accent = accentColor ?? const Color(0xFF043222);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: MacOSDesignTokens.borderRadiusMD,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: segments.map((segment) {
          final isSelected = segment == selectedSegment;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSegmentSelected(segment),
              child: AnimatedContainer(
                duration: MacOSDesignTokens.durationFast,
                padding: const EdgeInsets.symmetric(
                  horizontal: MacOSDesignTokens.spacingMD,
                  vertical: MacOSDesignTokens.spacingSM,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF2D2D2D) : Colors.white)
                      : Colors.transparent,
                  borderRadius: MacOSDesignTokens.borderRadiusSM,
                  boxShadow: isSelected
                      ? [MacOSDesignTokens.subtleShadow]
                      : null,
                ),
                child: Center(
                  child: Text(
                    labelBuilder(segment),
                    style: TextStyle(
                      fontSize: MacOSDesignTokens.fontSizeSubheadline,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? accent
                          : (isDark ? Colors.white70 : Colors.black54),
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
}

/// macOS-style Toolbar Button
///
/// Features:
/// - SF Symbols-style icons
/// - Subtle hover state (background highlight)
/// - No visible border by default
class MacOSToolbarButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool isActive;
  final Color? activeColor;
  final double iconSize;

  const MacOSToolbarButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.isActive = false,
    this.activeColor,
    this.iconSize = MacOSDesignTokens.iconSizeMD,
  });

  @override
  State<MacOSToolbarButton> createState() => _MacOSToolbarButtonState();
}

class _MacOSToolbarButtonState extends State<MacOSToolbarButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = widget.isActive
        ? (widget.activeColor ?? const Color(0xFF043222))
        : (isDark ? Colors.white70 : Colors.black87);

    Color? bgColor;
    if (_isPressed) {
      bgColor = isDark
          ? Colors.white.withOpacity(MacOSDesignTokens.opacityPressed)
          : Colors.black.withOpacity(MacOSDesignTokens.opacityPressed);
    } else if (_isHovered || widget.isActive) {
      bgColor = isDark
          ? Colors.white.withOpacity(MacOSDesignTokens.opacityHover)
          : Colors.black.withOpacity(MacOSDesignTokens.opacityHover);
    }

    Widget button = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed?.call();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: MacOSDesignTokens.durationFast,
          padding: const EdgeInsets.all(MacOSDesignTokens.spacingSM),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: MacOSDesignTokens.borderRadiusSM,
          ),
          child: Icon(widget.icon, size: widget.iconSize, color: iconColor),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        waitDuration: const Duration(milliseconds: 500),
        child: button,
      );
    }

    return button;
  }
}

/// macOS-style Pill Button
///
/// Features:
/// - Pill shape (fully rounded ends)
/// - Optional icon
/// - Subtle animation on press
class MacOSPillButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isPrimary;

  const MacOSPillButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.isPrimary = false,
  });

  @override
  State<MacOSPillButton> createState() => _MacOSPillButtonState();
}

class _MacOSPillButtonState extends State<MacOSPillButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = const Color(0xFF043222);

    Color bgColor;
    Color fgColor;

    if (widget.isPrimary) {
      bgColor = widget.backgroundColor ?? accent;
      fgColor = widget.foregroundColor ?? Colors.white;
    } else {
      bgColor =
          widget.backgroundColor ??
          (isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05));
      fgColor = widget.foregroundColor ?? (isDark ? Colors.white : accent);
    }

    if (_isHovered && !_isPressed) {
      bgColor = bgColor.withOpacity(bgColor.opacity * 1.1);
    }
    if (_isPressed) {
      bgColor = bgColor.withOpacity(bgColor.opacity * 0.9);
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed?.call();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: MacOSDesignTokens.durationFast,
          padding: EdgeInsets.symmetric(
            horizontal: widget.icon != null
                ? MacOSDesignTokens.spacingMD
                : MacOSDesignTokens.spacingLG,
            vertical: MacOSDesignTokens.spacingSM + 2,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(100),
            border: !widget.isPrimary
                ? Border.all(
                    color: fgColor.withOpacity(0.2),
                    width: MacOSDesignTokens.borderWidthThin,
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: MacOSDesignTokens.iconSizeSM,
                  color: fgColor,
                ),
                const SizedBox(width: MacOSDesignTokens.spacingXS),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: MacOSDesignTokens.fontSizeSubheadline,
                  fontWeight: FontWeight.w500,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// macOS-style Sheet (Bottom Modal)
///
/// Features:
/// - Rounded top corners (20px)
/// - Subtle blur background
/// - Drag handle indicator
class MacOSSheet extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final bool showDragHandle;
  final bool enableVibrancy;

  const MacOSSheet({
    super.key,
    required this.child,
    this.backgroundColor,
    this.showDragHandle = true,
    this.enableVibrancy = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        backgroundColor ??
        (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF2F0E9));

    Widget sheet = Container(
      decoration: BoxDecoration(
        color: enableVibrancy
            ? bgColor.withOpacity(MacOSDesignTokens.vibrancyOpacityLight)
            : bgColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(MacOSDesignTokens.radiusXXL),
        ),
        boxShadow: MacOSDesignTokens.popoverShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [if (showDragHandle) _buildDragHandle(isDark), child],
      ),
    );

    if (enableVibrancy) {
      sheet = ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(MacOSDesignTokens.radiusXXL),
        ),
        child: BackdropFilter(
          filter: MacOSDesignTokens.vibrancyFilter,
          child: sheet,
        ),
      );
    }

    return sheet;
  }

  Widget _buildDragHandle(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(
        top: MacOSDesignTokens.spacingMD,
        bottom: MacOSDesignTokens.spacingSM,
      ),
      width: 36,
      height: 5,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.2)
            : Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

/// macOS-style Divider
class MacOSDivider extends StatelessWidget {
  final double? indent;
  final double? endIndent;

  const MacOSDivider({super.key, this.indent, this.endIndent});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: MacOSDesignTokens.borderWidthThin,
      indent: indent,
      endIndent: endIndent,
      color: isDark
          ? Colors.white.withOpacity(MacOSDesignTokens.opacityDivider)
          : Colors.black.withOpacity(MacOSDesignTokens.opacityDivider),
    );
  }
}

/// macOS-style Section Header
class MacOSSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final String? fontFamily;

  const MacOSSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: MacOSDesignTokens.fontSizeCaption,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Colors.black45,
            letterSpacing: 0.5,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
