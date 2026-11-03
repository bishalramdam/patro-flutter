// settings_view.dart
// Settings, Numerals Preferences, and In-App GitHub Data Sync.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../engine/bikram.dart';
import '../engine/calendar_data.dart';
import '../engine/patro_engine.dart';

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

  Future<void> _checkGithubUpdate() async {
    setState(() {
      _isCheckingUpdate = true;
      _syncStatusMessage = "GitHub बाट नयाँ पात्रो डेटा जाँचिँदैछ...";
      _syncSuccess = false;
    });

    try {
      final url = Uri.parse("https://raw.githubusercontent.com/yogeshojha/patro/main/CalendarData.js");
      final response = await http.get(url).timeout(const Duration(seconds: 10));

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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F141C) : const Color(0xFFF6F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "सेटिङ",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Preference Section
            _buildSectionHeader("अङ्क तथा भाषा (Appearance & Language)", isDark),
            const SizedBox(height: 8),
            Container(
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
                children: [
                  ListTile(
                    title: const Text("अङ्क शैली (Numerals)"),
                    subtitle: Text(
                      widget.engine.numerals == "Devanagari" ? "देवनागरी (०१२३४५६७८९)" : "ल्याटिन (0123456789)",
                    ),
                    trailing: DropdownButton<String>(
                      value: widget.engine.numerals,
                      underline: const SizedBox(),
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
                  const Divider(height: 1),
                  ListTile(
                    title: const Text("भाषा (Language)"),
                    subtitle: Text(widget.engine.language == "Nepali" ? "नेपाली (Nepali)" : "English"),
                    trailing: DropdownButton<String>(
                      value: widget.engine.language,
                      underline: const SizedBox(),
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
            const SizedBox(height: 24),

            // In-app GitHub Sync Section
            _buildSectionHeader("पात्रो डेटा अद्यावधिक (Zero-Rebuild GitHub Sync)", isDark),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sync_rounded, color: Color(0xFF007AFF), size: 24),
                      const SizedBox(width: 8),
                      Text(
                        "पञ्चाङ्ग समिति डेटा सिङ्क",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "पञ्चाङ्ग समितिले २०८४ को नयाँ पात्रो निकाल्दा Play Store / App Store मा एप अपडेट नगरिकनै यो १-क्लिक सिङ्कमार्फत नयाँ वर्षको आधिकारिक दिनहरू स्वतः डाउनलोड हुन्छ।",
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildBadge("प्रमाणित: ${CalendarData.attestedThrough} सम्म", const Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      _buildBadge("स्वीकृत: ${CalendarData.publishedThrough} सम्म", const Color(0xFF007AFF)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isCheckingUpdate ? null : _checkGithubUpdate,
                    icon: _isCheckingUpdate
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.download_rounded, size: 20),
                    label: Text(
                      _isCheckingUpdate ? "जाँचिँदैछ..." : "नयाँ डेटा जाँच्नुहोस् (Check GitHub)",
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
                        color: _syncSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Home Screen Widget info
            _buildSectionHeader("होम-स्क्रिन विजेट (Home Screen Widgets)", isDark),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.widgets_rounded, color: Color(0xFF007AFF), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        "विजेट थप्ने तरिका",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "१. आफ्नो मोबाइलको होम स्क्रिनमा केही सेकेन्ड थिचिराख्नुहोस् (Long-press)।\n२. '+' वा 'Widgets' बटनमा थिच्नुहोस्।\n३. 'पात्रो' (Patro) छान्नुहोस् र २x२ वा ४x२ विजेट रोज्नुहोस्।\n४. मध्यरात १२:०० बजे विजेटले स्वतः नयाँ मिति देखाउँछ।",
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark ? Colors.white70 : const Color(0xFF4B5563),
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
          color: isDark ? Colors.white54 : const Color(0xFF6B7280),
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
