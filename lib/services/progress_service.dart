import 'api_service.dart';

/// Handles progress tracking operations.
class ProgressService {
  /// Get today's progress (calories, water, weight with targets).
  static Future<Map<String, dynamic>> getDailyProgress() async {
    return await ApiService.get('/progress/daily');
  }

  /// Log or update today's progress entry.
  static Future<Map<String, dynamic>> logProgress({
    int? caloriesConsumed,
    double? waterLitres,
    double? currentWeight,
  }) async {
    final body = <String, dynamic>{};
    if (caloriesConsumed != null) body['calories_consumed'] = caloriesConsumed;
    if (waterLitres != null) body['water_litres'] = waterLitres;
    if (currentWeight != null) body['current_weight'] = currentWeight;

    return await ApiService.post('/progress/log', body: body);
  }

  /// Add a meal to today's progress. Checks for duplicates.
  static Future<Map<String, dynamic>> logMeal(int calories, {
    double protein = 0,
    double carbs = 0,
    double fat = 0,
    String title = "Unknown Meal",
    int? mealId,
    bool confirmDuplicate = false,
    String? date,
    String? completionTime,
  }) async {
    return await ApiService.post(
      '/progress/log_meal',
      body: {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'title': title,
        'meal_id': mealId,
        'confirm_duplicate': confirmDuplicate,
        'date': date,
        'completion_time': completionTime,
      },
    );
  }

  /// Get last 7 days of activity.
  static Future<Map<String, dynamic>> getWeeklyActivity() async {
    return await ApiService.get('/progress/weekly');
  }

  /// Get all logged meals grouped by date.
  static Future<List<dynamic>> getMealHistory() async {
    final response = await ApiService.get('/progress/history');
    if (response.containsKey('data') && response['data'] is List) {
      return response['data'];
    }
    return [];
  }

  /// Delete a logged meal from history.
  static Future<Map<String, dynamic>> deleteLoggedMeal(int logId) async {
    return await ApiService.delete('/progress/logged_meal/$logId');
  }

  /// Update a logged meal's details.
  static Future<Map<String, dynamic>> updateLoggedMeal(int logId, {
    int? calories,
    double? protein,
    String? title,
  }) async {
    final body = <String, dynamic>{};
    if (calories != null) body['calories'] = calories;
    if (protein != null) body['protein'] = protein;
    if (title != null) body['title'] = title;

    return await ApiService.put('/progress/logged_meal/$logId', body: body);
  }
}
