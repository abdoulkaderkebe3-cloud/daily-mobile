import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  static const String baseUrl = 'https://daily-muse-letb.onrender.com';

  static final http.Client _client = http.Client();

  static Future<Map<String, String>> _getHeaders() async {
    return {
      'Content-Type': 'application/json',
    };
  }

  static Future<dynamic> _post(String endpoint, Map<String, dynamic> body) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return null;
    } else {
      throw Exception('Erreur API: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<dynamic> _get(String endpoint) async {
    final response = await _client.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur API: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<dynamic> _patch(String endpoint, Map<String, dynamic> body) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur API: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<dynamic> _delete(String endpoint) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return null;
    } else {
      throw Exception('Erreur API: ${response.statusCode} - ${response.body}');
    }
  }

  // --- AUTH ---

  static Future<dynamic> connexion({required String identite, required String motDePasse}) async {
    return await _post('/auth/login', {
      'username': identite,
      'password': motDePasse,
    });
  }

  static Future<dynamic> inscriptionInitiate({required String pseudo, required String identite, required String motDePasse}) async {
    return await _post('/auth/register/initiate', {
      'username': pseudo,
      'email': identite,
      'password': motDePasse,
    });
  }

  static Future<dynamic> inscriptionVerify({required String sessionId, required String code}) async {
    return await _post('/auth/register/verify', {
      'sessionId': sessionId,
      'code': code,
    });
  }

  static Future<dynamic> motDePasseOublieInitiate(String emailOrUsername) async {
    return await _post('/auth/password/forgot', {
      'emailOrUsername': emailOrUsername,
    });
  }

  static Future<dynamic> motDePasseOublieVerify({required String sessionId, required String code, required String newPassword}) async {
    return await _post('/auth/password/reset', {
      'sessionId': sessionId,
      'code': code,
      'newPassword': newPassword,
    });
  }

  static Future<void> deconnexion() async {
    try {
      await _post('/auth/logout', {});
    } catch (_) {}
    finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('utilisateur');
    }
  }

  // --- QUESTIONS ---

  static Future<dynamic> skiperQuestion(String userId) async {
    return await _post('/questions/skip', {'userId': userId});
  }

  static Future<dynamic> obtenirQuestionDuJour(String userId) async {
    return await _get('/questions/today/$userId');
  }

  static Future<dynamic> soumettreReponse({required String userId, required String questionId, required String reponse}) async {
    return await _post('/questions/answer', {
      'userId': userId,
      'questionId': questionId,
      'userInput': reponse,
    });
  }

  static Future<dynamic> obtenirQuestions() async {
    return await _get('/questions');
  }

  static Future<dynamic> creerQuestion(Map<String, dynamic> question) async {
    return await _post('/questions', question);
  }

  static Future<dynamic> mettreAJourQuestion(String id, Map<String, dynamic> modifications) async {
    return await _patch('/questions/$id', modifications);
  }

  static Future<dynamic> supprimerQuestion(String id) async {
    return await _delete('/questions/$id');
  }

  // --- UTILISATEURS ---

  static Future<dynamic> obtenirUtilisateurs({int page = 1, int limite = 10}) async {
    final data = await _get('/users?page=$page&limit=$limite');
    if (data is List) {
      return {'users': data, 'totalPages': 1, 'page': 1};
    }
    return data;
  }

  static Future<dynamic> obtenirUtilisateur(String id) async {
    return await _get('/users/$id');
  }

  static Future<dynamic> obtenirStatsUtilisateur(String id) async {
    return await _get('/users/$id/stats');
  }

  static Future<dynamic> mettreAJourUtilisateur(String id, Map<String, dynamic> modifications) async {
    return await _patch('/users/$id', modifications);
  }

  static Future<dynamic> supprimerUtilisateur(String id) async {
    return await _delete('/users/$id');
  }
}
