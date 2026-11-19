// main.dart
// Entry point for Patro Mobile (Flutter) - Android & iOS.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'engine/patro_engine.dart';
import 'services/notification_service.dart';
import 'ui/calendar_view.dart';
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

  // Render UI immediately so the app opens instantly on any device
  runApp(PatroApp(engine: engine));

  // Background services initialized asynchronously without blocking startup
  Future.microtask(() async {
    try {
      await HomeScreenWidgetHelper.updateWidgets(engine);
    } catch (e) {
      // Silently catch widget sync exceptions
    }

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
      // Silently catch notification initialization exceptions
    }
  });
}

class PatroApp extends StatelessWidget {
  final PatroEngine engine;

  const PatroApp({Key? key, required this.engine}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calendar',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F5F7),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF18181B),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          background: Colors.black,
          surface: Color(0xFF121316),
          primary: Colors.white,
          secondary: Color(0xFFD71921),
        ),
      ),
      home: PatroHomeScreen(engine: engine),
    );
  }
}

class PatroHomeScreen extends StatefulWidget {
  final PatroEngine engine;

  const PatroHomeScreen({Key? key, required this.engine}) : super(key: key);

  @override
  State<PatroHomeScreen> createState() => _PatroHomeScreenState();
}

class _PatroHomeScreenState extends State<PatroHomeScreen> {
  int _currentIndex = 0;

  void _onStateChanged() {
    setState(() {});
    HomeScreenWidgetHelper.updateWidgets(widget.engine);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF4F5F7),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          CalendarView(engine: widget.engine, onStateChanged: _onStateChanged),
          SettingsView(engine: widget.engine, onStateChanged: _onStateChanged),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.black : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF222428) : const Color(0xFFE5E7EB),
              width: 0.8,
            ),
          ),
        ),
        child: SafeArea(
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: Colors.transparent,
              indicatorColor: isDark ? const Color(0xFF22242A) : const Color(0xFFE5E7EB),
              indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              iconTheme: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return const IconThemeData(
                    color: Colors.white,
                    size: 22,
                  );
                }
                return IconThemeData(
                  color: isDark ? const Color(0xFF71717A) : const Color(0xFF9CA3AF),
                  size: 22,
                );
              }),
              labelTextStyle: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF18181B),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  );
                }
                return TextStyle(
                  color: isDark ? const Color(0xFF71717A) : const Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              height: 60,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.calendar_today_outlined),
                  selectedIcon: const Icon(Icons.calendar_today_rounded),
                  label: widget.engine.language == 'English' ? 'Calendar' : 'क्यालेन्डर',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings_rounded),
                  label: widget.engine.language == 'English' ? 'Settings' : 'सेटिङ',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
