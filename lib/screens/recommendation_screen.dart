import 'package:flutter/material.dart';
import '../models/meal_model.dart';
import '../services/meal_service.dart';
import '../services/profile_service.dart';
import 'food_details_screen.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  // Grouped recommendations: key = meal type, value = list of meals
  Map<String, List<MealModel>> _grouped = {};
  bool _isLoading = true;

  // AI Parameters (from user profile)
  int _userId = 1;
  String _selectedDiet = 'Vegetarian';
  String _selectedGoal = 'Weight Loss';
  int _age = 25;

  List<String> _mealCategories = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
  String? _passedMealType;
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('meal_type')) {
        _passedMealType = args['meal_type'];
        _mealCategories = [_passedMealType!];
      }
      _didInit = true;
      _initAndLoad();
    }
  }

  Future<void> _initAndLoad() async {
    // 1. Fetch user profile to get base parameters
    try {
      final profileResponse = await ProfileService.getProfile();
      if (profileResponse['statusCode'] == 200) {
        final data = profileResponse;
        if (data['user_id'] != null) _userId = data['user_id'];
        if (data['age'] != null) _age = data['age'];
        if (data['goal'] != null) {
          String goal = data['goal'];
          if (goal == "Fat Loss") goal = "Weight Loss";
          _selectedGoal = goal;
        }

        String rawDiet = 'Vegetarian';
        if (data['diet'] != null) {
          rawDiet = data['diet'];
        } else if (data['preference'] != null) {
          rawDiet = data['preference'];
        }

        if (rawDiet == 'Veg' || rawDiet == 'Vegetarian') {
          _selectedDiet = 'Vegetarian';
        } else if (rawDiet == 'Non-Veg' || rawDiet == 'Non-Vegetarian') {
          _selectedDiet = 'Non-Vegetarian';
        } else if (rawDiet == 'Vegan') {
          _selectedDiet = 'Vegan';
        } else {
          _selectedDiet = 'Vegetarian';
        }
      }
    } catch (e) {
      debugPrint("Could not fetch profile: $e");
    }

    _loadAllRecommendations();
  }

  Future<void> _loadAllRecommendations() async {
    setState(() => _isLoading = true);

    Map<String, List<MealModel>> grouped = {};

    // Fetch 2 items per meal category in parallel
    final futures = _mealCategories.map((category) async {
      final response = await MealService.getAIRecommendations(
        userId: _userId,
        diet: _selectedDiet,
        goal: _selectedGoal,
        age: _age,
        country: 'Global',
        mealType: category,
        topK: 2,
      );

      List<MealModel> meals = [];
      if (response['statusCode'] == 200) {
        final recs = response['recommendations'] as List? ?? [];
        meals = recs.map((m) => MealModel.fromJson(m as Map<String, dynamic>)).toList();
      }
      return MapEntry(category, meals);
    });

    final results = await Future.wait(futures);
    for (final entry in results) {
      grouped[entry.key] = entry.value;
    }

    if (!mounted) return;
    setState(() {
      _grouped = grouped;
      _isLoading = false;
    });
  }

  Future<void> _saveMeal(MealModel meal, String mealType) async {
    final response = await MealService.saveMeal({
      'meal_type': mealType.toLowerCase(),
      'title': meal.title,
      'calories': meal.calories,
      'protein': meal.protein,
      'carbs': meal.carbs,
      'fat': meal.fat,
      'ingredients': meal.ingredients,
      'recipe_steps': meal.recipeSteps,
      'health_benefits': meal.healthBenefits,
    });

    if (!mounted) return;

    if (response['statusCode'] == 200 || response['statusCode'] == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ "${meal.title}" saved to your meal plan!'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save: ${response['error'] ?? 'Unknown error'}'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: Colors.deepPurple, size: 24),
            SizedBox(width: 8),
            Text("AI Meal Plan", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.deepPurple),
            onPressed: _loadAllRecommendations,
            tooltip: "Refresh recommendations",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.deepPurple),
                  SizedBox(height: 16),
                  Text("AI is preparing your daily meal plan...", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAllRecommendations,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Profile info pills
                  Row(
                    children: [
                      _buildInfoPill(Icons.restaurant, _selectedDiet, Colors.green),
                      const SizedBox(width: 8),
                      _buildInfoPill(Icons.flag, _selectedGoal, Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Grouped sections
                  for (final category in _mealCategories) ...[
                    _buildCategorySection(category),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildInfoPill(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Breakfast': return Icons.breakfast_dining;
      case 'Lunch': return Icons.lunch_dining;
      case 'Dinner': return Icons.dinner_dining;
      case 'Snack': return Icons.cookie;
      default: return Icons.restaurant;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Breakfast': return Colors.orange;
      case 'Lunch': return Colors.green;
      case 'Dinner': return Colors.indigo;
      case 'Snack': return Colors.pink;
      default: return Colors.deepPurple;
    }
  }

  Widget _buildCategorySection(String category) {
    final meals = _grouped[category] ?? [];
    final color = _getCategoryColor(category);
    final icon = _getCategoryIcon(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              category,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              "${meals.length} items",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (meals.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text("No recommendations found", style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: meals.map((meal) {
                return Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  margin: const EdgeInsets.only(right: 16, bottom: 8),
                  child: _buildMealCard(meal, category, color),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildMealCard(MealModel meal, String category, Color accentColor) {
    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Calories Header
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FoodDetailsScreen(
                    mealId: meal.id,
                    mealType: category,
                    title: meal.title,
                    calories: meal.caloriesStr,
                    protein: meal.proteinStr,
                    carbs: meal.carbsStr,
                    fat: meal.fatStr,
                    ingredients: meal.ingredients,
                    recipeSteps: meal.recipeSteps,
                    healthBenefits: meal.healthBenefits,
                    recommendationReason: meal.recommendationReason,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  // Meal icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accentColor, accentColor.withOpacity(0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Icon(Icons.restaurant_menu, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.local_fire_department, size: 14, color: Colors.orange.shade700),
                            const SizedBox(width: 4),
                            Text(
                              meal.caloriesStr,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange.shade700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),

          // Macros Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildMacroPill("P", "${meal.protein.toStringAsFixed(0)}g", Colors.blue),
                const SizedBox(width: 8),
                _buildMacroPill("C", "${meal.carbs.toStringAsFixed(0)}g", Colors.amber.shade700),
                const SizedBox(width: 8),
                _buildMacroPill("F", "${meal.fat.toStringAsFixed(0)}g", Colors.red.shade400),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Ingredients Preview
          if (meal.ingredients.isNotEmpty)
            _buildInfoSection(
              icon: Icons.list_alt,
              title: "Ingredients",
              content: meal.ingredients,
              color: Colors.teal,
            ),

          // Health Benefits Preview
          if (meal.healthBenefits.isNotEmpty)
            _buildInfoSection(
              icon: Icons.favorite,
              title: "Health Benefits",
              content: meal.healthBenefits,
              color: Colors.pink,
            ),

          // Recipe Preview
          if (meal.recipeSteps.isNotEmpty)
            _buildInfoSection(
              icon: Icons.menu_book,
              title: "Recipe",
              content: meal.recipeSteps,
              color: Colors.deepPurple,
            ),

          // Save Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _saveMeal(meal, category),
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text("Add to Today's Plan"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    // Show max 3 lines to keep compact
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              content,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}