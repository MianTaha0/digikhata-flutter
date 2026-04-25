import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends Notifier<Locale> {
  static const _key = 'app_locale';
  static const supported = <Locale>[
    Locale('en'),
    Locale('ur'),
    Locale('hi'),
  ];

  @override
  Locale build() {
    // Start with English; async-load persisted choice.
    _load();
    return const Locale('en');
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null &&
        supported.any((l) => l.languageCode == code) &&
        code != state.languageCode) {
      state = Locale(code);
    }
  }

  Future<void> set(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }
}

final localeProvider =
    NotifierProvider<LocaleController, Locale>(LocaleController.new);
