import 'api_service.dart';

class ExerciseService {
  static const List<String> durationExercises = [
    "Walking",
    "Running",
    "Jogging",
    "Cycling",
    "Swimming",
    "Jump Rope",
    "Stair Climbing",
    "Aerobic / Dance",
    "Weight Training",
    "Bodyweight Training",
    "Stretching",
    "Pilates",
  ];

  static const List<String> repetitionExercises = [
    "Push-ups",
    "Squats",
    "Lunges",
  ];

  static List<String> getAllExercises() {
    return [...durationExercises, ...repetitionExercises];
  }

  static bool isRepetitionBased(String exerciseName) {
    return repetitionExercises.contains(exerciseName);
  }

  static int calculateEstimatedCalories({
    required String exerciseName,
    required int amount, // duration in minutes OR repetition count
    required String intensity,
    required double weight,
  }) {
    final Map<String, Map<String, double>> metMap = {
      "Walking": {"Low": 2.0, "Moderate": 3.5, "High": 4.5},
      "Running": {"Low": 6.0, "Moderate": 8.3, "High": 11.8},
      "Jogging": {"Low": 5.0, "Moderate": 7.0, "High": 9.0},
      "Cycling": {"Low": 4.0, "Moderate": 6.8, "High": 10.0},
      "Swimming": {"Low": 4.5, "Moderate": 6.0, "High": 8.0},
      "Jump Rope": {"Low": 7.0, "Moderate": 10.0, "High": 12.0},
      "Stair Climbing": {"Low": 4.0, "Moderate": 6.0, "High": 8.5},
      "Aerobic / Dance": {"Low": 4.0, "Moderate": 6.0, "High": 7.5},
      "Weight Training": {"Low": 3.0, "Moderate": 5.0, "High": 6.0},
      "Bodyweight Training": {"Low": 3.0, "Moderate": 4.5, "High": 6.0},
      "Stretching": {"Low": 2.0, "Moderate": 2.5, "High": 3.0},
      "Pilates": {"Low": 2.5, "Moderate": 3.0, "High": 4.0},
    };

    if (isRepetitionBased(exerciseName)) {
      final double factor = intensity == "Low"
          ? 0.8
          : intensity == "High"
              ? 1.2
              : 1.0;
      if (exerciseName == "Push-ups") {
        return (amount * 0.0007 * weight * factor).round().clamp(1, 99999);
      } else if (exerciseName == "Squats") {
        return (amount * 0.00137 * weight * factor).round().clamp(1, 99999);
      } else { // Lunges
        return (amount * 0.0014 * weight * factor).round().clamp(1, 99999);
      }
    } else {
      final met = metMap[exerciseName]?[intensity] ?? 3.5;
      final durationHours = amount / 60.0;
      return (met * weight * durationHours).round().clamp(1, 99999);
    }
  }

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
