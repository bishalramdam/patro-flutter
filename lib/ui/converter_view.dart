// converter_view.dart
// Bidirectional BS ↔ AD Date Converter.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../engine/patro_engine.dart';

class ConverterView extends StatefulWidget {
  final PatroEngine engine;

  const ConverterView({Key? key, required this.engine}) : super(key: key);

  @override
  State<ConverterView> createState() => _ConverterViewState();
}

class _ConverterViewState extends State<ConverterView> {
  final TextEditingController _inputController = TextEditingController();
  ConversionResult? _result;
  bool _isBsToAd = true;

  @override
  void initState() {
    super.initState();
    _inputController.text = "2083-07-17";
    _performConversion();
  }

  void _performConversion() {
    String text = _inputController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _result = null;
      });
      return;
    }
    var res = widget.engine.convertDate(text, isBsInput: _isBsToAd);
    setState(() {
      _result = res;
    });
  }

  void _toggleDirection() {
    setState(() {
      _isBsToAd = !_isBsToAd;
      if (_isBsToAd) {
        _inputController.text = "2083-07-17";
      } else {
        _inputController.text = "2026-11-03";
      }
      _performConversion();
    });
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
          "मिति रूपान्तरक",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Direction toggle card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    Text(
                      _isBsToAd ? "विक्रम संवत् ➔ ईस्वी संवत् (BS ➔ AD)" : "ईस्वी संवत् ➔ विक्रम संवत् (AD ➔ BS)",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF007AFF), size: 26),
                      tooltip: "दिशा बदल्नुहोस् (Switch)",
                      onPressed: _toggleDirection,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Input card
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
                    Text(
                      _isBsToAd ? "वि.सं. मिति लेख्नुहोस् (वर्ष-महिना-गते):" : "ई.सं. मिति लेख्नुहोस् (YYYY-MM-DD):",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _inputController,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                      decoration: InputDecoration(
                        hintText: _isBsToAd ? "२०८३-०७-१७ वा 2083-07-17" : "2026-11-03",
                        filled: true,
                        fillColor: isDark ? const Color(0xFF283141) : const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF007AFF)),
                          onPressed: _performConversion,
                        ),
                      ),
                      onChanged: (_) => _performConversion(),
                      onSubmitted: (_) => _performConversion(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Conversion Results
              if (_result != null) ...[
                if (_result!.valid) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2530) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF007AFF).withOpacity(0.3), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF007AFF).withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "रूपान्तरण नतिजा",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF007AFF),
                                letterSpacing: 0.5,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 20, color: Color(0xFF007AFF)),
                              tooltip: "कपी गर्नुहोस्",
                              onPressed: () {
                                String text =
                                    "${_result!.bsFormatted} वि.सं. = ${_result!.gregFormatted} ई.सं. (${_result!.weekdayName})";
                                Clipboard.setData(ClipboardData(text: text));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("नतिजा कपी गरियो: $text"),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                        const Divider(height: 16),
                        const SizedBox(height: 8),

                        _buildResultRow("विक्रम संवत् (BS):", _result!.bsFormatted ?? "", isDark, true),
                        const SizedBox(height: 12),
                        _buildResultRow("ईस्वी संवत् (AD):", "${_result!.gregFormatted} AD", isDark, false),
                        const SizedBox(height: 12),
                        _buildResultRow("बार (Weekday):", _result!.weekdayName ?? "", isDark, false),
                        const SizedBox(height: 12),
                        _buildResultRow("तिथि (Tithi):", _result!.tithiLabel ?? "", isDark, false),

                        if (_result!.observance != null && _result!.observance!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildResultRow("चाडपर्व / बिदा:", _result!.observance!, isDark, false,
                              valueColor: const Color(0xFFEF4444)),
                        ]
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _result!.error ?? "अवैध मिति",
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ]
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, bool isDark, bool isPrimary, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : const Color(0xFF6B7280),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isPrimary ? 16 : 14,
              fontWeight: isPrimary ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? (isDark ? Colors.white : const Color(0xFF111827)),
            ),
          ),
        ),
      ],
    );
  }
}
