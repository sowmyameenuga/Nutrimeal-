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
  });

  @override
  State<FoodDetailsScreen> createState() => _FoodDetailsScreenState();
}

class _FoodDetailsScreenState extends State<FoodDetailsScreen> {
  String ingredients = "Loading...";
  String healthBenefits = "Loading...";
  String recipeSteps = "";
  bool _isLoading = true;

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
      setState(() {
        ingredients = "Could not load ingredients";
        healthBenefits = "Could not load benefits";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),

          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          "Food Details",
          style: TextStyle(color: Colors.black),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [



            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              widget.calories,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,

                children: [

                  nutrition("Protein", widget.protein),
                  nutrition("Carbs", widget.carbs),
                  nutrition("Fat", widget.fat),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Ingredients",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            _isLoading
                ? const CircularProgressIndicator()
                : Text(
                    _fixEncoding(ingredients),
                    style: const TextStyle(fontSize: 16),
                  ),

            const SizedBox(height: 25),

            const Text(
              "Health Benefits",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            _isLoading
                ? const CircularProgressIndicator()
                : Text(
                    _fixEncoding(healthBenefits),
                    style: const TextStyle(fontSize: 16),
                  ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton(
                onPressed: () {
                  // Show recipe in a bottom sheet
                  if (recipeSteps.isNotEmpty) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (context) => Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Recipe: ${widget.title}",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              recipeSteps,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
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
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final int kcal = int.parse(widget.calories.replaceAll(RegExp(r'[^0-9]'), ''));
                    final double pGrams = double.tryParse(widget.protein.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                    
                    final response = await ProgressService.logMeal(
                      kcal,
                      protein: pGrams,
                      title: widget.title,
                      mealId: widget.mealId,
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
                          );
                          if (context.mounted && (retryResponse['statusCode'] == 200 || retryResponse.containsKey('message'))) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Meal logged successfully!"), backgroundColor: Colors.green),
                            );
                          }
                        }
                      } else if (response['statusCode'] == 200 || response.containsKey('message')) {
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
                        const SnackBar(content: Text("Meal saved to Today's Plan!"), backgroundColor: Colors.blue),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Could not save meal: $e")),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.bookmark_add, color: Colors.blue),
                label: const Text(
                  "Save Meal",
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

        Text(label),
      ],
    );
  }
}