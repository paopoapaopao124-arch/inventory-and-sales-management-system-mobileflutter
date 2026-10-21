import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String defaultBaseUrl = 'http://192.168.11.187:8000';
  static const String storageKey = 'app_api_base_url';

  static String baseUrl = defaultBaseUrl;
  static String get apiBaseUrl => '$baseUrl/api';

  static String normalizeBaseUrl(String input) {
    final sanitized = input.trim();

    if (sanitized.isEmpty) {
      return defaultBaseUrl;
    }

    return sanitized.replaceAll(RegExp(r'/+$'), '');
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(storageKey);
    baseUrl = normalizeBaseUrl(savedUrl ?? defaultBaseUrl);
  }

  static Future<void> setBaseUrl(String newUrl) async {
    final normalized = normalizeBaseUrl(newUrl);
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(storageKey, normalized);
    baseUrl = normalized;
  }
}
