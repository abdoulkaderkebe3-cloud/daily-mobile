import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onSuccess;

  const AuthScreen({super.key, required this.onSuccess});

  @override
  AuthScreenState createState() => AuthScreenState();
}

class AuthScreenState extends State<AuthScreen> {
  // Modes: "login", "register_init", "register_verify", "forgot_init", "forgot_verify"
  String _mode = "login";

  final TextEditingController _pseudoCtrl = TextEditingController();
  final TextEditingController _identiteCtrl = TextEditingController();
  final TextEditingController _motDePasseCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();

  bool _voirMotDePasse = false;
  bool _chargement = false;
  String _erreur = "";
  String _messageSucces = "";
  String? _sessionId;

  int _tentatives = 0;
  int _tempsRestant = 0;
  Timer? _verrouillageTimer;

  @override
  void dispose() {
    _pseudoCtrl.dispose();
    _identiteCtrl.dispose();
    _motDePasseCtrl.dispose();
    _codeCtrl.dispose();
    _verrouillageTimer?.cancel();
    super.dispose();
  }

  void _reinitialiserChamps(String nouveauMode) {
    setState(() {
      _mode = nouveauMode;
      _erreur = "";
      _messageSucces = "";
      if (nouveauMode == "login" || nouveauMode == "register_init" || nouveauMode == "forgot_init") {
        _motDePasseCtrl.clear();
        _codeCtrl.clear();
      }
    });
  }

