import 'api_service.dart';

/// Handles user profile CRUD operations.
class ProfileService {
  /// Fetch the current user's profile.
  static Future<Map<String, dynamic>> getProfile() async {
    return await ApiService.get('/profile');
  }

  /// Create or update the user's profile.
  static Future<Map<String, dynamic>> saveProfile({
    required String name,
    required String age,
    required String gender,
    required String heightCm,
    required String weightKg,
    required String goal,
    required String allergy,
    required String diet,
    required String country,
  }) async {
    return await ApiService.post(
      '/profile',
      body: {
        'name': name,
        'age': age,
        'gender': gender,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'goal': goal,
        'allergy': allergy,
        'diet': diet, 
        'country': country,
      },
    );
  }
}
