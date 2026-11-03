// bikram.dart
// Bikram Sambat arithmetic and calendar calculations using Howard Hinnant's civil algorithm.

import 'calendar_data.dart';

class GregorianDate {
  final int year;
  final int month;
  final int day;

  const GregorianDate({required this.year, required this.month, required this.day});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GregorianDate &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month &&
          day == other.day;

  @override
  int get hashCode => year.hashCode ^ month.hashCode ^ day.hashCode;

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

class BikramDate {
  final int year;
  final int month;
  final int day;

  const BikramDate({required this.year, required this.month, required this.day});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BikramDate &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month &&
          day == other.day;

  @override
  int get hashCode => year.hashCode ^ month.hashCode ^ day.hashCode;

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

class BikramEngine {
  static const int monthsInYear = 12;
  static const int daysInWeek = 7;

  // Days since 1970-01-01, proleptic Gregorian. Howard Hinnant's civil algorithm.
  static int daysFromCivil(int year, int month, int day) {
    int y = year - (month <= 2 ? 1 : 0);
    int era = (y >= 0 ? y : y - 399) ~/ 400;
    int yearOfEra = y - era * 400;
    int dayOfYear = (153 * (month + (month > 2 ? -3 : 9)) + 2) ~/ 5 + day - 1;
    int dayOfEra = yearOfEra * 365 + yearOfEra ~/ 4 - yearOfEra ~/ 100 + dayOfYear;
    return era * 146097 + dayOfEra - 719468;
  }

  static GregorianDate civilFromDays(int days) {
    int z = days + 719468;
    int era = (z >= 0 ? z : z - 146096) ~/ 146097;
    int dayOfEra = z - era * 146097;
    int yearOfEra = (dayOfEra - dayOfEra ~/ 1460 + dayOfEra ~/ 36524 - dayOfEra ~/ 146096) ~/ 365;
    int dayOfYear = dayOfEra - (365 * yearOfEra + yearOfEra ~/ 4 - yearOfEra ~/ 100);
    int mp = (5 * dayOfYear + 2) ~/ 153;
    int day = dayOfYear - (153 * mp + 2) ~/ 5 + 1;
    int month = mp + (mp < 10 ? 3 : -9);
    int year = yearOfEra + era * 400 + (month <= 2 ? 1 : 0);
    return GregorianDate(year: year, month: month, day: day);
  }

  static late List<int> yearOffsets;
  static late int totalDays;
  static late int anchorDays;

  static void initialize() {
    List<int> offsets = [];
    int total = 0;
    for (int i = 0; i < CalendarData.monthLengths.length; i++) {
      offsets.add(total);
      for (int m = 0; m < monthsInYear; m++) {
        total += CalendarData.monthLengths[i][m];
      }
    }
    offsets.add(total);
    yearOffsets = offsets;
    totalDays = offsets.last;
    anchorDays = daysFromCivil(
      CalendarData.anchorAdYear,
      CalendarData.anchorAdMonth,
      CalendarData.anchorAdDay,
    );
  }

  static int firstYear() => CalendarData.firstYear;
  static int lastYear() => CalendarData.lastYear;

  static bool supportsYear(int year) {
    return year >= CalendarData.firstYear && year <= CalendarData.lastYear;
  }

  static String confidence(int year) {
    if (!supportsYear(year)) return "unsupported";
    if (year <= CalendarData.attestedThrough) return "attested";
    if (year <= CalendarData.publishedThrough) return "published";
    return "provisional";
  }

  static int monthLength(int year, int month) {
    if (!supportsYear(year) || month < 1 || month > monthsInYear) return 0;
    return CalendarData.monthLengths[year - CalendarData.firstYear][month - 1];
  }

  static bool isValid(int year, int month, int day) {
    return day >= 1 && day <= monthLength(year, month);
  }

  static int dayIndex(int year, int month, int day) {
    if (!isValid(year, month, day)) return -1;
    int index = yearOffsets[year - CalendarData.firstYear];
    for (int m = 1; m < month; m++) {
      index += monthLength(year, m);
    }
    return index + day - 1;
  }

  static BikramDate? fromDayIndex(int index) {
    if (index < 0 || index >= totalDays) return null;
    int year = CalendarData.firstYear;
    while (index >= yearOffsets[year - CalendarData.firstYear + 1]) {
      year++;
    }
    int remaining = index - yearOffsets[year - CalendarData.firstYear];
    int month = 1;
    while (remaining >= monthLength(year, month)) {
      remaining -= monthLength(year, month);
      month++;
    }
    return BikramDate(year: year, month: month, day: remaining + 1);
  }

