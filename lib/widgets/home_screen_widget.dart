// home_screen_widget.dart
// Bridge to synchronize calendar data to native Android AppWidget & iOS WidgetKit.

import 'package:home_widget/home_widget.dart';
import '../engine/nepali.dart';
import '../engine/patro_engine.dart';

class HomeScreenWidgetHelper {
  static const String appGroupId = 'group.com.bishal.patromobile';
  static const String androidWidgetName = 'PatroAppWidget';
  static const String iOSWidgetName = 'PatroWidget';

  static Future<void> updateWidgets(PatroEngine engine) async {
    try {
      final today = engine.getToday();

      // Save key-value pairs accessible by native widgets
      await HomeWidget.saveWidgetData<String>('bs_day', today.dayText);
      await HomeWidget.saveWidgetData<String>('bs_month', today.monthName);
      await HomeWidget.saveWidgetData<String>('bs_year', today.yearText);
      await HomeWidget.saveWidgetData<String>('bs_full_label', today.cleanYearLabel);
      await HomeWidget.saveWidgetData<String>('weekday', today.weekdayName);
      await HomeWidget.saveWidgetData<String>('weekday_short', today.weekdayShort);
      await HomeWidget.saveWidgetData<String>('gregorian_day', today.gregorian.day.toString());
      await HomeWidget.saveWidgetData<String>(
          'gregorian_month', Nepali.gregorianShortMonths[today.gregorian.month - 1]);
      await HomeWidget.saveWidgetData<String>('tithi_label', today.tithiLabel);
      await HomeWidget.saveWidgetData<String>('observance', today.observances);
      await HomeWidget.saveWidgetData<bool>('is_holiday', today.isHoliday);

      // Trigger native widget update
      await HomeWidget.updateWidget(
        name: androidWidgetName,
        iOSName: iOSWidgetName,
      );
    } catch (e) {
      // In standalone testing or desktop simulation, catch quietly
      print("HomeWidget sync notice: $e");
    }
  }
}
