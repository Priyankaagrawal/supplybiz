// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'Supply Biz';

  @override
  String get developmentEnvironment => 'डेवलपमेंट परिवेश';

  @override
  String get stagingEnvironment => 'स्टेजिंग परिवेश';

  @override
  String get productionEnvironment => 'प्रोडक्शन परिवेश';

  @override
  String get startupError => 'कुछ गलत हुआ। कृपया फिर कोशिश करें।';
}