  static GregorianDate? toGregorian(int year, int month, int day) {
    int index = dayIndex(year, month, day);
    return index < 0 ? null : civilFromDays(anchorDays + index);
  }

  static BikramDate? fromGregorian(int year, int month, int day) {
    return fromDayIndex(daysFromCivil(year, month, day) - anchorDays);
  }

  // 0 is Sunday, 6 is Saturday
  static int weekdayOf(int year, int month, int day) {
    int index = dayIndex(year, month, day);
    if (index < 0) return -1;
    return (((anchorDays + index + 4) % daysInWeek) + daysInWeek) % daysInWeek;
  }

  static BikramDate? today([DateTime? date]) {
    var now = date ?? DateTime.now();
    return fromGregorian(now.year, now.month, now.day);
  }

  static BikramDate addMonths(int year, int month, int delta) {
    int absolute = year * monthsInYear + (month - 1) + delta;
    int target = absolute ~/ monthsInYear;
    if (target < CalendarData.firstYear) {
      return BikramDate(year: CalendarData.firstYear, month: 1, day: 1);
    }
    if (target > CalendarData.lastYear) {
      return BikramDate(year: CalendarData.lastYear, month: monthsInYear, day: 1);
    }
    return BikramDate(year: target, month: absolute - target * monthsInYear + 1, day: 1);
  }

  static BikramDate? addDays(int year, int month, int day, int delta) {
    int index = dayIndex(year, month, day);
    return index < 0 ? null : fromDayIndex(index + delta);
  }

  static int clampDay(int year, int month, int day) {
    int maxDays = monthLength(year, month);
    if (day < 1) return 1;
    if (day > maxDays) return maxDays;
    return day;
  }

  static const String devanagariDigits = "०१२३४५६७८९";

  static Map<String, int>? parseParts(String text) {
    String latin = "";
    String raw = text.trim();
    for (int i = 0; i < raw.length; i++) {
      int idx = devanagariDigits.indexOf(raw[i]);
      latin += idx >= 0 ? idx.toString() : raw[i];
    }
    var pieces = latin.split(RegExp(r'[^0-9]+')).where((s) => s.isNotEmpty).toList();
    if (pieces.length != 3) return null;
    int? y = int.tryParse(pieces[0]);
    int? m = int.tryParse(pieces[1]);
    int? d = int.tryParse(pieces[2]);
    if (y == null || m == null || d == null) return null;
    return {'year': y, 'month': m, 'day': d};
  }

  static Map<String, dynamic> readBikramDate(String text) {
    var parts = parseParts(text);
    if (parts == null) return {'reason': 'writeBikram'};
    int y = parts['year']!;
    int m = parts['month']!;
    int d = parts['day']!;
    if (m < 1 || m > monthsInYear) return {'reason': 'notADate'};
    if (!supportsYear(y)) return {'reason': 'outOfRange'};
    if (!isValid(y, m, d)) return {'reason': 'noSuchDay', 'parts': parts};
    return {'date': BikramDate(year: y, month: m, day: d)};
  }

  static Map<String, dynamic> readGregorianDate(String text) {
    var parts = parseParts(text);
    if (parts == null) return {'reason': 'writeGregorian'};
    int y = parts['year']!;
    int m = parts['month']!;
    int d = parts['day']!;
    if (m < 1 || m > 12 || d < 1 || d > 31) return {'reason': 'notADate'};
    var converted = fromGregorian(y, m, d);
    if (converted == null) return {'reason': 'outOfRange'};
    var back = toGregorian(converted.year, converted.month, converted.day);
    if (back == null || back.year != y || back.month != m || back.day != d) {
      return {'reason': 'notADate'};
    }
    return {'date': converted};
  }

  static List<List<BikramDate?>> monthGrid(int year, int month, [int weekStart = 0]) {
    int length = monthLength(year, month);
    if (length == 0) return [];

    int lead = (weekdayOf(year, month, 1) - weekStart + daysInWeek) % daysInWeek;
    List<List<BikramDate?>> weeks = [];
    List<BikramDate?> week = [];

    for (int i = 0; i < lead; i++) {
      week.add(null);
    }
    for (int day = 1; day <= length; day++) {
      week.add(BikramDate(year: year, month: month, day: day));
      if (week.length == daysInWeek) {
        weeks.add(week);
        week = [];
      }
    }
    if (week.isNotEmpty) {
      while (week.length < daysInWeek) {
        week.add(null);
      }
      weeks.add(week);
    }
    return weeks;
  }
}
