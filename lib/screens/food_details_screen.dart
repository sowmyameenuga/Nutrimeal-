import 'package:flutter/material.dart';
import '../services/meal_service.dart';
import '../services/progress_service.dart';

class FoodDetailsScreen extends StatefulWidget {
  final int mealId;
  final String title;
  final String calories;
  final String protein;
  final String carbs;
  final String fat;
  final String? ingredients;
  final String? healthBenefits;
  final String? recipeSteps;
  final String? mealType;
  final bool eaten;
  final String? completionTime;
  final String? date;
  final String? recommendationReason;

  const FoodDetailsScreen({
    super.key,
    required this.mealId,
    required this.title,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.ingredients,
    this.healthBenefits,
    this.recipeSteps,
    this.mealType,
    this.eaten = false,
    this.completionTime,
    this.date,
    this.recommendationReason,
  });

  @override
  State<FoodDetailsScreen> createState() => _FoodDetailsScreenState();
}

class _FoodDetailsScreenState extends State<FoodDetailsScreen> {
  String ingredients = "Loading...";
  String healthBenefits = "Loading...";
  String recipeSteps = "";
  String recommendationReason = "";
  bool _isLoading = true;
  bool _eaten = false;
  String? _completionTime;

  /// Fix common broken UTF-8 encoded characters (e.g. â€¢ → •)
  String _fixEncoding(String text) {
    return text
        .replaceAll('\u00e2\u0080\u00a2', '\u2022')   // â€¢ → •
        .replaceAll('\u00e2\u0080\u0093', '\u2013')   // â€" → –
        .replaceAll('\u00e2\u0080\u0094', '\u2014')   // â€" → —
        .replaceAll('\u00e2\u0080\u0099', '\u2019')   // â€™ → '
        .replaceAll('\u00e2\u0080\u009c', '\u201c')   // â€œ → "
        .replaceAll('\u00e2\u0080\u009d', '\u201d')   // â€ → "
        .replaceAll('â€¢', '•')
        .replaceAll('â€"', '–')
        .replaceAll('â€"', '—')
        .replaceAll('â€™', "'")
        .replaceAll('â€œ', '"')
        .replaceAll('â€\u009d', '"');
  }

  String _cleanMacro(String label, String val) {
    String clean = val.replaceAll(RegExp(r'^(Protein|Carbs|Fat):\s*'), '');
    clean = clean.replaceAll(RegExp(r'\s*g$'), '');
    clean = clean.replaceAll(RegExp(r'\s*kcal$'), '');
    if (clean.toLowerCase().contains("null") || clean.toLowerCase().contains("nan") || clean.toLowerCase().contains("undefined") || clean.trim().isEmpty) {
      return label == "Calories" ? "0 kcal" : "0g";
    }
    if (label == "Calories") {
      return "$clean kcal";
    }
    return "${clean}g";
  }

  String _getMealImageUrl(String? type) {
    final t = type?.toLowerCase() ?? '';
    if (t.contains('breakfast')) {
      return "https://images.unsplash.com/photo-1525351484163-7529414344d8?w=600&auto=format&fit=crop";
    } else if (t.contains('lunch')) {
      return "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&auto=format&fit=crop";
    } else if (t.contains('dinner')) {
      return "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600&auto=format&fit=crop";
    } else {
      return "https://images.unsplash.com/photo-1590080875515-8a3a8dc5735e?w=600&auto=format&fit=crop"; // snack
    }
  }

