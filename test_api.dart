import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  var baseUrl = 'http://127.0.0.1:8000/api';
  print('1. Tentative de login...');
  var response = await http.post(
    Uri.parse('$baseUrl/login'),
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    body: jsonEncode({'email': 'admin@test.com', 'password': 'password'}),
  );
  print('Status: ${response.statusCode}');
  print('Body: ${response.body}');
  if (response.statusCode != 200) return;

  var token = jsonDecode(response.body)['access_token'];
  print('\n2. Tentative envoi FCM Token...');
  var fcmResponse = await http.post(
    Uri.parse('$baseUrl/device-tokens'),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({'token': 'dummy_fcm_token_123', 'platform': 'android'}),
  );
  print('Status: ${fcmResponse.statusCode}');
  print('Body: ${fcmResponse.body}');
}
