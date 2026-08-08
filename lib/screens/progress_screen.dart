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

    setState(() => _isLoading = false);
  }

  int _calculateEstimatedCalories(
    String exercise,
    int duration,
    String intensity,
    double weight,
  ) {
    final Map<String, Map<String, double>> metMap = {
      "Running": {"Low": 6.0, "Moderate": 8.3, "High": 11.8},
      "Walking": {"Low": 2.5, "Moderate": 3.5, "High": 4.5},
      "Cycling": {"Low": 4.0, "Moderate": 6.8, "High": 10.0},
      "Swimming": {"Low": 4.5, "Moderate": 6.0, "High": 8.0},
      "Weight Lifting": {"Low": 3.0, "Moderate": 5.0, "High": 6.0},
      "Jump Rope (Skipping)": {"Low": 7.0, "Moderate": 10.0, "High": 12.0},
    };
    if (!metMap.containsKey(exercise)) return 0;
    final met = metMap[exercise]![intensity] ?? 5.0;
    final durationHours = duration / 60.0;
    return (met * weight * durationHours).round();
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
                      onPressed: () => _showLogExerciseDialog(context),
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

            const SizedBox(height: 30),

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
                            "$duration mins · $intensity intensity",
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

  void _showLogExerciseDialog(BuildContext context) {
    String selectedExercise = "Running";
    String selectedIntensity = "Moderate";
    final durationCtrl = TextEditingController();
    int estimatedCalories = 0;

    final userWeight = dailyProgress?.currentWeight ?? 70.0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void updatePreview() {
              final mins = int.tryParse(durationCtrl.text) ?? 0;
              if (mins > 0) {
                setDialogState(() {
                  estimatedCalories = _calculateEstimatedCalories(
                    selectedExercise,
                    mins,
                    selectedIntensity,
                    userWeight,
                  );
                });
              } else {
                setDialogState(() {
                  estimatedCalories = 0;
                });
              }
            }

            return AlertDialog(
              title: const Text("Log Exercise"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Exercise Type",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      value: selectedExercise,
                      isExpanded: true,
                      items:
                          [
                                "Running",
                                "Walking",
                                "Cycling",
                                "Swimming",
                                "Weight Lifting",
                                "Jump Rope (Skipping)",
                              ]
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedExercise = val);
                          updatePreview();
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Duration (minutes)",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      controller: durationCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: "e.g. 30"),
                      onChanged: (_) => updatePreview(),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Intensity",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: ["Low", "Moderate", "High"].map((intensity) {
                        return Expanded(
                          child: Row(
                            children: [
                              Radio<String>(
                                value: intensity,
                                groupValue: selectedIntensity,
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(
                                      () => selectedIntensity = val,
                                    );
                                    updatePreview();
                                  }
                                },
                              ),
                              Expanded(
                                child: Text(
                                  intensity,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Estimated Calorie Burn",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "$estimatedCalories kcal",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            "Based on weight: ${userWeight.toStringAsFixed(1)} kg",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final mins = int.tryParse(durationCtrl.text) ?? 0;
                    if (mins <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please enter a duration greater than 0 minutes.",
                          ),
                        ),
                      );
                      return;
                    }
                    if (userWeight <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please set your weight in your profile before logging an exercise.",
                          ),
                        ),
                      );
                      return;
                    }

                    final res = await ExerciseService.logExercise(
                      exerciseName: selectedExercise,
                      durationMinutes: mins,
                      intensity: selectedIntensity,
                    );

                    if (!context.mounted) return;

                    if (res['statusCode'] == 200) {
                      Navigator.pop(context);
                      _loadProgress(); // Refresh stats
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            res['error'] ?? "Failed to log exercise.",
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
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
