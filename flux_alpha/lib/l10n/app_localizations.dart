import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('vi'),
    Locale('en'),
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'vi': {
      'greeting': 'CHÀO BUỔI SÁNG',
      'greeting_morning': 'CHÀO BUỔI SÁNG',
      'greeting_afternoon': 'CHÀO BUỔI CHIỀU',
      'greeting_evening': 'CHÀO BUỔI TỐI',
      'books_are_dreams': 'Sách là giấc mơ\nbạn cầm trên tay.',
      'continue_reading_msg':
          'Bạn đang phiêu lưu dở ở chương 5 của "Harry Potter". Hãy đọc tiếp ngay!',
      'continue_reading_btn': 'Tiếp tục đọc',
      'progress': 'TIẾN ĐỘ',
      'last_read': 'Lần cuối đọc: 2 giờ trước\nChương 12: Tấm gương ảo ảnh',
      'recently_read': 'Gần đây',
      'continue_journey': 'Tiếp tục hành trình đọc của bạn',
      'explore_more': 'Khám phá thêm',
      'open_library': 'Mở thư viện',
      'reading_schedule': 'Lịch đọc',
      'todays_goal': 'Mục tiêu hôm nay',
      'goal_msg': 'Bạn còn 15 phút để đạt mục tiêu 30 phút đọc sách mỗi ngày.',
      'notes_highlight': 'Ghi chú & Highlight',
      'library': 'Thư viện',
      'developing': 'Đang phát triển',
      'stats': 'Thống kê',
      'reading_habit': 'Thói quen đọc của bạn trong tháng này',
      'books_read': 'Sách đã đọc',
      'reading_hours': 'Giờ đọc',
      'streak': 'Chuỗi ngày',
      'pages': 'Trang sách',
      'activity_week': 'Hoạt động tuần qua',
      'this_week': 'Tuần này',
      'achievements': 'Thành tựu',
      'bookworm': 'Mọt sách chính hiệu',
      'read_7_days': 'Đọc liên tục trong 7 ngày',
      'saved': 'Đã lưu',
      'home': 'Trang chủ',
      'notifications': 'Thông báo',
      'settings': 'Cài đặt',
      'dark_mode': 'CHẾ ĐỘ TỐI',
      'enable_dark_mode': 'Bật chế độ tối',
      'auto_schedule': 'Tự động theo lịch',
      'turn_on_at': 'BẬT LÚC',
      'turn_off_at': 'TẮT LÚC',
      'appearance': 'GIAO DIỆN & HIỂN THỊ',
      'main_color': 'Màu chủ đạo',
      'font_style': 'Kiểu chữ',
      'account': 'TÀI KHOẢN',
      'profile': 'Hồ sơ cá nhân',
      'security': 'Bảo mật',
      'help': 'Trợ giúp & Hỗ trợ',
      'logout': 'Đăng xuất',
      'language': 'NGÔN NGỮ',
      'vietnamese': 'Tiếng Việt',
      'english': 'English',
      'theme_forest': 'Rừng Già',
      'theme_charcoal': 'Than Chì',
      'theme_espresso': 'Cà Phê',
      'theme_ink': 'Mực In',
      'font_default': 'Mặc định',
      'font_contemporary': 'Đương đại',
      'font_vintage': 'Cổ điển',
      'font_academic': 'Học thuật',
      'font_bold': 'Tạp chí',
      'desc_font_default': 'Sang trọng & Hiện đại',
      'desc_font_contemporary': 'Báo chí & Sắc sảo',
      'desc_font_vintage': 'Thơ mộng & Hoài cổ',
      'desc_font_academic': 'Nghiêm túc & Dễ đọc',
      'desc_font_bold': 'Mạnh mẽ & Ấn tượng',
      'today': 'Hôm nay',
      'minutes': 'phút',
      'days': 'ngày',
      'add_goal': 'Thêm mục tiêu',
      // Common actions / Reader screen
      'common_close': 'Đóng',
      'common_cancel': 'Hủy',
      'common_save': 'Lưu',
      'common_edit': 'Sửa',
      'common_delete': 'Xóa',
      'reader_switching_chapter': 'Đang chuyển sang Chương {chapter}',
      'reader_chapter_label': 'Chương {chapter}',
      'reader_bookmark_added': 'Đã đánh dấu trang này',
      'reader_bookmark_removed': 'Đã bỏ đánh dấu',
      'reader_book_completed_title': 'Chúc mừng!',
      'reader_book_completed_message':
          'Bạn đã đọc xong "{title}"!\\n\\nĐánh dấu sách này là đã đọc xong?',
      'reader_book_completed_later': 'Để sau',
      'reader_mark_finished': 'Đánh dấu đọc xong',
      'reader_book_completed_toast': '📚 Đã thêm vào danh sách sách đã đọc!',
      'reader_no_book_content': 'Không tìm thấy nội dung trong sách này',
      'reader_default_chapter_title': 'Khởi đầu',
      'reader_table_of_contents': 'Mục lục',
      'reader_search_title': 'Tìm kiếm',
      'reader_search_hint': 'Nhập từ khóa...',
      'reader_search_dev_message': 'Tính năng tìm kiếm đang được phát triển',
      'reader_search_action': 'Tìm',
      'reader_highlight': 'Tô màu',
      'reader_note': 'Ghi chú',
      'reader_copy': 'Sao chép',
      'reader_select_all': 'Chọn tất cả',
      'reader_chapter_heading': 'CHƯƠNG {chapter}',
      'reader_no_chapter_content': 'Không tìm thấy nội dung trong chương này.',
      'reader_next_chapter': 'Chương tiếp theo',
      'reader_previous_chapter': 'Chương trước',
      'reader_back_tooltip': 'Quay lại',
      'reader_reading_now': 'ĐANG ĐỌC',
      'reader_search_tooltip': 'Tìm kiếm',
      'reader_bookmark_add_tooltip': 'Đánh dấu trang',
      'reader_bookmark_remove_tooltip': 'Bỏ đánh dấu',
      'reader_chapter_progress': 'CHƯƠNG {current}/{total}',
      'reader_reading_estimate': 'Còn khoảng 5 phút đọc',
      'reader_copy_success': 'Đã sao chép vào clipboard',
      'reader_highlight_success': 'Đã tô màu văn bản',
      'reader_select_text_prompt': 'Vui lòng chọn văn bản trước',
      'reader_add_note_title': 'Thêm ghi chú',
      'reader_selected_text_label': 'Văn bản đã chọn:',
      'reader_note_placeholder': 'Nhập ghi chú của bạn...',
      'reader_note_saved': 'Đã lưu ghi chú',
      'reader_note_view_title': 'Ghi chú',
      'reader_note_time_just_now': 'Vừa xong',
      'reader_note_time_minutes_ago': '{minutes} phút trước',
      'reader_note_time_hours_ago': '{hours} giờ trước',
      'reader_note_time_days_ago': '{days} ngày trước',
      'reader_note_time_date_format': '{day}/{month}/{year}',
      'reader_edit_note_title': 'Chỉnh sửa ghi chú',
      'reader_note_edit_placeholder': 'Nhập ghi chú...',
      'reader_delete_note_title': 'Xóa ghi chú?',
      'reader_delete_note_message': 'Bạn có chắc muốn xóa ghi chú này không?',
    },
    'en': {
      'greeting': 'GOOD MORNING',
      'greeting_morning': 'GOOD MORNING',
      'greeting_afternoon': 'GOOD AFTERNOON',
      'greeting_evening': 'GOOD EVENING',
      'books_are_dreams': 'Books are dreams\nyou hold in your hands.',
      'continue_reading_msg':
          'You are adventuring in chapter 5 of "Harry Potter". Don\'t let the Dementors catch up, read on now!',
      'continue_reading_btn': 'Continue Reading',
      'progress': 'PROGRESS',
      'last_read': 'Last read: 2 hours ago\nChapter 12: The Mirror of Erised',
      'recently_read': 'Recently Read',
      'continue_journey': 'Continue your reading journey',
      'explore_more': 'Explore More',
      'open_library': 'Open Library',
      'reading_schedule': 'Reading Schedule',
      'todays_goal': 'Today\'s Goal',
      'goal_msg':
          'You have 15 minutes left to reach your 30-minute daily reading goal.',
      'notes_highlight': 'Notes & Highlights',
      'library': 'Library',
      'developing': 'Under Development',
      'stats': 'Statistics',
      'reading_habit': 'Your reading habits this month',
      'books_read': 'Books Read',
      'reading_hours': 'Reading Hours',
      'streak': 'Streak',
      'pages': 'Pages',
      'activity_week': 'Activity This Week',
      'this_week': 'This Week',
      'achievements': 'Achievements',
      'bookworm': 'True Bookworm',
      'read_7_days': 'Read continuously for 7 days',
      'saved': 'Saved',
      'home': 'Home',
      'notifications': 'Notifications',
      'settings': 'Settings',
      'dark_mode': 'DARK MODE',
      'enable_dark_mode': 'Enable Dark Mode',
      'auto_schedule': 'Auto Schedule',
      'turn_on_at': 'TURN ON AT',
      'turn_off_at': 'TURN OFF AT',
      'appearance': 'APPEARANCE & DISPLAY',
      'main_color': 'Main Color',
      'font_style': 'Font Style',
      'account': 'ACCOUNT',
      'profile': 'Profile',
      'security': 'Security',
      'help': 'Help & Support',
      'logout': 'Logout',
      'language': 'LANGUAGE',
      'vietnamese': 'Tiếng Việt',
      'english': 'English',
      'theme_forest': 'Forest',
      'theme_charcoal': 'Charcoal',
      'theme_espresso': 'Espresso',
      'theme_ink': 'Ink',
      'font_default': 'Default',
      'font_contemporary': 'Contemporary',
      'font_vintage': 'Vintage',
      'font_academic': 'Academic',
      'font_bold': 'Magazine',
      'desc_font_default': 'Elegant & Modern',
      'desc_font_contemporary': 'Journalistic & Sharp',
      'desc_font_vintage': 'Poetic & Nostalgic',
      'desc_font_academic': 'Serious & Readable',
      'desc_font_bold': 'Strong & Impressive',
      'today': 'Today',
      'minutes': 'min',
      'days': 'days',
      'add_goal': 'Add Goal',
      // Reader screen / Common actions
      'common_close': 'Close',
      'common_cancel': 'Cancel',
      'common_save': 'Save',
      'common_edit': 'Edit',
      'common_delete': 'Delete',
      'reader_switching_chapter': 'Switching to Chapter {chapter}',
      'reader_chapter_label': 'Chapter {chapter}',
      'reader_bookmark_added': 'Bookmark added',
      'reader_bookmark_removed': 'Bookmark removed',
      'reader_book_completed_title': 'Congratulations!',
      'reader_book_completed_message':
          'You finished "{title}"!\\n\\nMark this book as completed?',
      'reader_book_completed_later': 'Later',
      'reader_mark_finished': 'Mark as finished',
      'reader_book_completed_toast': '📚 Added to completed books!',
      'reader_no_book_content': 'No content found in this book',
      'reader_default_chapter_title': 'Beginning',
      'reader_table_of_contents': 'Table of Contents',
      'reader_search_title': 'Search',
      'reader_search_hint': 'Enter a keyword...',
      'reader_search_dev_message': 'Search feature is under development',
      'reader_search_action': 'Search',
      'reader_highlight': 'Highlight',
      'reader_note': 'Note',
      'reader_copy': 'Copy',
      'reader_select_all': 'Select all',
      'reader_chapter_heading': 'CHAPTER {chapter}',
      'reader_no_chapter_content': 'No content found in this chapter.',
      'reader_next_chapter': 'Next chapter',
      'reader_previous_chapter': 'Previous chapter',
      'reader_back_tooltip': 'Back',
      'reader_reading_now': 'READING',
      'reader_search_tooltip': 'Search',
      'reader_bookmark_add_tooltip': 'Add bookmark',
      'reader_bookmark_remove_tooltip': 'Remove bookmark',
      'reader_chapter_progress': 'CHAPTER {current}/{total}',
      'reader_reading_estimate': 'About 5 minutes left',
      'reader_copy_success': 'Copied to clipboard',
      'reader_highlight_success': 'Highlight added',
      'reader_select_text_prompt': 'Please select text first',
      'reader_add_note_title': 'Add note',
      'reader_selected_text_label': 'Selected text:',
      'reader_note_placeholder': 'Enter your note...',
      'reader_note_saved': 'Note saved',
      'reader_note_view_title': 'Note',
      'reader_note_time_just_now': 'Just now',
      'reader_note_time_minutes_ago': '{minutes} minutes ago',
      'reader_note_time_hours_ago': '{hours} hours ago',
      'reader_note_time_days_ago': '{days} days ago',
      'reader_note_time_date_format': '{month}/{day}/{year}',
      'reader_edit_note_title': 'Edit note',
      'reader_note_edit_placeholder': 'Enter your note...',
      'reader_delete_note_title': 'Delete note?',
      'reader_delete_note_message':
          'Are you sure you want to delete this note?',
    },
  };

  String get greeting => _getGreetingFor(DateTime.now());
  String get books_are_dreams =>
      _localizedValues[locale.languageCode]!['books_are_dreams']!;
  String get continue_reading_msg =>
      _localizedValues[locale.languageCode]!['continue_reading_msg']!;
  String get continue_reading_btn =>
      _localizedValues[locale.languageCode]!['continue_reading_btn']!;
  String get progress => _localizedValues[locale.languageCode]!['progress']!;
  String get last_read => _localizedValues[locale.languageCode]!['last_read']!;
  String get recently_read =>
      _localizedValues[locale.languageCode]!['recently_read']!;
  String get continue_journey =>
      _localizedValues[locale.languageCode]!['continue_journey']!;
  String get explore_more =>
      _localizedValues[locale.languageCode]!['explore_more']!;
  String get open_library =>
      _localizedValues[locale.languageCode]!['open_library']!;
  String get reading_schedule =>
      _localizedValues[locale.languageCode]!['reading_schedule']!;
  String get todays_goal =>
      _localizedValues[locale.languageCode]!['todays_goal']!;
  String get goal_msg => _localizedValues[locale.languageCode]!['goal_msg']!;
  String get notes_highlight =>
      _localizedValues[locale.languageCode]!['notes_highlight']!;
  String get library => _localizedValues[locale.languageCode]!['library']!;
  String get developing =>
      _localizedValues[locale.languageCode]!['developing']!;
  String get stats => _localizedValues[locale.languageCode]!['stats']!;
  String get reading_habit =>
      _localizedValues[locale.languageCode]!['reading_habit']!;
  String get books_read =>
      _localizedValues[locale.languageCode]!['books_read']!;
  String get reading_hours =>
      _localizedValues[locale.languageCode]!['reading_hours']!;
  String get streak => _localizedValues[locale.languageCode]!['streak']!;
  String get pages => _localizedValues[locale.languageCode]!['pages']!;
  String get activity_week =>
      _localizedValues[locale.languageCode]!['activity_week']!;
  String get this_week => _localizedValues[locale.languageCode]!['this_week']!;
  String get achievements =>
      _localizedValues[locale.languageCode]!['achievements']!;
  String get bookworm => _localizedValues[locale.languageCode]!['bookworm']!;
  String get read_7_days =>
      _localizedValues[locale.languageCode]!['read_7_days']!;
  String get saved => _localizedValues[locale.languageCode]!['saved']!;
  String get home => _localizedValues[locale.languageCode]!['home']!;
  String get notifications =>
      _localizedValues[locale.languageCode]!['notifications']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get dark_mode => _localizedValues[locale.languageCode]!['dark_mode']!;
  String get enable_dark_mode =>
      _localizedValues[locale.languageCode]!['enable_dark_mode']!;
  String get auto_schedule =>
      _localizedValues[locale.languageCode]!['auto_schedule']!;
  String get turn_on_at =>
      _localizedValues[locale.languageCode]!['turn_on_at']!;
  String get turn_off_at =>
      _localizedValues[locale.languageCode]!['turn_off_at']!;
  String get appearance =>
      _localizedValues[locale.languageCode]!['appearance']!;
  String get main_color =>
      _localizedValues[locale.languageCode]!['main_color']!;
  String get font_style =>
      _localizedValues[locale.languageCode]!['font_style']!;
  String get account => _localizedValues[locale.languageCode]!['account']!;
  String get profile => _localizedValues[locale.languageCode]!['profile']!;
  String get security => _localizedValues[locale.languageCode]!['security']!;
  String get help => _localizedValues[locale.languageCode]!['help']!;
  String get logout => _localizedValues[locale.languageCode]!['logout']!;
  String get language => _localizedValues[locale.languageCode]!['language']!;
  String get vietnamese =>
      _localizedValues[locale.languageCode]!['vietnamese']!;
  String get english => _localizedValues[locale.languageCode]!['english']!;
  String get theme_forest =>
      _localizedValues[locale.languageCode]!['theme_forest']!;
  String get theme_charcoal =>
      _localizedValues[locale.languageCode]!['theme_charcoal']!;
  String get theme_espresso =>
      _localizedValues[locale.languageCode]!['theme_espresso']!;
  String get theme_ink => _localizedValues[locale.languageCode]!['theme_ink']!;
  String get font_default =>
      _localizedValues[locale.languageCode]!['font_default']!;
  String get font_contemporary =>
      _localizedValues[locale.languageCode]!['font_contemporary']!;
  String get font_vintage =>
      _localizedValues[locale.languageCode]!['font_vintage']!;
  String get font_academic =>
      _localizedValues[locale.languageCode]!['font_academic']!;
  String get font_bold => _localizedValues[locale.languageCode]!['font_bold']!;
  String get desc_font_default =>
      _localizedValues[locale.languageCode]!['desc_font_default']!;
  String get desc_font_contemporary =>
      _localizedValues[locale.languageCode]!['desc_font_contemporary']!;
  String get desc_font_vintage =>
      _localizedValues[locale.languageCode]!['desc_font_vintage']!;
  String get desc_font_academic =>
      _localizedValues[locale.languageCode]!['desc_font_academic']!;
  String get desc_font_bold =>
      _localizedValues[locale.languageCode]!['desc_font_bold']!;
  String get today => _localizedValues[locale.languageCode]!['today']!;
  String get minutes => _localizedValues[locale.languageCode]!['minutes']!;
  String get days => _localizedValues[locale.languageCode]!['days']!;
  String get add_goal => _localizedValues[locale.languageCode]!['add_goal']!;

  // Reader screen getters
  String get commonClose => _value('common_close');
  String get commonCancel => _value('common_cancel');
  String get commonSave => _value('common_save');
  String get commonEdit => _value('common_edit');
  String get commonDelete => _value('common_delete');
  String get readerBookmarkAdded => _value('reader_bookmark_added');
  String get readerBookmarkRemoved => _value('reader_bookmark_removed');
  String get readerBookCompletedTitle => _value('reader_book_completed_title');
  String get readerBookCompletedLater => _value('reader_book_completed_later');
  String get readerBookCompletedToast => _value('reader_book_completed_toast');
  String get readerMarkFinished => _value('reader_mark_finished');
  String get readerTableOfContents => _value('reader_table_of_contents');
  String get readerSearchTitle => _value('reader_search_title');
  String get readerSearchHint => _value('reader_search_hint');
  String get readerSearchDevMessage => _value('reader_search_dev_message');
  String get readerSearchAction => _value('reader_search_action');
  String get readerNoBookContent => _value('reader_no_book_content');
  String get readerDefaultChapterTitle =>
      _value('reader_default_chapter_title');
  String get readerHighlight => _value('reader_highlight');
  String get readerNote => _value('reader_note');
  String get readerCopy => _value('reader_copy');
  String get readerSelectAll => _value('reader_select_all');
  String get readerNoChapterContent => _value('reader_no_chapter_content');
  String get readerNextChapter => _value('reader_next_chapter');
  String get readerPreviousChapter => _value('reader_previous_chapter');
  String get readerBackTooltip => _value('reader_back_tooltip');
  String get readerReadingNow => _value('reader_reading_now');
  String get readerSearchTooltip => _value('reader_search_tooltip');
  String get readerBookmarkAddTooltip => _value('reader_bookmark_add_tooltip');
  String get readerBookmarkRemoveTooltip =>
      _value('reader_bookmark_remove_tooltip');
  String get readerReadingEstimate => _value('reader_reading_estimate');
  String get readerCopySuccess => _value('reader_copy_success');
  String get readerHighlightSuccess => _value('reader_highlight_success');
  String get readerSelectTextPrompt => _value('reader_select_text_prompt');
  String get readerAddNoteTitle => _value('reader_add_note_title');
  String get readerSelectedTextLabel => _value('reader_selected_text_label');
  String get readerNotePlaceholder => _value('reader_note_placeholder');
  String get readerNoteSaved => _value('reader_note_saved');
  String get readerNoteViewTitle => _value('reader_note_view_title');
  String get readerEditNoteTitle => _value('reader_edit_note_title');
  String get readerNoteEditPlaceholder =>
      _value('reader_note_edit_placeholder');
  String get readerDeleteNoteTitle => _value('reader_delete_note_title');
  String get readerDeleteNoteMessage => _value('reader_delete_note_message');
  String get readerNoteTimeJustNow => _value('reader_note_time_just_now');

  // Dynamic reader methods
  String readerChapterLabel(int chapter) =>
      _format('reader_chapter_label', {'chapter': '$chapter'});
  String readerSwitchingChapter(int chapter) =>
      _format('reader_switching_chapter', {'chapter': '$chapter'});
  String readerChapterHeading(int chapter) =>
      _format('reader_chapter_heading', {'chapter': '$chapter'});
  String readerChapterProgress(int current, int total) => _format(
    'reader_chapter_progress',
    {'current': '$current', 'total': '$total'},
  );
  String readerBookCompletedMessage(String title) =>
      _format('reader_book_completed_message', {'title': title});
  String readerNoteTimeMinutesAgo(int minutes) =>
      _format('reader_note_time_minutes_ago', {'minutes': '$minutes'});
  String readerNoteTimeHoursAgo(int hours) =>
      _format('reader_note_time_hours_ago', {'hours': '$hours'});
  String readerNoteTimeDaysAgo(int days) =>
      _format('reader_note_time_days_ago', {'days': '$days'});
  String get readerNoteTimeDateFormat => _value('reader_note_time_date_format');

  Map<String, String> get _activeTranslations =>
      _localizedValues[locale.languageCode] ?? _localizedValues['en']!;

  String _value(String key) {
    final translations = _activeTranslations;
    return translations[key] ?? _localizedValues['en']![key]!;
  }

  String _format(String key, Map<String, String> params) {
    var template = _value(key);
    params.forEach((placeholder, value) {
      template = template.replaceAll('{$placeholder}', value);
    });
    return template;
  }

  String _getGreetingFor(DateTime moment) {
    final hour = moment.hour;
    String key;
    if (hour < 12) {
      key = 'greeting_morning';
    } else if (hour < 18) {
      key = 'greeting_afternoon';
    } else {
      key = 'greeting_evening';
    }

    final languageMap = _activeTranslations;
    return languageMap[key] ?? languageMap['greeting']!;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'vi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return Future.value(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
