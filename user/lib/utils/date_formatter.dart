import 'package:intl/intl.dart';

class DateFormatter {
  /// Safely parses any date representation (String ISO, timestamp int/double, DateTime)
  /// and converts it to the user's local timezone.
  static DateTime? parseToLocal(dynamic input) {
    if (input == null) return null;
    if (input is DateTime) return input.toLocal();
    if (input is int) {
      final ms = input < 10000000000 ? input * 1000 : input;
      final dt = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
      if (dt.year < 2020) return null;
      return dt;
    }
    if (input is double) {
      final intVal = input.toInt();
      final ms = intVal < 10000000000 ? intVal * 1000 : intVal;
      final dt = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
      if (dt.year < 2020) return null;
      return dt;
    }

    final str = input.toString().trim();
    if (str.isEmpty || str == 'null') return null;

    // Check if integer string
    final asInt = int.tryParse(str);
    if (asInt != null) {
      final ms = asInt < 10000000000 ? asInt * 1000 : asInt;
      final dt = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
      if (dt.year < 2020) return null;
      return dt;
    }

    final maxAllowedFuture = DateTime.now().add(const Duration(minutes: 5));

    // Try parsing ISO/local string directly first
    final directParsed = DateTime.tryParse(str);
    if (directParsed != null) {
      final localTime = directParsed.toLocal();
      if (localTime.isAfter(maxAllowedFuture) || localTime.year < 2020) {
        return null;
      }
      return localTime;
    }

    // Format ISO string with space to 'T'
    String formattedStr = str.replaceAll(' ', 'T');
    final tParsed = DateTime.tryParse(formattedStr);
    if (tParsed != null) {
      final localTime = tParsed.toLocal();
      if (localTime.isAfter(maxAllowedFuture) || localTime.year < 2020) {
        return null;
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

    final parsed = DateTime.tryParse(formattedStr);
    if (parsed != null) {
      final localTime = parsed.toLocal();
      if (localTime.isAfter(maxAllowedFuture) || localTime.year < 2020) {
        return null;
      }
      return localTime;
    }

    return null;
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

  static String formatLastSeen(DateTime date) {
    final now = DateTime.now();
    final local = date.toLocal();
    final timeStr = DateFormat('hh:mm a').format(local);

    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(local.year, local.month, local.day);

    if (checkDate == today) {
      return 'last seen today at $timeStr';
    } else if (checkDate == yesterday) {
      return 'last seen yesterday at $timeStr';
    } else {
      final dateStr = DateFormat('dd MMM').format(local);
      return 'last seen $dateStr at $timeStr';
    }
  }
}
