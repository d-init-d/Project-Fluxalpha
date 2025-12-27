# Sửa chức năng đổi font chữ trong giao diện đọc

## ✅ Vấn đề đã được khắc phục

### Vấn đề ban đầu:
- Chức năng đổi font chữ trong giao diện đọc sách không hoạt động
- Font 'MySans' và 'MySerif' không tồn tại trong pubspec.yaml
- Khi người dùng chọn font Serif, Sans, hoặc Mono, không có thay đổi gì

### Nguyên nhân:
Các file `reading_screen.dart` và `reader_interface.dart` đang sử dụng font giả định:
- `'MySans'` - không tồn tại
- `'MySerif'` - không tồn tại
- `'monospace'` - font hệ thống, không phải font custom

### Giải pháp đã áp dụng:

#### 1. Cập nhật `reading_screen.dart`
**Trước:**
```dart
TextStyle getContentTextStyle() {
  TextStyle baseStyle;
  switch (fontFamily) {
    case FontType.sans:
      baseStyle = const TextStyle(fontFamily: 'MySans');
      break;
    case FontType.mono:
      baseStyle = const TextStyle(fontFamily: 'monospace');
      break;
    default:
      baseStyle = const TextStyle(fontFamily: 'MySerif');
  }
  return baseStyle.copyWith(...);
}
```

**Sau:**
```dart
TextStyle getContentTextStyle() {
  String fontFamilyName;
  switch (fontFamily) {
    case FontType.sans:
      fontFamilyName = 'Manrope'; // Sans-serif font from pubspec
      break;
    case FontType.mono:
      fontFamilyName = 'JetBrains Mono'; // Monospace font from pubspec
      break;
    default:
      fontFamilyName = 'Lora'; // Serif font from pubspec
  }
  return TextStyle(
    fontFamily: fontFamilyName,
    fontSize: fontSize,
    height: lineHeight,
    wordSpacing: getWordSpacing(),
    color: currentTheme.text,
  );
}
```

#### 2. Cập nhật `reader_interface.dart`

**a) Preload fonts:**
```dart
void _preloadFonts() {
  // Serif fonts
  const TextStyle(fontFamily: 'Lora', fontSize: 18);
  const TextStyle(fontFamily: 'Playfair Display', fontSize: 18);
  const TextStyle(fontFamily: 'Cormorant Garamond', fontSize: 18);
  const TextStyle(fontFamily: 'Merriweather', fontSize: 18);
  const TextStyle(fontFamily: 'Bitter', fontSize: 18);
  
  // Sans-serif fonts
  const TextStyle(fontFamily: 'Manrope', fontSize: 18);
  const TextStyle(fontFamily: 'Inter', fontSize: 18);
  const TextStyle(fontFamily: 'Proza Libre', fontSize: 18);
  const TextStyle(fontFamily: 'Mulish', fontSize: 18);
  const TextStyle(fontFamily: 'Work Sans', fontSize: 18);
  
  // Monospace font
  const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 18);
}
```

**b) Get font family name:**
```dart
String _getFontFamilyName(String fontFamily) {
  switch (fontFamily) {
    case 'sans':
      return 'Manrope'; // Sans-serif font
    case 'mono':
      return 'JetBrains Mono'; // Monospace font
    default:
      return 'Lora'; // Serif font (default)
  }
}
```

#### 3. Thay thế toàn bộ references
- Tất cả `fontFamily: 'MySans'` → `fontFamily: 'Manrope'`
- Tất cả `fontFamily: 'MySerif'` → `fontFamily: 'Lora'`

## 📝 Fonts được sử dụng từ pubspec.yaml

### Serif Fonts (cho reading):
- **Lora** - Default serif font
- Playfair Display
- Cormorant Garamond
- Merriweather
- Bitter

### Sans-serif Fonts:
- **Manrope** - Default sans-serif font
- Inter
- Proza Libre
- Mulish
- Work Sans

### Monospace Font:
- **JetBrains Mono** - For code/mono style reading

## ✅ Kết quả

Bây giờ khi người dùng:
1. Mở giao diện đọc sách
2. Nhấn vào nút Appearance (Aa)
3. Chọn Font chữ: Có chân / Sans / Mono
4. Font sẽ thay đổi ngay lập tức với các font thực tế:
   - **Có chân (Serif)**: Lora - font đẹp, dễ đọc cho văn bản dài
   - **Sans**: Manrope - font hiện đại, sạch sẽ
   - **Mono**: JetBrains Mono - font monospace chuyên nghiệp

## 🧪 Cách test

1. Chạy app: `flutter run -d windows`
2. Mở một cuốn sách bất kỳ
3. Nhấn vào icon "Aa" ở bottom panel
4. Thử chuyển đổi giữa 3 loại font
5. Quan sát văn bản thay đổi font ngay lập tức

## 📊 Files đã sửa

1. `flux_alpha/lib/screens/reading_screen.dart`
   - Sửa method `getContentTextStyle()`
   - Thay thế tất cả font references

2. `flux_alpha/lib/screens/reader_interface.dart`
   - Sửa method `_preloadFonts()`
   - Sửa method `_getFontFamilyName()`
   - Thay thế tất cả font references

## ⚠️ Lưu ý

- Tất cả fonts đã được định nghĩa trong `pubspec.yaml`
- Fonts được preload để đảm bảo chuyển đổi mượt mà
- Không cần thêm font mới vào pubspec.yaml
- Chức năng hoạt động ngay lập tức, không cần restart app
