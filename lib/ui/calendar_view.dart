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
                    color: isDark ? const Color(0xFF181A1F) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF272A30) : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.6 : 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
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
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            color: isSelected
                                ? (isDark ? const Color(0xFF272A30) : const Color(0xFFE5E7EB))
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
                                          ? (isDark ? Colors.white : const Color(0xFF18181B))
                                          : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B)),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_rounded,
                                    size: 13,
                                    color: isDark ? Colors.white : const Color(0xFF18181B),
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
      backgroundColor: isDark ? Colors.black : const Color(0xFFF4F5F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          widget.engine.language == "English" ? "Calendar" : "क्यालेन्डर",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: -0.3,
            color: isDark ? Colors.white : const Color(0xFF18181B),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF181A1F) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF272A30) : const Color(0xFFE4E4E7),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _goToToday,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.today_rounded,
                        size: 15,
                        color: isDark ? Colors.white : const Color(0xFF18181B),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.engine.language == "English" ? "Today" : "आज",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          color: isDark ? Colors.white : const Color(0xFF18181B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),

              // Unified Architectural Calendar Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF121316) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark ? const Color(0xFF222428) : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Month Navigation Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildNavButton(
                              icon: Icons.chevron_left_rounded,
                              onTap: _previousMonth,
                              isDark: isDark,
                            ),

                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                _closeDropdown();
                                setState(() {
                                  showDateSelector = !showDateSelector;
                                });
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        monthData.title,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.3,
                                          color: isDark ? Colors.white : const Color(0xFF18181B),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        showDateSelector
                                            ? Icons.keyboard_arrow_up_rounded
                                            : Icons.keyboard_arrow_down_rounded,
                                        size: 18,
                                        color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    monthData.gregorianSpan,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? const Color(0xFF71717A) : const Color(0xFF71717A),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            _buildNavButton(
                              icon: Icons.chevron_right_rounded,
                              onTap: _nextMonth,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),

                      // Direct Date Selector Bar (when open)
                      if (showDateSelector) ...[
                        Divider(height: 1, color: isDark ? const Color(0xFF222428) : const Color(0xFFE5E7EB)),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: _buildDateSelectorBar(activeDay, isDark),
                        ),
                      ],

                      Divider(height: 1, color: isDark ? const Color(0xFF222428) : const Color(0xFFE5E7EB)),

                      // 2. Weekday Header Row
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
                                          ? const Color(0xFFFF453A)
                                          : (isDark ? const Color(0xFF71717A) : const Color(0xFF71717A)),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      Divider(height: 1, color: isDark ? const Color(0xFF222428) : const Color(0xFFE5E7EB)),

                      // 3. Proportional, Even Grid of Days
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var week in monthData.weeks)
                              Container(
                                height: 48,
                                margin: const EdgeInsets.symmetric(vertical: 2),
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
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 4. Selected Day Detail Card
              if (activeDay != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF121316) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0xFF222428) : const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left Date Badge
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: activeDay.isToday
                                ? Colors.white
                                : (activeDay.isSaturday
                                    ? const Color(0xFFFF453A).withOpacity(0.12)
                                    : (isDark ? const Color(0xFF1C1E22) : const Color(0xFFF4F5F7))),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: activeDay.isToday
                                  ? Colors.transparent
                                  : (isDark ? const Color(0xFF2A2D34) : const Color(0xFFE5E7EB)),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              activeDay.dayText,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: activeDay.isToday
                                    ? Colors.black
                                    : (activeDay.isSaturday
                                        ? const Color(0xFFFF453A)
                                        : (isDark ? Colors.white : const Color(0xFF18181B))),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Date & Observance details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      "${activeDay.dayText} ${Nepali.monthName(activeDay.month, widget.engine.language)} ${widget.engine.formatNumber(activeDay.year)}",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF18181B),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "(${Nepali.weekdayName(activeDay.weekday, widget.engine.language)})",
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: activeDay.isSaturday
                                          ? const Color(0xFFFF453A)
                                          : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                "${activeDay.gregorian.day} ${Nepali.gregorianShortMonths[activeDay.gregorian.month - 1]} ${activeDay.gregorian.year} AD",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFF71717A) : const Color(0xFF71717A),
                                ),
                              ),
                              if (activeDay.observanceSummary.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: activeDay.isHoliday
                                        ? const Color(0xFFFF453A).withOpacity(0.12)
                                        : (isDark ? const Color(0xFF1C1E22) : const Color(0xFFF4F5F7)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    activeDay.observanceSummary,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: activeDay.isHoliday
                                          ? const Color(0xFFFF453A)
                                          : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B)),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Quick-copy button
                        IconButton(
                          tooltip: "कपी (Copy Date)",
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                          onPressed: () {
                            HapticFeedback.lightImpact();
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181A1F) : const Color(0xFFF4F5F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF272A30) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Icon(
            icon,
            size: 20,
            color: isDark ? Colors.white : const Color(0xFF18181B),
          ),
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
          color: isSelected
              ? (isDark ? Colors.white : const Color(0xFF18181B))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? const Color(0xFF71717A) : const Color(0xFF71717A)),
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
              ? (isDark ? const Color(0xFF22242A) : const Color(0xFFE5E7EB))
              : (isDark ? const Color(0xFF181A1F) : const Color(0xFFF4F5F7)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isOpen
                ? (isDark ? Colors.white54 : const Color(0xFF18181B))
                : (isDark ? const Color(0xFF272A30) : const Color(0xFFE5E7EB)),
            width: isOpen ? 1 : 0.8,
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
                      ? (isDark ? Colors.white : const Color(0xFF18181B))
                      : (isDark ? Colors.white : const Color(0xFF18181B)),
                ),
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: isOpen
                  ? (isDark ? Colors.white : const Color(0xFF18181B))
                  : (isDark ? const Color(0xFF71717A) : const Color(0xFF9CA3AF)),
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
      textColor = Colors.black;
    } else if (cell.isSaturday) {
      textColor = const Color(0xFFFF453A);
    } else {
      textColor = isDark ? Colors.white : const Color(0xFF18181B);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        HapticFeedback.selectionClick();
        _closeDropdown();
        setState(() {
          selectedDay = cell;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        decoration: BoxDecoration(
          color: cell.isToday
              ? Colors.white
              : (isSelected
                  ? (isDark ? const Color(0xFF22242A) : const Color(0xFFE5E7EB))
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
          border: isSelected && !cell.isToday
              ? Border.all(
                  color: isDark ? const Color(0xFF52525B) : const Color(0xFF9CA3AF),
                  width: 1.2,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              cell.dayText,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: cell.isToday
                    ? FontWeight.w800
                    : (isSelected ? FontWeight.w700 : FontWeight.w600),
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              cell.gregorianDayText,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: cell.isToday
                    ? const Color(0xFF3F3F46)
                    : (cell.isSaturday
                        ? const Color(0xFFFF453A).withOpacity(0.65)
                        : (isDark ? const Color(0xFF71717A) : const Color(0xFF9CA3AF))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
