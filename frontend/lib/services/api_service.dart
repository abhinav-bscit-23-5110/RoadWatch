import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:roadwatch/core/config/api_config.dart';
import '../core/exceptions/auth_exception.dart';
import 'storage_service.dart';

class ApiService {
  static final http.Client _client = http.Client();
  static String? _cachedBaseUrl;

  static Future<String> get baseUrl async {
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;
    if (kIsWeb) {
      _cachedBaseUrl = 'http://127.0.0.1:8000/api';
    } else {
      _cachedBaseUrl = 'http://10.0.2.2:8000/api';
    }
    return _cachedBaseUrl!;
  }

  static String _networkHelpMessage(String baseUrl) {
    return 'Ensure the backend is running and reachable at $baseUrl.';
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Generic HTTP request handler
  static Future<http.Response> request(
    String endpoint, {
    String method = 'GET',
    Map<String, String>? headers,
    dynamic body,
    bool auth = false,
    Duration timeout = const Duration(seconds: 10),
    bool isMultipart = false,
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
  }) async {
    final base = await baseUrl;
    final url = Uri.parse('$base$endpoint');
    Map<String, String> reqHeaders =
        headers ?? {'Content-Type': 'application/json'};
    if (auth) {
      reqHeaders = {...reqHeaders, ...(await _authHeaders())};
    }
    try {
      http.Response response;
      if (isMultipart) {
        final req = http.MultipartRequest(method, url);
        req.headers.addAll(reqHeaders);
        if (fields != null) req.fields.addAll(fields);
        if (files != null) req.files.addAll(files);
        final streamed = await req.send().timeout(timeout);
        response = await http.Response.fromStream(streamed);
      } else {
        // Automatically JSON encode body maps/lists when JSON content-type is used.
        dynamic requestBody = body;
        if (reqHeaders["Content-Type"]?.contains("application/json") == true &&
            body != null &&
            (body is Map || body is List)) {
          requestBody = jsonEncode(body);
        }

        switch (method) {
          case 'POST':
            response = await _client
                .post(url, headers: reqHeaders, body: requestBody)
                .timeout(timeout);
            break;
          case 'PUT':
            response = await _client
                .put(url, headers: reqHeaders, body: requestBody)
                .timeout(timeout);
            break;
          case 'DELETE':
            response = await _client
                .delete(url, headers: reqHeaders, body: requestBody)
                .timeout(timeout);
            break;
          default:
            response =
                await _client.get(url, headers: reqHeaders).timeout(timeout);
        }
      }
      return response;
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on TimeoutException {
      throw Exception('Request timed out.');
    }
  }

  // REGISTER
  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    final response = await request(
      '/auth/register/',
      method: 'POST',
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      await StorageService.saveLoginData(
        token: data['access'],
        name: data['user']['name'],
        email: data['user']['email'],
      );
      await StorageService.setDemoMode(false);
      return data;
    } else {
      throw Exception(
        data['email']?.first ??
            data['password']?.first ??
            data['detail'] ??
            'Registration failed',
      );
    }
  }

  // LOGIN
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await request(
      '/login/',
      method: 'POST',
      body: jsonEncode({
        "email": email.trim(),
        "password": password.trim(),
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      String? token = data["token"] ?? data["access"];
      if (token == null) {
        throw AuthException("Invalid response format: no token found");
      }

      String name = "User";
      String role = email == 'admin@roadwatch.com' ? 'admin' : 'user';

      if (data["name"] != null) {
        name = data["name"];
      } else if (data["user"] is Map && data["user"]["name"] != null) {
        name = data["user"]["name"];
      }

      if (data["role"] != null) {
        role = data["role"];
      } else if (data["user"] is Map && data["user"]["role"] != null) {
        role = data["user"]["role"];
      }

      await StorageService.saveLoginData(
        token: token,
        name: name,
        email: email,
        role: role,
      );
      await StorageService.setDemoMode(false);
      data['role'] = role; // Ensure role is available for navigation
      return data;
    }

    if (response.statusCode == 401) {
      throw AuthException("Invalid email or password");
    }

    throw AuthException(data["detail"] ?? data["message"] ?? "Login failed");
  }

  // FORGOT PASSWORD
  static Future<void> forgotPassword(String email) async {
    final response = await request(
      '/auth/forgot-password/',
      method: 'POST',
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode == 200) {
      return;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(
        data['detail'] ?? data['email']?.first ?? 'Failed to send reset link',
      );
    }
  }

  static Future<void> checkEmail(String email) async {
    final response = await request(
      '/auth/check-email/',
      method: 'POST',
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode == 200) {
      return;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Email already registered');
    }
  }

  // LOGOUT
  static Future<void> logout() async {
    try {
      await request('/auth/logout/', method: 'POST', auth: true);
    } catch (_) {
      // ignore network issues; local logout still proceeds
    }
  }

  // GET PROFILE (uses stored token)
  static Future<Map<String, dynamic>?> getProfile() async {
    final response = await request('/auth/profile/', auth: true);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  // DASHBOARD
  static Future<Map<String, dynamic>> getDashboard() async {
    final response = await request('/dashboard/', auth: true);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load dashboard');
  }

  // REPORTS (list)
  static Future<List<dynamic>> getReports() async {
    final response = await request('/reports/', auth: true);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to load reports');
  }

  // REPORTS (create)
  static Future<Map<String, dynamic>> createReport({
    required String issueType,
    required String description,
    required String severity,
    required double latitude,
    required double longitude,
    required String locationText,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated');
    }
    final fields = {
      'issue_type': issueType,
      'description': description,
      'severity': severity,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'location_text': locationText,
    };
    final files = <http.MultipartFile>[];
    if (imageBytes != null && imageBytes.isNotEmpty) {
      files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageName ?? 'report.jpg',
        ),
      );
    }
    final response = await request(
      '/reports/',
      method: 'POST',
      isMultipart: true,
      auth: true,
      fields: fields,
      files: files,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return data;
    }
    throw Exception(data['detail'] ?? 'Failed to submit report');
  }

  // REPORTS (delete)
  static Future<void> deleteReport(int reportId) async {
    final response =
        await request('/reports/$reportId/', method: 'DELETE', auth: true);
    if (response.statusCode == 204) {
      return;
    }
    if (response.body.isNotEmpty) {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Failed to delete report');
    }
    throw Exception('Failed to delete report');
  }

  // NOTIFICATIONS
  static Future<List<dynamic>> getNotifications() async {
    final response = await request('/notifications/', auth: true);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to load notifications');
  }

  // UPVOTE
  static Future<void> upvoteReport(int reportId) async {
    final response = await request(
      '/upvote/',
      method: 'POST',
      auth: true,
      body: jsonEncode({'report_id': reportId}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }
    final data = jsonDecode(response.body);
    throw Exception(data['detail'] ?? 'Failed to upvote');
  }
}

class DemoDataProvider {
  static const Map<String, int> stats = {
    'reports': 12,
    'verified': 8,
    'upvotes': 47,
  };

  static const Map<String, String> demoUser = {
    'name': 'Guest User',
    'email': 'guest@roadwatch.demo',
  };

  static const List<Map<String, dynamic>> reports = [
    {
      'id': 1,
      'issue_type': 'Pothole',
      'description': 'Large pothole on busy road',
      'severity': 'High',
      'status': 'Pending',
      'location_text': 'Bandra, Mumbai',
      'latitude': 19.0544,
      'longitude': 72.8404,
      'created_at': '2026-02-06T10:12:00Z',
      'upvotes': 12,
      'verifies': 5,
    },
    {
      'id': 2,
      'issue_type': 'Road Crack',
      'description': 'Deep crack forming along the carriageway',
      'severity': 'Medium',
      'status': 'In Progress',
      'location_text': 'Connaught Place, Delhi',
      'latitude': 28.6324,
      'longitude': 77.2195,
      'created_at': '2026-02-05T18:20:00Z',
      'upvotes': 19,
      'verifies': 6,
    },
    {
      'id': 3,
      'issue_type': 'Waterlogging',
      'description': 'Standing water after recent rain',
      'severity': 'Low',
      'status': 'Resolved',
      'location_text': 'Indiranagar, Bangalore',
      'latitude': 12.9716,
      'longitude': 77.6411,
      'created_at': '2026-02-03T09:05:00Z',
      'upvotes': 7,
      'verifies': 2,
    },
  ];

  static const List<Map<String, dynamic>> notifications = [
    {
      'id': 1,
      'title': 'Your report was verified',
      'message': 'The pothole on MG Road has been verified by 5 users.',
      'created_at': '2026-02-06T12:10:00Z',
      'read': false,
    },
    {
      'id': 2,
      'title': 'Issue status updated',
      'message': 'The flooding issue on Ring Road is now being addressed.',
      'created_at': '2026-02-06T09:20:00Z',
      'read': true,
    },
    {
      'id': 3,
      'title': 'New issue nearby',
      'message': 'A new pothole was reported 500m from your location.',
      'created_at': '2026-02-05T15:40:00Z',
      'read': true,
    },
  ];
}
