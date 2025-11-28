import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReadingStatsService extends ChangeNotifier {
  static final ReadingStatsService _instance = ReadingStatsService._internal();
  factory ReadingStatsService() => _instance;
  ReadingStatsService._internal();

  SharedPreferences? _prefs;
  Timer? _readingTimer;
  Timer? _saveTimer;
  bool _isReading = false;
  bool _hasUnsavedChanges = false;
  static const Duration _saveDebounceDelay = Duration(seconds: 5);

  // Stats data
  int _todayReadingSeconds = 0;
  int _totalReadingSeconds = 0;
  int _booksRead = 0;
  int _currentStreak = 0;
  int _totalPages = 0;
  int _dailyGoalMinutes = 60;
  
  // Weekly data (seconds per day, index 0 = Monday)
  List<int> _weeklyReadingSeconds = [0, 0, 0, 0, 0, 0, 0];
  
  // Monthly goals
  int _monthlyBookGoal = 10;
  int _monthlyHoursGoal = 50;
  int _monthlyPagesGoal = 4000;
  int _monthlyBooksRead = 0;
  int _monthlyReadingSeconds = 0;
  int _monthlyPagesRead = 0;
  
  // Last reading date for streak calculation
  String _lastReadingDate = '';

  // Getters
  int get todayReadingMinutes => _todayReadingSeconds ~/ 60;
  int get todayReadingSeconds => _todayReadingSeconds;
  int get totalReadingHours => _totalReadingSeconds ~/ 3600;
  double get totalReadingHoursDecimal => _totalReadingSeconds / 3600;
  int get booksRead => _booksRead;
  int get currentStreak => _currentStreak;
  int get totalPages => _totalPages;
  int get dailyGoalMinutes => _dailyGoalMinutes;
  double get dailyProgress => _dailyGoalMinutes > 0 
      ? (_todayReadingSeconds / 60) / _dailyGoalMinutes 
      : 0;
  bool get isReading => _isReading;
  
  List<int> get weeklyReadingMinutes => 
      _weeklyReadingSeconds.map((s) => s ~/ 60).toList();
  
  int get weeklyTotalMinutes => 
      _weeklyReadingSeconds.fold(0, (sum, s) => sum + s) ~/ 60;
  
  // Monthly getters
  int get monthlyBookGoal => _monthlyBookGoal;
  int get monthlyHoursGoal => _monthlyHoursGoal;
  int get monthlyPagesGoal => _monthlyPagesGoal;
  int get monthlyBooksRead => _monthlyBooksRead;
  int get monthlyReadingHours => _monthlyReadingSeconds ~/ 3600;
  int get monthlyPagesRead => _monthlyPagesRead;
  double get monthlyBookProgress => _monthlyBookGoal > 0 
      ? _monthlyBooksRead / _monthlyBookGoal 
      : 0;
  double get monthlyHoursProgress => _monthlyHoursGoal > 0 
      ? (_monthlyReadingSeconds / 3600) / _monthlyHoursGoal 
      : 0;
  double get monthlyPagesProgress => _monthlyPagesGoal > 0 
      ? _monthlyPagesRead / _monthlyPagesGoal 
      : 0;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadStats();
    _checkDayChange();
  }

  Future<void> _loadStats() async {
    if (_prefs == null) return;

    _todayReadingSeconds = _prefs!.getInt('today_reading_seconds') ?? 0;
    _totalReadingSeconds = _prefs!.getInt('total_reading_seconds') ?? 0;
    _booksRead = _prefs!.getInt('books_read') ?? 0;
    _currentStreak = _prefs!.getInt('current_streak') ?? 0;
    _totalPages = _prefs!.getInt('total_pages') ?? 0;
    _dailyGoalMinutes = _prefs!.getInt('daily_goal_minutes') ?? 60;
    _lastReadingDate = _prefs!.getString('last_reading_date') ?? '';
    
    // Weekly data
    final weeklyJson = _prefs!.getString('weekly_reading_seconds');
    if (weeklyJson != null) {
      _weeklyReadingSeconds = List<int>.from(jsonDecode(weeklyJson));
    }
    
    // Monthly data
    _monthlyBookGoal = _prefs!.getInt('monthly_book_goal') ?? 10;
    _monthlyHoursGoal = _prefs!.getInt('monthly_hours_goal') ?? 50;
    _monthlyPagesGoal = _prefs!.getInt('monthly_pages_goal') ?? 4000;
    _monthlyBooksRead = _prefs!.getInt('monthly_books_read') ?? 0;
    _monthlyReadingSeconds = _prefs!.getInt('monthly_reading_seconds') ?? 0;
    _monthlyPagesRead = _prefs!.getInt('monthly_pages_read') ?? 0;
    
    notifyListeners();
  }

  // Debounced save - batches multiple rapid changes
  void _saveStats() {
    _hasUnsavedChanges = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDebounceDelay, () async {
      if (!_hasUnsavedChanges) return;
      await _saveStatsImmediate();
    });
  }

  // Immediate save (for critical operations)
  Future<void> _saveStatsImmediate() async {
    if (_prefs == null || !_hasUnsavedChanges) return;
    _hasUnsavedChanges = false;

    await _prefs!.setInt('today_reading_seconds', _todayReadingSeconds);
    await _prefs!.setInt('total_reading_seconds', _totalReadingSeconds);
    await _prefs!.setInt('books_read', _booksRead);
    await _prefs!.setInt('current_streak', _currentStreak);
    await _prefs!.setInt('total_pages', _totalPages);
    await _prefs!.setInt('daily_goal_minutes', _dailyGoalMinutes);
    await _prefs!.setString('last_reading_date', _lastReadingDate);
    await _prefs!.setString('weekly_reading_seconds', jsonEncode(_weeklyReadingSeconds));
    
    // Monthly data
    await _prefs!.setInt('monthly_book_goal', _monthlyBookGoal);
    await _prefs!.setInt('monthly_hours_goal', _monthlyHoursGoal);
    await _prefs!.setInt('monthly_pages_goal', _monthlyPagesGoal);
    await _prefs!.setInt('monthly_books_read', _monthlyBooksRead);
    await _prefs!.setInt('monthly_reading_seconds', _monthlyReadingSeconds);
    await _prefs!.setInt('monthly_pages_read', _monthlyPagesRead);
  }

  void _checkDayChange() {
    final today = _getTodayString();
    final savedDate = _prefs?.getString('today_date') ?? '';
    
    if (savedDate != today) {
      // New day - reset today's reading
      _todayReadingSeconds = 0;
      _prefs?.setString('today_date', today);
      
      // Update streak
      if (_lastReadingDate.isNotEmpty) {
        final lastDate = DateTime.tryParse(_lastReadingDate);
        if (lastDate != null) {
          final yesterday = DateTime.now().subtract(const Duration(days: 1));
          if (lastDate.year != yesterday.year || 
              lastDate.month != yesterday.month || 
              lastDate.day != yesterday.day) {
            // Streak broken if last reading wasn't yesterday
            if (!(lastDate.year == DateTime.now().year && 
                  lastDate.month == DateTime.now().month && 
                  lastDate.day == DateTime.now().day)) {
              _currentStreak = 0;
            }
          }
        }
      }
      
      // Check for new month
      final savedMonth = _prefs?.getInt('current_month') ?? 0;
      final currentMonth = DateTime.now().month;
      if (savedMonth != currentMonth) {
        _monthlyBooksRead = 0;
        _monthlyReadingSeconds = 0;
        _monthlyPagesRead = 0;
        _prefs?.setInt('current_month', currentMonth);
      }
      
      // Shift weekly data
      _shiftWeeklyData();
      
      _saveStats();
      notifyListeners();
    }
  }
  
  void _shiftWeeklyData() {
    // Get current day of week (1 = Monday, 7 = Sunday)
    final today = DateTime.now().weekday - 1; // 0-indexed
    
    // Reset today's slot
    _weeklyReadingSeconds[today] = 0;
  }

  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // Start reading session
  void startReading() {
    if (_isReading) return;
    
    _isReading = true;
    
    // Start timer to update every second
    _readingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _todayReadingSeconds++;
      _totalReadingSeconds++;
      _monthlyReadingSeconds++;
      
      // Update weekly data
      final todayIndex = DateTime.now().weekday - 1;
      _weeklyReadingSeconds[todayIndex]++;
      
      // Save is debounced - will auto-save after 5 seconds of inactivity
      _saveStats();
      
      notifyListeners();
    });
    
    notifyListeners();
  }

  // Stop reading session
  void stopReading() {
    if (!_isReading) return;
    
    _isReading = false;
    _readingTimer?.cancel();
    _readingTimer = null;
    
    // Update last reading date for streak
    final today = _getTodayString();
    if (_lastReadingDate != today && _todayReadingSeconds > 60) {
      // At least 1 minute of reading to count for streak
      if (_lastReadingDate.isNotEmpty) {
        final lastDate = DateTime.tryParse(_lastReadingDate);
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        if (lastDate != null && 
            lastDate.year == yesterday.year && 
            lastDate.month == yesterday.month && 
            lastDate.day == yesterday.day) {
          _currentStreak++;
        } else if (_lastReadingDate != today) {
          _currentStreak = 1;
        }
      } else {
        _currentStreak = 1;
      }
      _lastReadingDate = today;
    }
    
    _saveStats();
    notifyListeners();
  }

  // Add pages read
  void addPagesRead(int pages) {
    _totalPages += pages;
    _monthlyPagesRead += pages;
    _saveStats();
    notifyListeners();
  }

  // Mark book as completed
  void completeBook() {
    _booksRead++;
    _monthlyBooksRead++;
    _saveStats();
    notifyListeners();
  }

  // Set daily goal
  void setDailyGoal(int minutes) {
    _dailyGoalMinutes = minutes;
    _saveStats();
    notifyListeners();
  }

  // Set monthly goals
  void setMonthlyGoals({int? books, int? hours, int? pages}) {
    if (books != null) _monthlyBookGoal = books;
    if (hours != null) _monthlyHoursGoal = hours;
    if (pages != null) _monthlyPagesGoal = pages;
    _saveStats();
    notifyListeners();
  }

  // Get formatted time string
  String getFormattedTodayTime() {
    final hours = _todayReadingSeconds ~/ 3600;
    final minutes = (_todayReadingSeconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '$minutes';
  }
  
  String getFormattedTotalTime() {
    final hours = _totalReadingSeconds ~/ 3600;
    final decimal = ((_totalReadingSeconds % 3600) / 3600 * 10).round();
    return '$hours.${decimal}h';
  }
  
  String getFormattedMonthlyTime() {
    final hours = _monthlyReadingSeconds ~/ 3600;
    return '$hours/${_monthlyHoursGoal}h';
  }
  
  String getFormattedPages() {
    if (_totalPages >= 1000) {
      return '${(_totalPages / 1000).toStringAsFixed(1)}k';
    }
    return _totalPages.toString();
  }
  
  String getFormattedMonthlyPages() {
    String formatNumber(int n) {
      if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
      return n.toString();
    }
    return '${formatNumber(_monthlyPagesRead)}/${formatNumber(_monthlyPagesGoal)}';
  }
  
  int getRemainingMinutesToGoal() {
    final remaining = _dailyGoalMinutes - todayReadingMinutes;
    return remaining > 0 ? remaining : 0;
  }

  @override
  void dispose() {
    _readingTimer?.cancel();
    _saveTimer?.cancel();
    // Force final save before disposal
    if (_hasUnsavedChanges) {
      _saveStatsImmediate();
    }
    super.dispose();
  }
}

