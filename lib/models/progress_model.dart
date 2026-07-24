class ProgressModel {
  final String date;
  final int caloriesConsumed;
  final int calorieTarget;
  final double waterLitres;
  final double waterTarget;
  final double currentWeight;
  final double weightGoal;

  ProgressModel({
    required this.date,
    required this.caloriesConsumed,
    required this.calorieTarget,
    required this.waterLitres,
    required this.waterTarget,
    required this.currentWeight,
    required this.weightGoal,
  });

  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    return ProgressModel(
      date: json['date'] ?? '',
      caloriesConsumed: json['calories_consumed'] ?? 0,
      calorieTarget: json['calorie_target'] ?? 2000,
      waterLitres: (json['water_litres'] ?? 0).toDouble(),
      waterTarget: (json['water_target'] ?? 4.0).toDouble(),
      currentWeight: (json['current_weight'] ?? 0).toDouble(),
      weightGoal: (json['weight_goal'] ?? 0).toDouble(),
    );
  }

  double get calorieProgress =>
      calorieTarget > 0 ? caloriesConsumed / calorieTarget : 0;

  double get waterProgress =>
      waterTarget > 0 ? waterLitres / waterTarget : 0;

  double get weightProgress {
    if (weightGoal <= 0 || currentWeight <= 0) return 0;
    // For weight loss: progress = how close to goal
    if (currentWeight > weightGoal) {
      final totalToLose = currentWeight + 5 - weightGoal;
      final lost = currentWeight + 5 - currentWeight;
      return totalToLose > 0 ? (lost / totalToLose).clamp(0.0, 1.0) : 0;
    }
    return 1.0;
  }
}

class WeeklyActivity {
  final String date;
  final String dayName;
  final int caloriesConsumed;
  final double waterLitres;
  final double currentWeight;

  WeeklyActivity({
    required this.date,
    required this.dayName,
    required this.caloriesConsumed,
    required this.waterLitres,
    required this.currentWeight,
  });

  factory WeeklyActivity.fromJson(Map<String, dynamic> json) {
    return WeeklyActivity(
      date: json['date'] ?? '',
      dayName: json['day_name'] ?? '',
      caloriesConsumed: json['calories_consumed'] ?? 0,
      waterLitres: (json['water_litres'] ?? 0).toDouble(),
      currentWeight: (json['current_weight'] ?? 0).toDouble(),
    );
  }
}
