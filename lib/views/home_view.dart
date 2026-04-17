import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../components/badge_streak.dart';
import '../components/carte_question.dart';
import 'package:share_plus/share_plus.dart';
import '../services/notification_service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  HomeViewState createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> {
  String _question = "";
  String _questionId = "";
  String _categorie = "";
  String _reponseCorrecte = "";
  String _explication = "";
  bool _chargement = true;
  String _etat = "actif";
  bool _pretPourDefi = false;

  @override
  void initState() {
    super.initState();
    _chargerQuestion();
  }

  Future<void> _chargerQuestion() async {
    final provider = context.read<AppProvider>();
    final userId = provider.donneesUtilisateur?['id'];
    if (userId == null) return;

    final today = DateTime.now().toIso8601String().split('T')[0];
    
    // Vérifier le cache
    if (provider.cacheQuestion != null && provider.dateCacheQuestion == today) {
      _appliquerDonneesQuestion(provider.cacheQuestion!);
      return;
    }

    setState(() => _chargement = true);

    try {
      final data = await ApiService.obtenirQuestionDuJour(userId.toString());
      provider.setCacheQuestion(data, today);
      _appliquerDonneesQuestion(data);
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  void _appliquerDonneesQuestion(Map<String, dynamic> data) async {
    final provider = context.read<AppProvider>();
    final userId = provider.donneesUtilisateur?['id'];
    
    if (data['alreadyPlayed'] == true) {
      final prefs = await SharedPreferences.getInstance();
      final dernierEtat = prefs.getString("etat_$userId") ?? "succes";
      
      // Si déjà joué aujourd'hui, on programme le rappel pour demain
      NotificationService.programmerRappelQuotidien(demain: true);

      if (mounted) {
        setState(() {
          _etat = dernierEtat;
          if (dernierEtat == "echec") {
            _reponseCorrecte = prefs.getString("rep_$userId") ?? "";
            _explication = prefs.getString("expl_$userId") ?? "";
          }
          _chargement = false;
        });
      }
    } else {
      // Sinon on programme pour aujourd'hui (18h)
      NotificationService.programmerRappelQuotidien(demain: false);
      if (mounted) {
        setState(() {
          _question = data['content'] ?? "";
          _questionId = data['id']?.toString() ?? "";
          _categorie = data['category'] ?? "";
          _etat = "actif";
          _pretPourDefi = false; // Attendre le clic sur Commencer
          _chargement = false;
        });
      }
    }
  }

  void _demarrerDefi() {
    final provider = context.read<AppProvider>();
    final userId = provider.donneesUtilisateur?['id'];
    if (userId == null) return;

    setState(() => _pretPourDefi = true);
    provider.demarrerMinuteurDefi(_questionId, userId.toString());
  }

  Future<void> _gererSoumission({required String reponse}) async {
    final provider = context.read<AppProvider>();
    final userId = provider.donneesUtilisateur?['id'];
    if (userId == null) return;

    try {
      final data = await ApiService.soumettreReponse(
        userId: userId.toString(),
        questionId: _questionId,
        reponse: reponse,
      );
      provider.arreterMinuteurDefi();

      final prefs = await SharedPreferences.getInstance();

      if (data['newTotalScore'] != null) {
        final u = Map<String, dynamic>.from(provider.donneesUtilisateur!);
        u['total_score'] = data['newTotalScore'];
        provider.setDonneesUtilisateur(u);
      }

      final rep = data['correctAnswer'] ?? "";
      final expl = data['explanation'] ?? "";

      if (data['isCorrect'] == true) {
        await prefs.setString("etat_$userId", "succes");
        provider.afficherNotification("Correct ! +${data['pointsEarned']} pts", type: "succes");
        NotificationService.programmerRappelQuotidien(demain: true);
        if (mounted) setState(() => _etat = "succes");
        
        // Refresh stats
        try {
          final stats = await ApiService.obtenirStatsUtilisateur(userId.toString());
          final u = Map<String, dynamic>.from(provider.donneesUtilisateur!);
          u.addAll(stats);
          provider.setDonneesUtilisateur(u);
        } catch (_) {}
      } else {
        await prefs.setString("etat_$userId", "echec");
        await prefs.setString("rep_$userId", rep);
        await prefs.setString("expl_$userId", expl);
        NotificationService.programmerRappelQuotidien(demain: true);
        
        if (mounted) {
          setState(() {
            _reponseCorrecte = rep;
            _explication = expl;
            _etat = "echec";
          });
        }
        provider.afficherNotification("Mauvaise réponse !", type: "erreur");
      }
    } catch (e) {
      provider.afficherNotification("Une erreur est survenue, réessaie.", type: "erreur");
    }
  }


  void _gererPartage() {
    final texte = "Le Daily Muse m'a mis en difficulté aujourd'hui\n❓ « $_question »\nOn compare nos scores ?\ndaily-hazel.vercel.app";
    Share.share(texte);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      provider.t("titre_enigme"),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  BadgeStreak(streak: provider.donneesUtilisateur?['streak'] ?? 0),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            if (_chargement)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(60.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_etat == "actif" && !_pretPourDefi)
              _buildEcranDemarrage(theme)
            else
              CarteQuestion(
                etat: _etat,
                question: _question,
                categorie: _categorie,
                reponseCorrecte: _reponseCorrecte,
                explication: _explication,
                onSoumettre: _gererSoumission,
                onPartager: _gererPartage,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEcranDemarrage(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(PhosphorIcons.timer(), size: 48, color: theme.primaryColor),
          ),
          const SizedBox(height: 24),
          Text(
            "Prêt pour le défi ?",
            style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            "Le chrono de 30 secondes démarrera dès que vous aurez chargé l'énigme.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5), height: 1.5),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _demarrerDefi,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: theme.scaffoldBackgroundColor,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text("COMMENCER", style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }
}
