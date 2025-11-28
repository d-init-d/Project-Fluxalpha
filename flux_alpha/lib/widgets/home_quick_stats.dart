import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/color_theme.dart';
import '../models/font_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/reading_stats_service.dart';

/// Quick stats row showing today's reading time, books read, and streak
class QuickStatsRow extends StatelessWidget {
  final ColorThemeModel theme;
  final FontThemeModel fontTheme;
  final bool darkMode;
  final ReadingStatsService statsService;

  const QuickStatsRow({
    super.key,
    required this.theme,
    required this.fontTheme,
    required this.darkMode,
    required this.statsService,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = darkMode ? const Color(0xFF131B24) : theme.cardBackground;
    final borderColor = darkMode
        ? const Color(0xFF2D3748)
        : const Color(0xFFC5BCAB);
    final textColor = darkMode ? const Color(0xFFE3DAC9) : theme.textColor;

    // Get today's reading time formatted
    final todayMinutes = statsService.todayReadingMinutes;
    String todayTimeValue;
    if (todayMinutes >= 60) {
      final hours = todayMinutes ~/ 60;
      final mins = todayMinutes % 60;
      todayTimeValue = mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    } else {
      todayTimeValue = '$todayMinutes ${AppLocalizations.of(context)!.minutes}';
    }

    return Row(
      children: [
        // Today's reading time
        Expanded(
          child: _QuickStatCard(
            icon: LucideIcons.clock,
            value: todayTimeValue,
            label: AppLocalizations.of(context)!.today,
            cardBg: cardBg,
            borderColor: borderColor,
            textColor: textColor,
            theme: theme,
            fontTheme: fontTheme,
          ),
        ),
        const SizedBox(width: 12),
        // Books read
        Expanded(
          child: _QuickStatCard(
            icon: LucideIcons.book,
            value: '${statsService.booksRead}',
            label: AppLocalizations.of(context)!.books_read,
            cardBg: cardBg,
            borderColor: borderColor,
            textColor: textColor,
            theme: theme,
            fontTheme: fontTheme,
          ),
        ),
        const SizedBox(width: 12),
        // Streak
        Expanded(
          child: _QuickStatCard(
            icon: LucideIcons.zap,
            value:
                '${statsService.currentStreak} ${AppLocalizations.of(context)!.days}',
            label: AppLocalizations.of(context)!.streak,
            cardBg: cardBg,
            borderColor: borderColor,
            textColor: textColor,
            theme: theme,
            fontTheme: fontTheme,
          ),
        ),
        const SizedBox(width: 12),
        // Add goal button
        Expanded(
          child: _AddGoalCard(
            cardBg: cardBg,
            borderColor: borderColor,
            textColor: textColor,
            theme: theme,
            fontTheme: fontTheme,
          ),
        ),
      ],
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final ColorThemeModel theme;
  final FontThemeModel fontTheme;

  const _QuickStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.theme,
    required this.fontTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.textColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 16, color: theme.cardBackground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.getFont(
                    fontTheme.sansFont,
                    fontSize: 10,
                    color: theme.textLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.getFont(
                    fontTheme.sansFont,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
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

class _AddGoalCard extends StatelessWidget {
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final ColorThemeModel theme;
  final FontThemeModel fontTheme;

  const _AddGoalCard({
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.theme,
    required this.fontTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // TODO: Implement add goal functionality
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.textLight.withValues(alpha: 0.5),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Icon(LucideIcons.plus, size: 16, color: theme.textLight),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.add_goal,
                  style: GoogleFonts.getFont(
                    fontTheme.sansFont,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
