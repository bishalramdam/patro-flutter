package com.bishal.patro_flutter

import java.util.Calendar
import java.util.TimeZone

data class BikramDate(val year: Int, val month: Int, val day: Int)

data class TodayDateData(
    val bsDay: String,
    val bsMonth: String,
    val bsYear: String,
    val weekday: String,
    val gregorianDay: String,
    val gregorianMonth: String,
    val gregorianYear: String,
    val bsDayInt: Int = 1
)

object BikramCalendarHelper {
    const val FIRST_YEAR = 2000
    const val LAST_YEAR = 2090
    private const val ANCHOR_AD_YEAR = 1943
    private const val ANCHOR_AD_MONTH = 4
    private const val ANCHOR_AD_DAY = 14

    private val MONTH_LENGTHS = arrayOf(
        intArrayOf(30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31), // 2000
        intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30), // 2001
        intArrayOf(31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30), // 2002
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31), // 2003
        intArrayOf(30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31), // 2004
        intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30), // 2005
        intArrayOf(31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30), // 2006
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31), // 2007
        intArrayOf(31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 29, 31), // 2008
        intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30), // 2009
        intArrayOf(31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30), // 2010
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31), // 2011
        intArrayOf(31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30), // 2012
        intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30), // 2013
        intArrayOf(31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30), // 2014
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31), // 2015
        intArrayOf(31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30), // 2016
        intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30), // 2017
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 29, 30, 29, 30, 30), // 2018
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31), // 2019
        intArrayOf(31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30), // 2020
        intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30), // 2021
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30), // 2022
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31), // 2023
        intArrayOf(31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30), // 2024
        intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30), // 2025
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31), // 2026
        intArrayOf(30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31), // 2027
        intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30), // 2028
        intArrayOf(31, 31, 32, 31, 32, 30, 30, 29, 30, 29, 30, 30), // 2029
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31), // 2030
        intArrayOf(30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31), // 2031
        intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30), // 2032
        intArrayOf(31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30), // 2033
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31), // 2034
        intArrayOf(30, 32, 31, 32, 31, 31, 29, 30, 30, 29, 29, 31), // 2035
        intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30), // 2036
        intArrayOf(31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30), // 2037
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31), // 2038
        intArrayOf(31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30), // 2039
        intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30), // 2040
        intArrayOf(31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30), // 2041
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31), // 2042
        intArrayOf(31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30), // 2043
        intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30), // 2044
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 29, 30, 29, 30, 30), // 2045
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31), // 2046
        intArrayOf(31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30), // 2047
        intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30), // 2048
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30), // 2049
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31), // 2050
        intArrayOf(31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30), // 2051
        intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30), // 2052
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30), // 2053
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31), // 2054
        intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30), // 2055
        intArrayOf(31, 31, 32, 31, 32, 30, 30, 29, 30, 29, 30, 30), // 2056
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31), // 2057
        intArrayOf(30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31), // 2058
        intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30), // 2059
        intArrayOf(31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30), // 2060
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31), // 2061
        intArrayOf(30, 32, 31, 32, 31, 31, 29, 30, 29, 30, 29, 31), // 2062
        intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30), // 2063
        intArrayOf(31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30), // 2064
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31), // 2065
        intArrayOf(31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 29, 31), // 2066
        intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30), // 2067
        intArrayOf(31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30), // 2068
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31), // 2069
        intArrayOf(31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30), // 2070
        intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30), // 2071
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 29, 30, 29, 30, 30), // 2072
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31), // 2073
        intArrayOf(31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30), // 2074
        intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30), // 2075
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30), // 2076
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31), // 2077
        intArrayOf(31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30), // 2078
        intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30), // 2079
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30), // 2080
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31), // 2081
        intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30), // 2082
        intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30), // 2083
        intArrayOf(31, 31, 32, 31, 31, 30, 30, 30, 29, 30, 30, 30), // 2084
        intArrayOf(30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31), // 2085
        intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30), // 2086
        intArrayOf(31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30), // 2087
        intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31), // 2088
        intArrayOf(30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31), // 2089
        intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30)  // 2090
    )

    private val yearOffsets = IntArray(MONTH_LENGTHS.size + 1)
    private val totalDays: Int
    private val anchorDays: Int

    val NEPALI_MONTHS = arrayOf(
        "बैशाख", "जेठ", "असार", "साउन", "भदौ", "असोज",
        "कात्तिक", "मंसिर", "पुस", "माघ", "फागुन", "चैत"
    )

    val ENGLISH_MONTHS = arrayOf(
        "Baisakh", "Jestha", "Ashar", "Shrawan", "Bhadra", "Ashwin",
        "Kartik", "Mangsir", "Poush", "Magh", "Falgun", "Chaitra"
    )

    val NEPALI_WEEKDAYS = arrayOf(
        "आइतबार", "सोमबार", "मङ्गलबार", "बुधबार", "बिहीबार", "शुक्रबार", "शनिबार"
    )

    val ENGLISH_WEEKDAYS = arrayOf(
        "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
    )

    val GREGORIAN_SHORT_MONTHS = arrayOf(
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    )

    private val DEVANAGARI_DIGITS = charArrayOf('०', '१', '२', '३', '४', '५', '६', '७', '८', '९')

    init {
        var total = 0
        yearOffsets[0] = 0
        for (i in MONTH_LENGTHS.indices) {
            yearOffsets[i] = total
            for (m in 0 until 12) {
                total += MONTH_LENGTHS[i][m]
            }
        }
        yearOffsets[MONTH_LENGTHS.size] = total
        totalDays = total
        anchorDays = daysFromCivil(ANCHOR_AD_YEAR, ANCHOR_AD_MONTH, ANCHOR_AD_DAY)
    }

    fun daysFromCivil(year: Int, month: Int, day: Int): Int {
        val y = year - if (month <= 2) 1 else 0
        val era = (if (y >= 0) y else y - 399) / 400
        val yearOfEra = y - era * 400
        val dayOfYear = (153 * (month + (if (month > 2) -3 else 9)) + 2) / 5 + day - 1
        val dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear
        return era * 146097 + dayOfEra - 719468
    }

    fun monthLength(year: Int, month: Int): Int {
        if (year < FIRST_YEAR || year > LAST_YEAR || month < 1 || month > 12) return 0
        return MONTH_LENGTHS[year - FIRST_YEAR][month - 1]
    }

    fun fromDayIndex(index: Int): BikramDate? {
        if (index < 0 || index >= totalDays) return null
        var year = FIRST_YEAR
        while (index >= yearOffsets[year - FIRST_YEAR + 1]) {
            year++
        }
        var remaining = index - yearOffsets[year - FIRST_YEAR]
        var month = 1
        while (remaining >= monthLength(year, month)) {
            remaining -= monthLength(year, month)
            month++
        }
        return BikramDate(year, month, remaining + 1)
    }

    fun fromGregorian(year: Int, month: Int, day: Int): BikramDate? {
        return fromDayIndex(daysFromCivil(year, month, day) - anchorDays)
    }

    fun weekdayOf(year: Int, month: Int, day: Int): Int {
        if (year < FIRST_YEAR || year > LAST_YEAR || month < 1 || month > 12) return -1
        var index = yearOffsets[year - FIRST_YEAR]
        for (m in 1 until month) {
            index += monthLength(year, m)
        }
        index += day - 1
        return (((anchorDays + index + 4) % 7) + 7) % 7
    }

    fun toDevanagari(num: Int): String {
        val str = num.toString()
        val sb = java.lang.StringBuilder()
        for (ch in str) {
            if (ch in '0'..'9') {
                sb.append(DEVANAGARI_DIGITS[ch - '0'])
            } else {
                sb.append(ch)
            }
        }
        return sb.toString()
    }

    fun getTodayData(isEnglish: Boolean = false, isLatinNumerals: Boolean = false): TodayDateData {
        val cal = Calendar.getInstance(TimeZone.getTimeZone("Asia/Kathmandu"))
        val gYear = cal.get(Calendar.YEAR)
        val gMonth = cal.get(Calendar.MONTH) + 1
        val gDay = cal.get(Calendar.DAY_OF_MONTH)

        val bs = fromGregorian(gYear, gMonth, gDay) ?: BikramDate(2083, 7, 30)
        val wd = weekdayOf(bs.year, bs.month, bs.day)

        val bsDayStr = if (isLatinNumerals) bs.day.toString() else toDevanagari(bs.day)
        val bsYearStr = if (isLatinNumerals) bs.year.toString() else toDevanagari(bs.year)
        val bsMonthStr = if (isEnglish) ENGLISH_MONTHS[bs.month - 1] else NEPALI_MONTHS[bs.month - 1]
        val wdStr = if (isEnglish) ENGLISH_WEEKDAYS[wd] else NEPALI_WEEKDAYS[wd]
        val gMonthStr = GREGORIAN_SHORT_MONTHS[gMonth - 1]

        return TodayDateData(
            bsDay = bsDayStr,
            bsMonth = bsMonthStr,
            bsYear = bsYearStr,
            weekday = wdStr,
            gregorianDay = gDay.toString(),
            gregorianMonth = gMonthStr,
            gregorianYear = gYear.toString(),
            bsDayInt = bs.day
        )
    }
}
