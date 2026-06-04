import 'package:flutter/material.dart';
import '../constants/app_strings.dart';

class LanguageProvider extends ChangeNotifier {
  AppLanguage _currentLanguage = AppLanguage.arabic;

  AppLanguage get currentLanguage => _currentLanguage;

  void changeLanguage(AppLanguage newLang) {
    if (_currentLanguage != newLang) {
      _currentLanguage = newLang;
      notifyListeners();
    }
  }

  String t(String key) {
    return AppStrings.translations[_currentLanguage]?[key] ?? key;
  }
}