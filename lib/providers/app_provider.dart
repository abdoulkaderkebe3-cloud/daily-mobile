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

  NotificationData _notification = NotificationData();
  String _vueActive = "accueil";
  String? _imageZoomee;

  // Timer Défis
  int _tempsRestantDefi = 30;
  Timer? _timerDefi;
  String? _questionIdActive;

  int get tempsRestantDefi => _tempsRestantDefi;
  bool get timerActif => _timerDefi != null;

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
    final prefs = await SharedPreferences.getInstance();
    _theme = prefs.getString("theme") ?? "dark";
    _langue = prefs.getString("langue") ?? "fr";
    
    final savedUser = prefs.getString("utilisateur");
    if (savedUser != null) {
      try {
        _donneesUtilisateur = jsonDecode(savedUser);
      } catch (e) {
        _donneesUtilisateur = null;
      }
    }
    _isLoadingUtilisateur = false;
    notifyListeners();
  }

  String t(String cle) {
    return Translations.data[_langue]?[cle] ?? cle;
  }

  Future<void> basculerTheme() async {
    _theme = _theme == "dark" ? "light" : "dark";
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("theme", _theme);
    notifyListeners();
  }

  Future<void> basculerLangue() async {
    _langue = _langue == "fr" ? "en" : "fr";
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("langue", _langue);
    notifyListeners();
  }

  void setDonneesUtilisateur(Map<String, dynamic>? utilisateur) {
    _donneesUtilisateur = utilisateur;
    if (utilisateur != null) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString("utilisateur", jsonEncode(utilisateur));
      });
    } else {
      SharedPreferences.getInstance().then((prefs) {
        prefs.remove("utilisateur");
      });
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
}
