import 'dart:convert';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized HTTP client for all API calls.
/// Handles base URL, JWT injection, and JSON encoding.
class ApiService {
  // Android emulator → 10.0.2.2, iOS simulator → localhost, web → localhost
  static String get baseUrl {
    if (kIsWeb) return 'https://nutrimeal-backend-qjqa.onrender.com/api';
    if (Platform.isAndroid) return 'https://nutrimeal-backend-qjqa.onrender.com/api';
    return 'https://nutrimeal-backend-qjqa.onrender.com/api';
  }

  /// Retrieve stored JWT token.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Store JWT token.
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  /// Clear JWT token on logout.
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  /// Check if user is logged in (token exists).
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Build headers with optional JWT.
  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (auth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// GET request.
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    bool auth = true,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _headers(auth: auth),
      ).timeout(const Duration(seconds: 60));
      return _handleResponse(response);
    } on TimeoutException {
      return {'error': 'Server is waking up (takes ~50s). Please try again!', 'statusCode': 408};
    } catch (e) {
      return {'error': 'Connection failed: $e', 'statusCode': 0};
    }
  }

  /// POST request.
  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _headers(auth: auth),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 60));
      return _handleResponse(response);
    } on TimeoutException {
      return {'error': 'Server is waking up (takes ~50s). Please try again!', 'statusCode': 408};
    } catch (e) {
      return {'error': 'Connection failed: $e', 'statusCode': 0};
    }
  }

  /// Parse response JSON and attach status code.
  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        decoded['statusCode'] = response.statusCode;
        return decoded;
      }

      // If the response is a JSON array, wrap it
      if (decoded is List) {
        return {
          'data': decoded,
          'statusCode': response.statusCode,
        };
      }

      return {
        'error': 'Unexpected response format',
        'statusCode': response.statusCode,
      };
    } catch (_) {
      return {
        'error': 'Invalid response from server',
        'statusCode': response.statusCode,
      };
    }
  }
}
