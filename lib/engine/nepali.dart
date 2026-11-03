// nepali.dart
// Names, numerals and localized label formatting for Bikram Sambat.

import 'bikram.dart';
import 'calendar_data.dart';

class Nepali {
  static const List<String> devanagariDigits = ["०", "१", "२", "३", "४", "५", "६", "७", "८", "९"];

  static const Map<String, List<String>> months = {
    'nepali': ["बैशाख", "जेठ", "असार", "साउन", "भदौ", "असोज", "कात्तिक", "मंसिर", "पुस", "माघ", "फागुन", "चैत"],
    'english': ["Baisakh", "Jestha", "Ashar", "Shrawan", "Bhadra", "Ashwin", "Kartik", "Mangsir", "Poush", "Magh", "Falgun", "Chaitra"]
  };

  static const Map<String, List<String>> weekdays = {
    'nepali': ["आइतबार", "सोमबार", "मङ्गलबार", "बुधबार", "बिहीबार", "शुक्रबार", "शनिबार"],
    'english': ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
  };

  static const Map<String, List<String>> weekdaysShort = {
    'nepali': ["आइत", "सोम", "मङ्गल", "बुध", "बिही", "शुक्र", "शनि"],
    'english': ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
  };

  static const Map<String, List<String>> tithis = {
    'nepali': [
      "प्रतिपदा", "द्वितीया", "तृतीया", "चतुर्थी", "पञ्चमी", "षष्ठी", "सप्तमी",
      "अष्टमी", "नवमी", "दशमी", "एकादशी", "द्वादशी", "त्रयोदशी", "चतुर्दशी"
    ],
    'english': [
      "Pratipada", "Dwitiya", "Tritiya", "Chaturthi", "Panchami", "Shashthi",
      "Saptami", "Ashtami", "Navami", "Dashami", "Ekadashi", "Dwadashi",
      "Trayodashi", "Chaturdashi"
    ]
  };

  static const Map<String, String> fullMoon = {'nepali': "पूर्णिमा", 'english': "Purnima"};
  static const Map<String, String> newMoon = {'nepali': "औंसी", 'english': "Aunsi"};

  static const Map<String, Map<String, String>> paksha = {
    'shukla': {'nepali': "शुक्ल", 'english': "Shukla"},
    'krishna': {'nepali': "कृष्ण", 'english': "Krishna"}
  };

