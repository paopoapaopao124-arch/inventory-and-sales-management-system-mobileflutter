import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/product.dart';

class ApiService {
  static const String _baseUrl = AppConfig.apiBaseUrl;
  static final Map<String, String> _sessionCookies = {};

  static void _storeSessionCookies(http.Response response) {
    final rawCookieHeader = response.headers['set-cookie'];
    if (rawCookieHeader == null || rawCookieHeader.isEmpty) {
      return;
    }

    for (final cookieEntry in rawCookieHeader.split(',')) {
      final cookieParts = cookieEntry.split(';');
      final cookie = cookieParts.first.trim();
      if (!cookie.contains('=')) {
        continue;
      }

      final equalsIndex = cookie.indexOf('=');
      final name = cookie.substring(0, equalsIndex).trim();
      final value = cookie.substring(equalsIndex + 1).trim();

      if (name.isNotEmpty) {
        _sessionCookies[name] = value;
      }
    }
  }

  static Map<String, String> _headers({bool includeSession = true}) {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (includeSession && _sessionCookies.isNotEmpty) {
      headers['Cookie'] = _sessionCookies.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join('; ');
    }

    return headers;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: _headers(includeSession: false),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    _storeSessionCookies(response);

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return body as Map<String, dynamic>;
    }

    final message = body is Map && body.containsKey('message')
        ? body['message']
        : 'Authentication failed.';

    throw Exception(message);
  }

  static Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/password/forgot'),
      headers: _headers(includeSession: false),
      body: jsonEncode({
        'email': email,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{};
    }

    final message = body is Map && body.containsKey('message')
        ? body['message']
        : 'Unable to send the reset link.';

    throw Exception(message);
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/password/reset'),
      headers: _headers(includeSession: false),
      body: jsonEncode({
        'email': email,
        'token': token,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{};
    }

    final message = body is Map && body.containsKey('message')
        ? body['message']
        : 'Unable to reset the password.';

    throw Exception(message);
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String municipality,
    required String barangay,
    required String streetNo,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: _headers(includeSession: false),
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'municipality': municipality,
        'barangay': barangay,
        'street_no': streetNo,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    _storeSessionCookies(response);

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return body as Map<String, dynamic>;
    }

    final message = body is Map && body.containsKey('message')
        ? body['message']
        : 'Registration failed.';

    throw Exception(message);
  }

  static Future<Map<String, dynamic>> fetchCustomerProfile() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/me'),
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Unable to fetch your profile.');
    }

    final body = jsonDecode(response.body);
    if (body is Map && body.containsKey('user') && body['user'] is Map) {
      return Map<String, dynamic>.from(body['user'] as Map);
    }

    throw Exception('Unable to load profile details.');
  }

  static Future<Map<String, dynamic>> updateCustomerProfile({
    required String name,
    required String email,
    required String phone,
    required String barangay,
    required String streetNo,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/profile'),
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'barangay': barangay,
        'street_no': streetNo,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{};
    }

    final message = body is Map && body.containsKey('message')
        ? body['message']
        : 'Unable to update profile.';

    throw Exception(message);
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/change-password'),
      headers: _headers(),
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': confirmPassword,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{};
    }

    final message = body is Map && body.containsKey('message')
        ? body['message']
        : 'Unable to update password.';

    throw Exception(message);
  }

  static Future<List<Product>> fetchProducts() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/products'),
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Unable to fetch products.');
    }

    final parsed = jsonDecode(response.body);
    if (parsed is! List) {
      return const [];
    }

    return parsed
        .map((item) => Product.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  static Future<List<dynamic>> fetchSales() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/sales'),
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Unable to fetch your orders.');
    }

    final parsed = jsonDecode(response.body);
    if (parsed is! List) {
      return const [];
    }

    return parsed;
  }

  static Future<List<dynamic>> createSale({
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    double amountPaid = 0,
  }) async {
    final payload = {
      'payment_method': paymentMethod.toLowerCase(),
      'amount_paid': amountPaid,
      'items': items,
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/sales'),
      headers: _headers(),
      body: jsonEncode(payload),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is List) {
        return body;
      }
      return [body];
    }

    final message = body is Map && body.containsKey('message')
        ? body['message']
        : 'Unable to process order.';

    throw Exception(message);
  }
}
