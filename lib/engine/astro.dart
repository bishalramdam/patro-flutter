// astro.dart
// Tithi calculation via Meeus, Astronomical Algorithms 2nd ed., chapters 25 & 47.
// Sunrise reckoned at Kathmandu (27.7172° N, 85.324° E).

import 'dart:math' as math;

class Location {
  final double latitude;
  final double longitude;
  const Location({required this.latitude, required this.longitude});
}

class Astro {
  static const Location kathmandu = Location(latitude: 27.7172, longitude: 85.324);
  static const double rad = math.pi / 180.0;
  static const double dayMs = 86400000.0;
  static const double tithiArc = 12.0;

  static const List<List<int>> moonTerms = [
    [0, 0, 1, 0, 6288774], [2, 0, -1, 0, 1274027], [2, 0, 0, 0, 658314],
    [0, 0, 2, 0, 213618], [0, 1, 0, 0, -185116], [0, 0, 0, 2, -114332],
    [2, 0, -2, 0, 58793], [2, -1, -1, 0, 57066], [2, 0, 1, 0, 53322],
    [2, -1, 0, 0, 45758], [0, 1, -1, 0, -40923], [1, 0, 0, 0, -34720],
    [0, 1, 1, 0, -30383], [2, 0, 0, -2, 15327], [0, 0, 1, 2, -12528],
    [0, 0, 1, -2, 10980], [4, 0, -1, 0, 10675], [0, 0, 3, 0, 10034],
    [4, 0, -2, 0, 8548], [2, 1, -1, 0, -7888], [2, 1, 0, 0, -6766],
    [1, 0, -1, 0, -5163], [1, 1, 0, 0, 4987], [2, -1, 1, 0, 4036],
    [2, 0, 2, 0, 3994], [4, 0, 0, 0, 3861], [2, 0, -3, 0, 3665],
    [0, 1, -2, 0, -2689], [2, 0, -1, 2, -2602], [2, -1, -2, 0, 2390],
    [1, 0, 1, 0, -2348], [2, -2, 0, 0, 2236], [0, 1, 2, 0, -2120],
    [0, 2, 0, 0, -2069], [2, -2, -1, 0, 2048], [2, 0, 1, -2, -1773],
    [2, 0, 0, 2, -1595], [4, -1, -1, 0, 1215], [0, 0, 2, 2, -1110],
    [3, 0, -1, 0, -892], [2, 1, 1, 0, -810], [4, -1, -2, 0, 759],
    [0, 2, -1, 0, -713], [2, 2, -1, 0, -700], [2, 1, -2, 0, 691],
    [2, -1, 0, -2, 596], [4, 0, 1, 0, 549], [0, 0, 4, 0, 537],
    [4, -1, 0, 0, 520], [1, 0, -2, 0, -487], [2, 1, 0, -2, -399],
    [0, 0, 2, -2, -381], [1, 1, 1, 0, 351], [3, 0, -2, 0, -340],
    [4, 0, -3, 0, 330], [2, -1, 2, 0, 327], [0, 2, 1, 0, -323],
    [1, 1, -1, 0, 299], [2, 0, 3, 0, 294], [2, 0, -1, -2, 0]
  ];

  static double norm360(double degrees) {
    var wrapped = degrees % 360.0;
    return wrapped < 0 ? wrapped + 360.0 : wrapped;
  }

  static double julianDay(double utcMs) {
    return utcMs / dayMs + 2440587.5;
  }

  static double centuries(double jd) {
    return (jd - 2451545.0) / 36525.0;
  }

  static double solarLongitude(double t) {
    var l0 = 280.46646 + 36000.76983 * t + 0.0003032 * t * t;
    var m = norm360(357.52911 + 35999.05029 * t - 0.0001537 * t * t) * rad;
    var centre = (1.914602 - 0.004817 * t - 0.000014 * t * t) * math.sin(m) +
        (0.019993 - 0.000101 * t) * math.sin(2 * m) +
        0.000289 * math.sin(3 * m);
    return norm360(l0 + centre);
  }

  static double lunarLongitude(double t) {
    var lp = 218.3164477 + 481267.88123421 * t - 0.0015786 * t * t +
        (t * t * t) / 538841.0 - (t * t * t * t) / 65194000.0;
    var d = 297.8501921 + 445267.1114034 * t - 0.0018819 * t * t +
        (t * t * t) / 545868.0 - (t * t * t * t) / 113065000.0;
    var m = 357.5291092 + 35999.0502909 * t - 0.0001536 * t * t +
        (t * t * t) / 24490000.0;
    var mp = 134.9633964 + 477198.8675055 * t + 0.0087414 * t * t +
        (t * t * t) / 69699.0 - (t * t * t * t) / 14712000.0;
    var f = 93.272095 + 483202.0175233 * t - 0.0036539 * t * t -
        (t * t * t) / 3526000.0 + (t * t * t * t) / 863310000.0;
    var e = 1.0 - 0.002516 * t - 0.0000074 * t * t;

    double sum = 0.0;
    for (var term in moonTerms) {
      var argument = (term[0] * d + term[1] * m + term[2] * mp + term[3] * f) * rad;
      var damping = term[1] == 0 ? 1.0 : (term[1].abs() == 1 ? e : e * e);
      sum += term[4] * damping * math.sin(argument);
    }
    sum += 3958.0 * math.sin(norm360(119.75 + 131.849 * t) * rad) +
        1962.0 * math.sin((lp - f) * rad) +
        318.0 * math.sin(norm360(53.09 + 479264.29 * t) * rad);

    return norm360(lp + sum / 1000000.0);
  }

