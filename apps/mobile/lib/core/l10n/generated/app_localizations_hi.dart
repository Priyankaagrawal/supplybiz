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

  @override
  String get routeLoading => 'लोड हो रहा है';

  @override
  String get routeLanguage => 'अपनी भाषा चुनें';

  @override
  String get routeLogin => 'साइन इन करें';

  @override
  String get routeOtp => 'मोबाइल नंबर सत्यापित करें';

  @override
  String get routeRole => 'अपनी भूमिका चुनें';

  @override
  String get routeOnboarding => 'अपना व्यवसाय सेट अप करें';

  @override
  String get routeUpdate => 'अपडेट आवश्यक है';

  @override
  String get routeLegal => 'नियम और गोपनीयता';

  @override
  String get routeNotifications => 'सूचनाएँ';

  @override
  String get routeSettings => 'सेटिंग्स';

  @override
  String get routeSwitchRole => 'भूमिका बदलें';

  @override
  String get routeSwitchMessage =>
      'यह लिंक खोलने के लिए आवश्यक भूमिका में स्विच करें।';

  @override
  String get routeHomeAction => 'होम पर वापस जाएँ';

  @override
  String get routePlaceholder => 'यह स्क्रीन तैयार की जा रही है।';

  @override
  String get navHome => 'होम';

  @override
  String get navOrders => 'ऑर्डर';

  @override
  String get navProducts => 'उत्पाद';

  @override
  String get navCustomers => 'ग्राहक';

  @override
  String get navMore => 'अधिक';

  @override
  String get navKhata => 'Khata';

  @override
  String get navServices => 'सेवाएँ';

  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String get routeOrder => 'ऑर्डर विवरण';

  @override
  String get routeSubscription => 'सदस्यता विवरण';

  @override
  String get routeVendor => 'विक्रेता विवरण';

  @override
  String get routeLedger => 'विक्रेता Khata';
}
