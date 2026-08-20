import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/dashboard_service.dart';
import '../services/meal_service.dart';
import 'food_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String userName = "User";
  int totalCalories = 0;
  double totalProtein = 0;
  double totalCarbs = 0;
  double totalFat = 0;
  double totalWater = 0;
  String breakfastTitle = "Loading...";
  String lunchTitle = "Loading...";
  String dinnerTitle = "Loading...";
  String snackTitle = "Loading...";
  bool _isLoading = true;
  
  // Water Logging Preferences Customization
  int _waterGlasses = 0;
  double _waterTargetVolume = 4.0;
  int _glassSizeMl = 500;
  String _waterUnit = "L";

  Map<String, dynamic>? breakfastMeal;
  Map<String, dynamic>? lunchMeal;
  Map<String, dynamic>? dinnerMeal;
  Map<String, dynamic>? snackMeal;

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadDashboard().then((_) => _loadWaterPreferences());
  }

  Future<void> _loadWaterPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _waterTargetVolume = prefs.getDouble('water_target_volume') ?? 4.0;
      _glassSizeMl = prefs.getInt('water_glass_size_ml') ?? 500;
      _waterUnit = prefs.getString('water_unit') ?? "L";
      _waterGlasses = (_glassSizeMl > 0) ? (totalWater * 1000 / _glassSizeMl).round() : 0;
    });
  }

  Future<void> _saveWaterPreferences(double target, int size, String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('water_target_volume', target);
    await prefs.setInt('water_glass_size_ml', size);
    await prefs.setString('water_unit', unit);
    await _loadWaterPreferences();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);

    final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    final response = await DashboardService.getDashboardData(dateStr);

    if (!mounted) return;

    if (response['statusCode'] == 200) {
      _applyData(response);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _applyData(Map<String, dynamic> response) {
    final summary = response['daily_summary'] ?? {};
    final meals = response['today_meals'] ?? {};

    setState(() {
      userName = response['user_name'] ?? "User";
      totalCalories = summary['calories'] ?? 0;
      totalProtein = (summary['protein'] ?? 0).toDouble();
      totalCarbs = (summary['carbs'] ?? 0).toDouble();
      totalFat = (summary['fat'] ?? 0).toDouble();
      totalWater = (summary['water'] ?? 0).toDouble();
      _waterGlasses = (_glassSizeMl > 0) ? (totalWater * 1000 / _glassSizeMl).round() : 0;

      final breakfasts = meals['breakfast'] as List? ?? [];
      final lunches = meals['lunch'] as List? ?? [];
      final dinners = meals['dinner'] as List? ?? [];
      final snacks = meals['snack'] as List? ?? [];

      breakfastMeal = breakfasts.isNotEmpty ? breakfasts[0] as Map<String, dynamic> : null;
      lunchMeal = lunches.isNotEmpty ? lunches[0] as Map<String, dynamic> : null;
      dinnerMeal = dinners.isNotEmpty ? dinners[0] as Map<String, dynamic> : null;
      snackMeal = snacks.isNotEmpty ? snacks[0] as Map<String, dynamic> : null;

      breakfastTitle = breakfastMeal != null ? breakfastMeal!['title'] : "No breakfast planned";
      lunchTitle = lunchMeal != null ? lunchMeal!['title'] : "No lunch planned";
      dinnerTitle = dinnerMeal != null ? dinnerMeal!['title'] : "No dinner planned";
      snackTitle = snackMeal != null ? snackMeal!['title'] : "No snack planned";
    });
  }

  Future<void> _logWater(int glasses) async {
    final litres = glasses * (_glassSizeMl / 1000.0);
    final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    await ApiService.post(
      '/progress/log',
      body: {
        'water_litres': litres,
        'date': dateStr,
      },
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  void _showWaterPreferencesDialog() {
    double tempTarget = _waterTargetVolume;
    int tempSize = _glassSizeMl;
    String tempUnit = _waterUnit;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.water_drop, color: Colors.blue),
                  SizedBox(width: 8),
                  Text("Water Preferences", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Daily Water Goal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<double>(
                    initialValue: tempTarget,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: [1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0].map((val) {
                      return DropdownMenuItem<double>(
                        value: val,
                        child: Text("${val.toStringAsFixed(1)} Liters"),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => tempTarget = val);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text("Glass Size", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: tempSize,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: const [
                      DropdownMenuItem<int>(value: 250, child: Text("250 ml (Standard Cup)")),
                      DropdownMenuItem<int>(value: 330, child: Text("330 ml (Medium Glass)")),
                      DropdownMenuItem<int>(value: 500, child: Text("500 ml (Large Glass/Bottle)")),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => tempSize = val);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text("Measurement Unit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: tempUnit,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: const [
                      DropdownMenuItem<String>(value: "L", child: Text("Liters (L)")),
                      DropdownMenuItem<String>(value: "ml", child: Text("Milliliters (ml)")),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => tempUnit = val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _saveWaterPreferences(tempTarget, tempSize, tempUnit);
                    if (context.mounted) {
                      Navigator.pop(context);
                      _loadDashboard();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // APP BAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: MediaQuery.of(context).size.width > 800
            ? const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.restaurant_menu, color: Colors.green, size: 28),
              )
            : null,
        title: MediaQuery.of(context).size.width > 800
            ? const Text("NutriMeal", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
            : null,
        actions: [
          if (MediaQuery.of(context).size.width > 800) ...[
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/dashboard'),
              icon: const Icon(Icons.home, size: 18),
              label: const Text("Home"),
              style: TextButton.styleFrom(foregroundColor: Colors.black87),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/recommendation'),
              icon: const Icon(Icons.restaurant, size: 18),
              label: const Text("Meals"),
              style: TextButton.styleFrom(foregroundColor: Colors.black87),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/progress'),
              icon: const Icon(Icons.bar_chart, size: 18),
              label: const Text("Progress"),
              style: TextButton.styleFrom(foregroundColor: Colors.black87),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/workout'),
              icon: const Icon(Icons.fitness_center, size: 18),
              label: const Text("Workout"),
              style: TextButton.styleFrom(foregroundColor: Colors.black87),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/insights'),
              icon: const Icon(Icons.insights, size: 18),
              label: const Text("Insights"),
              style: TextButton.styleFrom(foregroundColor: Colors.black87),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/profile'),
              icon: const Icon(Icons.person, size: 18),
              label: const Text("Profile"),
              style: TextButton.styleFrom(foregroundColor: Colors.black87),
            ),
          ],
          const SizedBox(width: 10),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    // GREETING
                    Text(
                      "Hello, $userName 👋",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      "Today's Plan",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 25),

                    // DAILY INSIGHT
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.green, size: 30),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '"Take care of your body. It\'s the only place you have to live."',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // DAILY SUMMARY CARD
                    Container(
                      padding: const EdgeInsets.all(20),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          const Text(
                            "Daily Summary",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 25),

                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.spaceEvenly,
                            children: [

                              SummaryCircle(
                                icon: Icons.local_fire_department,
                                value: "$totalCalories",
                                label: "Calories",
                              ),

                              SummaryCircle(
                                icon: Icons.fitness_center,
                                value: "${totalProtein.toStringAsFixed(0)}g",
                                label: "Protein",
                              ),

                              SummaryCircle(
                                icon: Icons.grain,
                                value: "${totalCarbs.toStringAsFixed(0)}g",
                                label: "Carbs",
                              ),

                              SummaryCircle(
                                icon: Icons.pie_chart,
                                value: "${totalFat.toStringAsFixed(0)}g",
                                label: "Fat",
                              ),

                              SummaryCircle(
                                icon: Icons.water_drop,
                                value: _waterUnit == "L"
                                    ? "${totalWater.toStringAsFixed(1)}L"
                                    : "${(totalWater * 1000).toStringAsFixed(0)}ml",
                                label: "Water",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // WATER REMINDER
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Water Reminder",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.settings, color: Colors.white, size: 24),
                                onPressed: _showWaterPreferencesDialog,
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _waterUnit == "L"
                                ? "Logged: ${totalWater.toStringAsFixed(1)}L / ${_waterTargetVolume.toStringAsFixed(1)}L"
                                : "Logged: ${(totalWater * 1000).toStringAsFixed(0)}ml / ${(_waterTargetVolume * 1000).toStringAsFixed(0)}ml",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: List.generate((_waterTargetVolume * 1000 / _glassSizeMl).round(), (index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 6.0),
                                        child: Icon(
                                          Icons.local_drink,
                                          color: index < _waterGlasses
                                              ? Colors.white
                                              : Colors.white30,
                                          size: 26,
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  final targetGlasses = (_waterTargetVolume * 1000 / _glassSizeMl).round();
                                  if (_waterGlasses < targetGlasses) {
                                    setState(() {
                                      _waterGlasses++;
                                      totalWater = _waterGlasses * (_glassSizeMl / 1000.0);
                                    });
                                    await _logWater(_waterGlasses);
                                    _loadDashboard();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.blue.shade700,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text("Drink"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // TODAY'S MEAL PLAN
                    const Text(
                      "Today's Meal Plan",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    // BREAKFAST
                    MealCard(
                      title: "Breakfast",
                      subtitle: breakfastTitle,
                      icon: Icons.breakfast_dining,
                      status: breakfastMeal != null
                          ? (breakfastMeal!['eaten'] == true
                              ? "Eaten at ${breakfastMeal!['completion_time']}"
                              : "Pending")
                          : null,
                      onTap: () {
                        if (breakfastMeal != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FoodDetailsScreen(
                                mealId: breakfastMeal!['id'],
                                mealType: 'breakfast',
                                title: breakfastMeal!['title'],
                                calories: "${breakfastMeal!['calories']} kcal",
                                protein: "${breakfastMeal!['protein']}g",
                                carbs: "${breakfastMeal!['carbs']}g",
                                fat: "${breakfastMeal!['fat']}g",
                                ingredients: breakfastMeal!['ingredients'],
                                healthBenefits: breakfastMeal!['health_benefits'],
                                recipeSteps: breakfastMeal!['recipe_steps'],
                                eaten: breakfastMeal!['eaten'] ?? false,
                                completionTime: breakfastMeal!['completion_time'],
                                date: dateStr,
                              ),
                            ),
                          ).then((_) => _loadDashboard());
                        } else {
                          Navigator.pushNamed(
                            context,
                            '/recommendation',
                            arguments: {'meal_type': 'breakfast'},
                          ).then((_) => _loadDashboard());
                        }
                      },
                    ),

                    // LUNCH
                    MealCard(
                      title: "Lunch",
                      subtitle: lunchTitle,
                      icon: Icons.lunch_dining,
                      status: lunchMeal != null
                          ? (lunchMeal!['eaten'] == true
                              ? "Eaten at ${lunchMeal!['completion_time']}"
                              : "Pending")
                          : null,
                      onTap: () {
                        if (lunchMeal != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FoodDetailsScreen(
                                mealId: lunchMeal!['id'],
                                mealType: 'lunch',
                                title: lunchMeal!['title'],
                                calories: "${lunchMeal!['calories']} kcal",
                                protein: "${lunchMeal!['protein']}g",
                                carbs: "${lunchMeal!['carbs']}g",
                                fat: "${lunchMeal!['fat']}g",
                                ingredients: lunchMeal!['ingredients'],
                                healthBenefits: lunchMeal!['health_benefits'],
                                recipeSteps: lunchMeal!['recipe_steps'],
                                eaten: lunchMeal!['eaten'] ?? false,
                                completionTime: lunchMeal!['completion_time'],
                                date: dateStr,
                              ),
                            ),
                          ).then((_) => _loadDashboard());
                        } else {
                          Navigator.pushNamed(
                            context,
                            '/recommendation',
                            arguments: {'meal_type': 'lunch'},
                          ).then((_) => _loadDashboard());
                        }
                      },
                    ),

                    // DINNER
                    MealCard(
                      title: "Dinner",
                      subtitle: dinnerTitle,
                      icon: Icons.dinner_dining,
                      status: dinnerMeal != null
                          ? (dinnerMeal!['eaten'] == true
                              ? "Eaten at ${dinnerMeal!['completion_time']}"
                              : "Pending")
                          : null,
                      onTap: () {
                        if (dinnerMeal != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FoodDetailsScreen(
                                mealId: dinnerMeal!['id'],
                                mealType: 'dinner',
                                title: dinnerMeal!['title'],
                                calories: "${dinnerMeal!['calories']} kcal",
                                protein: "${dinnerMeal!['protein']}g",
                                carbs: "${dinnerMeal!['carbs']}g",
                                fat: "${dinnerMeal!['fat']}g",
                                ingredients: dinnerMeal!['ingredients'],
                                healthBenefits: dinnerMeal!['health_benefits'],
                                recipeSteps: dinnerMeal!['recipe_steps'],
                                eaten: dinnerMeal!['eaten'] ?? false,
                                completionTime: dinnerMeal!['completion_time'],
                                date: dateStr,
                              ),
                            ),
                          ).then((_) => _loadDashboard());
                        } else {
                          Navigator.pushNamed(
                            context,
                            '/recommendation',
                            arguments: {'meal_type': 'dinner'},
                          ).then((_) => _loadDashboard());
                        }
                      },
                    ),

                    // SNACK
                    MealCard(
                      title: "Snack",
                      subtitle: snackTitle,
                      icon: Icons.cookie,
                      status: snackMeal != null
                          ? (snackMeal!['eaten'] == true
                              ? "Eaten at ${snackMeal!['completion_time']}"
                              : "Pending")
                          : null,
                      onTap: () {
                        if (snackMeal != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FoodDetailsScreen(
                                mealId: snackMeal!['id'],
                                mealType: 'snack',
                                title: snackMeal!['title'],
                                calories: "${snackMeal!['calories']} kcal",
                                protein: "${snackMeal!['protein']}g",
                                carbs: "${snackMeal!['carbs']}g",
                                fat: "${snackMeal!['fat']}g",
                                ingredients: snackMeal!['ingredients'],
                                healthBenefits: snackMeal!['health_benefits'],
                                recipeSteps: snackMeal!['recipe_steps'],
                                eaten: snackMeal!['eaten'] ?? false,
                                completionTime: snackMeal!['completion_time'],
                                date: dateStr,
                              ),
                            ),
                          ).then((_) => _loadDashboard());
                        } else {
                          Navigator.pushNamed(
                            context,
                            '/recommendation',
                            arguments: {'meal_type': 'snack'},
                          ).then((_) => _loadDashboard());
                        }
                      },
                    ),

                    const SizedBox(height: 30),

                    // QUICK ACTIONS
                    const Text(
                      "Quick Actions",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [

                        Expanded(
                          child: actionCard(
                            context,
                            "Progress",
                            Icons.bar_chart,
                            '/progress',
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: actionCard(
                            context,
                            "Workout",
                            Icons.fitness_center,
                            '/workout',
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: actionCard(
                            context,
                            "Settings",
                            Icons.settings,
                            '/settings',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

      // BOTTOM NAVIGATION
      bottomNavigationBar: MediaQuery.of(context).size.width > 800
          ? null
          : BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,

        onTap: (index) {

          if (index == 1) {
            Navigator.pushNamed(context, '/recommendation').then((_) => _loadDashboard());
          }

          if (index == 2) {
            Navigator.pushNamed(context, '/progress').then((_) => _loadDashboard());
          }

          if (index == 3) {
            Navigator.pushNamed(context, '/insights').then((_) => _loadDashboard());
          }

          if (index == 4) {
            Navigator.pushNamed(context, '/profile').then((_) => _loadDashboard());
          }
        },

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: "Meals",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Progress",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: "Insights",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  // ACTION CARD
  Widget actionCard(
      BuildContext context,
      String title,
      IconData icon,
      String route,
      ) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, route).then((_) => _loadDashboard());
      },

      child: Container(
        height: 120,

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Icon(
              icon,
              size: 40,
              color: Colors.black,
            ),

            const SizedBox(height: 10),

            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// SUMMARY CIRCLE
class SummaryCircle extends StatelessWidget {

  final IconData icon;
  final String value;
  final String label;

  const SummaryCircle({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey.shade200,

          child: Icon(
            icon,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        Text(label),
      ],
    );
  }
}

// MEAL CARD
class MealCard extends StatelessWidget {

  final String title;
  final String subtitle;
  final IconData icon;
  final String? status;
  final VoidCallback onTap;

  const MealCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),

      child: ListTile(
        contentPadding: const EdgeInsets.all(15),

        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey.shade200,

          child: Icon(
            icon,
            color: Colors.black,
          ),
        ),

        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            if (status != null) ...[
              const SizedBox(height: 6),
              Text(
                status!,
                style: TextStyle(
                  color: status!.contains("Eaten") ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),

        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
        ),

        onTap: onTap,
      ),
    );
  }
}