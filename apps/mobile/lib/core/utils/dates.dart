import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

const _istOffset = Duration(hours: 5, minutes: 30);

/// Load bundled EN/HI date symbols before formatting; no network is used.
Future<void> initializeDateFormatters() => initializeDateFormatting();

// This shifted value contains IST wall-clock fields for formatting only.
// It must never be stored or treated as an actual UTC instant.
DateTime _istFields(DateTime timestamp) => timestamp.toUtc().add(_istOffset);

/// Display an instant as an IST business date, independent of device timezone.
String formatIstDate(DateTime timestamp, {String locale = 'en'}) =>
    DateFormat.yMMMd(locale).format(_istFields(timestamp));

/// Display an instant as an IST date and 24-hour time.
String formatIstDateTime(DateTime timestamp, {String locale = 'en'}) =>
    DateFormat.yMMMd(locale).add_Hm().format(_istFields(timestamp));

/// Stable Gregorian business-date key for an instant (yyyy-MM-dd, IST).
String istDateKey(DateTime timestamp) =>
    DateFormat('yyyy-MM-dd', 'en').format(_istFields(timestamp));
