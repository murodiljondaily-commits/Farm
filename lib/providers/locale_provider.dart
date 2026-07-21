import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const _prefKey = 'locale_lang_code';

  Locale _locale = const Locale('uz');
  Locale get locale => _locale;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey) ?? 'uz';
    _locale = _decode(code);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (locale == _locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _encode(locale));
  }

  // scriptCode (e.g. 'Cyrl') must be persisted too, or the app would always
  // reopen in Latin even after the farmer picked Cyrillic.
  String _encode(Locale l) =>
      l.scriptCode != null ? '${l.languageCode}_${l.scriptCode}' : l.languageCode;

  // Backward compatible: an existing stored 'uz'/'ru' (no scriptCode part)
  // still parses correctly as a plain Locale.
  Locale _decode(String s) {
    final parts = s.split('_');
    if (parts.length == 2) {
      return Locale.fromSubtags(languageCode: parts[0], scriptCode: parts[1]);
    }
    return Locale(parts[0]);
  }
}
