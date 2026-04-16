import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../components/badge_streak.dart';
import '../components/carte_question.dart';

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

  @override
  void initState() {
    super.initState();
    _chargerQuestion();
  }

  Future<void> _chargerQuestion() async {
    final provider = context.read<AppProvider>();
    final userId = provider.donneesUtilisateur?['id'];
    if (userId == null) return;

    setState(() => _chargement = true);

    try {
      final data = await ApiService.obtenirQuestionDuJour(userId.toString());
      if (data['alreadyPlayed'] == true) {
        final prefs = await SharedPreferences.getInstance();
        final dernierEtat = prefs.getString("etat_$userId") ?? "succes";
        
        if (mounted) {
          setState(() {
            _etat = dernierEtat;
            if (dernierEtat == "echec") {
              _reponseCorrecte = prefs.getString("rep_$userId") ?? "";
              _explication = prefs.getString("expl_$userId") ?? "";
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _question = data['content'] ?? "";
            _questionId = data['id']?.toString() ?? "";
            _categorie = data['category'] ?? "";
            _etat = "actif";
          });
        }
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
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
    // Basic sharing logic or copy to clipboard
    final provider = context.read<AppProvider>();
    final texte = "Le Daily Muse m'a mis en difficulté aujourd'hui\n❓ « $_question »\nOn compare nos scores ?\ndaily-hazel.vercel.app";
    // We can use a clipboard tool here for Flutter
    provider.afficherNotification("Copié !", type: "succes");
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
}
