class MealModel {
  final int id;
  final int userId;
  final String mealType;
  final String title;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String ingredients;
  final String healthBenefits;
  final String recipeSteps;
  final String? date;
  final String recommendationReason;

  MealModel({
    required this.id,
    required this.userId,
    required this.mealType,
    required this.title,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.ingredients = '',
    this.healthBenefits = '',
    this.recipeSteps = '',
    this.date,
    this.recommendationReason = '',
  });

  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      mealType: json['meal_type'] ?? '',
      title: json['title'] ?? '',
      calories: json['calories'] ?? 0,
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      ingredients: json['ingredients'] ?? '',
      healthBenefits: json['health_benefits'] ?? '',
      recipeSteps: json['recipe_steps'] ?? '',
      date: json['date'],
      recommendationReason: json['recommendation_reason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'meal_type': mealType,
      'title': title,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'ingredients': ingredients,
      'health_benefits': healthBenefits,
      'recipe_steps': recipeSteps,
      'date': date,
      'recommendation_reason': recommendationReason,
    };
  }

  /// Formatted strings for display.
  String get caloriesStr => '$calories kcal';
  String get proteinStr => 'Protein: ${protein.toStringAsFixed(0)}g';
  String get carbsStr => 'Carbs: ${carbs.toStringAsFixed(0)}g';
  String get fatStr => 'Fat: ${fat.toStringAsFixed(0)}g';
}
