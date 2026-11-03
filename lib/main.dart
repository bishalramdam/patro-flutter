// main.dart
// Entry point for Patro Mobile (Flutter) - Android & iOS.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'engine/patro_engine.dart';
import 'services/notification_service.dart';
import 'ui/calendar_view.dart';
import 'ui/converter_view.dart';
import 'ui/settings_view.dart';
import 'widgets/home_screen_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize unified engine
  final engine = PatroEngine.instance;

  // Background update home screen widgets
  HomeScreenWidgetHelper.updateWidgets(engine);

  // Initialize offline notifications & show persistent lock-screen banner
  try {
    final prefs = await SharedPreferences.getInstance();
    final bool showBanner = prefs.getBool('show_lockscreen_banner') ?? true;
    final String statusIconNumeral = prefs.getString('status_bar_numeral') ?? 'Latin';
    final notifService = NotificationService.instance;
    await notifService.initialize();

    if (showBanner) {
      final today = engine.getToday();
      await notifService.showOngoingDateBanner(today, statusIconNumeral: statusIconNumeral);
    }
  } catch (e) {
    print("Notification initialization notice: $e");
  }

  runApp(PatroApp(engine: engine));
}

class PatroApp extends StatefulWidget {
  final PatroEngine engine;

  const PatroApp({Key? key, required this.engine}) : super(key: key);

  @override
  State<PatroApp> createState() => _PatroAppState();
}

class _PatroAppState extends State<PatroApp> {
  int _currentIndex = 0;

  void _onStateChanged() {
    setState(() {});
    HomeScreenWidgetHelper.updateWidgets(widget.engine);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'पात्रो',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF6F8FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F141C),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
          brightness: Brightness.dark,
        ),
      ),
      home: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            CalendarView(engine: widget.engine, onStateChanged: _onStateChanged),
            ConverterView(engine: widget.engine),
            SettingsView(engine: widget.engine, onStateChanged: _onStateChanged),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E2530)
              : Colors.white,
          elevation: 8,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded, color: Color(0xFF007AFF)),
              label: 'पात्रो',
            ),
            NavigationDestination(
              icon: Icon(Icons.swap_horiz_outlined),
              selectedIcon: Icon(Icons.swap_horiz_rounded, color: Color(0xFF007AFF)),
              label: 'रूपान्तरक',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded, color: Color(0xFF007AFF)),
              label: 'सेटिङ',
            ),
          ],
        ),
      ),
    );
  }
}
