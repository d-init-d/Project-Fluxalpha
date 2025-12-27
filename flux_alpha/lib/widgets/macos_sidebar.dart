import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flux_alpha/utils/macos_design_tokens.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// macOS-style Sidebar Navigation
///
/// Features:
/// - Collapsible/expandable sidebar
/// - Source list style items
/// - Hover effects
/// - Smooth animations
class MacOSSidebar extends StatefulWidget {
  final int activeIndex;
  final ValueChanged<int> onItemSelected;
  final List<MacOSSidebarItem> items;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;
  final Color? backgroundColor;
  final Color? activeColor;
  final String? fontFamily;
  final bool isDarkMode;

  const MacOSSidebar({
    super.key,
    required this.activeIndex,
    required this.onItemSelected,
    required this.items,
    this.isExpanded = true,
    this.onToggleExpanded,
    this.backgroundColor,
    this.activeColor,
    this.fontFamily,
    this.isDarkMode = false,
  });

  @override
  State<MacOSSidebar> createState() => _MacOSSidebarState();
}

class _MacOSSidebarState extends State<MacOSSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;

  static const double expandedWidth = 220.0;
  static const double collapsedWidth = 64.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: MacOSDesignTokens.durationNormal,
      vsync: this,
    );
    _widthAnimation = Tween<double>(begin: collapsedWidth, end: expandedWidth)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: MacOSDesignTokens.curveDefault,
          ),
        );

    if (widget.isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(MacOSSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor =
        widget.backgroundColor ??
        (widget.isDarkMode
            ? const Color(0xFF1A1A1A).withValues(alpha: 0.95)
            : const Color(0xFFF5F0E6).withValues(alpha: 0.95));

    final activeColor = widget.activeColor ?? const Color(0xFF043222);

    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: _widthAnimation.value,
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(
                  right: BorderSide(
                    color: widget.isDarkMode
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: MacOSDesignTokens.spacingLG),
                  // Toggle button
                  _buildToggleButton(activeColor),
                  const SizedBox(height: MacOSDesignTokens.spacingXL),
                  // Navigation items
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MacOSDesignTokens.spacingSM,
                      ),
                      itemCount: widget.items.length,
                      itemBuilder: (context, index) {
                        return _MacOSSidebarItemWidget(
                          item: widget.items[index],
                          isActive: index == widget.activeIndex,
                          isExpanded: widget.isExpanded,
                          activeColor: activeColor,
                          isDarkMode: widget.isDarkMode,
                          fontFamily: widget.fontFamily,
                          onTap: () => widget.onItemSelected(index),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: MacOSDesignTokens.spacingLG),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToggleButton(Color activeColor) {
    // Calculate padding to center icon in collapsed state (64px width)
    // Icon size is MD (16px).
    // (64 - 16 - 16 (padding Sxx2?))
    // Let's use specific padding matching the items.
    // For items we'll use horizontal padding of 20px to center 16px icon in near 60px?
    // Actually collapsedWidth is 64.
    // To center 16px icon: (64-16)/2 = 24px per side.
    const double iconSize = MacOSDesignTokens.iconSizeMD;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.isExpanded ? 0 : 0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onToggleExpanded,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            // When expanded, we use standard padding. When collapsed, we center.
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: MacOSDesignTokens.borderRadiusSM,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Icon wrapper to ensure exact center alignment
                Container(
                  width: 48, // 64 (width) - 16 (margin) = 48 available space
                  alignment: Alignment.center,
                  child: Icon(
                    widget.isExpanded
                        ? LucideIcons.panelLeftClose
                        : LucideIcons.panelLeft,
                    size: iconSize,
                    color: widget.isDarkMode ? Colors.white60 : Colors.black45,
                  ),
                ),
                // Text with animated opacity
                Expanded(
                  child: AnimatedOpacity(
                    opacity: widget.isExpanded ? 1.0 : 0.0,
                    duration: MacOSDesignTokens.durationFast,
                    curve: Curves.easeOut,
                    child: widget.isExpanded
                        ? Text(
                            'Thu gọn',
                            style: TextStyle(
                              fontFamily: widget.fontFamily,
                              fontSize: MacOSDesignTokens.fontSizeSubheadline,
                              color: widget.isDarkMode
                                  ? Colors.white60
                                  : Colors.black45,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                          )
                        : const SizedBox(),
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

/// Data class for sidebar items
class MacOSSidebarItem {
  final IconData icon;
  final String label;
  final String? badge;

  const MacOSSidebarItem({required this.icon, required this.label, this.badge});
}

/// Individual sidebar item widget with hover effect
class _MacOSSidebarItemWidget extends StatefulWidget {
  final MacOSSidebarItem item;
  final bool isActive;
  final bool isExpanded;
  final Color activeColor;
  final bool isDarkMode;
  final String? fontFamily;
  final VoidCallback onTap;

  const _MacOSSidebarItemWidget({
    required this.item,
    required this.isActive,
    required this.isExpanded,
    required this.activeColor,
    required this.isDarkMode,
    required this.onTap,
    this.fontFamily,
  });

  @override
  State<_MacOSSidebarItemWidget> createState() =>
      _MacOSSidebarItemWidgetState();
}

class _MacOSSidebarItemWidgetState extends State<_MacOSSidebarItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color iconColor;
    Color textColor;

    if (widget.isActive) {
      bgColor = widget.activeColor.withValues(alpha: 0.12);
      iconColor = widget.activeColor;
      textColor = widget.activeColor;
    } else if (_isHovered) {
      bgColor = widget.isDarkMode
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.04);
      iconColor = widget.isDarkMode ? Colors.white70 : Colors.black87;
      textColor = widget.isDarkMode ? Colors.white70 : Colors.black87;
    } else {
      bgColor = Colors.transparent;
      iconColor = widget.isDarkMode ? Colors.white54 : Colors.black54;
      textColor = widget.isDarkMode ? Colors.white54 : Colors.black54;
    }

    const double iconSize = MacOSDesignTokens.iconSizeMD;

    return Padding(
      padding: const EdgeInsets.only(bottom: MacOSDesignTokens.spacingXS),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: MacOSDesignTokens.durationFast,
            margin: const EdgeInsets.symmetric(
              horizontal: 8,
            ), // Standard margin
            padding: const EdgeInsets.symmetric(
              vertical: 8,
              // No horizontal padding in container, we handle layout manually
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: MacOSDesignTokens.borderRadiusSM,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Fixed width container for icon to ensure stability
                Container(
                  width: 48, // Matches toggle button: 64 - 16 = 48
                  alignment: Alignment.center,
                  child: Icon(
                    widget.item.icon,
                    size: iconSize,
                    color: iconColor,
                  ),
                ),
                // Text Content
                Expanded(
                  child: AnimatedOpacity(
                    opacity: widget.isExpanded ? 1.0 : 0.0,
                    duration: MacOSDesignTokens.durationFast,
                    curve: Curves.easeOut,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.item.label,
                            style: TextStyle(
                              fontFamily: widget.fontFamily,
                              fontSize: MacOSDesignTokens.fontSizeSubheadline,
                              fontWeight: widget.isActive
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: textColor,
                            ),
                            overflow: TextOverflow.clip,
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                        if (widget.item.badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(left: 4, right: 8),
                            decoration: BoxDecoration(
                              color: widget.activeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              widget.item.badge!,
                              style: TextStyle(
                                fontSize: MacOSDesignTokens.fontSizeCaption2,
                                fontWeight: FontWeight.w600,
                                color: widget.activeColor,
                              ),
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
      ),
    );
  }
}
