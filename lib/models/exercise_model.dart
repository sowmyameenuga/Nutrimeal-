class ExerciseLogModel {
  final int id;
  final int userId;
  final String exerciseName;
  final int durationMinutes;
  final String intensity;
  final int caloriesBurned;
  final String exerciseDate;
  final String? createdAt;

  ExerciseLogModel({
    required this.id,
    required this.userId,
    required this.exerciseName,
    required this.durationMinutes,
    required this.intensity,
    required this.caloriesBurned,
    required this.exerciseDate,
    this.createdAt,
  });

  factory ExerciseLogModel.fromJson(Map<String, dynamic> json) {
    return ExerciseLogModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      exerciseName: json['exercise_name'] ?? '',
      durationMinutes: json['duration_minutes'] ?? 0,
      intensity: json['intensity'] ?? 'Moderate',
      caloriesBurned: json['calories_burned'] ?? 0,
      exerciseDate: json['exercise_date'] ?? '',
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'exercise_name': exerciseName,
      'duration_minutes': durationMinutes,
      'intensity': intensity,
      'calories_burned': caloriesBurned,
      'exercise_date': exerciseDate,
      'created_at': createdAt,
    };
  }
}

class WeeklyExercise {
  final String date;
  final String dayName;
  final int caloriesBurned;

  WeeklyExercise({
    required this.date,
    required this.dayName,
    required this.caloriesBurned,
  });

  factory WeeklyExercise.fromJson(Map<String, dynamic> json) {
    return WeeklyExercise(
      date: json['date'] ?? '',
      dayName: json['day_name'] ?? '',
      caloriesBurned: json['calories_burned'] ?? 0,
    );
  }
}
