import 'api_service.dart';

/// Handles authentication: signup, login, logout, token management.
class AuthService {
  /// Register a new user. Returns the response map.
  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await ApiService.post(
      '/auth/signup',
      body: {
        'name': name,
        'email': email,
        'password': password,
      },
      auth: false,
    );

    // Store token on success
    if (response['statusCode'] == 201 && response['token'] != null) {
      await ApiService.saveToken(response['token']);
    }

    return response;
  }

  /// Login with email and password. Returns the response map.
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiService.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
      auth: false,
    );

    // Store token on success
    if (response['statusCode'] == 200 && response['token'] != null) {
      await ApiService.saveToken(response['token']);
    }

    return response;
  }

  /// Logout: clear token locally and notify server.
  static Future<void> logout() async {
    await ApiService.post('/auth/logout');
    await ApiService.clearToken();
  }

  /// Check if user is authenticated.
  static Future<bool> isLoggedIn() async {
    return await ApiService.isLoggedIn();
  }
}
