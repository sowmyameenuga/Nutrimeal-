import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/progress_model.dart';
import '../services/progress_service.dart';

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
  List<dynamic> loggedExercises = [];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);

    final dailyResponse = await ProgressService.getDailyProgress();
    final weeklyResponse = await ProgressService.getWeeklyActivity();

    if (!mounted) return;

    if (dailyResponse['statusCode'] == 200) {
      dailyProgress = ProgressModel.fromJson(dailyResponse);
      try {
        loggedExercises = jsonDecode(dailyProgress!.exercisesJson) as List;
      } catch (_) {
        loggedExercises = [];
      }
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
            // DAILY CALORIES
            progressCard(
              title: "Today's Calories",
              value: dp != null
                  ? "${dp.caloriesConsumed - dp.caloriesBurned} / ${dp.calorieTarget} kcal"
                  : "0 / 2000 kcal",
              progress: dp?.calorieProgress.clamp(0.0, 1.0) ?? 0.0,
              icon: Icons.local_fire_department,
              subtitle: dp != null
                  ? "Consumed: ${dp.caloriesConsumed} kcal | Burned: ${dp.caloriesBurned} kcal\n${(dp.calorieTarget - (dp.caloriesConsumed - dp.caloriesBurned)).clamp(0, 99999)} kcal remaining"
                  : "Consumed: 0 kcal | Burned: 0 kcal | 2000 kcal remaining",
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

            // BUTTONS ROW 1
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
                      onPressed: () => _showExerciseDialog(context),
                      icon: const Icon(Icons.fitness_center),
                      label: const Text("Log Exercise"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // BUTTONS ROW 2
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

            // WEEKLY NUTRITION SUMMARY
            const Text(
              "Weekly Nutrition",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 16) / 2;
                  return Column(
                    children: [
                      Row(
                        children: [
                          _buildNutritionItem(
                            "Calories",
                            "$weeklyCalories kcal",
                            Icons.local_fire_department,
                            Colors.orange,
                            itemWidth,
                          ),
                          const SizedBox(width: 16),
                          _buildNutritionItem(
                            "Protein",
                            "${weeklyProtein.toStringAsFixed(1)} g",
                            Icons.egg,
                            Colors.red,
                            itemWidth,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildNutritionItem(
                            "Carbs",
                            "${weeklyCarbs.toStringAsFixed(1)} g",
                            Icons.rice_bowl,
                            Colors.amber,
                            itemWidth,
                          ),
                          const SizedBox(width: 16),
                          _buildNutritionItem(
                            "Fat",
                            "${weeklyFat.toStringAsFixed(1)} g",
                            Icons.opacity,
                            Colors.blue,
                            itemWidth,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            // DAILY BREAKDOWN LIST
            const Text(
              "Daily Breakdown",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (weeklyActivity.isEmpty)
              const Text("No weekly activity logged yet.")
            else
              ...weeklyActivity.reversed.map(
                (a) => weeklyTile(a.dayName, "${a.caloriesConsumed} kcal"),
              ),

            const SizedBox(height: 30),

            // TODAY'S EXERCISES
            const Text(
              "Today's Exercises",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (loggedExercises.isEmpty)
              const Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(
                    child: Text(
                      "No exercises logged today.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              )
            else
              ...loggedExercises.map(
                (e) => exerciseTile(
                  e['name'] ?? 'Exercise',
                  e['duration'] != null ? "${e['duration']} mins" : "",
                  "${e['calories'] ?? 0} kcal",
                  e['time'] ?? "",
                ),
              ),
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

  void _showExerciseDialog(BuildContext context) {
    String selectedExercise = "Running 🏃‍♂️";
    final caloriesCtrl = TextEditingController();
    final durationCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Log Exercise"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedExercise,
                decoration: const InputDecoration(labelText: "Select Exercise"),
                items:
                    [
                      "Running 🏃‍♂️",
                      "Walking 🚶‍♂️",
                      "Cycling 🚴‍♂️",
                      "Strength Training 🏋️‍♂️",
                      "Yoga 🧘‍♂️",
                      "Other ⚡",
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setStateDialog(() {
                      selectedExercise = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Duration (minutes)",
                  hintText: "30",
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: caloriesCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Calories Burned (kcal)",
                  hintText: "300",
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
                final duration = int.tryParse(durationCtrl.text) ?? 0;
                final burned = int.tryParse(caloriesCtrl.text) ?? 0;
                final now = DateTime.now();
                final timeString =
                    "${now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour)}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";

                final newExercise = {
                  "name": selectedExercise,
                  "duration": duration,
                  "calories": burned,
                  "time": timeString,
                };

                final updatedExercises = List<dynamic>.from(loggedExercises)
                  ..add(newExercise);
                final currentBurned = dailyProgress?.caloriesBurned ?? 0;

                await ProgressService.logProgress(
                  caloriesBurned: currentBurned + burned,
                  exercisesJson: jsonEncode(updatedExercises),
                );

                if (!context.mounted) return;
                Navigator.pop(context);
                _loadProgress(); // Refresh data
              },
              child: const Text("Save"),
            ),
          ],
        ),
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

  Widget _buildNutritionItem(
    String label,
    String value,
    IconData icon,
    Color color,
    double width,
  ) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
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

  Widget exerciseTile(
    String name,
    String duration,
    String calories,
    String time,
  ) {
    IconData iconData = Icons.fitness_center;
    if (name.contains("Run")) {
      iconData = Icons.directions_run;
    } else if (name.contains("Walk")) {
      iconData = Icons.directions_walk;
    } else if (name.contains("Cycle")) {
      iconData = Icons.directions_bike;
    } else if (name.contains("Yoga")) {
      iconData = Icons.self_improvement;
    } else if (name.contains("Strength")) {
      iconData = Icons.fitness_center;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade50,
          child: Icon(iconData, color: Colors.orange),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          "$duration${duration.isNotEmpty && time.isNotEmpty ? ' | ' : ''}Logged at $time",
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: Text(
          "+ $calories",
          style: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
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
}
