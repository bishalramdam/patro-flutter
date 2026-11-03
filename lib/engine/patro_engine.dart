// patro_engine.dart
// Unified calendar engine for Patro Mobile (Flutter).

import 'astro.dart';
import 'bikram.dart';
import 'calendar_data.dart';
import 'nepali.dart';
import 'observances.dart';

class TodayInfo {
  final BikramDate bs;
  final GregorianDate gregorian;
  final String dayText;
  final String monthName;
  final String yearText;
  final String cleanYearLabel;
  final String fullLabel;
  final String weekdayName;
  final String weekdayShort;
  final int weekday;
  final int tithi;
  final String tithiLabel;
  final bool isHoliday;
  final bool isSaturday;
  final String observances;

  const TodayInfo({
    required this.bs,
    required this.gregorian,
    required this.dayText,
    required this.monthName,
    required this.yearText,
    required this.cleanYearLabel,
    required this.fullLabel,
    required this.weekdayName,
    required this.weekdayShort,
    required this.weekday,
    required this.tithi,
    required this.tithiLabel,
    required this.isHoliday,
    required this.isSaturday,
    required this.observances,
  });
}

class DayCellModel {
  final int year;
  final int month;
  final int day;
  final int weekday;
  final String dayText;
  final String gregorianDayText;
  final GregorianDate gregorian;
  final int tithi;
  final String tithiLabel;
  final bool isToday;
  final bool isSaturday;
  final bool isHoliday;
  final String observanceSummary;

  const DayCellModel({
    required this.year,
    required this.month,
    required this.day,
    required this.weekday,
    required this.dayText,
    required this.gregorianDayText,
    required this.gregorian,
    required this.tithi,
    required this.tithiLabel,
    required this.isToday,
    required this.isSaturday,
    required this.isHoliday,
    required this.observanceSummary,
  });
}

class MonthViewModel {
  final int year;
  final int month;
  final String title;
  final String gregorianSpan;
  final String confidence;
  final String provisionalNotice;
  final List<List<DayCellModel?>> weeks;

  const MonthViewModel({
    required this.year,
    required this.month,
    required this.title,
    required this.gregorianSpan,
    required this.confidence,
    required this.provisionalNotice,
    required this.weeks,
  });
}

class ConversionResult {
  final bool valid;
  final BikramDate? bs;
  final GregorianDate? gregorian;
  final String? bsFormatted;
  final String? gregFormatted;
  final String? weekdayName;
  final String? tithiLabel;
  final String? observance;
  final String? error;

  const ConversionResult({
    required this.valid,
    this.bs,
    this.gregorian,
    this.bsFormatted,
    this.gregFormatted,
    this.weekdayName,
    this.tithiLabel,
    this.observance,
    this.error,
  });
}

class PatroEngine {
  static final PatroEngine instance = PatroEngine._internal();

  String language = "Nepali";
  String numerals = "Devanagari";
  int weekStart = 0; // 0 = Sunday

  factory PatroEngine() {
    return instance;
  }

  PatroEngine._internal() {
    BikramEngine.initialize();
  }

  TodayInfo getToday([DateTime? customDate]) {
    var now = customDate ?? DateTime.now();
    var bs = BikramEngine.fromGregorian(now.year, now.month, now.day) ??
        BikramDate(year: 2083, month: 7, day: 17);
    var greg = GregorianDate(year: now.year, month: now.month, day: now.day);
    int wd = BikramEngine.weekdayOf(bs.year, bs.month, bs.day);
    int tithi = Astro.tithiForDate(greg.year, greg.month, greg.day);
    String paksha = Astro.pakshaOf(tithi);

    var obsList = Observances.forDate(bs, greg, tithi);
    bool holiday = Observances.isHoliday(obsList);
    String obsSummary = Observances.summary(Observances.named(obsList), language);

    String dayDev = Nepali.numerals(bs.day, numerals);
    String monthDev = Nepali.monthName(bs.month, language);
    String yearDev = Nepali.numerals(bs.year, numerals);
    String cleanYearLabel = "$dayDev $monthDev $yearDev";
    String fullLabel = Nepali.formatDate(
      bs,
      language: language,
      numeralsStyle: numerals,
      format: "Full",
      showWeekday: true,
      weekday: wd,
    );

    return TodayInfo(
      bs: bs,
      gregorian: greg,
      dayText: dayDev,
      monthName: monthDev,
      yearText: yearDev,
      cleanYearLabel: cleanYearLabel,
      fullLabel: fullLabel,
      weekdayName: Nepali.weekdayName(wd, language),
      weekdayShort: Nepali.weekdayShort(wd, language),
      weekday: wd,
      tithi: tithi,
      tithiLabel: Nepali.tithiLabel(tithi, paksha, language),
      isHoliday: holiday,
      isSaturday: wd == 6,
      observances: obsSummary,
    );
  }

