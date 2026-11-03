// observances.dart
// Public holidays, observances, and moon markers in Nepal.

import 'bikram.dart';

enum ObservanceKind { holiday, observance, moon }

class ObservanceEntry {
  final int? month;
  final int? day;
  final int? from;
  final int? tithi;
  final ObservanceKind kind;
  final String nepali;
  final String english;

  const ObservanceEntry({
    this.month,
    this.day,
    this.from,
    this.tithi,
    required this.kind,
    required this.nepali,
    required this.english,
  });

  String name(String language) => language == "English" ? english : nepali;
}

class Observances {
  static const List<ObservanceEntry> fixedBikram = [
    ObservanceEntry(month: 1, day: 1, kind: ObservanceKind.holiday, nepali: "नयाँ वर्ष", english: "Nepali New Year"),
    ObservanceEntry(month: 1, day: 11, from: 2063, kind: ObservanceKind.holiday, nepali: "लोकतन्त्र दिवस", english: "Loktantra Diwas"),
    ObservanceEntry(month: 2, day: 15, from: 2065, kind: ObservanceKind.holiday, nepali: "गणतन्त्र दिवस", english: "Republic Day"),
    ObservanceEntry(month: 3, day: 29, kind: ObservanceKind.observance, nepali: "भानु जयन्ती", english: "Bhanu Jayanti"),
    ObservanceEntry(month: 4, day: 1, kind: ObservanceKind.observance, nepali: "साउने सङ्क्रान्ति", english: "Shrawan Sankranti"),
    ObservanceEntry(month: 4, day: 15, kind: ObservanceKind.observance, nepali: "खिर खाने दिन", english: "Khir Khane Din"),
    ObservanceEntry(month: 5, day: 22, kind: ObservanceKind.observance, nepali: "निजामती सेवा दिवस", english: "Civil Service Day"),
    ObservanceEntry(month: 6, day: 1, kind: ObservanceKind.observance, nepali: "विश्वकर्मा पूजा", english: "Vishwakarma Puja"),
    ObservanceEntry(month: 6, day: 3, from: 2072, kind: ObservanceKind.holiday, nepali: "संविधान दिवस", english: "Constitution Day"),
    ObservanceEntry(month: 9, day: 27, kind: ObservanceKind.holiday, nepali: "पृथ्वी जयन्ती", english: "Prithvi Jayanti"),
    ObservanceEntry(month: 10, day: 1, kind: ObservanceKind.holiday, nepali: "माघे सङ्क्रान्ति", english: "Maghe Sankranti"),
    ObservanceEntry(month: 10, day: 16, kind: ObservanceKind.holiday, nepali: "सहिद दिवस", english: "Martyrs' Day"),
    ObservanceEntry(month: 11, day: 7, from: 2007, kind: ObservanceKind.holiday, nepali: "प्रजातन्त्र दिवस", english: "Prajatantra Diwas"),
  ];

  static const List<ObservanceEntry> fixedGregorian = [
    ObservanceEntry(month: 1, day: 1, kind: ObservanceKind.observance, nepali: "अङ्ग्रेजी नयाँ वर्ष", english: "New Year's Day"),
    ObservanceEntry(month: 3, day: 8, kind: ObservanceKind.holiday, nepali: "अन्तर्राष्ट्रिय नारी दिवस", english: "International Women's Day"),
    ObservanceEntry(month: 5, day: 1, kind: ObservanceKind.holiday, nepali: "अन्तर्राष्ट्रिय श्रमिक दिवस", english: "Labour Day"),
    ObservanceEntry(month: 5, day: 8, kind: ObservanceKind.observance, nepali: "विश्व रेडक्रस दिवस", english: "World Red Cross Day"),
    ObservanceEntry(month: 12, day: 1, kind: ObservanceKind.observance, nepali: "विश्व एड्स दिवस", english: "World AIDS Day"),
    ObservanceEntry(month: 12, day: 10, kind: ObservanceKind.observance, nepali: "मानव अधिकार दिवस", english: "Human Rights Day"),
    ObservanceEntry(month: 12, day: 25, kind: ObservanceKind.holiday, nepali: "क्रिसमस", english: "Christmas"),
  ];

  static const List<ObservanceEntry> moonMarkers = [
    ObservanceEntry(tithi: 15, kind: ObservanceKind.moon, nepali: "पूर्णिमा", english: "Purnima"),
    ObservanceEntry(tithi: 30, kind: ObservanceKind.moon, nepali: "औंसी", english: "Aunsi"),
    ObservanceEntry(tithi: 11, kind: ObservanceKind.moon, nepali: "एकादशी", english: "Ekadashi"),
    ObservanceEntry(tithi: 26, kind: ObservanceKind.moon, nepali: "एकादशी", english: "Ekadashi"),
  ];

  static int _rank(ObservanceKind kind) {
    switch (kind) {
      case ObservanceKind.holiday:
        return 0;
      case ObservanceKind.observance:
        return 1;
      case ObservanceKind.moon:
        return 2;
    }
  }

  static List<ObservanceEntry> forDate(BikramDate? bikram, GregorianDate? gregorian, int tithi) {
    List<ObservanceEntry> found = [];

    if (bikram != null) {
      for (var bs in fixedBikram) {
        if (bs.month == bikram.month && bs.day == bikram.day) {
          if (bs.from == null || bikram.year >= bs.from!) {
            found.add(bs);
          }
        }
      }
    }

    if (gregorian != null) {
      for (var ad in fixedGregorian) {
        if (ad.month == gregorian.month && ad.day == gregorian.day) {
          found.add(ad);
        }
      }
    }

    for (var moon in moonMarkers) {
      if (moon.tithi == tithi) {
        found.add(moon);
      }
    }

    found.sort((a, b) => _rank(a.kind).compareTo(_rank(b.kind)));
    return found;
  }

  static bool isHoliday(List<ObservanceEntry> entries) {
    return entries.any((e) => e.kind == ObservanceKind.holiday);
  }

  static List<ObservanceEntry> named(List<ObservanceEntry> entries) {
    return entries.where((e) => e.kind != ObservanceKind.moon).toList();
  }

  static String summary(List<ObservanceEntry> entries, [String language = "Nepali"]) {
    return entries.map((e) => e.name(language)).join(" · ");
  }
}
