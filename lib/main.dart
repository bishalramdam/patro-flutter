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

class PatroApp extends StatelessWidget {
  final PatroEngine engine;

  const PatroApp({Key? key, required this.engine}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'गते',
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
          surface: const Color(0xFF161B22),
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
      backgroundColor: isDark ? const Color(0xFF0F141C) : const Color(0xFFF6F8FA),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          CalendarView(engine: widget.engine, onStateChanged: _onStateChanged),
          ConverterView(engine: widget.engine),
          SettingsView(engine: widget.engine, onStateChanged: _onStateChanged),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B22) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF252E3E) : const Color(0xFFE5E7EB),
              width: 0.8,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            )
          ],
        ),
        child: SafeArea(
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: Colors.transparent,
              indicatorColor: isDark
                  ? const Color(0xFF007AFF).withOpacity(0.24)
                  : const Color(0xFF007AFF).withOpacity(0.12),
              indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              iconTheme: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return IconThemeData(
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF007AFF),
                    size: 24,
                  );
                }
                return IconThemeData(
                  color: isDark ? const Color(0xFF8B949E) : const Color(0xFF6B7280),
                  size: 24,
                );
              }),
              labelTextStyle: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return TextStyle(
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF007AFF),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  );
                }
                return TextStyle(
                  color: isDark ? const Color(0xFF8B949E) : const Color(0xFF6B7280),
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
              height: 64,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month_rounded),
                  label: 'गते',
                ),
                NavigationDestination(
                  icon: Icon(Icons.swap_horiz_outlined),
                  selectedIcon: Icon(Icons.swap_horiz_rounded),
                  label: 'रूपान्तरक',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: 'सेटिङ',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
