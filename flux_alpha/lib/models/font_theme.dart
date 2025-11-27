class FontThemeModel {
  final String id;
  final String name;
  final String serifFont;
  final String sansFont;
  final String description;

  const FontThemeModel({
    required this.id,
    required this.name,
    required this.serifFont,
    required this.sansFont,
    required this.description,
  });
}

class AppFonts {
  // --- MẶC ĐỊNH ---
  static const String defaultSerif = 'Playfair Display';
  static const String defaultSans = 'Manrope';

  // --- ĐƯƠNG ĐẠI ---
  static const String contemporarySerif = 'Lora';
  static const String contemporarySans = 'Inter';

  // --- CỔ ĐIỂN ---
  static const String vintageSerif = 'Cormorant Garamond';
  static const String vintageSans = 'Proza Libre';

  // --- HỌC THUẬT ---
  static const String academicSerif = 'Merriweather';
  static const String academicSans = 'Mulish';

  // --- TẠP CHÍ ---
  static const String boldSerif = 'Bitter';
  static const String boldSans = 'Work Sans';
}

// Font Themes Configuration (Ported from React)
class FontThemes {
  static const FontThemeModel defaultTheme = FontThemeModel(
    id: 'default',
    name: 'Mặc định',
    serifFont: AppFonts.defaultSerif,
    sansFont: AppFonts.defaultSans,
    description: 'Sang trọng & Hiện đại',
  );

  static const FontThemeModel contemporary = FontThemeModel(
    id: 'contemporary',
    name: 'Đương đại',
    serifFont: AppFonts.contemporarySerif,
    sansFont: AppFonts.contemporarySans,
    description: 'Báo chí & Sắc sảo',
  );

  static const FontThemeModel vintage = FontThemeModel(
    id: 'vintage',
    name: 'Cổ điển',
    serifFont: AppFonts.vintageSerif,
    sansFont: AppFonts.vintageSans,
    description: 'Thơ mộng & Hoài cổ',
  );

  static const FontThemeModel academic = FontThemeModel(
    id: 'academic',
    name: 'Học thuật',
    serifFont: AppFonts.academicSerif,
    sansFont: AppFonts.academicSans,
    description: 'Nghiêm túc & Dễ đọc',
  );

  static const FontThemeModel bold = FontThemeModel(
    id: 'bold',
    name: 'Tạp chí',
    serifFont: AppFonts.boldSerif,
    sansFont: AppFonts.boldSans,
    description: 'Mạnh mẽ & Ấn tượng',
  );

  static const Map<String, FontThemeModel> all = {
    'default': defaultTheme,
    'contemporary': contemporary,
    'vintage': vintage,
    'academic': academic,
    'bold': bold,
  };
}
