import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LanguageNotifier extends StateNotifier<Locale> {
  LanguageNotifier() : super(const Locale('vi'));

  void setLocale(Locale locale) {
    state = locale;
  }

  void toggleLanguage() {
    state = state.languageCode == 'vi'
        ? const Locale('en')
        : const Locale('vi');
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  return LanguageNotifier();
});
