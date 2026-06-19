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
import '../components/pull_to_refresh.dart';
import 'package:confetti/confetti.dart';
import '../components/muse_loading_indicator.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  HomeViewState createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  String _question = "";
  String _questionId = "";
  String _categorie = "";
  String _reponseCorrecte = "";
  String _explication = "";
  bool _chargement = true;
  String _etat = "actif";
  bool _pretPourDefi = false;
  String _messageDejaJoue = "";
  String _typeErreur = "";
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _chargerQuestion();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _chargerQuestion({bool isRefresh = false}) async {
    final provider = context.read<AppProvider>();
    
    // Empêcher l'actualisation pendant que le chrono tourne (triche)
    if (provider.timerActif && isRefresh) {
      provider.forcerEchecDefi();
      provider.afficherNotification("Action non autorisée pendant le défi !", type: "erreur");
      return;
    }

    final userId = provider.donneesUtilisateur?['id'];
    if (userId == null) {
      if (mounted && !isRefresh) setState(() => _chargement = false);
      return;
    }

    final today = DateTime.now().toIso8601String().split('T')[0];
    
    // Vérifier le cache
    if (!isRefresh && provider.cacheQuestion != null && provider.dateCacheQuestion == today) {
      _appliquerDonneesQuestion(provider.cacheQuestion!);
      return;
    }

    if (!isRefresh && mounted) {
      setState(() => _chargement = true);
    }

    try {
      final data = await ApiService.obtenirQuestionDuJour(userId.toString());

      if (isRefresh) {
        // Garantir un temps minimum d'affichage de l'animation d'actualisation
        await Future.delayed(const Duration(milliseconds: 600));
      }

      provider.setCacheQuestion(data, today);
      _appliquerDonneesQuestion(data);
    } catch (e) {
      if (e.toString().contains("401") || e.toString().contains("403")) {
        // Session expirée ou invalide -> déconnexion
        ApiService.deconnexion().then((_) {
          if (mounted) provider.setDonneesUtilisateur(null);
        });
        return;
      }
      if (mounted) {
        setState(() {
          _etat = "erreur";
          if (e.toString().contains("SocketException") || e.toString().contains("Failed host lookup") || e.toString().contains("TimeoutException") || e.toString().contains("ClientException") || e.toString().contains("XMLHttpRequest error")) {
            _typeErreur = "internet";
          } else {
            _typeErreur = "backend";
          }
        });
      }
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  void _appliquerDonneesQuestion(Map<String, dynamic> data) async {
    final provider = context.read<AppProvider>();
    final userId = provider.donneesUtilisateur?['id'];
    
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final dateEtat = prefs.getString("date_etat_$userId");
    final dernierEtat = prefs.getString("etat_$userId");
    
    bool aJoueLocalementAujourdhui = (dateEtat == today && dernierEtat != null);

    if (data['alreadyPlayed'] == true || aJoueLocalementAujourdhui) {
      // Load cached question
      final cachedQuestion = prefs.getString("question_$userId");
      
      // Si déjà joué aujourd'hui, on programme le rappel pour demain
      NotificationService.programmerRappelQuotidien(demain: true);

      if (mounted) {
        setState(() {
          if (cachedQuestion != null) _question = cachedQuestion;
          if (dernierEtat == "echec") {
            _etat = "echec";
            _reponseCorrecte = prefs.getString("rep_$userId") ?? "";
            _explication = prefs.getString("expl_$userId") ?? "";
          } else if (dernierEtat == "succes") {
            _etat = "succes";
          } else {
            _etat = "deja_joue";
            _messageDejaJoue = data['message'] ?? "Vous avez déjà joué aujourd'hui !";
          }
          _chargement = false;
        });
      }
    } else {
      // Sinon on programme pour aujourd'hui (18h)
      NotificationService.programmerRappelQuotidien(demain: false);
      
      // Save question for later
      final prefs = await SharedPreferences.getInstance();
      if (data['content'] != null) {
        await prefs.setString("question_$userId", data['content']);
      }

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
    provider.demarrerMinuteurDefi(
      _questionId, 
      userId.toString(),
      onTimeout: () {
        if (mounted) _gererSoumission(reponse: "");
      },
    );
  }

  Future<void> _gererSoumission({required String reponse}) async {
    final provider = context.read<AppProvider>();
    final userId = provider.donneesUtilisateur?['id'];
    if (userId == null) return;

    // Si la réponse est vide (timeout ou triche), on met à jour l'UI instantanément pour bloquer l'interaction
    if (reponse.isEmpty) {
      if (mounted) {
        setState(() {
          _etat = "echec";
          _reponseCorrecte = "...";
          _explication = "Défi échoué (hors délai ou action non autorisée).";
        });
      }
      
      // On envoie cette chaîne de caractères spécifique à l'API en arrière-plan
      reponse = "___TRICHE_OU_TIMEOUT___";
      
      // Sauvegarde immédiate locale pour éviter de rejouer en rechargeant la page
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      await prefs.setString("etat_$userId", "echec");
      await prefs.setString("date_etat_$userId", today);
      await prefs.setString("rep_$userId", "...");
      await prefs.setString("expl_$userId", "Défi échoué (hors délai ou action non autorisée).");
      
      final cachedData = provider.cacheQuestion;
      if (cachedData != null) {
        cachedData['alreadyPlayed'] = true;
        provider.setCacheQuestion(cachedData, today);
      }
    }

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
        final today = DateTime.now().toIso8601String().split('T')[0];
        await prefs.setString("etat_$userId", "succes");
        await prefs.setString("date_etat_$userId", today);
        provider.afficherNotification("Correct ! +${data['pointsEarned']} pts", type: "succes");
        NotificationService.programmerRappelQuotidien(demain: true);
        if (mounted) {
          setState(() => _etat = "succes");
          _confettiController.play();
        }
        
        // Refresh stats
        try {
          final stats = await ApiService.obtenirStatsUtilisateur(userId.toString());
          final u = Map<String, dynamic>.from(provider.donneesUtilisateur!);
          u.addAll(stats);
          provider.setDonneesUtilisateur(u);
        } catch (_) {}
      } else {
        final today = DateTime.now().toIso8601String().split('T')[0];
        await prefs.setString("etat_$userId", "echec");
        await prefs.setString("date_etat_$userId", today);
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
    super.build(context);
    final provider = context.read<AppProvider>();
    context.select<AppProvider, String>((p) => p.langue);
    final isConnected = context.select<AppProvider, bool>((p) => p.donneesUtilisateur?['id'] != null);
    final streak = context.select<AppProvider, int>((p) => p.donneesUtilisateur?['streak'] ?? 0);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
        MuseRefreshControl(onRefresh: () async {
          await _chargerQuestion(isRefresh: true);
        }),
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
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
                    BadgeStreak(streak: streak),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              if (!isConnected)
                _buildNonConnecte(theme, provider)
              else if (_chargement)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(60.0),
                    child: MuseLoadingIndicator(size: 40),
                  ),
                )
              else if (_etat == "erreur")
                _buildErreur(theme, provider)
              else if (_etat == "actif" && !_pretPourDefi)
                _buildEcranDemarrage(theme, provider)
              else
                CarteQuestion(
                  etat: _etat,
                  question: _question,
                  categorie: _categorie,
                  reponseCorrecte: _reponseCorrecte,
                  explication: _explication,
                  messageDejaJoue: _messageDejaJoue,
                  onSoumettre: _gererSoumission,
                  onPartager: _gererPartage,
                ),
            ]),
          ),
        ),
          ],
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.orange, Colors.white, Colors.green],
          ),
        ),
      ],
    );
  }

  Widget _buildErreur(ThemeData theme, AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _typeErreur == "internet" ? PhosphorIcons.wifiSlash() : PhosphorIcons.warningCircle(), 
              size: 64, 
              color: theme.primaryColor.withOpacity(0.1)
            ),
            const SizedBox(height: 24),
            Text(
              _typeErreur == "internet" ? provider.t("err_timeout") : provider.t("err_generique"), 
              style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _typeErreur == "internet" ? provider.t("err_check_internet") : provider.t("err_backend_unavailable"), 
              style: GoogleFonts.inter(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildEcranDemarrage(ThemeData theme, AppProvider provider) {
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
            provider.t("titre_pret"),
            style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            provider.t("msg_chrono_desc"),
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
              child: Text(provider.t("btn_commencer"), style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNonConnecte(ThemeData theme, AppProvider provider) {
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
          Icon(PhosphorIcons.userMinus(), size: 64, color: theme.primaryColor.withOpacity(0.5)),
          const SizedBox(height: 24),
          Text(
            provider.t("titre_veuillez_connecter"),
            style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            provider.t("msg_connectez_vous"),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5), height: 1.5),
          ),
        ],
      ),
    );
  }
}
