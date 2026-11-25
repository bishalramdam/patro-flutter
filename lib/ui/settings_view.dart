// settings_view.dart
// Settings, Numerals Preferences, and In-App GitHub Data Sync.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../engine/bikram.dart';
import '../engine/calendar_data.dart';
import '../engine/patro_engine.dart';
import '../services/notification_service.dart';
import '../widgets/home_screen_widget.dart';

class SettingsView extends StatefulWidget {
  final PatroEngine engine;
  final VoidCallback onStateChanged;

  const SettingsView({Key? key, required this.engine, required this.onStateChanged}) : super(key: key);

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _isCheckingUpdate = false;
  String _syncStatusMessage = "";
  bool _syncSuccess = false;
  bool _showLockScreenBanner = true;
  String _statusBarNumeral = "Latin";
  double _statusBarIconScale = 90.0;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final legacySize = prefs.getString('status_bar_icon_size') ?? 'Large';
    final int initialScale = prefs.getInt('status_bar_icon_scale') ??
        (legacySize == 'Small' ? 55 : (legacySize == 'Medium' ? 75 : 90));
    setState(() {
      _showLockScreenBanner = prefs.getBool('show_lockscreen_banner') ?? true;
      _statusBarNumeral = prefs.getString('status_bar_numeral') ?? 'Latin';
      _statusBarIconScale = initialScale.clamp(40, 100).toDouble();
    });
  }

  Future<void> _updateStatusBarNumeral(String val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('status_bar_numeral', val);
    setState(() {
      _statusBarNumeral = val;
    });

    if (_showLockScreenBanner) {
      final today = widget.engine.getToday();
      await NotificationService.instance.showOngoingDateBanner(
        today,
        statusIconNumeral: val,
        statusIconScale: _statusBarIconScale.round(),
      );
    }
    await HomeScreenWidgetHelper.updateWidgets(widget.engine);
  }

  Future<void> _updateStatusBarIconScale(int scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('status_bar_icon_scale', scale);
    setState(() {
      _statusBarIconScale = scale.toDouble();
    });

    if (_showLockScreenBanner) {
      final today = widget.engine.getToday();
      await NotificationService.instance.showOngoingDateBanner(
        today,
        statusIconNumeral: _statusBarNumeral,
        statusIconScale: scale,
      );
    }
    await HomeScreenWidgetHelper.updateWidgets(widget.engine);
  }

  Future<void> _toggleLockScreenBanner(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_lockscreen_banner', enabled);
    setState(() {
      _showLockScreenBanner = enabled;
    });

    final isEnglish = widget.engine.language == "English";

    if (enabled) {
      final today = widget.engine.getToday();
      await NotificationService.instance.showOngoingDateBanner(
        today,
        statusIconNumeral: _statusBarNumeral,
        statusIconScale: _statusBarIconScale.round(),
      );
      await HomeScreenWidgetHelper.updateWidgets(widget.engine);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEnglish ? "Lock-screen banner enabled!" : "लक-स्क्रिन ब्यानर सक्रिय भयो!"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      await NotificationService.instance.cancelOngoingBanner();
      await HomeScreenWidgetHelper.updateWidgets(widget.engine);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEnglish ? "Lock-screen banner disabled." : "लक-स्क्रिन ब्यानर निष्क्रिय भयो।"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _sendTestAlert() async {
    final today = widget.engine.getToday();
    final isEnglish = widget.engine.language == "English";
    await NotificationService.instance.showNormalAlert(
      today,
      statusIconNumeral: _statusBarNumeral,
      statusIconScale: _statusBarIconScale.round(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEnglish
              ? "Test notification sent! Swipe down from the top to view."
              : "नोटिफिकेसन ब्यानर पठाइयो! माथि स्क्रिनबाट स्वाइप गरी हेर्नुहोस्।"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _checkGithubUpdate() async {
    setState(() {
      _isCheckingUpdate = true;
      _syncStatusMessage = "GitHub बाट नयाँ क्यालेन्डर डेटा जाँचिँदैछ...";
      _syncSuccess = false;
    });

    try {
      // Primary canonical branch is 'master' on upstream patro repository
      var url = Uri.parse("https://raw.githubusercontent.com/yogeshojha/patro/master/CalendarData.js");
      var response = await http.get(url).timeout(const Duration(seconds: 10));

      // Fallback to 'main' branch if master is not found
      if (response.statusCode != 200) {
        url = Uri.parse("https://raw.githubusercontent.com/yogeshojha/patro/main/CalendarData.js");
        response = await http.get(url).timeout(const Duration(seconds: 10));
      }

      if (response.statusCode == 200) {
        final body = response.body;

        // Extract published through year
        final pubMatch = RegExp(r'var\s+PUBLISHED_THROUGH\s*=\s*(\d+)').firstMatch(body);
        final pubYear = pubMatch != null ? int.parse(pubMatch.group(1)!) : CalendarData.publishedThrough;

        final attMatch = RegExp(r'var\s+ATTESTED_THROUGH\s*=\s*(\d+)').firstMatch(body);
        final attYear = attMatch != null ? int.parse(attMatch.group(1)!) : CalendarData.attestedThrough;

        // Save raw content to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('custom_calendar_data', body);
        await prefs.setInt('custom_published_through', pubYear);
        await prefs.setInt('custom_attested_through', attYear);

        CalendarData.publishedThrough = pubYear;
        CalendarData.attestedThrough = attYear;

        setState(() {
          _isCheckingUpdate = false;
          _syncSuccess = true;
          _syncStatusMessage =
              "सफलतापूर्वक अद्यावधिक भयो! आधिकारिक निर्णय: वि.सं. $pubYear सम्म। (Rebuild आवश्यक छैन)";
        });

        widget.onStateChanged();
      } else {
        setState(() {
          _isCheckingUpdate = false;
          _syncStatusMessage = "डेटा डाउनलोड गर्न सकिएन (HTTP ${response.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        _isCheckingUpdate = false;
        _syncStatusMessage = "सम्पर्क त्रुटि: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEnglish = widget.engine.language == "English";

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF4F5F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          isEnglish ? "Settings" : "सेटिङ",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: -0.3,
            color: isDark ? Colors.white : const Color(0xFF18181B),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Preference Section
            _buildSectionHeader(
              isEnglish ? "Appearance & Language" : "अङ्क तथा भाषा (Appearance & Language)",
              isDark,
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121316) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF222428) : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(isEnglish ? "Numerals" : "अङ्क शैली (Numerals)"),
                        subtitle: Text(
                          widget.engine.numerals == "Devanagari"
                              ? (isEnglish ? "Devanagari (०१२३४५६७८९)" : "देवनागरी (०१२३४५६७८९)")
                              : (isEnglish ? "Latin (0123456789)" : "ल्याटिन (0123456789)"),
                        ),
                        trailing: DropdownButton<String>(
                          value: widget.engine.numerals,
                          underline: const SizedBox(),
                          dropdownColor: isDark ? const Color(0xFF181A1F) : Colors.white,
                          items: const [
                            DropdownMenuItem(value: "Devanagari", child: Text("देवनागरी")),
                            DropdownMenuItem(value: "Latin", child: Text("English")),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                widget.engine.numerals = val;
                              });
                              widget.onStateChanged();
                            }
                          },
                        ),
                      ),
                      Divider(height: 1, color: isDark ? const Color(0xFF222428) : const Color(0xFFE5E7EB)),
                      ListTile(
                        title: Text(isEnglish ? "Language" : "भाषा (Language)"),
                        subtitle: Text(widget.engine.language == "Nepali" ? "नेपाली (Nepali)" : "English"),
                        trailing: DropdownButton<String>(
                          value: widget.engine.language,
                          underline: const SizedBox(),
                          dropdownColor: isDark ? const Color(0xFF181A1F) : Colors.white,
                          items: const [
                            DropdownMenuItem(value: "Nepali", child: Text("नेपाली")),
                            DropdownMenuItem(value: "English", child: Text("English")),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                widget.engine.language = val;
                              });
                              widget.onStateChanged();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Notification Section
            _buildSectionHeader(
              isEnglish ? "Notifications & Lock Screen" : "सूचना तथा ब्यानर (Notifications & Lock Screen)",
              isDark,
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121316) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF222428) : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text(isEnglish ? "Lock Screen Banner" : "लक-स्क्रिन र ब्यानर (Lock Screen Banner)"),
                        subtitle: Text(
                          isEnglish
                              ? "Keep today's date visible in the status bar & lock screen"
                              : "फोन लक हुँदा पनि स्क्रिनमा आजको मिति र बार देखाइराख्ने",
                          style: const TextStyle(fontSize: 12),
                        ),
                        value: _showLockScreenBanner,
                        activeColor: isDark ? Colors.white : const Color(0xFF18181B),
                        onChanged: _toggleLockScreenBanner,
                      ),
                      Divider(height: 1, color: isDark ? const Color(0xFF222428) : const Color(0xFFE5E7EB)),
                      ListTile(
                        leading: Icon(Icons.pin_rounded, color: isDark ? Colors.white : const Color(0xFF18181B)),
                        title: Text(isEnglish ? "Status Bar Icon Numeral" : "स्ट्याटस बार आइकन (Status Bar Icon Day)"),
                        subtitle: Text(
                          _statusBarNumeral == "Latin"
                              ? (isEnglish ? "English digits (17)" : "अंग्रेजी गते (17)")
                              : (isEnglish ? "Nepali digits (१७)" : "नेपाली गते (१७)"),
                        ),
                        trailing: DropdownButton<String>(
                          value: _statusBarNumeral,
                          underline: const SizedBox(),
                          dropdownColor: isDark ? const Color(0xFF181A1F) : Colors.white,
                          items: const [
                            DropdownMenuItem(value: "Latin", child: Text("17 (English)")),
                            DropdownMenuItem(value: "Devanagari", child: Text("१७ (नेपाली)")),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              _updateStatusBarNumeral(val);
                            }
                          },
                        ),
                      ),
                      Divider(height: 1, color: isDark ? const Color(0xFF222428) : const Color(0xFFE5E7EB)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.photo_size_select_large_rounded,
                                  color: isDark ? Colors.white : const Color(0xFF18181B),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    isEnglish ? "Status Bar Icon Size" : "आइकन साइज (Status Bar Icon Size)",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isDark ? Colors.white : const Color(0xFF18181B)).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "${_statusBarIconScale.round()}%",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF18181B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _statusBarIconScale,
                              min: 40,
                              max: 100,
                              divisions: 60,
                              label: "${_statusBarIconScale.round()}%",
                              activeColor: isDark ? Colors.white : const Color(0xFF18181B),
                              inactiveColor: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB),
                              onChanged: (val) {
                                setState(() {
                                  _statusBarIconScale = val;
                                });
                              },
                              onChangeEnd: (val) {
                                _updateStatusBarIconScale(val.round());
                              },
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: isDark ? const Color(0xFF222428) : const Color(0xFFE5E7EB)),
                      ListTile(
                        leading: Icon(Icons.notifications_active_rounded, color: isDark ? Colors.white : const Color(0xFF18181B)),
                        title: Text(isEnglish ? "Test Alert Banner" : "सामान्य सूचना परीक्षण (Test Alert Banner)"),
                        subtitle: Text(
                          isEnglish
                              ? "Send an immediate popup notification to preview"
                              : "तत्काल पप-अप ब्यानर सूचना पठाएर हेर्नुहोस्",
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _sendTestAlert,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // In-app GitHub Sync Section
            _buildSectionHeader(
              isEnglish ? "Calendar Data Sync" : "क्यालेन्डर डेटा अद्यावधिक (Zero-Rebuild GitHub Sync)",
              isDark,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121316) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF222428) : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sync_rounded, color: isDark ? Colors.white : const Color(0xFF18181B), size: 24),
                      const SizedBox(width: 8),
                      Text(
                        isEnglish ? "Panchanga Samiti Data Sync" : "पञ्चाङ्ग समिति डेटा सिङ्क",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF18181B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEnglish
                        ? "Download official new year calendar tables directly with 1 click whenever Panchanga Samiti publishes updates—no app rebuild needed."
                        : "पञ्चाङ्ग समितिले २०८४ को नयाँ क्यालेन्डर निकाल्दा Play Store / App Store मा एप अपडेट नगरिकनै यो १-क्लिक सिङ्कमार्फत नयाँ वर्षको आधिकारिक दिनहरू स्वतः डाउनलोड हुन्छ।",
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildBadge(
                        isEnglish
                            ? "Attested: ${CalendarData.attestedThrough}"
                            : "प्रमाणित: ${CalendarData.attestedThrough} सम्म",
                        const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 8),
                      _buildBadge(
                        isEnglish
                            ? "Published: ${CalendarData.publishedThrough}"
                            : "स्वीकृत: ${CalendarData.publishedThrough} सम्म",
                        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : const Color(0xFF18181B),
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: _isCheckingUpdate ? null : _checkGithubUpdate,
                    icon: _isCheckingUpdate
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: isDark ? Colors.black : Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.download_rounded, size: 20),
                    label: Text(
                      _isCheckingUpdate
                          ? (isEnglish ? "Checking..." : "जाँचिँदैछ...")
                          : (isEnglish ? "Check for Updates (GitHub)" : "नयाँ डेटा जाँच्नुहोस् (Check GitHub)"),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                  if (_syncStatusMessage.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _syncStatusMessage,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _syncSuccess ? const Color(0xFF10B981) : const Color(0xFFFF453A),
                      ),
                    ),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Home Screen Widget info
            _buildSectionHeader(
              isEnglish ? "Home Screen Widgets" : "होम-स्क्रिन विजेट (Home Screen Widgets)",
              isDark,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121316) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF222428) : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.widgets_rounded, color: isDark ? Colors.white : const Color(0xFF18181B), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        isEnglish ? "How to Add Widgets" : "विजेट थप्ने तरिका",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF18181B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEnglish
                        ? "1. Long-press on your phone's home screen.\n2. Tap '+' or 'Widgets'.\n3. Select 'Calendar' and pick a widget.\n4. Widgets update automatically every midnight at 12:00 AM."
                        : "१. आफ्नो मोबाइलको होम स्क्रिनमा केही सेकेन्ड थिचिराख्नुहोस् (Long-press)।\n२. '+' वा 'Widgets' बटनमा थिच्नुहोस्।\n३. 'Calendar' छान्नुहोस् र विजेट रोज्नुहोस्।\n४. मध्यरात १२:०० बजे विजेटले स्वतः नयाँ मिति देखाउँछ।",
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFF71717A) : const Color(0xFF71717A),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
