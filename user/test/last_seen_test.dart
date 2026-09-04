import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

DateTime? parseToLocal(dynamic input) {
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

  final asInt = int.tryParse(str);
  if (asInt != null) {
    final ms = asInt < 10000000000 ? asInt * 1000 : asInt;
    final dt = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    if (dt.year < 2020) return null;
    return dt;
  }

  final maxAllowedFuture = DateTime.now().add(const Duration(minutes: 5));

  final directParsed = DateTime.tryParse(str);
  if (directParsed != null) {
    final localTime = directParsed.toLocal();
    if (localTime.isAfter(maxAllowedFuture) || localTime.year < 2020) {
      return null;
    }
    return localTime;
  }

  String formattedStr = str.replaceAll(' ', 'T');
  final tParsed = DateTime.tryParse(formattedStr);
  if (tParsed != null) {
    final localTime = tParsed.toLocal();
    if (localTime.isAfter(maxAllowedFuture) || localTime.year < 2020) {
      return null;
    }
    return localTime;
  }

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

String formatLastSeen(DateTime date) {
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

void main() {
  test('Unix seconds timestamp converts to correct local last seen string', () {
    final secondsTimestamp = 1772619000;
    final parsed = parseToLocal(secondsTimestamp);
    expect(parsed, isNotNull);
    final output = formatLastSeen(parsed!);
    print('Unix Seconds Output: $output');
    expect(output, contains('last seen'));
  });

  test('ISO UTC string parses into correct local time', () {
    final iso = "2026-09-04T07:15:00Z";
    final parsed = parseToLocal(iso);
    expect(parsed, isNotNull);
    final output = formatLastSeen(parsed!);
    print('ISO UTC Output: $output');
    expect(output, contains('last seen today at'));
  });

  test('Null input returns null (prevents fake current time)', () {
    final parsed = parseToLocal(null);
    expect(parsed, isNull);
  });
}
