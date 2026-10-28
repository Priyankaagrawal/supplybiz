import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Package-owned ARB strings; applications supply feature-specific labels.
class SbLocalizations {
  SbLocalizations(this._messages);
  final Map<String, dynamic> _messages;
  String text(String key) => _messages[key] as String;
  static SbLocalizations of(BuildContext context) =>
      Localizations.of<SbLocalizations>(context, SbLocalizations)!;
  static const supportedLocales = [Locale('en'), Locale('hi')];
  static const delegates = <LocalizationsDelegate<dynamic>>[
    _SbDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
}

class _SbDelegate extends LocalizationsDelegate<SbLocalizations> {
  const _SbDelegate();
  static final _cache = <String, SbLocalizations>{};
  @override
  bool isSupported(Locale locale) => ['en', 'hi'].contains(locale.languageCode);
  @override
  Future<SbLocalizations> load(Locale locale) {
    final cached = _cache[locale.languageCode];
    return cached == null ? _load(locale) : SynchronousFuture(cached);
  }

  Future<SbLocalizations> _load(Locale locale) async {
    final source = await rootBundle.loadString(
      'packages/ui_kit/lib/l10n/ui_${locale.languageCode}.arb',
    );
    final result = SbLocalizations(jsonDecode(source) as Map<String, dynamic>);
    _cache[locale.languageCode] = result;
    return result;
  }

  @override
  bool shouldReload(_SbDelegate old) => false;
}
