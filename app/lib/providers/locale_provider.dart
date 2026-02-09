import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_provider.dart';

/// 支援的語言列表
const supportedLocales = [
  Locale('zh', 'TW'), // 繁體中文（預設）
  Locale('en'),        // English
  Locale('zh', 'CN'),  // 簡體中文
];

/// SharedPreferences key
const _kLocaleKey = 'app_locale';

/// 語言設定 Provider
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

/// 語言設定 Notifier
class LocaleNotifier extends StateNotifier<Locale?> {
  final SharedPreferences _prefs;

  LocaleNotifier(this._prefs) : super(null) {
    _loadSavedLocale();
  }

  void _loadSavedLocale() {
    final saved = _prefs.getString(_kLocaleKey);
    if (saved != null) {
      state = _parseLocale(saved);
    }
    // null = 跟隨系統語言
  }

  /// 切換語言
  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _prefs.setString(_kLocaleKey, _localeToString(locale));
  }

  /// 重設為跟隨系統
  Future<void> resetToSystem() async {
    state = null;
    await _prefs.remove(_kLocaleKey);
  }

  /// 取得當前語言的顯示名稱
  static String getDisplayName(Locale locale) {
    if (locale.countryCode == 'TW') return '繁體中文';
    if (locale.countryCode == 'CN') return '简体中文';
    if (locale.languageCode == 'en') return 'English';
    return locale.toString();
  }

  static Locale? _parseLocale(String s) {
    final parts = s.split('_');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    } else if (parts.length == 1) {
      return Locale(parts[0]);
    }
    return null;
  }

  static String _localeToString(Locale locale) {
    if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
      return '${locale.languageCode}_${locale.countryCode}';
    }
    return locale.languageCode;
  }
}
