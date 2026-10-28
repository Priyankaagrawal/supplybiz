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

  @override
  String get networkUnavailable =>
      'अपना इंटरनेट कनेक्शन जाँचें और फिर कोशिश करें।';

  @override
  String get networkTimeout =>
      'अनुरोध का समय समाप्त हो गया। कृपया फिर कोशिश करें।';

  @override
  String get networkUnauthorized => 'जारी रखने के लिए कृपया फिर साइन इन करें।';

  @override
  String get networkForbidden => 'आपको यह कार्रवाई करने की अनुमति नहीं है।';

  @override
  String get networkPlanLocked => 'इस सुविधा के लिए अपना प्लान अपग्रेड करें।';

  @override
  String get networkNotFound => 'यह आइटम अब उपलब्ध नहीं है।';

  @override
  String get networkConflict =>
      'यह आइटम बदल गया है। रीफ़्रेश करके फिर कोशिश करें।';

  @override
  String get networkVersionConflict =>
      'एक नया संस्करण उपलब्ध है। रीफ़्रेश करके फिर कोशिश करें।';

  @override
  String get networkValidation => 'भरी गई जानकारी जाँचें और फिर कोशिश करें।';

  @override
  String get networkBusinessRule =>
      'यह कार्रवाई पूरी नहीं हो सकी। जानकारी जाँचें और फिर कोशिश करें।';

  @override
  String get networkRateLimited =>
      'बहुत अधिक अनुरोध हुए हैं। कृपया रुककर फिर कोशिश करें।';

  @override
  String get networkServer =>
      'सेवा अभी उपलब्ध नहीं है। कृपया कुछ देर बाद फिर कोशिश करें।';
}
