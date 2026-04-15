import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class ZoneCadeaux extends StatefulWidget {
  final Future<void> Function(String code) onUtiliserCode;

  const ZoneCadeaux({super.key, required this.onUtiliserCode});

  @override
  ZoneCadeauxState createState() => ZoneCadeauxState();
}

class ZoneCadeauxState extends State<ZoneCadeaux> {
  final TextEditingController _codeCtrl = TextEditingController();
  bool _chargement = false;

  @override
  void initState() {
    super.initState();
    _codeCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _gererUtilisation() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _chargement = true);
    try {
      await widget.onUtiliserCode(code);
      _codeCtrl.clear();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
        boxShadow: theme.brightness == Brightness.light ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            provider.t("titre_zone_cadeaux"),
            style: GoogleFonts.playfairDisplay(
              fontSize: 22, 
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: provider.t("ph_code"),
                    hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3)),
                    filled: true,
                    fillColor: theme.brightness == Brightness.light ? const Color(0xFFF4F4F5) : const Color(0xFF27272A),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _gererUtilisation(),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _chargement || _codeCtrl.text.trim().isEmpty ? null : _gererUtilisation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: theme.brightness == Brightness.light ? Colors.white : Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: _chargement
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: theme.brightness == Brightness.light ? Colors.white : Colors.black, strokeWidth: 2))
                      : Text(provider.t("btn_utiliser").toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
