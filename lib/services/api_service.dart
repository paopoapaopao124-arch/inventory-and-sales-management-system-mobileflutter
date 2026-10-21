import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiService {
  static const String _baseUrl = AppConfig.apiBaseUrl;

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return body as Map<String, dynamic>;
    }

    final message = body is Map && body.containsKey('message')
        ? body['message']
        : 'Authentication failed.';

    throw Exception(message);
  }

  static Future<List<dynamic>> fetchProducts() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/products'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Unable to fetch products.');
    }

    final parsed = jsonDecode(response.body);
    if (parsed is List) {
      return parsed;
    }

    return const [];
  }
}
