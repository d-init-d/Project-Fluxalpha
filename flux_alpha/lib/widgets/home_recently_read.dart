import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/book.dart';
import '../models/color_theme.dart';
import '../models/font_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/book_provider.dart';
import '../widgets/book_cover_widget.dart';
import '../screens/book_reader_screen.dart';

/// Recently read books section with horizontal scrolling list
class RecentlyReadSection extends ConsumerWidget {
  final List<Book> recentBooks;
  final ColorThemeModel theme;
  final FontThemeModel fontTheme;

  const RecentlyReadSection({
    super.key,
    required this.recentBooks,
    required this.theme,
    required this.fontTheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.recently_read,
                  style: GoogleFonts.getFont(
                    fontTheme.serifFont,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.continue_journey,
                  style: GoogleFonts.getFont(
                    fontTheme.sansFont,
                    fontSize: 14,
                    color: theme.textLight,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.chevronLeft, size: 16),
                  style: IconButton.styleFrom(
                    shape: const CircleBorder(),
                    side: BorderSide(color: theme.textColor),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.chevronRight, size: 16),
                  style: IconButton.styleFrom(
                    shape: const CircleBorder(),
                    side: BorderSide(color: theme.textColor),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentBooks.length + 1,
            itemBuilder: (context, index) {
              return index == recentBooks.length
                  ? _AddMoreCard(theme: theme, fontTheme: fontTheme)
                  : _BookCard(
                      book: recentBooks[index],
                      theme: theme,
                      fontTheme: fontTheme,
                    );
            },
          ),
        ),
      ],
    );
  }
}

class _BookCard extends ConsumerWidget {
  final Book book;
  final ColorThemeModel theme;
  final FontThemeModel fontTheme;

  const _BookCard({
    required this.book,
    required this.theme,
    required this.fontTheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = book.progress.clamp(0.0, 1.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await ref.read(bookListProvider.notifier).markBookOpened(book.id);
          if (!context.mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BookReaderScreen(book: book),
            ),
          );
        },
        borderRadius: BorderRadius.circular(10),
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.only(right: 24),
          child: BookCoverWidget(
            book: book,
            theme: theme,
            overlayWidgets: [
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
              // Book info overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        book.title,
                        style: GoogleFonts.getFont(
                          fontTheme.serifFont,
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.author,
                        style: GoogleFonts.getFont(
                          fontTheme.sansFont,
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation(
                            Colors.white,
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
    );
  }
}

class _AddMoreCard extends StatelessWidget {
  final ColorThemeModel theme;
  final FontThemeModel fontTheme;

  const _AddMoreCard({required this.theme, required this.fontTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.textColor.withValues(alpha: 0.2),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to library tab
            // This will be handled by parent widget via callback
          },
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.textColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.plus,
                    size: 32,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Thêm sách',
                  style: GoogleFonts.getFont(
                    fontTheme.sansFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
