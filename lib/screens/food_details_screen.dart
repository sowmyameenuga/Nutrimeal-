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
  });

  @override
  State<FoodDetailsScreen> createState() => _FoodDetailsScreenState();
}

class _FoodDetailsScreenState extends State<FoodDetailsScreen> {
  String ingredients = "Loading...";
  String healthBenefits = "Loading...";
  String recipeSteps = "";
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

  @override
  void initState() {
    super.initState();
    _eaten = widget.eaten;
    _completionTime = widget.completionTime;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    // If details were passed directly (e.g. from Recommendations), use them
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

    // Otherwise fetch from API (e.g. from Dashboard)
    final response = await MealService.getMealDetails(widget.mealId);

    if (!mounted) return;

    if (response['statusCode'] == 200) {
      setState(() {
        ingredients = response['ingredients'] ?? "No ingredients listed";
        healthBenefits = response['health_benefits'] ?? "No benefits listed";
        recipeSteps = response['recipe_steps'] ?? "";
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
                  widget.calories,
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
                nutrition("Protein", widget.protein),
                nutrition("Carbs", widget.carbs),
                nutrition("Fat", widget.fat),
              ],
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
                "Recipe",
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

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  if (widget.recipeSteps != null && widget.recipeSteps!.isNotEmpty) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Recipe Instructions"),
                        content: SingleChildScrollView(
                          child: Text(cleanSteps),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Close"),
                          ),
                        ],
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Recipe not available yet"),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
                child: const Text(
                  "View Recipe",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),

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
                    final int kcal = int.parse(widget.calories.replaceAll(RegExp(r'[^0-9]'), ''));
                    final double pGrams = double.tryParse(widget.protein.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                    
                    // Format current local time without package dependency
                    final now = DateTime.now();
                    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
                    final minute = now.minute.toString().padLeft(2, '0');
                    final period = now.hour >= 12 ? 'PM' : 'AM';
                    final timeStr = '$hour:$minute $period';

                    final response = await ProgressService.logMeal(
                      kcal,
                      protein: pGrams,
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

            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await MealService.saveMeal({
                      'meal_type': widget.mealType ?? 'snack',
                      'title': widget.title,
                      'calories': int.parse(widget.calories.replaceAll(RegExp(r'[^0-9]'), '')),
                      'protein': double.parse(widget.protein.replaceAll(RegExp(r'[^0-9.]'), '')),
                      'carbs': double.parse(widget.carbs.replaceAll(RegExp(r'[^0-9.]'), '')),
                      'fat': double.parse(widget.fat.replaceAll(RegExp(r'[^0-9.]'), '')),
                      'ingredients': widget.ingredients ?? '',
                      'recipe_steps': widget.recipeSteps ?? '',
                      'health_benefits': widget.healthBenefits ?? '',
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Meal added to Today's Plan!"), backgroundColor: Colors.blue),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Could not add meal to plan: $e")),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.bookmark_add, color: Colors.blue),
                label: const Text(
                  "Add to Today's Plan",
                  style: TextStyle(color: Colors.blue, fontSize: 18),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blue, width: 2),
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