  static const List<String> gregorianShortMonths = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
  ];

  static String normalizeLanguage(String? value) => value == "English" ? "English" : "Nepali";
  static String normalizeNumerals(String? value) => value == "Latin" ? "Latin" : "Devanagari";
  static String normalizeFormat(String? value) {
    if (value == "Compact" || value == "Numeric" || value == "With Gregorian") return value!;
    return "Full";
  }

  static String langKey(String language) => normalizeLanguage(language) == "English" ? "english" : "nepali";

  static String numerals(dynamic value, [String? style]) {
    String text = value.toString();
    if (normalizeNumerals(style) != "Devanagari") return text;
    String out = "";
    for (int i = 0; i < text.length; i++) {
      int code = text.codeUnitAt(i) - 48;
      if (code >= 0 && code <= 9) {
        out += devanagariDigits[code];
      } else {
        out += text[i];
      }
    }
    return out;
  }

  static String padded(int value, [String? style]) {
    String text = value < 10 ? "0$value" : value.toString();
    return numerals(text, style);
  }

  static String monthName(int month, [String language = "Nepali"]) {
    var list = months[langKey(language)];
    if (list != null && month >= 1 && month <= 12) return list[month - 1];
    return "";
  }

  static String weekdayName(int weekday, [String language = "Nepali"]) {
    var list = weekdays[langKey(language)];
    if (list != null && weekday >= 0 && weekday <= 6) return list[weekday];
    return "";
  }

  static String weekdayShort(int weekday, [String language = "Nepali"]) {
    var list = weekdaysShort[langKey(language)];
    if (list != null && weekday >= 0 && weekday <= 6) return list[weekday];
    return "";
  }

  static String tithiName(int tithi, [String language = "Nepali"]) {
    String script = langKey(language);
    if (tithi == 15) return fullMoon[script] ?? "";
    if (tithi == 30) return newMoon[script] ?? "";
    int position = tithi <= 15 ? tithi : tithi - 15;
    var list = tithis[script];
    if (list != null && position >= 1 && position <= 14) return list[position - 1];
    return "";
  }

  static String pakshaName(String pName, [String language = "Nepali"]) {
    var entry = paksha[pName];
    return entry != null ? (entry[langKey(language)] ?? "") : "";
  }

  static String tithiLabel(int tithi, String pName, [String language = "Nepali"]) {
    String name = tithiName(tithi, language);
    if (tithi == 15 || tithi == 30) return name;
    return "${pakshaName(pName, language)} $name";
  }

  static String gregorianShort(GregorianDate date, [String? style]) {
    return "${numerals(date.day, style)} ${gregorianShortMonths[date.month - 1]}";
  }

  static String formatDate(BikramDate parts, {
    String language = "Nepali",
    String numeralsStyle = "Devanagari",
    String format = "Full",
    bool showWeekday = false,
    int? weekday,
    GregorianDate? gregorian,
  }) {
    String normFormat = normalizeFormat(format);
    if (normFormat == "Numeric") {
      String numeric = "${numerals(parts.year, numeralsStyle)}-${padded(parts.month, numeralsStyle)}-${padded(parts.day, numeralsStyle)}";
      return _withWeekday(numeric, showWeekday, weekday, language);
    }

    String stem = "${numerals(parts.day, numeralsStyle)} ${monthName(parts.month, language)}";
    if (normFormat == "Compact") {
      return _withWeekday(stem, showWeekday, weekday, language);
    }

    String full = "$stem ${numerals(parts.year, numeralsStyle)}";
    if (normFormat == "With Gregorian" && gregorian != null) {
      full += " · ${gregorianShort(gregorian, "Latin")}";
    }
    return _withWeekday(full, showWeekday, weekday, language);
  }

  static String _withWeekday(String text, bool showWeekday, int? weekday, String language) {
    if (!showWeekday || weekday == null || weekday < 0) return text;
    String name = weekdayName(weekday, language);
    return name.isEmpty ? text : "$name, $text";
  }

  static const Map<String, Map<String, String>> messages = {
    'provisional': {
      'nepali': "पञ्चाङ्ग निर्णायक समितिले %1 सालको पात्रो अझै निर्धारण गरेको छैन।",
      'english': "%1 BS is not yet fixed by the Panchanga Nirnayak Samiti."
    },
    'writeBikram': {
      'nepali': "बिक्रम सम्बत् मिति वर्ष-महिना-गते गरी लेख्नुहोस्।",
      'english': "Write a Bikram Sambat date as year-month-day."
    },
    'writeGregorian': {
      'nepali': "ग्रेगोरियन मिति वर्ष-महिना-गते गरी लेख्नुहोस्।",
      'english': "Write a Gregorian date as year-month-day."
    },
    'notADate': {
      'nepali': "यो मिति होइन।",
      'english': "That is not a date."
    },
    'outOfRange': {
      'nepali': "%1 देखि %2 सम्मको पात्रो मात्र छ, अर्थात् %3 देखि %4 सम्म।",
      'english': "Only %1 BS to %2 BS is covered, which is %3 to %4."
    },
    'noSuchDay': {
      'nepali': "%1 %2 मा %3 गते मात्र हुन्छन्।",
      'english': "%1 %2 has %3 days."
    }
  };

  static String message(String name, [String language = "Nepali"]) {
    var entry = messages[name];
    return entry != null ? (entry[langKey(language)] ?? "") : "";
  }

  static String provisionalNotice(int year, {String language = "Nepali", String numeralsStyle = "Devanagari"}) {
    return message("provisional", language).replaceAll("%1", numerals(year, numeralsStyle));
  }

  static String monthTitle(int year, int month, {String language = "Nepali", String numeralsStyle = "Devanagari"}) {
    return "${monthName(month, language)} ${numerals(year, numeralsStyle)}";
  }

  static String gregorianSpan(GregorianDate? first, GregorianDate? last) {
    if (first == null || last == null) return "";
    String head = gregorianShortMonths[first.month - 1];
    String tail = gregorianShortMonths[last.month - 1];
    String m = head == tail ? head : "$head/$tail";
    return first.year == last.year ? "$m ${first.year}" : "$m ${first.year}/${last.year}";
  }

  static bool isWeeklyHoliday(int weekday) => weekday == 6; // Saturday
}
