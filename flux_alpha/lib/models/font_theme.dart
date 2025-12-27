class FontThemeModel {
  final String id;
  final String name;
  final String serifFont;
  final String sansFont;
  final String monoFont;
  final String description;

  const FontThemeModel({
    required this.id,
    required this.name,
    required this.serifFont,
    required this.sansFont,
    required this.monoFont,
    required this.description,
  });
}

class AppFonts {
  // --- MẶC ĐỊNH ---
  static const String defaultSerif = 'Playfair Display';
  static const String defaultSans = 'Inter';

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

  // --- MONOSPACE ---
  static const String monoFont = 'JetBrains Mono';
}

// Font Themes Configuration (Ported from React)
class FontThemes {
  static const FontThemeModel defaultTheme = FontThemeModel(
    id: 'default',
    name: 'Mặc định',
    serifFont: AppFonts.defaultSerif,
    sansFont: AppFonts.defaultSans,
    monoFont: AppFonts.monoFont,
    description: 'Sang trọng & Hiện đại',
  );

  static const FontThemeModel contemporary = FontThemeModel(
    id: 'contemporary',
    name: 'Đương đại',
    serifFont: AppFonts.contemporarySerif,
    sansFont: AppFonts.contemporarySans,
    monoFont: AppFonts.monoFont,
    description: 'Báo chí & Sắc sảo',
  );

  static const FontThemeModel vintage = FontThemeModel(
    id: 'vintage',
    name: 'Cổ điển',
    serifFont: AppFonts.vintageSerif,
    sansFont: AppFonts.vintageSans,
    monoFont: AppFonts.monoFont,
    description: 'Thơ mộng & Hoài cổ',
  );

  static const FontThemeModel academic = FontThemeModel(
    id: 'academic',
    name: 'Học thuật',
    serifFont: AppFonts.academicSerif,
    sansFont: AppFonts.academicSans,
    monoFont: AppFonts.monoFont,
    description: 'Nghiêm túc & Dễ đọc',
  );

  static const FontThemeModel bold = FontThemeModel(
    id: 'bold',
    name: 'Tạp chí',
    serifFont: AppFonts.boldSerif,
    sansFont: AppFonts.boldSans,
    monoFont: AppFonts.monoFont,
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
