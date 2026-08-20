import 'package:flutter/material.dart';
import '../models/progress_model.dart';
import '../services/progress_service.dart';
import '../services/exercise_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  ProgressModel? dailyProgress;
  List<WeeklyActivity> weeklyActivity = [];
  bool _isLoading = true;
  int weeklyCalories = 0;
  double weeklyProtein = 0.0;
  double weeklyCarbs = 0.0;
  double weeklyFat = 0.0;

  // Exercise states
  int todayBurnedCalories = 0;
  List<dynamic> todayExercises = [];
  List<dynamic> weeklyExercises = [];

  // Weekly summary states
  List<dynamic> weeklySummary = [];
  int? expandedDayIndex;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);

    final dailyResponse = await ProgressService.getDailyProgress();
    final weeklyResponse = await ProgressService.getWeeklyActivity();
    final todayExerciseRes = await ExerciseService.getTodayExercises();
    final weeklyExerciseRes = await ExerciseService.getWeeklyExercises();
    final weeklySummaryRes = await ProgressService.getWeeklySummary();

    if (!mounted) return;

    if (dailyResponse['statusCode'] == 200) {
      dailyProgress = ProgressModel.fromJson(dailyResponse);
    }

    if (weeklyResponse['statusCode'] == 200) {
      if (weeklyResponse.containsKey('weekly_nutrition')) {
        final nut = weeklyResponse['weekly_nutrition'] as Map<String, dynamic>;
        weeklyCalories = (nut['calories'] ?? 0).toInt();
        weeklyProtein = (nut['protein'] ?? 0.0).toDouble();
        weeklyCarbs = (nut['carbs'] ?? 0.0).toDouble();
        weeklyFat = (nut['fat'] ?? 0.0).toDouble();
      }

      if (weeklyResponse.containsKey('data')) {
        final List rawList = weeklyResponse['data'] as List;
        weeklyActivity = rawList
            .map(
              (item) => WeeklyActivity.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
    }

    if (todayExerciseRes['statusCode'] == 200) {
      todayBurnedCalories = (todayExerciseRes['total_calories_burned'] ?? 0)
          .toInt();
      todayExercises = todayExerciseRes['exercises'] ?? [];
    }

    if (weeklyExerciseRes['statusCode'] == 200) {
      weeklyExercises = weeklyExerciseRes['data'] ?? [];
    }

    if (weeklySummaryRes['statusCode'] == 200) {
      weeklySummary = weeklySummaryRes['data'] ?? [];
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Progress Tracking",
            style: TextStyle(color: Colors.black),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final dp = dailyProgress;
    final netCalories = dp != null
        ? dp.caloriesConsumed - todayBurnedCalories
        : 0;
    final calorieProgress = dp != null && dp.calorieTarget > 0
        ? netCalories.clamp(0, dp.calorieTarget) / dp.calorieTarget
        : 0.0;

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
          "Progress Tracking",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DAILY CALORIES (WITH EXERCISE NET CALORIES INCLUDED)
            progressCard(
              title: "Today's Calories",
              value: dp != null
                  ? "$netCalories / ${dp.calorieTarget} kcal (Net)"
                  : "0 / 2000 kcal",
              progress: calorieProgress,
              icon: Icons.local_fire_department,
              subtitle: dp != null
                  ? "Consumed: ${dp.caloriesConsumed} kcal | Burned: $todayBurnedCalories kcal\n${(dp.calorieTarget - netCalories).clamp(0, 99999)} kcal remaining"
                  : "2000 kcal remaining",
            ),

            const SizedBox(height: 20),

            // WATER INTAKE
            progressCard(
              title: "Water Intake",
              value: dp != null
                  ? "${dp.waterLitres.toStringAsFixed(1)} / ${dp.waterTarget.toStringAsFixed(0)} L"
                  : "0.0 / 4 L",
              progress: dp?.waterProgress.clamp(0.0, 1.0) ?? 0.0,
              icon: Icons.water_drop,
              subtitle: dp != null
                  ? "${(dp.waterProgress * 100).toStringAsFixed(0)}% of daily goal"
                  : "0% of daily goal",
            ),

            const SizedBox(height: 20),

            // WEIGHT GOAL
            progressCard(
              title: "Weight Goal",
              value: dp != null
                  ? "${dp.currentWeight.toStringAsFixed(1)} kg → ${dp.weightGoal.toStringAsFixed(1)} kg"
                  : "-- → --",
              progress: dp?.weightProgress.clamp(0.0, 1.0) ?? 0.0,
              icon: Icons.monitor_weight,
              subtitle: dp != null ? getWeightProgressSubtitle(dp) : "",
            ),

            const SizedBox(height: 30),

            // BUTTONS GRID (2x2)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _showLogDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text("Log Progress"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/workout',
                        ).then((_) => _loadProgress());
                      },
                      icon: const Icon(Icons.fitness_center),
                      label: const Text("Log Exercise"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/saved_meals',
                        ).then((_) => _loadProgress());
                      },
                      icon: const Icon(Icons.bookmark),
                      label: const Text("Saved Meals"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/meal_history',
                        ).then((_) => _loadProgress());
                      },
                      icon: const Icon(Icons.history),
                      label: const Text("Meal History"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // TODAY'S EXERCISE SUMMARY CARD
            const Text(
              "Today's Exercises",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (todayExercises.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          "No exercises logged today.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    ...todayExercises.map((exercise) {
                      final name = exercise['exercise_name'] ?? '';
                      final duration = exercise['duration_minutes'] ?? 0;
                      final intensity = exercise['intensity'] ?? 'Moderate';
                      final burned = exercise['calories_burned'] ?? 0;

                      IconData icon = Icons.fitness_center;
                      Color iconColor = Colors.orange;

                      if (name.contains("Running")) {
                        icon = Icons.directions_run;
                        iconColor = Colors.blue;
                      } else if (name.contains("Walking")) {
                        icon = Icons.directions_walk;
                        iconColor = Colors.green;
                      } else if (name.contains("Cycling")) {
                        icon = Icons.directions_bike;
                        iconColor = Colors.purple;
                      } else if (name.contains("Swimming")) {
                        icon = Icons.pool;
                        iconColor = Colors.teal;
                      } else if (name.contains("Weight Lifting")) {
                        icon = Icons.fitness_center;
                        iconColor = Colors.red;
                      } else if (name.contains("Jump Rope")) {
                        icon = Icons.bolt;
                        iconColor = Colors.amber;
                      }

                      return Card(
                        elevation: 0,
                        color: Colors.grey.shade50,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: iconColor.withOpacity(0.1),
                            child: Icon(icon, color: iconColor),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            ExerciseService.isRepetitionBased(name)
                                ? "$duration reps · $intensity intensity"
                                : "$duration mins · $intensity intensity",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          trailing: Text(
                            "-$burned kcal",
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    }),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total Burned:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "$todayBurnedCalories kcal",
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 30),

            // WEEKLY CALORIE INTAKE (BAR CHART)
            const Text(
              "Weekly Calorie Intake",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              height: 220,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _buildBarChart(),
            ),

            const SizedBox(height: 30),

            // WEEKLY CALORIES BURNED (BAR CHART)
            const Text(
              "Weekly Calories Burned",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              height: 220,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _buildWeeklyExerciseChart(),
            ),

            const SizedBox(height: 30),

            // DAILY SUMMARY LIST
            const Text(
              "Daily Summary",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (weeklySummary.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    "No activity summary available yet.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...weeklySummary.reversed.toList().asMap().entries.map((entry) {
                final int index = entry.key;
                final dayData = entry.value;

                final String dayName = dayData['day_name'] ?? '';
                
                final nutrition = dayData['nutrition'] ?? {};
                final int consumed = (nutrition['calories'] ?? 0).toInt();
                final double protein = (nutrition['protein'] ?? 0.0).toDouble();
                final double carbs = (nutrition['carbs'] ?? 0.0).toDouble();
                final double fat = (nutrition['fat'] ?? 0.0).toDouble();

                final exercise = dayData['exercise'] ?? {};
                final int burned = (exercise['burned'] ?? 0).toInt();
                final List exercisesList = exercise['exercises'] ?? [];

                final summary = dayData['summary'] ?? {};
                final int net = (summary['net'] ?? 0).toInt();

                final bool isExpanded = expandedDayIndex == index;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        expandedDayIndex = isExpanded ? null : index;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black87,
                                ),
                              ),
                              Icon(
                                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Consumed: $consumed kcal | Burned: $burned kcal | Net: $net kcal",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          if (isExpanded) ...[
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 12),
                            
                            // NUTRITION SECTION
                            const Text(
                              "Nutrition",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text("• Calories: $consumed kcal", style: const TextStyle(fontSize: 14)),
                            Text("• Protein: ${protein.toStringAsFixed(1)} g", style: const TextStyle(fontSize: 14)),
                            Text("• Carbs: ${carbs.toStringAsFixed(1)} g", style: const TextStyle(fontSize: 14)),
                            Text("• Fat: ${fat.toStringAsFixed(1)} g", style: const TextStyle(fontSize: 14)),
                            
                            const SizedBox(height: 16),
                            
                            // EXERCISE SECTION
                            const Text(
                              "Exercise",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (exercisesList.isEmpty)
                              const Text("• No exercises logged", style: TextStyle(fontSize: 14, color: Colors.grey))
                            else
                              ...exercisesList.map((e) {
                                final String name = e['exercise_name'] ?? '';
                                final int duration = (e['duration_minutes'] ?? 0).toInt();
                                final String intensity = e['intensity'] ?? 'Moderate';
                                final int eBurned = (e['calories_burned'] ?? 0).toInt();
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: Text(
                                    ExerciseService.isRepetitionBased(name)
                                        ? "• $name — $duration reps — $intensity\n  Calories burned: $eBurned kcal"
                                        : "• $name — $duration min — $intensity\n  Calories burned: $eBurned kcal",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }),
                              
                            const SizedBox(height: 16),
                            
                            // SUMMARY SECTION
                            const Text(
                              "Summary",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text("• Consumed: $consumed kcal", style: const TextStyle(fontSize: 14)),
                            Text("• Burned: $burned kcal", style: const TextStyle(fontSize: 14)),
                            Text(
                              "• Net: $net kcal",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showLogDialog(BuildContext context) {
    final caloriesCtrl = TextEditingController();
    final waterCtrl = TextEditingController();
    final weightCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log Progress"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: caloriesCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Calories consumed",
                hintText: "e.g. 1500",
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: waterCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Water (litres)",
                hintText: "e.g. 2.5",
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: weightCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Current weight (kg)",
                hintText: "e.g. 68.5",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await ProgressService.logProgress(
                caloriesConsumed: int.tryParse(caloriesCtrl.text),
                waterLitres: double.tryParse(waterCtrl.text),
                currentWeight: double.tryParse(weightCtrl.text),
              );
              if (!context.mounted) return;
              Navigator.pop(context);
              _loadProgress(); // Refresh data
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }



  String getWeightProgressSubtitle(ProgressModel dp) {
    final start = dp.startingWeight;
    final current = dp.currentWeight;
    final target = dp.weightGoal;
    final diff = (start - target).abs();
    if (target < start) {
      final lost = (start - current).clamp(0.0, diff);
      return "${lost.toStringAsFixed(1)} kg lost of ${diff.toStringAsFixed(1)} kg";
    } else if (target > start) {
      final gained = (current - start).clamp(0.0, diff);
      return "${gained.toStringAsFixed(1)} kg gained of ${diff.toStringAsFixed(1)} kg";
    } else {
      return "Weight maintained";
    }
  }

  // PROGRESS CARD
  Widget progressCard({
    required String title,
    required String value,
    required double progress,
    required IconData icon,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                child: Icon(icon, color: Colors.black),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.grey.shade300,
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  // WEEKLY TILE
  Widget weeklyTile(String day, String calories) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: const Icon(Icons.bar_chart),
        title: Text(day),
        trailing: Text(
          calories,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final hasData = weeklyActivity.isNotEmpty;
    final List<Map<String, dynamic>> chartData = hasData
        ? weeklyActivity
              .map(
                (a) => {
                  "day": a.dayName.substring(0, 3),
                  "cals": a.caloriesConsumed,
                },
              )
              .toList()
        : [
            {"day": "Mon", "cals": 1800},
            {"day": "Tue", "cals": 2100},
            {"day": "Wed", "cals": 1950},
            {"day": "Thu", "cals": 1600},
            {"day": "Fri", "cals": 2200},
            {"day": "Sat", "cals": 2400},
            {"day": "Sun", "cals": 2000},
          ];

    int maxCals = chartData.fold(
      0,
      (max, item) => item["cals"] > max ? item["cals"] : max,
    );
    if (maxCals == 0) maxCals = 2000;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: chartData.map((data) {
        final double heightPercentage = (data["cals"] / maxCals)
            .clamp(0.0, 1.0)
            .toDouble();
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "${data["cals"]}",
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 30,
              height: (140 * heightPercentage).toDouble(),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade300, Colors.deepPurple],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data["day"],
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildWeeklyExerciseChart() {
    final hasData = weeklyExercises.isNotEmpty;
    final List<Map<String, dynamic>> chartData = hasData
        ? weeklyExercises.map((a) {
            final day = (a['day_name'] ?? 'Sun') as String;
            final cals = (a['calories_burned'] ?? 0) as int;
            return {"day": day.substring(0, 3), "cals": cals};
          }).toList()
        : [
            {"day": "Sun", "cals": 0},
            {"day": "Mon", "cals": 0},
            {"day": "Tue", "cals": 0},
            {"day": "Wed", "cals": 0},
            {"day": "Thu", "cals": 0},
            {"day": "Fri", "cals": 0},
            {"day": "Sat", "cals": 0},
          ];

    int maxCals = chartData.fold(
      0,
      (max, item) => item["cals"] > max ? item["cals"] : max,
    );
    if (maxCals == 0) maxCals = 500;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: chartData.map((data) {
        final double heightPercentage = (data["cals"] / maxCals)
            .clamp(0.0, 1.0)
            .toDouble();
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "${data["cals"]}",
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 30,
              height: (140 * heightPercentage).toDouble(),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade300, Colors.orange.shade700],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data["day"],
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        );
      }).toList(),
    );
  }
}
