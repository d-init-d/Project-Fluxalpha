import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/color_theme.dart';
import '../models/font_theme.dart';
import '../l10n/app_localizations.dart';

/// Reading calendar and notes section displayed side by side
class StatsAndNotesSection extends StatelessWidget {
  final ColorThemeModel theme;
  final FontThemeModel fontTheme;
  final bool darkMode;

  const StatsAndNotesSection({
    super.key,
    required this.theme,
    required this.fontTheme,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ReadingCalendarCard(
              theme: theme,
              fontTheme: fontTheme,
              darkMode: darkMode,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: NotesCard(
              theme: theme,
              fontTheme: fontTheme,
              darkMode: darkMode,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reading calendar widget showing weekly schedule
class ReadingCalendarCard extends StatelessWidget {
  final ColorThemeModel theme;
  final FontThemeModel fontTheme;
  final bool darkMode;

  const ReadingCalendarCard({
    super.key,
    required this.theme,
    required this.fontTheme,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    // Dynamic colors based on dark mode
    final cardBg = darkMode ? const Color(0xFF131B24) : theme.cardBackground;
    final borderColor = darkMode
        ? const Color(0xFF2D3748)
        : const Color(0xFFC5BCAB);
    final textColor = darkMode ? const Color(0xFFE3DAC9) : theme.textColor;
    final iconBg = darkMode ? const Color(0xFF1C2530) : Colors.white;

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
                  fontTheme.serifFont,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Icon(LucideIcons.settings, size: 18, color: theme.textLight),
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
                  color: isActive ? theme.textColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      days[index],
                      style: GoogleFonts.getFont(
                        fontTheme.sansFont,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isActive
                            ? theme.cardBackground.withValues(alpha: 0.7)
                            : theme.textLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${11 + index}',
                      style: GoogleFonts.getFont(
                        fontTheme.sansFont,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isActive ? theme.cardBackground : textColor,
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
                    color: theme.textColor,
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
                          fontTheme.sansFont,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.goal_msg,
                        style: GoogleFonts.getFont(
                          fontTheme.sansFont,
                          fontSize: 12,
                          color: theme.textLight,
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
}

/// Notes and highlights card
class NotesCard extends StatelessWidget {
  final ColorThemeModel theme;
  final FontThemeModel fontTheme;
  final bool darkMode;

  const NotesCard({
    super.key,
    required this.theme,
    required this.fontTheme,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    // Dynamic colors based on dark mode
    final cardBg = darkMode ? const Color(0xFF131B24) : theme.cardBackground;
    final borderColor = darkMode
        ? const Color(0xFF2D3748)
        : const Color(0xFFC5BCAB);
    final textColor = darkMode ? const Color(0xFFE3DAC9) : theme.textColor;

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
                  fontTheme.serifFont,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Icon(LucideIcons.penTool, size: 18, color: theme.textLight),
            ],
          ),
          const SizedBox(height: 24),
          // No hardcoded notes - will be populated from actual data
        ],
      ),
    );
  }
}
