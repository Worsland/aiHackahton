import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language.dart';

class AppLanguageController extends ChangeNotifier {
  AppLanguageController._();

  static final AppLanguageController instance = AppLanguageController._();
  static const _preferenceKey = 'app_language';

  AppLanguage _language = AppLanguage.english;
  AppLanguage get language => _language;

  Future<void> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = preferences.getString(_preferenceKey);
      _language = switch (saved) {
        'yoruba' => AppLanguage.yoruba,
        _ => AppLanguage.english,
      };
    } catch (error) {
      debugPrint('Could not load saved language preference: $error');
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) return;
    _language = language;
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_preferenceKey, language.name);
    } catch (error) {
      debugPrint('Could not persist language preference: $error');
    }
  }
}
