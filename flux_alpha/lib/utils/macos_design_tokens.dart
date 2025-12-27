import 'dart:ui';
import 'package:flutter/material.dart';

/// macOS Design Tokens
///
/// Design tokens đặc trưng của macOS Big Sur và mới hơn.
/// Sử dụng các giá trị này để đảm bảo consistency với phong cách macOS.
class MacOSDesignTokens {
  MacOSDesignTokens._();

  // ============================================
  // SPACING (8pt Grid System)
  // ============================================
  static const double spacingXXS = 2.0;
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 12.0;
  static const double spacingLG = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;
  static const double spacing3XL = 32.0;

  // ============================================
  // BORDER RADIUS (macOS Big Sur style - flatter)
  // ============================================
  static const double radiusXS = 4.0;
  static const double radiusSM = 6.0;
  static const double radiusMD = 8.0;
  static const double radiusLG = 10.0;
  static const double radiusXL = 14.0;
  static const double radiusXXL = 20.0;

  // Common border radius values
  static BorderRadius get borderRadiusSM => BorderRadius.circular(radiusSM);
  static BorderRadius get borderRadiusMD => BorderRadius.circular(radiusMD);
  static BorderRadius get borderRadiusLG => BorderRadius.circular(radiusLG);
  static BorderRadius get borderRadiusXL => BorderRadius.circular(radiusXL);

  // ============================================
  // BLUR & VIBRANCY
  // ============================================
  static const double blurRadiusSM = 10.0;
  static const double blurRadiusMD = 20.0;
  static const double blurRadiusLG = 30.0;
  static const double vibrancyOpacity = 0.7;
  static const double vibrancyOpacityLight = 0.85;

  // ============================================
  // SHADOWS (macOS subtle shadows)
  // ============================================
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 2,
      offset: const Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get floatingShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> get popoverShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 32,
      offset: const Offset(0, 12),
      spreadRadius: -8,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: -4,
    ),
  ];

  static BoxShadow get subtleShadow => BoxShadow(
    color: Colors.black.withOpacity(0.03),
    blurRadius: 4,
    offset: const Offset(0, 1),
    spreadRadius: 0,
  );

  // ============================================
  // TYPOGRAPHY SIZES (SF Pro inspired)
  // ============================================
  static const double fontSizeCaption2 = 10.0;
  static const double fontSizeCaption = 11.0;
  static const double fontSizeFootnote = 12.0;
  static const double fontSizeSubheadline = 13.0;
  static const double fontSizeBody = 14.0;
  static const double fontSizeCallout = 15.0;
  static const double fontSizeHeadline = 16.0;
  static const double fontSizeTitle3 = 18.0;
  static const double fontSizeTitle2 = 20.0;
  static const double fontSizeTitle = 24.0;
  static const double fontSizeLargeTitle = 28.0;

  // ============================================
  // ANIMATION DURATIONS
  // ============================================
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 350);

  // Animation curves (macOS uses ease-in-out predominantly)
  static const Curve curveDefault = Curves.easeInOut;
  static const Curve curveDecelerate = Curves.decelerate;
  static const Curve curveOvershoot = Curves.easeOutBack;

  // ============================================
  // COMPONENT SIZES
  // ============================================
  static const double sidebarWidth = 240.0;
  static const double sidebarMinWidth = 200.0;
  static const double toolbarHeight = 52.0;
  static const double buttonHeightSM = 22.0;
  static const double buttonHeightMD = 28.0;
  static const double buttonHeightLG = 32.0;
  static const double iconSizeSM = 14.0;
  static const double iconSizeMD = 16.0;
  static const double iconSizeLG = 20.0;

  // ============================================
  // BORDER WIDTHS
  // ============================================
  static const double borderWidthThin = 0.5;
  static const double borderWidthNormal = 1.0;
  static const double borderWidthThick = 2.0;

  // ============================================
  // OPACITY VALUES
  // ============================================
  static const double opacityDisabled = 0.38;
  static const double opacityHover = 0.08;
  static const double opacityPressed = 0.12;
  static const double opacitySelected = 0.16;
  static const double opacityDivider = 0.12;
  static const double opacityBorder = 0.08;

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Creates a macOS-style border with subtle color
  static Border subtleBorder(Color baseColor, {bool isDark = false}) {
    return Border.all(
      color: isDark
          ? Colors.white.withOpacity(opacityBorder)
          : baseColor.withOpacity(opacityBorder),
      width: borderWidthThin,
    );
  }

  /// Creates a macOS-style hover decoration
  static BoxDecoration hoverDecoration(Color color) {
    return BoxDecoration(
      color: color.withOpacity(opacityHover),
      borderRadius: borderRadiusSM,
    );
  }

  /// Creates a macOS-style selected decoration
  static BoxDecoration selectedDecoration(Color accentColor) {
    return BoxDecoration(
      color: accentColor.withOpacity(opacitySelected),
      borderRadius: borderRadiusSM,
    );
  }

  /// Creates a blur filter for vibrancy effect
  static ImageFilter get vibrancyFilter =>
      ImageFilter.blur(sigmaX: blurRadiusMD, sigmaY: blurRadiusMD);
}
