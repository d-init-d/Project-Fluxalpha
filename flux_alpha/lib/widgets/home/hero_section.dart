import 'dart:io';
import 'package:flutter/material.dart';

import 'package:lucide_icons/lucide_icons.dart';
import '../../models/book.dart';
import '../../models/color_theme.dart';
import '../../models/font_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/reading_position_service.dart';

/// Hero section widget displaying the main call-to-action with 3D book preview
class HeroSection extends StatelessWidget {
  final Book? recentBook;
  final ColorThemeModel theme;
  final FontThemeModel fontTheme;
  final ReadingPositionService positionService;
  final VoidCallback onContinueReading;
  final VoidCallback onExploreLibrary;
  final String Function(DateTime) formatRelativeTime;

  const HeroSection({
    super.key,
    required this.recentBook,
    required this.theme,
    required this.fontTheme,
    required this.positionService,
    required this.onContinueReading,
    required this.onExploreLibrary,
    required this.formatRelativeTime,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = recentBook != null
        ? "Bạn đang phiêu lưu dở ở chương ${positionService.getCurrentChapter(recentBook!.id)} của cuốn '${recentBook!.title}'. Hãy đọc tiếp ngay!"
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
                  style: TextStyle(fontFamily: fontTheme.serifFont,
                    fontSize: 48,
                    height: 1.2,
                    color: theme.textColor,
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
                style: TextStyle(fontFamily: fontTheme.sansFont,
                  fontSize: 16,
                  color: theme.textLight,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: recentBook != null
                    ? onContinueReading
                    : onExploreLibrary,
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
                  foregroundColor: theme.textColor,
                  side: BorderSide(color: theme.textColor),
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
        Expanded(
          flex: 2,
          child: _Build3DBook(
            recentBook: recentBook,
            theme: theme,
            fontTheme: fontTheme,
            formatRelativeTime: formatRelativeTime,
            onTapBook: onContinueReading,
          ),
        ),
      ],
    );
  }
}

/// 3D book display component
class _Build3DBook extends StatelessWidget {
  final Book? recentBook;
  final ColorThemeModel theme;
  final FontThemeModel fontTheme;
  final String Function(DateTime) formatRelativeTime;
  final VoidCallback onTapBook;

  const _Build3DBook({
    required this.recentBook,
    required this.theme,
    required this.fontTheme,
    required this.formatRelativeTime,
    required this.onTapBook,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider coverImage = const NetworkImage(
      'https://images.unsplash.com/photo-1618365908648-e71bd5716cba?auto=format&fit=crop&q=80&w=600',
    );
    if (recentBook?.coverFilePath != null &&
        recentBook!.coverFilePath!.isNotEmpty) {
      final coverFile = File(recentBook!.coverFilePath!);
      if (coverFile.existsSync()) {
        coverImage = FileImage(coverFile);
      }
    }

    final displayAuthor = recentBook?.author ?? 'J.K. Rowling';
    final displayTitle =
        recentBook?.title ?? 'Harry Potter\\n& Hòn đá phù thủy';
    final progressValue = (recentBook?.progress ?? 0.52)
        .clamp(0.0, 1.0)
        .toDouble();
    final progressText = '${(progressValue * 100).round()}%';
    final lastReadText = recentBook != null
        ? 'Lần cuối đọc: ${formatRelativeTime(recentBook!.lastRead)}'
        : 'Chưa có lịch sử đọc - mở thư viện để thêm sách mới.';
    final themeColor = theme.accentBg;

    const double coverAspectRatio = 2 / 3;
    const double coverHeight = 280.0;
    final double coverWidth = coverHeight * coverAspectRatio;
    const double overlayHeight = 82.0;
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
                        style: TextStyle(fontFamily: fontTheme.serifFont,
                          color: Colors.white70,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        displayTitle,
                        style: TextStyle(fontFamily: fontTheme.serifFont,
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
                              style: TextStyle(fontFamily: fontTheme.sansFont,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: overlayPrimary,
                              ),
                            ),
                            Text(
                              progressText,
                              style: TextStyle(fontFamily: fontTheme.sansFont,
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
                          style: TextStyle(fontFamily: fontTheme.sansFont,
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
              onTap: onTapBook,
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
}


