import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiConfig {
  static String? _cachedBaseUrl;

  static Future<String> getBaseUrl() async {
    if (_cachedBaseUrl != null) {
      return _cachedBaseUrl!;
    }

    // Release Mode
    if (kReleaseMode) {
      _cachedBaseUrl = "https://your-production-api.com/api";
      return _cachedBaseUrl!;
    }

    // Web
    if (kIsWeb) {
      _cachedBaseUrl = "http://127.0.0.1:8000/api";
      return _cachedBaseUrl!;
    }

    // Emulator default
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      const emulatorUrl = "http://10.0.2.2:8000/api";
      final ok = await _probeServer(emulatorUrl);
      if (ok) {
        _cachedBaseUrl = emulatorUrl;
        return _cachedBaseUrl!;
      }
    }

    // Stable fallback LAN IP
    const fallbackHost = "10.142.25.159";
    _cachedBaseUrl = "http://$fallbackHost:8000/api";
    return _cachedBaseUrl!;
  }

  static Future<bool> _probeServer(String url) async {
    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 1));
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }
}
