// calendar_view.dart
// Clean, minimalist Bikram Sambat Monthly Calendar View with Direct Date Selector.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../engine/bikram.dart';
import '../engine/nepali.dart';
import '../engine/patro_engine.dart';

class _DropdownItem {
  final int id;
  final String title;
  const _DropdownItem({required this.id, required this.title});
}

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

  // Direct Date Selector State
  bool showDateSelector = false;
  String pickerMode = "BS"; // "BS" or "AD"
  String? activeDropdown; // "year", "month", "day", or null

  final LayerLink _yearLink = LayerLink();
  final LayerLink _monthLink = LayerLink();
  final LayerLink _dayLink = LayerLink();
  OverlayEntry? _dropdownOverlay;

  @override
  void initState() {
    super.initState();
    var today = widget.engine.getToday();
    viewYear = today.bs.year;
    viewMonth = today.bs.month;
  }

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  void _closeDropdown() {
    if (_dropdownOverlay != null) {
      _dropdownOverlay!.remove();
      _dropdownOverlay = null;
    }
    if (activeDropdown != null) {
      setState(() {
        activeDropdown = null;
      });
    }
  }

  void _previousMonth() {
    _closeDropdown();
    var next = BikramEngine.addMonths(viewYear, viewMonth, -1);
    setState(() {
      viewYear = next.year;
      viewMonth = next.month;
      selectedDay = null;
    });
  }

  void _nextMonth() {
    _closeDropdown();
    var next = BikramEngine.addMonths(viewYear, viewMonth, 1);
    setState(() {
      viewYear = next.year;
      viewMonth = next.month;
      selectedDay = null;
    });
  }

  void _goToToday() {
    _closeDropdown();
    var today = widget.engine.getToday();
    setState(() {
      viewYear = today.bs.year;
      viewMonth = today.bs.month;
      selectedDay = null;
    });
  }

  void _jumpToBS(int year, int month, [int? day]) {
    final y = year.clamp(2000, 2090);
    final m = month.clamp(1, 12);
    final maxDays = BikramEngine.monthLength(y, m);
    int targetDay = day ?? selectedDay?.day ?? 1;
    if (targetDay > maxDays) targetDay = maxDays;
    if (targetDay < 1) targetDay = 1;

    setState(() {
      viewYear = y;
      viewMonth = m;

      final monthData = widget.engine.getMonthData(viewYear, viewMonth);
      selectedDay = null;
      for (var week in monthData.weeks) {
        for (var cell in week) {
          if (cell != null && cell.day == targetDay) {
            selectedDay = cell;
            break;
          }
        }
        if (selectedDay != null) break;
      }
    });
  }

  void _jumpToAD(int year, int month, int day) {
    final bs = BikramEngine.fromGregorian(year, month, day);
    if (bs != null) {
      _jumpToBS(bs.year, bs.month, bs.day);
    }
  }

  List<_DropdownItem> _getYearItems() {
    if (pickerMode == "BS") {
      return [
        for (int y = 2090; y >= 2000; y--)
          _DropdownItem(id: y, title: widget.engine.formatNumber(y))
      ];
    } else {
      return [
        for (int y = 2034; y >= 1944; y--)
          _DropdownItem(id: y, title: "$y")
      ];
    }
  }

  List<_DropdownItem> _getMonthItems() {
    if (pickerMode == "BS") {
      return [
        for (int m = 1; m <= 12; m++)
          _DropdownItem(id: m, title: Nepali.monthName(m, widget.engine.language))
      ];
    } else {
      return [
        for (int m = 1; m <= 12; m++)
          _DropdownItem(id: m, title: Nepali.gregorianShortMonths[m - 1])
      ];
    }
  }

  List<_DropdownItem> _getDayItems(DayCellModel? activeDay) {
    final isEnglish = widget.engine.language == "English";
    if (pickerMode == "BS") {
      final maxDays = BikramEngine.monthLength(viewYear, viewMonth);
      final suffix = isEnglish ? "" : " गते";
      return [
        for (int d = 1; d <= maxDays; d++)
          _DropdownItem(id: d, title: "${widget.engine.formatNumber(d)}$suffix")
      ];
    } else {
      final currentADYear = activeDay?.gregorian.year ?? 2026;
      final currentADMonth = activeDay?.gregorian.month ?? 11;
      final maxDays = DateTime(currentADYear, currentADMonth + 1, 0).day;
      return [
        for (int d = 1; d <= maxDays; d++)
          _DropdownItem(id: d, title: "$d")
      ];
    }
  }

  void _toggleDropdown(
    String type,
    LayerLink link,
    List<_DropdownItem> items,
    int selectedId,
    double width,
    bool isDark,
    ValueChanged<int> onSelect,
  ) {
    if (activeDropdown == type) {
      _closeDropdown();
      return;
    }
    _openDropdown(
      type: type,
      link: link,
      items: items,
      selectedId: selectedId,
      width: width,
      isDark: isDark,
      onSelect: onSelect,
    );
  }

  void _openDropdown({
    required String type,
    required LayerLink link,
    required List<_DropdownItem> items,
    required int selectedId,
    required double width,
    required bool isDark,
    required ValueChanged<int> onSelect,
  }) {
    _closeDropdown();
    setState(() {
      activeDropdown = type;
    });

    const double rowHeight = 30.0;
    final int visibleRows = items.length > 10 ? 10 : items.length;
    final double menuHeight = visibleRows * rowHeight + 8.0;

    int selectedIndex = items.indexWhere((it) => it.id == selectedId);
    if (selectedIndex < 0) selectedIndex = 0;
    final double initialScroll = (selectedIndex > 3)
        ? (selectedIndex - 2) * rowHeight
        : 0.0;

    final scrollController = ScrollController(initialScrollOffset: initialScroll);

    _dropdownOverlay = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Fullscreen transparent barrier to dismiss on outside tap
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeDropdown,
                child: const SizedBox.expand(),
              ),
            ),

            // Anchored floating dropdown directly below button
            CompositedTransformFollower(
              link: link,
              showWhenUnlinked: false,
              offset: const Offset(0, 32),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: width,
                  height: menuHeight,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2530) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.black12,
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: items.length,
                      itemExtent: rowHeight,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final bool isSelected = item.id == selectedId;

                        return InkWell(
                          onTap: () {
                            _closeDropdown();
                            onSelect(item.id);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            color: isSelected
                                ? const Color(0xFF007AFF)
                                : Colors.transparent,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark ? Colors.white : const Color(0xFF1F2937)),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_dropdownOverlay!);
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded, size: 28),
                          color: const Color(0xFF007AFF),
                          onPressed: _previousMonth,
                        ),
                        // Clickable Month & Year Header to toggle Date Selector
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            _closeDropdown();
                            setState(() {
                              showDateSelector = !showDateSelector;
                            });
                          },
                          child: Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    monthData.title,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    showDateSelector
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 20,
                                    color: showDateSelector
                                        ? const Color(0xFF007AFF)
                                        : (isDark ? Colors.white54 : const Color(0xFF6B7280)),
                                  ),
                                ],
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
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded, size: 28),
                          color: const Color(0xFF007AFF),
                          onPressed: _nextMonth,
                        ),
                      ],
                    ),

                    // Direct Date Selector Bar (revealed on tapping the Month & Year header)
                    if (showDateSelector) ...[
                      const SizedBox(height: 10),
                      Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
                      const SizedBox(height: 10),
                      _buildDateSelectorBar(activeDay, isDark),
                    ],
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
                                  "${activeDay.dayText} ${Nepali.monthName(activeDay.month, widget.engine.language)} ${widget.engine.formatNumber(activeDay.year)}",
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
                              "${activeDay!.dayText} ${Nepali.monthName(activeDay.month, widget.engine.language)} ${widget.engine.formatNumber(activeDay.year)} (${activeDay.gregorian.year}-${activeDay.gregorian.month.toString().padLeft(2, '0')}-${activeDay.gregorian.day.toString().padLeft(2, '0')})";
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

  Widget _buildDateSelectorBar(DayCellModel? activeDay, bool isDark) {
    final isEnglish = widget.engine.language == "English";

    final currentADYear = activeDay?.gregorian.year ?? 2026;
    final currentADMonth = activeDay?.gregorian.month ?? 11;
    final currentADDay = activeDay?.gregorian.day ?? 8;

    final String yearText = pickerMode == "BS"
        ? widget.engine.formatNumber(viewYear)
        : "$currentADYear";

    final String monthText = pickerMode == "BS"
        ? Nepali.monthName(viewMonth, widget.engine.language)
        : (currentADMonth >= 1 && currentADMonth <= 12
            ? Nepali.gregorianShortMonths[currentADMonth - 1]
            : "Nov");

    final String daySuffix = (pickerMode == "BS" && !isEnglish) ? " गते" : "";
    final int dayVal = activeDay?.day ?? 1;
    final String dayText = pickerMode == "BS"
        ? "${widget.engine.formatNumber(dayVal)}$daySuffix"
        : "$currentADDay";

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mode Capsule: [ वि.सं. | ई.सं. ] or [ BS | AD ]
          _buildModeCapsuleToggle(isEnglish, isDark),
          const SizedBox(width: 6),

          // Year Button
          CompositedTransformTarget(
            link: _yearLink,
            child: _buildSelectorButton(
              title: yearText,
              isOpen: activeDropdown == "year",
              width: 72,
              isDark: isDark,
              onTap: () => _toggleDropdown(
                "year",
                _yearLink,
                _getYearItems(),
                pickerMode == "BS" ? viewYear : currentADYear,
                82,
                isDark,
                (val) {
                  if (pickerMode == "BS") {
                    _jumpToBS(val, viewMonth, activeDay?.day);
                  } else {
                    _jumpToAD(val, currentADMonth, currentADDay);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Month Button
          CompositedTransformTarget(
            link: _monthLink,
            child: _buildSelectorButton(
              title: monthText,
              isOpen: activeDropdown == "month",
              width: 86,
              isDark: isDark,
              onTap: () => _toggleDropdown(
                "month",
                _monthLink,
                _getMonthItems(),
                pickerMode == "BS" ? viewMonth : currentADMonth,
                110,
                isDark,
                (val) {
                  if (pickerMode == "BS") {
                    _jumpToBS(viewYear, val, activeDay?.day);
                  } else {
                    _jumpToAD(currentADYear, val, currentADDay);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Day Button
          CompositedTransformTarget(
            link: _dayLink,
            child: _buildSelectorButton(
              title: dayText,
              isOpen: activeDropdown == "day",
              width: 66,
              isDark: isDark,
              onTap: () => _toggleDropdown(
                "day",
                _dayLink,
                _getDayItems(activeDay),
                pickerMode == "BS" ? (activeDay?.day ?? 1) : currentADDay,
                78,
                isDark,
                (val) {
                  if (pickerMode == "BS") {
                    _jumpToBS(viewYear, viewMonth, val);
                  } else {
                    _jumpToAD(currentADYear, currentADMonth, val);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCapsuleToggle(bool isEnglish, bool isDark) {
    return Container(
      height: 28,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCapsuleSegment(
            title: isEnglish ? "BS" : "वि.सं.",
            isSelected: pickerMode == "BS",
            isDark: isDark,
            onTap: () {
              if (pickerMode != "BS") {
                _closeDropdown();
                setState(() {
                  pickerMode = "BS";
                });
              }
            },
          ),
          _buildCapsuleSegment(
            title: isEnglish ? "AD" : "ई.सं.",
            isSelected: pickerMode == "AD",
            isDark: isDark,
            onTap: () {
              if (pickerMode != "AD") {
                _closeDropdown();
                setState(() {
                  pickerMode = "AD";
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCapsuleSegment({
    required String title,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF007AFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white60 : const Color(0xFF6B7280)),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorButton({
    required String title,
    required bool isOpen,
    required double width,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: width,
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: isOpen
              ? const Color(0xFF007AFF).withOpacity(0.15)
              : (isDark ? Colors.white10 : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isOpen
                ? const Color(0xFF007AFF)
                : (isDark ? Colors.white12 : Colors.black12),
            width: isOpen ? 1 : 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isOpen
                      ? const Color(0xFF007AFF)
                      : (isDark ? Colors.white : const Color(0xFF1F2937)),
                ),
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: isOpen
                  ? const Color(0xFF007AFF)
                  : (isDark ? Colors.white54 : const Color(0xFF9CA3AF)),
            ),
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
        _closeDropdown();
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
