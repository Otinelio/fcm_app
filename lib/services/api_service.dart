import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  // Récupère l'URL de base depuis le fichier .env
  static String get baseUrl {
    return dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000/api';
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['access_token'] != null) {
          await setToken(data['access_token']);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Erreur de connexion: $e');
      return false;
    }
  }

  static Future<bool> registerDeviceToken(String fcmToken, String platform) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/device-tokens'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'token': fcmToken,
          'platform': platform,
        }),
      );

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print('Erreur enregistrement token: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchNotifications() async {
    try {
      final token = await getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Erreur récupération notifications: $e');
      return [];
    }
  }

  static Future<bool> simulateEvent(String type) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/simulate'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'type': type}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur simulation: $e');
      return false;
    }
  }
}
