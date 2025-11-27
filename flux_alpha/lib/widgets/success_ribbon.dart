import 'package:flutter/material.dart';

/// Custom clipper for creating a bookmark ribbon shape with a V-shaped notch at the bottom.
/// This clipper creates a path that resembles a bookmark ribbon.
class BookmarkRibbonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Calculate notch depth (15% of height as specified)
    final notchDepth = size.height * 0.15;

    // 1. Start at top-left corner (0, 0)
    path.moveTo(0, 0);

    // 2. Draw straight to top-right corner (width, 0)
    path.lineTo(size.width, 0);

    // 3. Draw straight down to bottom-right (width, height)
    path.lineTo(size.width, size.height);

    // 4. Draw diagonally to center bottom to create fishtail (width / 2, height - notchDepth)
    path.lineTo(size.width / 2, size.height - notchDepth);

    // 5. Draw diagonally to bottom-left (0, height)
    path.lineTo(0, size.height);

    // 6. Close the path back to (0, 0)
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false; // Shape doesn't change dynamically
  }
}

/// A vertical ribbon/banner widget with a V-shaped cut (swallowtail) at the bottom.
/// Uses CustomClipper with PhysicalShape for optimized rendering and natural shadows.
class SuccessRibbon extends StatelessWidget {
  /// The size of the ribbon
  final Size size;

  /// Optional icon size override
  final double? iconSize;

  /// Optional background color override (uses theme primary if not provided)
  final Color? backgroundColor;

  /// Optional border color override (not used in PhysicalShape approach)
  final Color? borderColor;

  /// Optional icon color override (uses theme onPrimary if not provided)
  final Color? iconColor;

  const SuccessRibbon({
    super.key,
    this.size = const Size(28, 36),
    this.iconSize,
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveIconSize = iconSize ?? size.width * 0.57;

    // Use provided colors or fall back to theme colors
    final bgColor = backgroundColor ?? colorScheme.primary;
    final icon = iconColor ?? colorScheme.onPrimary;

    return SizedBox(
      width: size.width,
      height: size.height,
      child: PhysicalShape(
        clipper: BookmarkRibbonClipper(),
        color: bgColor,
        elevation: 4.0,
        shadowColor: Colors.black.withOpacity(0.5),
        child: Center(
          child: Icon(Icons.check, color: icon, size: effectiveIconSize),
        ),
      ),
    );
  }
}
