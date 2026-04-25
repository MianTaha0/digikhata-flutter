import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'locale_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    final current = ref.watch(localeProvider);
    final ctl = ref.read(localeProvider.notifier);

    String label(String code) {
      switch (code) {
        case 'ur':
          return t.languageUrdu;
        case 'hi':
          return t.languageHindi;
        default:
          return t.languageEnglish;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.settingsTitle)),
      body: ListView(
        children: [
          ListTile(
            title: Text(t.language,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          ...LocaleController.supported.map((l) => RadioListTile<String>(
                value: l.languageCode,
                groupValue: current.languageCode,
                title: Text(label(l.languageCode)),
                onChanged: (v) {
                  if (v != null) ctl.set(Locale(v));
                },
              )),
        ],
      ),
    );
  }
}
