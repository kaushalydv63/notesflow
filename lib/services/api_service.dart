import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://your-api-url.com/api';

  static Map<String, String> headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String endpoint, {String? token}) {
    return http
        .get(Uri.parse('$baseUrl$endpoint'), headers: headers(token: token))
        .timeout(const Duration(seconds: 15));
  }

  static Future<http.Response> post(
      String endpoint,
      Map<String, dynamic> body, {
        String? token,
      }) {
    return http
        .post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers(token: token),
      body: jsonEncode(body),
    )
        .timeout(const Duration(seconds: 15));
  }
}