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
    }

    if (weeklyResponse['statusCode'] == 200 &&
        weeklyResponse.containsKey('data')) {
      final List rawList = weeklyResponse['data'] as List;
      weeklyActivity = rawList
          .map((item) =>
              WeeklyActivity.fromJson(item as Map<String, dynamic>))
          .toList();
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
              title: "Daily Calories",
              value: dp != null
                  ? "${dp.caloriesConsumed} / ${dp.calorieTarget} kcal"
                  : "0 / 2000 kcal",
              progress: dp?.calorieProgress.clamp(0.0, 1.0) ?? 0.0,
              icon: Icons.local_fire_department,
            ),

            const SizedBox(height: 20),

            // WATER INTAKE
            progressCard(
              title: "Water Intake",
              value: dp != null
                  ? "${dp.waterLitres.toStringAsFixed(1)} / ${dp.waterTarget.toStringAsFixed(0)} Litres"
                  : "0 / 3 Litres",
              progress: dp?.waterProgress.clamp(0.0, 1.0) ?? 0.0,
              icon: Icons.water_drop,
            ),

            const SizedBox(height: 20),

            // WEIGHT GOAL
            progressCard(
              title: "Weight Goal",
              value: dp != null
                  ? "${dp.currentWeight.toStringAsFixed(1)}kg → ${dp.weightGoal.toStringAsFixed(1)}kg"
                  : "-- → --",
              progress: dp?.weightProgress.clamp(0.0, 1.0) ?? 0.0,
              icon: Icons.monitor_weight,
            ),

            const SizedBox(height: 30),

            // BUTTONS ROW
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
                        Navigator.pushNamed(context, '/saved_meals').then((_) => _loadProgressData());
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
              ],
            ),

            const SizedBox(height: 30),

            // WEEKLY ACTIVITY (BAR CHART)
            const Text(
              "Weekly Activity (Calories)",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
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
              if (!mounted) return;
              Navigator.pop(context);
              _loadProgress(); // Refresh data
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // PROGRESS CARD
  Widget progressCard({
    required String title,
    required String value,
    required double progress,
    required IconData icon,
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
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  // WEEKLY TILE
  Widget weeklyTile(String day, String calories) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),

      child: ListTile(
        leading: const Icon(Icons.bar_chart),

        title: Text(day),

        trailing: Text(
          calories,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    // If no real data, use dummy data
    final hasData = weeklyActivity.isNotEmpty;
    final List<Map<String, dynamic>> chartData = hasData 
      ? weeklyActivity.map((a) => {"day": a.dayName.substring(0, 3), "cals": a.caloriesConsumed}).toList()
      : [
          {"day": "Mon", "cals": 1800},
          {"day": "Tue", "cals": 2100},
          {"day": "Wed", "cals": 1950},
          {"day": "Thu", "cals": 1600},
          {"day": "Fri", "cals": 2200},
          {"day": "Sat", "cals": 2400},
          {"day": "Sun", "cals": 2000},
        ];

    // Find max for scaling
    int maxCals = chartData.fold(0, (max, item) => item["cals"] > max ? item["cals"] : max);
    if (maxCals == 0) maxCals = 2000;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: chartData.map((data) {
        final double heightPercentage = (data["cals"] / maxCals).clamp(0.0, 1.0).toDouble();
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Tooltip-like text
            Text(
              "${data["cals"]}",
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            // The Bar
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
            // Day Label
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