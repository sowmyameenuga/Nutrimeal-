import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';
import '../services/meal_service.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String userName = "User";
  int totalCalories = 0;
  double totalProtein = 0;
  double totalWater = 0;
  String breakfastTitle = "Loading...";
  String lunchTitle = "Loading...";
  String dinnerTitle = "Loading...";
  String snackTitle = "Loading...";
  bool _isLoading = true;
  int _waterGlasses = 0;
  final int _waterGoal = 8;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);

    final response = await DashboardService.getDashboardData();

    if (!mounted) return;

    if (response['statusCode'] == 200) {
      final summary = response['daily_summary'] ?? {};
      final meals = response['today_meals'] ?? {};

      // If no meals exist, trigger generation
      if (_isMealsEmpty(meals)) {
        await MealService.getTodayMeals();
        // Re-fetch dashboard
        final refreshed = await DashboardService.getDashboardData();
        if (!mounted) return;
        if (refreshed['statusCode'] == 200) {
          _applyData(refreshed);
        }
      } else {
        _applyData(response);
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  bool _isMealsEmpty(Map<String, dynamic> meals) {
    final b = meals['breakfast'] as List? ?? [];
    final l = meals['lunch'] as List? ?? [];
    final d = meals['dinner'] as List? ?? [];
    return b.isEmpty && l.isEmpty && d.isEmpty;
  }

  void _applyData(Map<String, dynamic> response) {
    final summary = response['daily_summary'] ?? {};
    final meals = response['today_meals'] ?? {};

    setState(() {
      userName = response['user_name'] ?? "User";
      totalCalories = summary['calories'] ?? 0;
      totalProtein = (summary['protein'] ?? 0).toDouble();
      totalWater = (summary['water'] ?? 0).toDouble();
      _waterGlasses = summary['water_glasses'] ?? 0;

      final breakfasts = meals['breakfast'] as List? ?? [];
      final lunches = meals['lunch'] as List? ?? [];
      final dinners = meals['dinner'] as List? ?? [];
      final snacks = meals['snack'] as List? ?? [];

      breakfastTitle = breakfasts.isNotEmpty
          ? breakfasts[0]['title'] ?? "Breakfast"
          : "No breakfast planned";
      lunchTitle = lunches.isNotEmpty
          ? lunches[0]['title'] ?? "Lunch"
          : "No lunch planned";
      dinnerTitle = dinners.isNotEmpty
          ? dinners[0]['title'] ?? "Dinner"
          : "No dinner planned";
      snackTitle = snacks.isNotEmpty
          ? snacks[0]['title'] ?? "Snack"
          : "No snack planned";
    });
  }

  Future<void> _logWater(int glasses) async {
    final litres = glasses * 0.5; // 1 glass = 500ml
    await ApiService.post(
      '/progress/log',
      body: {'water_litres': litres},
    );
  }

  @override
  Widget build(BuildContext context) {
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
            : const Icon(Icons.menu, color: Colors.black),
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
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/recommendation').then((_) => _loadDashboard()),
              icon: const Icon(Icons.restaurant, size: 18),
              label: const Text("Meals"),
              style: TextButton.styleFrom(foregroundColor: Colors.black87),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/progress').then((_) => _loadDashboard()),
              icon: const Icon(Icons.bar_chart, size: 18),
              label: const Text("Progress"),
              style: TextButton.styleFrom(foregroundColor: Colors.black87),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/insights').then((_) => _loadDashboard()),
              icon: const Icon(Icons.insights, size: 18),
              label: const Text("Insights"),
              style: TextButton.styleFrom(foregroundColor: Colors.black87),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/profile').then((_) => _loadDashboard()),
              icon: const Icon(Icons.person, size: 18),
              label: const Text("Profile"),
              style: TextButton.styleFrom(foregroundColor: Colors.black87),
            ),
            const SizedBox(width: 16),
          ],
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            icon: const Icon(
              Icons.notifications_none,
              color: Colors.black,
            ),
          ),
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
                      "Track your nutrition journey today",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
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

                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceAround,

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
                                icon: Icons.water_drop,
                                value: "${totalWater.toStringAsFixed(1)}L",
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.water_drop, color: Colors.white, size: 28),
                              const SizedBox(width: 10),
                              const Text(
                                "Water Reminder",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const Spacer(),
                              Text(
                                "$_waterGlasses / $_waterGoal",
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(_waterGoal, (index) {
                              final filled = index < _waterGlasses;
                              return GestureDetector(
                                onTap: () {
                                  final newGlasses = index + 1;
                                  setState(() {
                                    _waterGlasses = newGlasses;
                                    totalWater = newGlasses * 0.5;
                                  });
                                  _logWater(newGlasses);
                                },
                                child: Icon(
                                  filled ? Icons.local_drink : Icons.local_drink_outlined,
                                  color: filled ? Colors.white : Colors.white38,
                                  size: 30,
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _waterGlasses / _waterGoal,
                              backgroundColor: Colors.white24,
                              color: Colors.white,
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _waterGlasses >= _waterGoal
                                ? "🎉 Great job! You've reached your daily water goal!"
                                : "💧 Drink ${_waterGoal - _waterGlasses} more glasses to reach your goal",
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // TODAY MEALS
                    const Text(
                      "Today's Meal Plan",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // BREAKFAST
                    MealCard(
                      title: "Breakfast",
                      subtitle: breakfastTitle,
                      icon: Icons.breakfast_dining,

                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/recommendation',
                          arguments: {'meal_type': 'Breakfast'},
                        ).then((_) => _loadDashboard());
                      },
                    ),

                    // LUNCH
                    MealCard(
                      title: "Lunch",
                      subtitle: lunchTitle,
                      icon: Icons.lunch_dining,

                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/recommendation',
                          arguments: {'meal_type': 'Lunch'},
                        ).then((_) => _loadDashboard());
                      },
                    ),

                    // DINNER
                    MealCard(
                      title: "Dinner",
                      subtitle: dinnerTitle,
                      icon: Icons.dinner_dining,

                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/recommendation',
                          arguments: {'meal_type': 'Dinner'},
                        ).then((_) => _loadDashboard());
                      },
                    ),

                    // SNACK
                    MealCard(
                      title: "Snack",
                      subtitle: snackTitle,
                      icon: Icons.cookie,

                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/recommendation',
                          arguments: {'meal_type': 'Snack'},
                        ).then((_) => _loadDashboard());
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

                        const SizedBox(width: 15),

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
  final VoidCallback onTap;

  const MealCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
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

        subtitle: Text(subtitle),

        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
        ),

        onTap: onTap,
      ),
    );
  }
}