import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../translations/translations.dart';
import '../services/api_service.dart';

class NotificationData {
  final bool visible;
  final String message;
  final String type; // 'succes' or 'erreur'

  NotificationData({this.visible = false, this.message = '', this.type = 'succes'});
}

class AppProvider with ChangeNotifier {
  String _theme = "dark";
  String _langue = "fr";
  Map<String, dynamic>? _donneesUtilisateur;
  bool _isLoadingUtilisateur = true;
  SharedPreferences? _prefs;

  NotificationData _notification = NotificationData();
  String _vueActive = "accueil";
  String? _imageZoomee;

  // Timer Défis
  int _tempsRestantDefi = 30;
  Timer? _timerDefi;
  String? _questionIdActive;

  // Caches
  Map<String, dynamic>? _cacheQuestion;
  String? _dateCacheQuestion;
  
  List<dynamic>? _cacheClassement;
  DateTime? _derniereMAJClassement;

  int get tempsRestantDefi => _tempsRestantDefi;
  bool get timerActif => _timerDefi != null;

  Map<String, dynamic>? get cacheQuestion => _cacheQuestion;
  String? get dateCacheQuestion => _dateCacheQuestion;

  List<dynamic>? get cacheClassement => _cacheClassement;
  DateTime? get derniereMAJClassement => _derniereMAJClassement;

  String get theme => _theme;
  String get langue => _langue;
  Map<String, dynamic>? get donneesUtilisateur => _donneesUtilisateur;
  bool get isLoadingUtilisateur => _isLoadingUtilisateur;
  NotificationData get notification => _notification;
  String get vueActive => _vueActive;
  String? get imageZoomee => _imageZoomee;

  AppProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _theme = _prefs?.getString("theme") ?? "dark";
    _langue = _prefs?.getString("langue") ?? "fr";
    
    final savedUser = _prefs?.getString("utilisateur");
    if (savedUser != null) {
      try {
        _donneesUtilisateur = jsonDecode(savedUser);
        // Lancement du préchargement en arrière-plan
        preChargerDonnees();
      } catch (e) {
        _donneesUtilisateur = null;
      }
    }

    final savedQ = _prefs?.getString("cache_question");
    if (savedQ != null) {
      try {
        _cacheQuestion = jsonDecode(savedQ);
        _dateCacheQuestion = _prefs?.getString("date_cache_question");
      } catch (_) {}
    }

    _isLoadingUtilisateur = false;
    notifyListeners();
  }

  String t(String cle) {
    return Translations.data[_langue]?[cle] ?? cle;
  }

  Future<void> basculerTheme() async {
    _theme = _theme == "dark" ? "light" : "dark";
    await _prefs?.setString("theme", _theme);
    notifyListeners();
  }

  Future<void> basculerLangue() async {
    _langue = _langue == "fr" ? "en" : "fr";
    await _prefs?.setString("langue", _langue);
    notifyListeners();
  }

  void setDonneesUtilisateur(Map<String, dynamic>? utilisateur) {
    _donneesUtilisateur = utilisateur;
    
    // Effacer les caches pour éviter que le nouvel utilisateur ne voie les données du précédent
    _cacheQuestion = null;
    _dateCacheQuestion = null;
    _cacheClassement = null;
    _derniereMAJClassement = null;
    _prefs?.remove("cache_question");
    _prefs?.remove("date_cache_question");

    if (utilisateur != null) {
      _prefs?.setString("utilisateur", jsonEncode(utilisateur));
      preChargerDonnees();
    } else {
      _prefs?.remove("utilisateur");
    }
    notifyListeners();
  }

  void afficherNotification(String message, {String type = "succes"}) {
    _notification = NotificationData(visible: true, message: message, type: type);
    notifyListeners();
    
    Future.delayed(const Duration(seconds: 3), () {
      _notification = NotificationData(visible: false, message: '', type: 'succes');
      notifyListeners();
    });
  }

  void changerVue(String vue) {
    _vueActive = vue;
    notifyListeners();
  }

  void setImageZoomee(String? image) {
    _imageZoomee = image;
    notifyListeners();
  }

  void demarrerMinuteurDefi(String questionId, String userId) {
    if (_timerDefi != null && _questionIdActive == questionId) return;
    
    arreterMinuteurDefi();
    _questionIdActive = questionId;
    _tempsRestantDefi = 30;
    
    _timerDefi = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_tempsRestantDefi > 0) {
        _tempsRestantDefi--;
        notifyListeners();
      } else {
        final qId = _questionIdActive;
        arreterMinuteurDefi();
        if (qId != null) {
          try {
            await ApiService.soumettreReponse(
              userId: userId,
              questionId: qId,
              reponse: "",
            );
            // Rafraîchir les stats après soumission automatique
            final stats = await ApiService.obtenirStatsUtilisateur(userId);
            setDonneesUtilisateur({..._donneesUtilisateur!, ...stats});
          } catch (_) {}
        }
      }
    });
    notifyListeners();
  }

  void arreterMinuteurDefi() {
    _timerDefi?.cancel();
    _timerDefi = null;
    notifyListeners();
  }

  void setCacheQuestion(Map<String, dynamic>? data, String date) {
    _cacheQuestion = data;
    _dateCacheQuestion = date;
    if (data != null) {
      _prefs?.setString("cache_question", jsonEncode(data));
      _prefs?.setString("date_cache_question", date);
    } else {
      _prefs?.remove("cache_question");
      _prefs?.remove("date_cache_question");
    }
    notifyListeners();
  }

  void setCacheClassement(List<dynamic>? data) {
    _cacheClassement = data;
    _derniereMAJClassement = DateTime.now();
    notifyListeners();
  }

  /// Précharge les données essentielles en arrière-plan
  Future<void> preChargerDonnees() async {
    final userId = _donneesUtilisateur?['id'];
    if (userId == null) return;

    final idStr = userId.toString();

    // 1. Rafraîchir les stats de l'utilisateur
    ApiService.obtenirStatsUtilisateur(idStr).then((stats) {
      if (_donneesUtilisateur != null) {
        setDonneesUtilisateur({..._donneesUtilisateur!, ...stats});
      }
    }).catchError((_) {});

    // 2. Précharger la question du jour si non présente ou périmée
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (_cacheQuestion == null || _dateCacheQuestion != today) {
       ApiService.obtenirQuestionDuJour(idStr).then((data) {
         setCacheQuestion(data, today);
       }).catchError((_) {});
    }

    // 3. Précharger le premier top 10 du classement
    ApiService.obtenirUtilisateurs(page: 1, limite: 10).then((rep) {
      final liste = rep['users'] ?? rep['data'] ?? [];
      setCacheClassement(liste);
    }).catchError((_) {});
  }
}
