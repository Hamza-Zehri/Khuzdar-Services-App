import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'translations.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLocale = 'en';

  String get currentLocale => _currentLocale;
  bool get isUrdu => _currentLocale == 'ur';

  LanguageProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLocale = prefs.getString('locale') ?? 'en';
    notifyListeners();
  }

  Future<void> setLocale(String locale) async {
    if (!Translations.data.containsKey(locale)) return;
    _currentLocale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale);
    notifyListeners();
  }

  String translate(String key, {List<String>? args}) {
    String? text = Translations.data[_currentLocale]?[key] ?? Translations.data['en']?[key] ?? key;
    
    if (args != null && args.isNotEmpty) {
      for (var arg in args) {
        text = text!.replaceFirst('{}', arg);
      }
    }
    return text!;
  }
}

// Extension to make it easy to use in widgets: context.tr('welcome', args: ['Hamza'])
extension TranslationExtension on BuildContext {
  String tr(String key, {List<String>? args}) {
    return read<LanguageProvider>().translate(key, args: args);
  }

  bool get isUrdu => read<LanguageProvider>().isUrdu;
}