  MonthViewModel getMonthData(int year, int month) {
    var rawWeeks = BikramEngine.monthGrid(year, month, weekStart);
    var today = getToday();

    GregorianDate? firstGreg = BikramEngine.toGregorian(year, month, 1);
    int length = BikramEngine.monthLength(year, month);
    GregorianDate? lastGreg = BikramEngine.toGregorian(year, month, length);

    List<List<DayCellModel?>> weeks = [];
    for (var week in rawWeeks) {
      List<DayCellModel?> row = [];
      for (var day in week) {
        if (day == null) {
          row.add(null);
        } else {
          var greg = BikramEngine.toGregorian(day.year, day.month, day.day) ??
              const GregorianDate(year: 2026, month: 1, day: 1);
          int wd = BikramEngine.weekdayOf(day.year, day.month, day.day);
          int tithi = Astro.tithiForDate(greg.year, greg.month, greg.day);
          String paksha = Astro.pakshaOf(tithi);
          var obs = Observances.forDate(day, greg, tithi);

          bool isToday = (today.bs.year == day.year &&
              today.bs.month == day.month &&
              today.bs.day == day.day);

          row.add(DayCellModel(
            year: day.year,
            month: day.month,
            day: day.day,
            weekday: wd,
            dayText: Nepali.numerals(day.day, numerals),
            gregorianDayText: greg.day.toString(),
            gregorian: greg,
            tithi: tithi,
            tithiLabel: Nepali.tithiLabel(tithi, paksha, language),
            isToday: isToday,
            isSaturday: wd == 6,
            isHoliday: Observances.isHoliday(obs),
            observanceSummary: Observances.summary(Observances.named(obs), language),
          ));
        }
      }
      weeks.add(row);
    }

    String conf = BikramEngine.confidence(year);
    String notice = conf == "provisional"
        ? Nepali.provisionalNotice(year, language: language, numeralsStyle: numerals)
        : "";

    return MonthViewModel(
      year: year,
      month: month,
      title: Nepali.monthTitle(year, month, language: language, numeralsStyle: numerals),
      gregorianSpan: Nepali.gregorianSpan(firstGreg, lastGreg),
      confidence: conf,
      provisionalNotice: notice,
      weeks: weeks,
    );
  }

  ConversionResult convertDate(String text, {bool? isBsInput}) {
    var raw = text.trim();
    if (raw.isEmpty) {
      return const ConversionResult(valid: false, error: "कृपया मिति प्रविष्ट गर्नुहोस्");
    }

    // If direction is explicitly AD to BS, or if isBsInput is null and year <= 2035
    if (isBsInput == false) {
      return _convertFromGregorian(raw);
    } else if (isBsInput == true) {
      return _convertFromBikram(raw);
    }

    // Auto detection
    var parts = BikramEngine.parseParts(raw);
    if (parts != null && parts['year']! <= 2035 && parts['year']! >= 1943) {
      // Very likely a Gregorian date (1943 to 2035 AD)
      var adRes = _convertFromGregorian(raw);
      if (adRes.valid) return adRes;
    }

    var bsRes = _convertFromBikram(raw);
    if (bsRes.valid) return bsRes;

    return _convertFromGregorian(raw);
  }

  ConversionResult _convertFromBikram(String raw) {
    var bsParsed = BikramEngine.readBikramDate(raw);
    if (bsParsed['date'] != null) {
      BikramDate bs = bsParsed['date'];
      var greg = BikramEngine.toGregorian(bs.year, bs.month, bs.day);
      if (greg == null) {
        return const ConversionResult(valid: false, error: "मिति दायरा भन्दा बाहिर छ");
      }
      int wd = BikramEngine.weekdayOf(bs.year, bs.month, bs.day);
      int tithi = Astro.tithiForDate(greg.year, greg.month, greg.day);
      String paksha = Astro.pakshaOf(tithi);
      var obs = Observances.forDate(bs, greg, tithi);

      return ConversionResult(
        valid: true,
        bs: bs,
        gregorian: greg,
        bsFormatted: "${bs.year}-${bs.month.toString().padLeft(2, '0')}-${bs.day.toString().padLeft(2, '0')}",
        gregFormatted: "${greg.year}-${greg.month.toString().padLeft(2, '0')}-${greg.day.toString().padLeft(2, '0')}",
        weekdayName: Nepali.weekdayName(wd, language),
        tithiLabel: Nepali.tithiLabel(tithi, paksha, language),
        observance: Observances.summary(Observances.named(obs), language),
      );
    }
    String reason = (bsParsed['reason'] ?? "notADate").toString();
    return _buildErrorResult(reason);
  }

  ConversionResult _convertFromGregorian(String raw) {
    var gregParsed = BikramEngine.readGregorianDate(raw);
    if (gregParsed['date'] != null) {
      BikramDate bs = gregParsed['date'];
      var greg = BikramEngine.toGregorian(bs.year, bs.month, bs.day)!;
      int wd = BikramEngine.weekdayOf(bs.year, bs.month, bs.day);
      int tithi = Astro.tithiForDate(greg.year, greg.month, greg.day);
      String paksha = Astro.pakshaOf(tithi);
      var obs = Observances.forDate(bs, greg, tithi);

      return ConversionResult(
        valid: true,
        bs: bs,
        gregorian: greg,
        bsFormatted: "${bs.year}-${bs.month.toString().padLeft(2, '0')}-${bs.day.toString().padLeft(2, '0')}",
        gregFormatted: "${greg.year}-${greg.month.toString().padLeft(2, '0')}-${greg.day.toString().padLeft(2, '0')}",
        weekdayName: Nepali.weekdayName(wd, language),
        tithiLabel: Nepali.tithiLabel(tithi, paksha, language),
        observance: Observances.summary(Observances.named(obs), language),
      );
    }
    String reason = (gregParsed['reason'] ?? "notADate").toString();
    return _buildErrorResult(reason);
  }

  ConversionResult _buildErrorResult(String reason) {
    String err = Nepali.message(reason, language);
    if (reason == "outOfRange") {
      err = err
          .replaceAll("%1", CalendarData.firstYear.toString())
          .replaceAll("%2", CalendarData.lastYear.toString())
          .replaceAll("%3", "1943")
          .replaceAll("%4", "2034");
    }
    return ConversionResult(valid: false, error: err.isNotEmpty ? err : "अवैध मिति");
  }
}
