// notification_service.dart
// Offline Local Notifications for Patro: Lock-screen Banner & Normal Alerts.

import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../engine/nepali.dart';
import '../engine/patro_engine.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const int ongoingNotificationId = 1001;
  static const int alertNotificationId = 1002;

  static const String ongoingChannelId = 'patro_lockscreen_banner_channel';
  static const String alertChannelId = 'patro_alert_channel';

  factory NotificationService() {
    return instance;
  }

  NotificationService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handled when user taps notification
      },
    );

    _isInitialized = true;
    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// 1. Persistent / Ongoing Notification Banner (Visible on Lock Screen & Status Bar)
  Future<void> showOngoingDateBanner(TodayInfo today, {String statusIconNumeral = 'Latin'}) async {
    await initialize();

    final int dayNumber = today.bs.day;
    final String dayIcon = (statusIconNumeral == "Devanagari") ? "day_dev_$dayNumber" : "day_$dayNumber";

    final String title = "${today.dayText} ${today.monthName} ${today.yearText}, ${today.weekdayName}";
    final String gMonth = Nepali.gregorianShortMonths[today.gregorian.month - 1];
    final String body = "${today.gregorian.day} $gMonth ${today.gregorian.year} AD";

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      ongoingChannelId,
      'दैनिक पात्रो ब्यानर (Lock Screen Banner)',
      channelDescription: 'लक-स्क्रिन र नोटिफिकेसन बारमा आजको मिति देखाउँछ',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ongoing: true, // Cannot be accidentally swiped away
      autoCancel: false,
      visibility: NotificationVisibility.public, // Fully visible on Locked Screen!
      showWhen: false,
      playSound: false,
      enableVibration: false,
      icon: dayIcon,
      largeIcon: DrawableResourceAndroidBitmap(dayIcon),
      number: dayNumber,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
      ),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: ongoingNotificationId,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  /// 2. Normal Alert Notification (Popup / Heads-Up Banner with Sound)
  Future<void> showNormalAlert(TodayInfo today, {String statusIconNumeral = 'Latin'}) async {
    await initialize();

    final int dayNumber = today.bs.day;
    final String dayIcon = (statusIconNumeral == "Devanagari") ? "day_dev_$dayNumber" : "day_$dayNumber";

    final String title = "आज: ${today.dayText} ${today.monthName} ${today.yearText}";
    final String gMonth = Nepali.gregorianShortMonths[today.gregorian.month - 1];
    final String body =
        "${today.cleanYearLabel} (${today.weekdayName}) · ${today.gregorian.day} $gMonth ${today.gregorian.year} AD";

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      alertChannelId,
      'दैनिक मिति सूचना (Daily Date Alerts)',
      channelDescription: 'दैनिक बिहानको मिति सूचना',
      importance: Importance.high,
      priority: Priority.high,
      visibility: NotificationVisibility.public, // Shown on lock screen
      playSound: true,
      enableVibration: true,
      icon: dayIcon,
      largeIcon: DrawableResourceAndroidBitmap(dayIcon),
      number: dayNumber,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
      ),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: alertNotificationId,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  /// Cancel Ongoing Banner
  Future<void> cancelOngoingBanner() async {
    await _notificationsPlugin.cancel(id: ongoingNotificationId);
  }
}
