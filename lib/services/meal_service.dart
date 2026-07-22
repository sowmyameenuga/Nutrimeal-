import 'api_service.dart';

/// Handles meal plan operations.
class MealService {
  /// Get today's meal plan (grouped by breakfast, lunch, dinner).
  static Future<Map<String, dynamic>> getTodayMeals() async {
    return await ApiService.get('/meals');
  }

  /// Get full details for a single meal by ID.
  static Future<Map<String, dynamic>> getMealDetails(int mealId) async {
    return await ApiService.get('/meals/$mealId');
  }

  /// Refresh / regenerate today's meal plan.
  static Future<Map<String, dynamic>> refreshMeals() async {
    return await ApiService.post('/meals/refresh');
  }

  /// Search meals by title.
  static Future<Map<String, dynamic>> searchMeals(String query) async {
    return await ApiService.get('/meals/search?q=$query');
  }

  /// Get AI-powered personalized food recommendations.
  static Future<Map<String, dynamic>> getAIRecommendations({
    required int userId,
    required String diet,
    required String goal,
    required int age,
    required String country,
    String? mealType,
    int topK = 10,
  }) async {
    final Map<String, dynamic> body = {
      'user_id': userId,
      'diet': diet,
      'goal': goal,
      'age': age,
      'country': country,
      'top_k': topK,
    };
    if (mealType != null) {
      body['meal_type'] = mealType;
    }

    return await ApiService.post(
      '/recommend',
      body: body,
    );
  }

  /// Save an AI recommended meal to today's meal plan
  static Future<Map<String, dynamic>> saveMeal(Map<String, dynamic> mealData) async {
    return await ApiService.post(
      '/meals/save',
      body: mealData,
    );
  }

  /// Delete a meal from today's meal plan.
  static Future<Map<String, dynamic>> deleteMeal(int mealId) async {
    return await ApiService.delete('/meals/$mealId');
  }
}

