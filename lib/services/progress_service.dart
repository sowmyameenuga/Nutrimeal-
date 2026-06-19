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

  /// Add a meal's calories to today's progress.
  static Future<Map<String, dynamic>> logMeal(int calories) async {
    return await ApiService.post(
      '/progress/log_meal',
      body: {'calories': calories},
    );
  }

  /// Get last 7 days of activity.
  static Future<Map<String, dynamic>> getWeeklyActivity() async {
    return await ApiService.get('/progress/weekly');
  }
}
