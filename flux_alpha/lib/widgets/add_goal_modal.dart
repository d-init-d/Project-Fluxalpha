import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/color_theme.dart';
import '../models/font_theme.dart';
import '../services/reading_stats_service.dart';

class AddGoalModal extends StatefulWidget {
  final ColorThemeModel theme;
  final FontThemeModel fontTheme;
  final bool isDarkMode;

  const AddGoalModal({
    super.key,
    required this.theme,
    required this.fontTheme,
    required this.isDarkMode,
  });

  @override
  State<AddGoalModal> createState() => _AddGoalModalState();
}

class _AddGoalModalState extends State<AddGoalModal> {
  final _statsService = ReadingStatsService();
  
  // Goal type: 'daily', 'monthly_books', 'monthly_hours', 'monthly_pages'
  String _selectedGoalType = 'daily';
  
  // Controllers for different goal types
  final _dailyMinutesController = TextEditingController();
  final _monthlyBooksController = TextEditingController();
  final _monthlyHoursController = TextEditingController();
  final _monthlyPagesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with current values
    _dailyMinutesController.text = _statsService.dailyGoalMinutes.toString();
    _monthlyBooksController.text = _statsService.monthlyBookGoal.toString();
    _monthlyHoursController.text = _statsService.monthlyHoursGoal.toString();
    _monthlyPagesController.text = _statsService.monthlyPagesGoal.toString();
  }

  @override
  void dispose() {
    _dailyMinutesController.dispose();
    _monthlyBooksController.dispose();
    _monthlyHoursController.dispose();
    _monthlyPagesController.dispose();
    super.dispose();
  }

  void _saveGoal() {
    try {
      switch (_selectedGoalType) {
        case 'daily':
          final minutes = int.tryParse(_dailyMinutesController.text);
          if (minutes != null && minutes > 0) {
            _statsService.setDailyGoal(minutes);
          }
          break;
        case 'monthly_books':
          final books = int.tryParse(_monthlyBooksController.text);
          if (books != null && books > 0) {
            _statsService.setMonthlyGoals(books: books);
          }
          break;
        case 'monthly_hours':
          final hours = int.tryParse(_monthlyHoursController.text);
          if (hours != null && hours > 0) {
            _statsService.setMonthlyGoals(hours: hours);
          }
          break;
        case 'monthly_pages':
          final pages = int.tryParse(_monthlyPagesController.text);
          if (pages != null && pages > 0) {
            _statsService.setMonthlyGoals(pages: pages);
          }
          break;
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDarkMode
        ? const Color(0xFF131B24)
        : widget.theme.cardBackground;
    final borderColor = widget.isDarkMode
        ? const Color(0xFF2D3748)
        : const Color(0xFFC5BCAB);
    final textColor = widget.isDarkMode
        ? const Color(0xFFE3DAC9)
        : widget.theme.textColor;
    final textLight = widget.isDarkMode
        ? Colors.grey[400]!
        : widget.theme.textLight;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 480,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: borderColor.withValues(alpha: 0.5)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.theme.highlight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.target,
                      color: widget.theme.highlight,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thêm mục tiêu',
                          style: TextStyle(
                            fontFamily: widget.fontTheme.serifFont,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Đặt mục tiêu đọc sách của bạn',
                          style: TextStyle(
                            fontFamily: widget.fontTheme.sansFont,
                            fontSize: 14,
                            color: textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(LucideIcons.x, size: 20, color: textLight),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Goal Type Selector
                    Text(
                      'LOẠI MỤC TIÊU',
                      style: TextStyle(
                        fontFamily: widget.fontTheme.sansFont,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: textLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildGoalTypeButton(
                      'daily',
                      'Mục tiêu hàng ngày',
                      'Số phút đọc mỗi ngày',
                      LucideIcons.clock,
                      textColor,
                      borderColor,
                    ),
                    const SizedBox(height: 8),
                    _buildGoalTypeButton(
                      'monthly_books',
                      'Sách đọc trong tháng',
                      'Số cuốn sách hoàn thành',
                      LucideIcons.book,
                      textColor,
                      borderColor,
                    ),
                    const SizedBox(height: 8),
                    _buildGoalTypeButton(
                      'monthly_hours',
                      'Giờ đọc trong tháng',
                      'Tổng số giờ đọc sách',
                      LucideIcons.timer,
                      textColor,
                      borderColor,
                    ),
                    const SizedBox(height: 8),
                    _buildGoalTypeButton(
                      'monthly_pages',
                      'Trang sách trong tháng',
                      'Tổng số trang đã đọc',
                      LucideIcons.fileText,
                      textColor,
                      borderColor,
                    ),

                    const SizedBox(height: 24),

                    // Goal Value Input
                    Text(
                      'GIÁ TRỊ MỤC TIÊU',
                      style: TextStyle(
                        fontFamily: widget.fontTheme.sansFont,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: textLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildGoalInput(textColor, borderColor, cardBg),

                    const SizedBox(height: 24),

                    // Current Progress
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.theme.highlight.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.theme.highlight.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.info,
                            size: 20,
                            color: widget.theme.highlight,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _getCurrentProgressText(),
                              style: TextStyle(
                                fontFamily: widget.fontTheme.sansFont,
                                fontSize: 13,
                                color: textColor,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: borderColor.withValues(alpha: 0.5)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Hủy',
                        style: TextStyle(
                          fontFamily: widget.fontTheme.sansFont,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveGoal,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: widget.theme.textColor,
                        foregroundColor: widget.theme.cardBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Lưu mục tiêu',
                        style: TextStyle(
                          fontFamily: widget.fontTheme.sansFont,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildGoalTypeButton(
    String type,
    String title,
    String subtitle,
    IconData icon,
    Color textColor,
    Color borderColor,
  ) {
    final isSelected = _selectedGoalType == type;
    return InkWell(
      onTap: () => setState(() => _selectedGoalType = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? widget.theme.highlight.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? widget.theme.highlight
                : borderColor.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? widget.theme.highlight.withValues(alpha: 0.2)
                    : widget.theme.textColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? widget.theme.highlight
                    : widget.theme.textLight,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: widget.fontTheme.sansFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: widget.fontTheme.sansFont,
                      fontSize: 12,
                      color: widget.theme.textLight,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                LucideIcons.checkCircle2,
                size: 20,
                color: widget.theme.highlight,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalInput(Color textColor, Color borderColor, Color cardBg) {
    TextEditingController controller;
    String label;
    String hint;
    String suffix;

    switch (_selectedGoalType) {
      case 'daily':
        controller = _dailyMinutesController;
        label = 'Số phút mỗi ngày';
        hint = 'Ví dụ: 30';
        suffix = 'phút';
        break;
      case 'monthly_books':
        controller = _monthlyBooksController;
        label = 'Số cuốn sách';
        hint = 'Ví dụ: 5';
        suffix = 'cuốn';
        break;
      case 'monthly_hours':
        controller = _monthlyHoursController;
        label = 'Số giờ đọc';
        hint = 'Ví dụ: 20';
        suffix = 'giờ';
        break;
      case 'monthly_pages':
        controller = _monthlyPagesController;
        label = 'Số trang sách';
        hint = 'Ví dụ: 1000';
        suffix = 'trang';
        break;
      default:
        controller = _dailyMinutesController;
        label = 'Giá trị';
        hint = '';
        suffix = '';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: widget.fontTheme.sansFont,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(
            fontFamily: widget.fontTheme.sansFont,
            fontSize: 16,
            color: textColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: widget.fontTheme.sansFont,
              color: widget.theme.textLight.withValues(alpha: 0.5),
            ),
            suffixText: suffix,
            suffixStyle: TextStyle(
              fontFamily: widget.fontTheme.sansFont,
              fontSize: 14,
              color: widget.theme.textLight,
            ),
            filled: true,
            fillColor: widget.isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.02),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: widget.theme.highlight, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  String _getCurrentProgressText() {
    switch (_selectedGoalType) {
      case 'daily':
        return 'Hôm nay bạn đã đọc ${_statsService.todayReadingMinutes} phút. '
            'Mục tiêu hiện tại: ${_statsService.dailyGoalMinutes} phút/ngày.';
      case 'monthly_books':
        return 'Tháng này bạn đã đọc ${_statsService.monthlyBooksRead} cuốn. '
            'Mục tiêu hiện tại: ${_statsService.monthlyBookGoal} cuốn/tháng.';
      case 'monthly_hours':
        return 'Tháng này bạn đã đọc ${_statsService.monthlyReadingHours} giờ. '
            'Mục tiêu hiện tại: ${_statsService.monthlyHoursGoal} giờ/tháng.';
      case 'monthly_pages':
        return 'Tháng này bạn đã đọc ${_statsService.monthlyPagesRead} trang. '
            'Mục tiêu hiện tại: ${_statsService.monthlyPagesGoal} trang/tháng.';
      default:
        return '';
    }
  }
}