  @override
  void initState() {
    super.initState();
    _eaten = widget.eaten;
    _completionTime = widget.completionTime;
    recommendationReason = widget.recommendationReason ?? "Recommended based on your health profile and nutritional goals.";
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    // If details were passed directly, use them
    if (widget.ingredients != null && widget.ingredients!.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        ingredients = widget.ingredients!;
        healthBenefits = widget.healthBenefits ?? "No benefits listed";
        recipeSteps = widget.recipeSteps ?? "";
        _isLoading = false;
      });
      return;
    }

    // Fetch from API
    final response = await MealService.getMealDetails(widget.mealId);

    if (!mounted) return;

    if (response['statusCode'] == 200) {
      setState(() {
        ingredients = response['ingredients'] ?? "No ingredients listed";
        healthBenefits = response['health_benefits'] ?? "No benefits listed";
        recipeSteps = response['recipe_steps'] ?? "";
        if (response.containsKey('recommendation_reason') && response['recommendation_reason'] != null) {
          recommendationReason = response['recommendation_reason'];
        }
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cleanIngredients = _fixEncoding(ingredients);
    final cleanBenefits = _fixEncoding(healthBenefits);
    final cleanSteps = _fixEncoding(recipeSteps);
    final cleanReason = _fixEncoding(recommendationReason);

    final cleanCalories = _cleanMacro("Calories", widget.calories);
    final cleanProtein = _cleanMacro("Protein", widget.protein);
    final cleanCarbs = _cleanMacro("Carbs", widget.carbs);
    final cleanFat = _cleanMacro("Fat", widget.fat);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meal Image
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                _getMealImageUrl(widget.mealType),
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 220,
                    color: Colors.green.shade50,
                    child: const Icon(Icons.restaurant, size: 50, color: Colors.green),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Title & Calories
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  cleanCalories,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Macros Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                nutrition("Protein", cleanProtein),
                nutrition("Carbs", cleanCarbs),
                nutrition("Fat", cleanFat),
              ],
            ),
            const SizedBox(height: 30),

            // AI Recommendation Reason
            const Text(
              "AI Recommendation Reason",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Text(
                cleanReason,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: Colors.green.shade900,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Ingredients
            const Text(
              "Ingredients",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              cleanIngredients,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 30),

            // Health Benefits
            const Text(
              "Health Benefits",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              cleanBenefits,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 30),

            // Recipe Steps
            if (cleanSteps.isNotEmpty) ...[
              const Text(
                "Recipe Steps",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                cleanSteps,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 30),
            ],

            // Action Buttons (I Ate This)
            SizedBox(
              width: double.infinity,
              height: 55,
              child: _eaten
                  ? ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: Text(
                  "Eaten at $_completionTime",
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  disabledBackgroundColor: Colors.green.shade700,
                ),
              )
                  : ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final int kcal = int.parse(cleanCalories.replaceAll(RegExp(r'[^0-9]'), ''));
                    final double pGrams = double.tryParse(cleanProtein.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                    final double cGrams = double.tryParse(cleanCarbs.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                    final double fGrams = double.tryParse(cleanFat.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                    
                    // Format current local time without package dependency
                    final now = DateTime.now();
                    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
                    final minute = now.minute.toString().padLeft(2, '0');
                    final period = now.hour >= 12 ? 'PM' : 'AM';
                    final timeStr = '$hour:$minute $period';

                    final response = await ProgressService.logMeal(
                      kcal,
                      protein: pGrams,
                      carbs: cGrams,
                      fat: fGrams,
                      title: widget.title,
                      mealId: widget.mealId,
                      date: widget.date,
                      completionTime: timeStr,
                    );

                    if (context.mounted) {
                      if (response['statusCode'] == 409) {
                        final bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Duplicate Meal"),
                            content: Text(response['message'] ?? "You already logged this meal today. Log it again?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Log Again"),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          final retryResponse = await ProgressService.logMeal(
                            kcal,
                            protein: pGrams,
                            carbs: cGrams,
                            fat: fGrams,
                            title: widget.title,
                            mealId: widget.mealId,
                            confirmDuplicate: true,
                            date: widget.date,
                            completionTime: timeStr,
                          );
                          if (context.mounted && (retryResponse['statusCode'] == 200 || retryResponse.containsKey('message'))) {
                            setState(() {
                              _eaten = true;
                              _completionTime = timeStr;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Meal logged successfully!"), backgroundColor: Colors.green),
                            );
                          }
                        }
                      } else if (response['statusCode'] == 200 || response.containsKey('message')) {
                        setState(() {
                          _eaten = true;
                          _completionTime = timeStr;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Meal logged successfully!"), backgroundColor: Colors.green),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(response['error'] ?? "Failed to log meal")),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Could not log meal: $e")),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text(
                  "I Ate This!",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Replace Meal Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                onPressed: () async {
                  try {
                    setState(() => _isLoading = true);
                    final response = await MealService.replaceMeal(
                      widget.mealType ?? 'snack',
                      widget.date ?? DateTime.now().toIso8601String().split('T')[0],
                    );
                    if (response['statusCode'] == 200) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Meal replaced successfully!"), backgroundColor: Colors.green),
                        );
                        Navigator.pop(context);
                      }
                    } else {
                      setState(() => _isLoading = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Could not replace meal: ${response['error'] ?? 'Unknown error'}")),
                        );
                      }
                    }
                  } catch (e) {
                    setState(() => _isLoading = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e")),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.refresh, color: Colors.orange),
                label: const Text(
                  "Replace Meal",
                  style: TextStyle(color: Colors.orange, fontSize: 18),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orange, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget nutrition(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}