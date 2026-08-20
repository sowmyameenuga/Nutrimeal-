import 'package:flutter/material.dart';
import '../models/progress_model.dart';
import '../services/progress_service.dart';
import '../services/exercise_service.dart';
import '../services/profile_service.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  ProgressModel? dailyProgress;
  bool _isLoading = true;
  double userWeight = 70.0;

  // Recommendation states
  String recommendedExercise = "";
  int recommendedDuration = 0;
  String recommendedIntensity = "";
  int recommendedCalories = 0;
  String _recommendError = "";
  bool recommendedIsReps = false;

  // Choose your own exercise states
  String chosenExercise = "Walking";
  final TextEditingController chosenDurationCtrl = TextEditingController(text: "30");
  String chosenIntensity = "Moderate";

  @override
  void initState() {
    super.initState();
    _loadWorkoutData();
  }

  Future<void> _loadWorkoutData() async {
    setState(() => _isLoading = true);

    final dailyResponse = await ProgressService.getDailyProgress();
    final recommendRes = await ExerciseService.getExerciseRecommendation();
    final profileRes = await ProfileService.getProfile();

    if (!mounted) return;

    if (dailyResponse['statusCode'] == 200) {
      dailyProgress = ProgressModel.fromJson(dailyResponse);
    }

    if (profileRes['statusCode'] == 200 && profileRes['profile'] != null) {
      final p = profileRes['profile'];
      final w = p['weight_kg'];
      if (w != null) {
        userWeight = double.tryParse(w.toString()) ?? 70.0;
      }
    }

    if (dailyProgress != null && dailyProgress!.currentWeight > 0) {
      userWeight = dailyProgress!.currentWeight;
    }

    if (recommendRes['statusCode'] == 200) {
      recommendedExercise = recommendRes['exercise_name'] ?? "";
      recommendedDuration = (recommendRes['duration_minutes'] ?? 0).toInt();
      recommendedIntensity = recommendRes['intensity'] ?? "";
      recommendedCalories = (recommendRes['calories_burned'] ?? 0).toInt();
      recommendedIsReps = recommendRes['is_repetition_based'] ?? false;
      _recommendError = "";
    } else {
      _recommendError = recommendRes['error'] ?? "Failed to load recommendation. Please update your profile with weight/age first.";
      recommendedExercise = "";
    }

    setState(() => _isLoading = false);
  }

  int get customEstimatedCalories {
    final amount = int.tryParse(chosenDurationCtrl.text) ?? 0;
    return ExerciseService.calculateEstimatedCalories(
      exerciseName: chosenExercise,
      amount: amount,
      intensity: chosenIntensity,
      weight: userWeight,
    );
  }

  Future<void> _logRecommendedExercise() async {
    if (recommendedExercise.isEmpty) return;
    setState(() => _isLoading = true);
    final response = await ExerciseService.logExercise(
      exerciseName: recommendedExercise,
      durationMinutes: recommendedDuration,
      intensity: recommendedIntensity,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (response['statusCode'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Recommended exercise logged successfully!"), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Go back after logging
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['error'] ?? "Failed to log recommended exercise")),
      );
    }
  }

  Future<void> _logCustomExercise() async {
    final amount = int.tryParse(chosenDurationCtrl.text) ?? 0;
    final isReps = ExerciseService.isRepetitionBased(chosenExercise);
    final label = isReps ? "repetitions" : "duration";
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a valid $label greater than 0.")),
      );
      return;
    }
    setState(() => _isLoading = true);
    final response = await ExerciseService.logExercise(
      exerciseName: chosenExercise,
      durationMinutes: amount,
      intensity: chosenIntensity,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (response['statusCode'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Custom exercise saved successfully!"), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Go back after logging
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['error'] ?? "Failed to log exercise")),
      );
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Workouts & Exercises",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // OPTION A: RECOMMENDED FOR YOU
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Recommended for You 🌟",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_recommendError.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              _recommendError,
                              style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                            ),
                          )
                        else if (recommendedExercise.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              "No recommendations found. Make sure age/weight are set in Profile.",
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.deepPurple.shade100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 24),
                                    const SizedBox(width: 8),
                                    Text(
                                      recommendedExercise,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  recommendedIsReps
                                      ? "$recommendedDuration repetitions • $recommendedIntensity intensity"
                                      : "$recommendedDuration minutes • $recommendedIntensity intensity",
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Estimated Calories Burned: ~$recommendedCalories kcal",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _logRecommendedExercise,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text("Log Recommended Exercise", style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // OPTION B: CHOOSE YOUR OWN EXERCISE
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Choose Your Own Exercise 🏃",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        const Text("Exercise Type", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: chosenExercise,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          items: ExerciseService.getAllExercises()
                              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                chosenExercise = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        Text(
                          ExerciseService.isRepetitionBased(chosenExercise)
                              ? "Repetitions"
                              : "Duration (minutes)",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: chosenDurationCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {}); // triggers dynamic estimate update
                          },
                        ),
                        const SizedBox(height: 16),

                        const Text("Intensity", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: ["Low", "Moderate", "High"].map((level) {
                            final isSelected = chosenIntensity == level;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: isSelected ? Colors.orange : Colors.white,
                                    side: BorderSide(color: isSelected ? Colors.orange : Colors.grey.shade300),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      chosenIntensity = level;
                                    });
                                  },
                                  child: Text(
                                    level,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black87,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade100),
                          ),
                          child: Text(
                            "Estimated Calorie Burn: $customEstimatedCalories kcal\n(Based on weight: ${userWeight.toStringAsFixed(1)} kg)",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _logCustomExercise,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("Save Exercise", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // SAFETY DISCLAIMER
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blueGrey, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Exercise recommendations are general wellness suggestions. If you have an injury, medical condition, or physical limitation, consult a qualified healthcare professional before starting a new exercise routine.",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
