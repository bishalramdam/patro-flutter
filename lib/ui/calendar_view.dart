// calendar_view.dart
// Clean, minimalist Bikram Sambat Monthly Calendar View.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../engine/bikram.dart';
import '../engine/nepali.dart';
import '../engine/patro_engine.dart';

class CalendarView extends StatefulWidget {
  final PatroEngine engine;
  final VoidCallback onStateChanged;

  const CalendarView({Key? key, required this.engine, required this.onStateChanged}) : super(key: key);

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late int viewYear;
  late int viewMonth;
  DayCellModel? selectedDay;

  @override
  void initState() {
    super.initState();
    var today = widget.engine.getToday();
    viewYear = today.bs.year;
    viewMonth = today.bs.month;
  }

  void _previousMonth() {
    var next = BikramEngine.addMonths(viewYear, viewMonth, -1);
    setState(() {
      viewYear = next.year;
      viewMonth = next.month;
      selectedDay = null;
    });
  }

  void _nextMonth() {
    var next = BikramEngine.addMonths(viewYear, viewMonth, 1);
    setState(() {
      viewYear = next.year;
      viewMonth = next.month;
      selectedDay = null;
    });
  }

  void _goToToday() {
    var today = widget.engine.getToday();
    setState(() {
      viewYear = today.bs.year;
      viewMonth = today.bs.month;
      selectedDay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final monthData = widget.engine.getMonthData(viewYear, viewMonth);
    final today = widget.engine.getToday();
    final bool isCurrentMonth = (today.bs.year == viewYear && today.bs.month == viewMonth);

    // Pick active selected day or default to today (if in current month) or 1st of month
    DayCellModel? activeDay = selectedDay;
    if (activeDay == null) {
      for (var week in monthData.weeks) {
        for (var cell in week) {
          if (cell != null) {
            if (isCurrentMonth && cell.isToday) {
              activeDay = cell;
              break;
            } else if (!isCurrentMonth && cell.day == 1) {
              activeDay = cell;
            }
          }
        }
        if (activeDay != null && isCurrentMonth) break;
      }
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F141C) : const Color(0xFFF6F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "पात्रो",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: isCurrentMonth
                    ? (isDark ? Colors.white12 : Colors.black.withOpacity(0.05))
                    : const Color(0xFF007AFF),
                foregroundColor: isCurrentMonth
                    ? (isDark ? Colors.white70 : const Color(0xFF4B5563))
                    : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: _goToToday,
              icon: const Icon(Icons.today_rounded, size: 16),
              label: const Text("आज", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Month navigation card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2530) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 28),
                      color: const Color(0xFF007AFF),
                      onPressed: _previousMonth,
                    ),
                    Column(
                      children: [
                        Text(
                          monthData.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          monthData.gregorianSpan,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 28),
                      color: const Color(0xFF007AFF),
                      onPressed: _nextMonth,
                    ),
                  ],
                ),
              ),
            ),

            // Weekday header bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Row(
                children: [
                  for (int i = 0; i < 7; i++)
                    Expanded(
                      child: Center(
                        child: Text(
                          Nepali.weekdayShort(i, widget.engine.language),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: i == 6
                                ? const Color(0xFFEF4444) // Saturday in subtle red
                                : (isDark ? Colors.white60 : const Color(0xFF6B7280)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 7x6 Calendar Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2530) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      for (var week in monthData.weeks)
                        Expanded(
                          child: Row(
                            children: [
                              for (var cell in week)
                                Expanded(
                                  child: cell == null
                                      ? const SizedBox.shrink()
                                      : _buildDayCell(cell, activeDay, isDark),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Selected Day Detail Card
            if (activeDay != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2530) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: activeDay.isToday
                          ? const Color(0xFF007AFF).withOpacity(0.3)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Date bubble
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: activeDay.isToday
                              ? const Color(0xFF007AFF)
                              : (activeDay.isSaturday
                                  ? const Color(0xFFEF4444).withOpacity(0.12)
                                  : (isDark ? Colors.white10 : const Color(0xFFF3F4F6))),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            activeDay.dayText,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: activeDay.isToday
                                  ? Colors.white
                                  : (activeDay.isSaturday
                                      ? const Color(0xFFEF4444)
                                      : (isDark ? Colors.white : const Color(0xFF111827))),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Date description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "${activeDay.dayText} ${Nepali.monthName(activeDay.month, widget.engine.language)} ${Nepali.numerals(activeDay.year, widget.engine.numerals)}",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "(${Nepali.weekdayName(activeDay.weekday, widget.engine.language)})",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: activeDay.isSaturday
                                        ? const Color(0xFFEF4444)
                                        : (isDark ? Colors.white60 : const Color(0xFF6B7280)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${activeDay.gregorian.day} ${Nepali.gregorianShortMonths[activeDay.gregorian.month - 1]} ${activeDay.gregorian.year} AD",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Copy button
                      IconButton(
                        tooltip: "प्रतिलिपि गर्नुहोस् (Copy Date)",
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                        onPressed: () {
                          String copyText =
                              "${activeDay!.dayText} ${Nepali.monthName(activeDay.month, widget.engine.language)} ${Nepali.numerals(activeDay.year, widget.engine.numerals)} (${activeDay.gregorian.year}-${activeDay.gregorian.month.toString().padLeft(2, '0')}-${activeDay.gregorian.day.toString().padLeft(2, '0')})";
                          Clipboard.setData(ClipboardData(text: copyText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("मिति कपी गरियो: $copyText"),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCell(DayCellModel cell, DayCellModel? activeDay, bool isDark) {
    final bool isSelected = (activeDay != null &&
        activeDay.year == cell.year &&
        activeDay.month == cell.month &&
        activeDay.day == cell.day);

    Color textColor;
    if (cell.isToday) {
      textColor = Colors.white;
    } else if (cell.isSaturday) {
      textColor = const Color(0xFFEF4444);
    } else {
      textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          selectedDay = cell;
        });
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: cell.isToday
              ? const Color(0xFF007AFF)
              : (isSelected
                  ? (isDark ? Colors.white12 : const Color(0xFF007AFF).withOpacity(0.1))
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
          border: isSelected && !cell.isToday
              ? Border.all(color: const Color(0xFF007AFF), width: 1.5)
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                cell.dayText,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: cell.isToday ? FontWeight.w800 : FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                cell.gregorianDayText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: cell.isToday
                      ? Colors.white.withOpacity(0.8)
                      : (isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