  static double deltaTSeconds(int year) {
    if (year < 1941) return -20.0 + 32.0 * math.pow((year - 1820) / 100.0, 2);
    if (year < 1961) {
      var t = (year - 1950).toDouble();
      return 29.07 + 0.407 * t - (t * t) / 233.0 + (t * t * t) / 2547.0;
    }
    if (year < 1986) {
      var t = (year - 1975).toDouble();
      return 45.45 + 1.067 * t - (t * t) / 260.0 - (t * t * t) / 718.0;
    }
    if (year < 2005) {
      var t = (year - 2000).toDouble();
      return 63.86 + 0.3345 * t - 0.060374 * t * t + 0.0017275 * t * t * t +
          0.000651814 * t * t * t * t + 0.00002373599 * t * t * t * t * t;
    }
    if (year < 2050) {
      var t = (year - 2000).toDouble();
      return 62.92 + 0.32217 * t + 0.005589 * t * t;
    }
    if (year < 2150) {
      return -20.0 + 32.0 * math.pow((year - 1820) / 100.0, 2) - 0.5628 * (2150 - year);
    }
    return -20.0 + 32.0 * math.pow((year - 1820) / 100.0, 2);
  }

  static double terrestrialCenturies(double utcMs) {
    var date = DateTime.fromMillisecondsSinceEpoch(utcMs.toInt(), isUtc: true);
    return centuries(julianDay(utcMs + deltaTSeconds(date.year) * 1000.0));
  }

  static double obliquity(double t) {
    return (23.439291 - 0.0130042 * t) * rad;
  }

  static double solarDeclination(double t) {
    return math.asin(math.sin(obliquity(t)) * math.sin(solarLongitude(t) * rad));
  }

  static double equationOfTimeMinutes(double t) {
    var l0 = norm360(280.46646 + 36000.76983 * t + 0.0003032 * t * t);
    var y = math.pow(math.tan(obliquity(t) / 2.0), 2);
    var m = norm360(357.52911 + 35999.05029 * t) * rad;
    var eccentricity = 0.016708634 - 0.000042037 * t;
    var value = y * math.sin(2 * l0 * rad) -
        2 * eccentricity * math.sin(m) +
        4 * eccentricity * y * math.sin(m) * math.cos(2 * l0 * rad) -
        0.5 * y * y * math.sin(4 * l0 * rad) -
        1.25 * eccentricity * eccentricity * math.sin(2 * m);
    return (value / rad) * 4.0;
  }

  static double? sunriseUtcMs(int year, int month, int day, [Location? place]) {
    var where = place ?? kathmandu;
    var midnight = DateTime.utc(year, month, day).millisecondsSinceEpoch.toDouble();
    var guess = midnight + (12.0 - where.longitude / 15.0) * 3600000.0;

    for (var pass = 0; pass < 3; pass++) {
      var t = centuries(julianDay(guess));
      var declination = solarDeclination(t);
      var latitude = where.latitude * rad;
      var cosHourAngle = (math.sin(-0.833 * rad) - math.sin(latitude) * math.sin(declination)) /
          (math.cos(latitude) * math.cos(declination));
      if (cosHourAngle < -1.0 || cosHourAngle > 1.0) return null;
      var hourAngle = math.acos(cosHourAngle) / rad;
      var noon = 720.0 - 4.0 * where.longitude - equationOfTimeMinutes(t);
      guess = midnight + (noon - 4.0 * hourAngle) * 60000.0;
    }
    return guess;
  }

  static double elongationAt(double utcMs) {
    var t = terrestrialCenturies(utcMs);
    return norm360(lunarLongitude(t) - solarLongitude(t));
  }

  static int tithiAt(double utcMs) {
    return (elongationAt(utcMs) / tithiArc).floor() + 1;
  }

  static int tithiForDate(int year, int month, int day) {
    var sunrise = sunriseUtcMs(year, month, day, kathmandu);
    return sunrise == null ? 0 : tithiAt(sunrise);
  }

  static String pakshaOf(int tithi) {
    return tithi <= 15 ? "shukla" : "krishna";
  }

  static int tithiInPaksha(int tithi) {
    return tithi <= 15 ? tithi : tithi - 15;
  }

  static bool isEkadashi(int tithi) => tithi == 11 || tithi == 26;
  static bool isPurnima(int tithi) => tithi == 15;
  static bool isAunsi(int tithi) => tithi == 30;
}
