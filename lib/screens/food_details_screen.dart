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

  String _estimateCookingTime(String title) {
    final name = title.toLowerCase();
    if (name.contains("smoothie") || name.contains("shake") || name.contains("salad") || name.contains("fruit") || name.contains("avocado toast") || name.contains("sandwich") || name.contains("wrap")) {
      return "5–10 minutes";
    }
    if (name.contains("egg") || name.contains("omelet") || name.contains("scramble") || name.contains("pancake") || name.contains("upma") || name.contains("oatmeal") || name.contains("oats") || name.contains("toast") || name.contains("chai") || name.contains("tea")) {
      return "10–15 minutes";
    }
    if (name.contains("fried rice") || name.contains("rice") || name.contains("pasta") || name.contains("quinoa") || name.contains("tofu") || name.contains("paneer") || name.contains("dosa") || name.contains("idli")) {
      return "15–20 minutes";
    }
    if (name.contains("biryani") || name.contains("curry") || name.contains("chicken") || name.contains("stew") || name.contains("soup")) {
      return "30–40 minutes";
    }
    return "15–25 minutes";
  }

  String _estimateServingSize(String title) {
    final name = title.toLowerCase();
    if (name.contains("smoothie") || name.contains("shake") || name.contains("juice") || name.contains("chai") || name.contains("tea")) {
      return "1 tall glass";
    }
    if (name.contains("salad") || name.contains("soup") || name.contains("oats") || name.contains("oatmeal") || name.contains("porridge")) {
      return "1 bowl";
    }
    if (name.contains("wrap") || name.contains("sandwich") || name.contains("roll")) {
      return "1 wrap / sandwich";
    }
    if (name.contains("toast")) {
      return "2 slices";
    }
    if (name.contains("idli") || name.contains("dosa")) {
      return "1 plate (2-3 pieces)";
    }
    return "1 plate (serving size for 1 person)";
  }

  String _generateFallbackRecipeSteps(String title) {
    final name = title.toLowerCase();
    if (name.contains("fried rice") || name.contains("rice bowl")) {
      return "1. Heat oil in a pan over medium heat.\n2. Add ginger-garlic paste and sauté briefly.\n3. Add mixed vegetables and stir-fry until slightly tender.\n4. Add cooked rice and mix well.\n5. Add soy sauce and salt.\n6. Stir-fry for 2-3 minutes.\n7. Garnish with spring onions and serve hot.";
    }
    if (name.contains("idli")) {
      return "1. Grease the idli plates lightly with cooking oil.\n2. Pour fermented idli batter into each mold.\n3. Steam in a closed steamer or pressure cooker for 10-12 minutes.\n4. Let it cool for 2 minutes, then unmold using a wet spoon.\n5. Serve warm with coconut chutney.";
    }
    if (name.contains("dosa")) {
      return "1. Heat a non-stick tawa or griddle and wipe with a damp cloth.\n2. Pour a ladle of dosa batter in the center and spread thinly in circles.\n3. Drizzle oil or ghee around the edges and cook on medium heat.\n4. Once golden and crisp, fold in half or wrap.\n5. Serve hot with chutney and sambar.";
    }
    if (name.contains("upma")) {
      return "1. Dry roast the semolina (rava) until lightly fragrant.\n2. Heat oil in a pan, add mustard seeds, curry leaves, onions, and green chilies.\n3. Pour in water, add salt, and bring to a boil.\n4. Gradually add the roasted rava while stirring continuously to avoid lumps.\n5. Cover and cook on low heat for 3 minutes, then serve warm.";
    }
    if (name.contains("biryani")) {
      return "1. Soak basmati rice for 30 minutes, then boil until 70% cooked.\n2. Saute sliced onions in ghee until caramelized and brown.\n3. Cook vegetables or marinated protein with biryani spices in a pot.\n4. Layer the rice over the cooked base, sprinkle fried onions and mint.\n5. Cover tightly and cook on very low heat (dum) for 15 minutes.";
    }
    if (name.contains("oatmeal") || name.contains("oats")) {
      return "1. In a medium saucepan, combine oats with milk or water.\n2. Bring to a gentle boil over medium heat.\n3. Simmer for 5 minutes, stirring occasionally until thick.\n4. Transfer to a bowl and top with fresh fruits or honey.\n5. Serve warm.";
    }
    if (name.contains("sandwich") || name.contains("wrap") || name.contains("toast")) {
      return "1. Lightly toast the bread slices or warm the wrap tortilla in a pan.\n2. Slice vegetables such as cucumber, tomato, and avocado.\n3. Spread spreads or sauces evenly onto the bread or wrap.\n4. Assemble by layering ingredients, proteins, and greens.\n5. Cut in half and serve immediately.";
    }
    if (name.contains("smoothie") || name.contains("shake")) {
      return "1. Chop ingredients such as fruits or greens into small pieces.\n2. Add them into a high-speed blender.\n3. Pour in milk, juice, or water base.\n4. Blend on high speed for 60 seconds until smooth.\n5. Pour into a glass and serve cold.";
    }
    if (name.contains("salad")) {
      return "1. Wash all salad greens and vegetables thoroughly.\n2. Chop greens, vegetables, and proteins into bite-sized pieces.\n3. Whisk together oil, lemon juice, salt, and pepper in a small bowl.\n4. Drizzle dressing over salad and toss to coat.\n5. Garnish with nuts or cheese and serve fresh.";
    }
    if (name.contains("paneer") || name.contains("curry")) {
      return "1. Heat oil in a pan and saute diced onions, ginger, and garlic.\n2. Stir in spices (turmeric, garam masala, salt) and tomato puree.\n3. Cook until the gravy thickens and releases oil.\n4. Add paneer cubes or main proteins, along with a splash of water.\n5. Simmer for 5 minutes, garnish with fresh coriander, and serve hot.";
    }
    return "1. Wash and prep all raw vegetables and ingredients.\n2. Heat oil in a pan and saute aromatics until fragrant.\n3. Add main ingredients and cook on medium heat for 8-10 minutes.\n4. Season with salt, pepper, and herbs.\n5. Transfer to a serving plate and serve warm.";
  }

  String _generateFallbackIngredients(String title) {
    final name = title.toLowerCase();
    if (name.contains("fried rice")) {
      return "- 1 cup cooked rice\n- 1/2 cup mixed vegetables\n- 1 tbsp oil\n- 1/2 tsp ginger-garlic paste\n- Salt to taste\n- 1 tbsp soy sauce\n- Spring onions";
    }
    if (name.contains("idli")) {
      return "- 2 cups fermented idli batter (rice & urad dal)\n- 1 tsp cooking oil\n- Coconut chutney (for serving)";
    }
    if (name.contains("dosa")) {
      return "- 1.5 cups fermented dosa batter\n- 2 tsp oil or ghee\n- Chutney & sambar";
    }
    if (name.contains("upma")) {
      return "- 1 cup semolina (rava)\n- 1/2 onion, finely chopped\n- 1 green chili\n- 1 tsp mustard seeds & curry leaves\n- 2 cups water\n- 2 tsp oil & salt";
    }
    if (name.contains("biryani")) {
      return "- 1 cup basmati rice\n- 1 cup mixed vegetables or protein\n- 1 onion, sliced\n- 2 tbsp ghee\n- Biryani masala & mint leaves";
    }
    if (name.contains("oats") || name.contains("oatmeal")) {
      return "- 50g rolled oats\n- 200ml milk or water\n- 1 tsp honey or maple syrup\n- Fresh berries or banana slices";
    }
    if (name.contains("sandwich") || name.contains("wrap") || name.contains("toast")) {
      return "- 2 slices of bread or 1 wrap tortilla\n- Sliced tomato & cucumber\n- 1/2 avocado or spreads\n- Salad greens & protein slices";
    }
    if (name.contains("smoothie") || name.contains("shake")) {
      return "- 1 banana or mixed fruits\n- 1 glass milk or plant-based milk\n- 1 tbsp honey or seeds";
    }
    if (name.contains("salad")) {
      return "- 2 cups mixed salad greens\n- 1/2 cucumber, sliced\n- 5 cherry tomatoes\n- 1 tbsp olive oil & lemon juice\n- Salt & pepper";
    }
    if (name.contains("paneer") || name.contains("curry")) {
      return "- 200g paneer or main protein\n- 1 onion & 2 tomatoes, pureed\n- 1 tsp ginger-garlic paste\n- Garam masala, turmeric, & salt\n- 1 tbsp oil & fresh coriander";
    }
    return "- Main dish ingredients\n- 1 tsp oil\n- Salt and pepper to taste\n- Selected spices and herbs";
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
    // If details were passed directly, validate them
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
      final String apiTitle = response['title'] ?? '';
      
      // Strict validation: recipe.name === selectedDish.name
      final normApi = apiTitle.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').trim();
      final normWidget = widget.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').trim();

      setState(() {
        if (normApi == normWidget && response['ingredients'] != null && response['ingredients'].toString().trim().isNotEmpty) {
          ingredients = response['ingredients'] ?? "No ingredients listed";
          healthBenefits = response['health_benefits'] ?? "No benefits listed";
          recipeSteps = response['recipe_steps'] ?? "";
        } else {
          // If mismatch or missing recipe, do NOT show generic. Generate specific dish recipe steps!
          ingredients = _generateFallbackIngredients(widget.title);
          recipeSteps = _generateFallbackRecipeSteps(widget.title);
          healthBenefits = "A nutritious dish tailored to support a healthy body and fit your fitness goals.";
        }
        
        if (response.containsKey('recommendation_reason') && response['recommendation_reason'] != null) {
          recommendationReason = response['recommendation_reason'];
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        // If API fails, fall back to safe specific recipe generator for this dish
        ingredients = _generateFallbackIngredients(widget.title);
        recipeSteps = _generateFallbackRecipeSteps(widget.title);
        healthBenefits = "A nutritious dish tailored to support a healthy body and fit your fitness goals.";
        _isLoading = false;
      });
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
            const SizedBox(height: 10),

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

            // Cooking Time & Serving Size Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Colors.orange),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Cooking Time",
                              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _estimateCookingTime(widget.title),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey.shade300),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.restaurant_menu_outlined, color: Colors.green),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Serving Size",
                                style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _estimateServingSize(widget.title),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Short Description
            const Text(
              "Short Description",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              cleanBenefits.isNotEmpty ? cleanBenefits : "A delicious and healthy meal choice tailored to your wellness needs.",
              style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
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
            const SizedBox(height: 15),
            ...cleanIngredients.split('\n').where((s) => s.trim().isNotEmpty).map((ing) {
              String ingText = ing.trim();
              if (ingText.startsWith('-')) {
                ingText = ingText.substring(1).trim();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, size: 20, color: Colors.green.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ingText,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.4,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 25),

            // Preparation Steps
            if (cleanSteps.isNotEmpty) ...[
              const Text(
                "Preparation Steps",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              ...cleanSteps.split('\n').where((s) => s.trim().isNotEmpty).map((step) {
                final match = RegExp(r'^(\d+)\.\s*(.*)').firstMatch(step);
                String numStr = "";
                String stepText = step;
                if (match != null) {
                  numStr = match.group(1)!;
                  stepText = match.group(2)!;
                } else {
                  numStr = "*";
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.green.shade200, width: 1.5),
                        ),
                        child: Text(
                          numStr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          stepText,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
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
                      oldTitle: widget.title,
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