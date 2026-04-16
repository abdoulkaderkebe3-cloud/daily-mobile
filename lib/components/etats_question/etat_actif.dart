import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class EtatActif extends StatefulWidget {
  final String question;
  final String categorie;
  final Future<void> Function({required String reponse}) onSoumettre;

  const EtatActif({
    super.key,
    required this.question,
    required this.categorie,
    required this.onSoumettre,
  });

  @override
  EtatActifState createState() => EtatActifState();
}

class EtatActifState extends State<EtatActif> {
  final TextEditingController _reponseCtrl = TextEditingController();
  int _tempsRestant = 30;
  bool _chargement = false;
  Timer? _timer;
  bool _autoSoumis = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _reponseCtrl.addListener(() => setState(() {}));
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      setState(() {
        if (_tempsRestant > 0) {
          _tempsRestant--;
        } else if (!_autoSoumis && !_chargement) {
          _autoSoumis = true;
          _gererSoumission(reponse: "Temps écoulé");
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _reponseCtrl.dispose();
    super.dispose();
  }

  Future<void> _gererSoumission({String? reponse}) async {
    final rep = reponse ?? _reponseCtrl.text;
    if (rep.trim().isEmpty && reponse == null) return;

    setState(() => _chargement = true);
    
    try {
      await widget.onSoumettre(reponse: rep);
    } finally {
      if (mounted) {
        setState(() {
          _chargement = false;
          _reponseCtrl.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isCritical = _tempsRestant <= 10;

    return Column(
      children: [
        if (widget.categorie.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light ? const Color(0xFFF4F4F5) : const Color(0xFF27272A),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Text(
                widget.categorie.toUpperCase(),
                style: GoogleFonts.inter(
                  color: theme.textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        
        Text(
          _tempsRestant > 0 ? "$_tempsRestant s" : "Terminé !",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: isCritical ? const Color(0xFFEF4444) : theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
          ),
        ),
        
        const SizedBox(height: 12),
        
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            widget.question.isEmpty ? "..." : "« ${widget.question} »",
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              height: 1.4,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            children: [
              TextField(
                controller: _reponseCtrl,
                enabled: !_chargement,
                onSubmitted: (_) => _gererSoumission(),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: provider.t("ph_reponse"),
                  hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3)),
                  filled: true,
                  fillColor: theme.cardColor,
                  contentPadding: const EdgeInsets.all(20),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.primaryColor),
                  ),
                ),
              ),
              
              const SizedBox(height: 10),
              
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: (_chargement || _reponseCtrl.text.trim().isEmpty) 
                      ? null 
                      : () => _gererSoumission(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: theme.brightness == Brightness.light ? Colors.white : Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _chargement
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: theme.brightness == Brightness.light ? Colors.white : Colors.black, strokeWidth: 2),
                        )
                      : Text(
                          provider.t("btn_valider").toUpperCase(), 
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
