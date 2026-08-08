class ProgressModel {
  final String date;
  final int caloriesConsumed;
  final int calorieTarget;
  final double waterLitres;
  final double waterTarget;
  final double currentWeight;
  final double weightGoal;
  final double startingWeight;

  ProgressModel({
    required this.date,
    required this.caloriesConsumed,
    required this.calorieTarget,
    required this.waterLitres,
    required this.waterTarget,
    required this.currentWeight,
    required this.weightGoal,
    required this.startingWeight,
  });

  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    final currentVal = (json['current_weight'] ?? 0).toDouble();
    final goalVal = (json['weight_goal'] ?? 0).toDouble();
    final startVal = (json['starting_weight'] ?? currentVal).toDouble();
    return ProgressModel(
      date: json['date'] ?? '',
      caloriesConsumed: json['calories_consumed'] ?? 0,
      calorieTarget: json['calorie_target'] ?? 2000,
      waterLitres: (json['water_litres'] ?? 0).toDouble(),
      waterTarget: (json['water_target'] ?? 4.0).toDouble(),
      currentWeight: currentVal,
      weightGoal: goalVal,
      startingWeight: startVal,
    );
  }

  double get calorieProgress => calorieTarget > 0
      ? caloriesConsumed.clamp(0, calorieTarget) / calorieTarget
      : 0;

  double get waterProgress => waterTarget > 0 ? waterLitres / waterTarget : 0;

  double get weightProgress {
    if (startingWeight <= 0 || weightGoal <= 0 || currentWeight <= 0) {
      return 0.0;
    }
    final totalChange = (startingWeight - weightGoal).abs();
    if (totalChange == 0) {
      return 1.0;
    }
    final achieved = (startingWeight - currentWeight).abs();
    return (achieved / totalChange).clamp(0.0, 1.0);
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
