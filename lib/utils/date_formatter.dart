import 'package:intl/intl.dart';

class DateFormatter {
  /// Safely parses any date representation (String ISO, timestamp int/double, DateTime)
  /// and converts it to the user's local timezone.
  static DateTime parseToLocal(dynamic input) {
    if (input == null) return DateTime.now();
    if (input is DateTime) return input.toLocal();
    if (input is int) {
      return DateTime.fromMillisecondsSinceEpoch(input).toLocal();
    }
    if (input is double) {
      return DateTime.fromMillisecondsSinceEpoch(input.toInt()).toLocal();
    }

    final str = input.toString().trim();
    if (str.isEmpty) return DateTime.now();

    // Check if integer string
    final asInt = int.tryParse(str);
    if (asInt != null) {
      return DateTime.fromMillisecondsSinceEpoch(asInt).toLocal();
    }

    final maxAllowedFuture = DateTime.now().add(const Duration(minutes: 5));

    // Try parsing ISO/local string directly first
    final directParsed = DateTime.tryParse(str);
    if (directParsed != null) {
      final localTime = directParsed.toLocal();
      if (localTime.isAfter(maxAllowedFuture)) {
        return DateTime.now();
      }
      return localTime;
    }

    // Format ISO string with space to 'T'
    String formattedStr = str.replaceAll(' ', 'T');
    final tParsed = DateTime.tryParse(formattedStr);
    if (tParsed != null) {
      final localTime = tParsed.toLocal();
      if (localTime.isAfter(maxAllowedFuture)) {
        return DateTime.now();
      }
      return localTime;
    }

    // If server ISO string doesn't specify timezone offset or Z, assume server time is UTC
    if (!formattedStr.endsWith('Z') &&
        !formattedStr.endsWith('z') &&
        !formattedStr.contains('+') &&
        !RegExp(r'-\d{2}:?\d{2}$').hasMatch(formattedStr)) {
      formattedStr = '${formattedStr}Z';
    }

    final parsed = DateTime.tryParse(formattedStr) ?? DateTime.now();
    final localTime = parsed.toLocal();
    if (localTime.isAfter(maxAllowedFuture)) {
      return DateTime.now();
    }
    return localTime;
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date.toLocal());
  }

  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date.toLocal());
  }

  static String formatFullDateTime(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date.toLocal());
  }
}
