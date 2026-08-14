import 'api_service.dart';

class ExerciseService {
  /// Log a new exercise.
  static Future<Map<String, dynamic>> logExercise({
    required String exerciseName,
    required int durationMinutes,
    required String intensity,
    String? date,
  }) async {
    final body = <String, dynamic>{
      'exercise_name': exerciseName,
      'duration_minutes': durationMinutes,
      'intensity': intensity,
    };
    if (date != null) {
      body['date'] = date;
    }
    return await ApiService.post('/exercise/log', body: body);
  }

  /// Get personalized exercise recommendation based on user profile.
  static Future<Map<String, dynamic>> getExerciseRecommendation() async {
    return await ApiService.get('/exercise/recommend');
  }

  /// Get exercise logs for today.
  static Future<Map<String, dynamic>> getTodayExercises() async {
    return await ApiService.get('/exercise/today');
  }

  /// Get weekly exercise summaries (Sunday to Saturday).
  static Future<Map<String, dynamic>> getWeeklyExercises() async {
    return await ApiService.get('/exercise/weekly');
  }

  /// Get exercise history, optionally filtered by a specific date.
  static Future<Map<String, dynamic>> getExerciseHistory({String? date}) async {
    final path = date != null
        ? '/exercise/history?date=$date'
        : '/exercise/history';
    return await ApiService.get(path);
  }
}