  void _lancerVerrouillage() {
    setState(() {
      _tempsRestant = 30; // 30 seconds wait
    });
    _verrouillageTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_tempsRestant > 0) {
          _tempsRestant--;
        } else {
          _tentatives = 0;
          timer.cancel();
        }
      });
    });
  }

  bool _validerFormulaire() {
    if (_mode == "register_init") {
      if (_pseudoCtrl.text.trim().isEmpty) return false;
      if (!_identiteCtrl.text.contains("@")) return false;
      if (_motDePasseCtrl.text.trim().length < 8) return false;
    } else if (_mode == "register_verify" || _mode == "forgot_verify") {
      if (_codeCtrl.text.trim().isEmpty) return false;
      if (_mode == "forgot_verify" && _motDePasseCtrl.text.trim().length < 8) return false;
    } else if (_mode == "forgot_init") {
      if (!_identiteCtrl.text.contains("@")) return false;
    } else {
      if (_identiteCtrl.text.trim().isEmpty) return false;
      if (_motDePasseCtrl.text.trim().isEmpty) return false;
    }
    return true;
  }

  String _traduireErreur(AppProvider provider, dynamic err) {
    // Basic translation, could be improved by parsing exception
    final errStr = err.toString().toLowerCase();
    if (errStr.contains('401')) return provider.t("err_identifiants");
    if (errStr.contains('409')) return provider.t("err_compte_existe");
    if (errStr.contains('404')) return provider.t("err_non_trouve");
    return provider.t("err_generique");
  }

  Future<void> _gererSoumission() async {
    final provider = context.read<AppProvider>();

    if (!_validerFormulaire()) {
      setState(() => _erreur = provider.t("err_remplir_champs"));
      return;
    }

    if (_tempsRestant > 0) {
      setState(() => _erreur = provider.t("err_trop_de_tentatives").replaceAll("{n}", "$_tempsRestant"));
      return;
    }

    setState(() {
      _erreur = "";
      _messageSucces = "";
      _chargement = true;
    });

    try {
      if (_mode == "register_init") {
        final res = await ApiService.inscriptionInitiate(
          pseudo: _pseudoCtrl.text.trim(),
          identite: _identiteCtrl.text.trim(),
          motDePasse: _motDePasseCtrl.text,
        );
        _sessionId = res['sessionId'];
        setState(() {
          _messageSucces = provider.t("msg_otp_envoye");
          _mode = "register_verify";
        });
      } else if (_mode == "register_verify") {
        final res = await ApiService.inscriptionVerify(
          sessionId: _sessionId!,
          code: _codeCtrl.text.trim(),
        );
        provider.setDonneesUtilisateur(res['user']);
        widget.onSuccess();
      } else if (_mode == "forgot_init") {
        try {
          final res = await ApiService.motDePasseOublieInitiate(_identiteCtrl.text.trim());
          _sessionId = res['sessionId'];
        } catch (_) {}
        setState(() {
          _messageSucces = provider.t("msg_reset_envoye");
          _mode = "forgot_verify";
        });
      } else if (_mode == "forgot_verify") {
        await ApiService.motDePasseOublieVerify(
          sessionId: _sessionId!,
          code: _codeCtrl.text.trim(),
          newPassword: _motDePasseCtrl.text,
        );
        setState(() {
          _messageSucces = provider.t("msg_mdp_change");
          _reinitialiserChamps("login");
        });
      } else {
        // Login
        final res = await ApiService.connexion(
          identite: _identiteCtrl.text.trim(),
          motDePasse: _motDePasseCtrl.text,
        );
        setState(() => _tentatives = 0);
        provider.setDonneesUtilisateur(res['user']);
        widget.onSuccess();
      }
    } catch (err) {
      if (_mode == "login") {
        _tentatives++;
        if (_tentatives >= 5) {
          _lancerVerrouillage();
        }
      }
      setState(() => _erreur = _traduireErreur(provider, err));
    } finally {
      setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    context.select<AppProvider, String>((p) => p.langue);
    context.select<AppProvider, String>((p) => p.theme);
    final theme = Theme.of(context);

    String titre = provider.t("titre_connexion");
    String btnTexte = provider.t("btn_connexion");

    if (_mode.startsWith("register")) {
      titre = provider.t("titre_inscription");
      btnTexte = _mode == "register_verify" ? provider.t("btn_verifier_creer") : provider.t("btn_inscription");
    } else if (_mode.startsWith("forgot")) {
      titre = provider.t("titre_oublie");
      btnTexte = _mode == "forgot_verify" ? provider.t("btn_reinitialiser") : provider.t("btn_envoyer_code");
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo Connexion
                Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.dividerColor),
                      boxShadow: theme.brightness == Brightness.light ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ] : null,
                    ),
                    child: Center(
                      child: Icon(PhosphorIcons.asterisk(), color: Colors.black, size: 28),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  provider.t("nom_app"),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  "Viso Studio Community".toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  titre,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                
                if (_erreur.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.warningCircle(), color: const Color(0xFFEF4444), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _erreur,
                            style: GoogleFonts.inter(color: const Color(0xFFEF4444), fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms),

                if (_messageSucces.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.checkCircle(), color: const Color(0xFF10B981), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _messageSucces,
                            style: GoogleFonts.inter(color: const Color(0xFF10B981), fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                  
                // Fields
                if (_mode == "register_init") ...[
                  _buildField(_pseudoCtrl, provider.t("ph_pseudo"), theme),
                  const SizedBox(height: 15),
                ],
                
                if (_mode != "register_verify" && _mode != "forgot_verify") ...[
                  _buildField(_identiteCtrl, _mode == "login" || _mode == "forgot_init" ? provider.t("ph_identite") : "Email", theme),
                  const SizedBox(height: 15),
                ],

                if (_mode == "register_verify" || _mode == "forgot_verify") ...[
                  _buildField(_codeCtrl, provider.t("ph_code_otp"), theme),
                  const SizedBox(height: 15),
                ],

                if (_mode == "login" || _mode == "register_init" || _mode == "forgot_verify") ...[
                  _buildField(
                    _motDePasseCtrl, 
                    _mode == "forgot_verify" ? provider.t("ph_nouveau_mot_de_passe") : provider.t("ph_mot_de_passe"), 
                    theme,
                    obscure: !_voirMotDePasse,
                    suffix: IconButton(
                      icon: Icon(_voirMotDePasse ? PhosphorIcons.eyeSlash() : PhosphorIcons.eye()),
                      onPressed: () => setState(() => _voirMotDePasse = !_voirMotDePasse),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: theme.brightness == Brightness.light ? Colors.white : Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _chargement || _tempsRestant > 0 ? null : _gererSoumission,
                    child: _chargement 
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: theme.brightness == Brightness.light ? Colors.white : Colors.black, strokeWidth: 2))
                      : Text(
                          (_tempsRestant > 0 ? "$_tempsRestant s" : btnTexte).toUpperCase(), 
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                  ),
                ),

                const SizedBox(height: 10),
                
                if (_mode == "login")
                  _buildTextButton(provider.t("mot_de_passe_oublie"), () => _reinitialiserChamps("forgot_init")),

                _buildTextButton(
                  _mode.startsWith("register") ? provider.t("deja_un_compte") : provider.t("pas_de_compte"), 
                  () => _reinitialiserChamps(_mode.startsWith("register") ? "login" : "register_init")
                ),

                if (_mode.startsWith("forgot"))
                  _buildTextButton(provider.t("retour_connexion"), () => _reinitialiserChamps("login")),

                // Footer controls
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildIconBtn(Icon(provider.theme == "dark" ? PhosphorIcons.sun() : PhosphorIcons.moon()), provider.basculerTheme, theme),
                    const SizedBox(width: 12),
                    _buildIconBtn(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIcons.globe(), size: 18),
                          const SizedBox(width: 6),
                          Text(provider.langue.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      provider.basculerLangue,
                      theme,
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, ThemeData theme, {bool obscure = false, Widget? suffix}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: GoogleFonts.inter(fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4)),
        filled: true,
        fillColor: theme.cardColor,
        contentPadding: const EdgeInsets.all(16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.primaryColor),
        ),
        suffixIcon: suffix,
      ),
    );
  }

  Widget _buildTextButton(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildIconBtn(Widget icon, VoidCallback onTap, ThemeData theme) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: icon,
      ),
    );
  }
}
