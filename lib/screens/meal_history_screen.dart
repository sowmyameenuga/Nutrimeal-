import 'package:flutter/material.dart';
import '../services/progress_service.dart';

class MealHistoryScreen extends StatefulWidget {
  const MealHistoryScreen({super.key});

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _historyData = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await ProgressService.getMealHistory();
      if (mounted) {
        setState(() {
          _historyData = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load history: $e")),
        );
      }
    }
  }

  Future<void> _deleteMeal(int logId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Meal"),
        content: const Text("Are you sure you want to delete this meal log?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final res = await ProgressService.deleteLoggedMeal(logId);
      if (mounted) {
        if (res['statusCode'] == 200 || res.containsKey('message')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Meal deleted"), backgroundColor: Colors.green),
          );
          _loadHistory();
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['error'] ?? "Failed to delete")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Meal History", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historyData.isEmpty
              ? const Center(child: Text("No meal history found.", style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _historyData.length,
                    itemBuilder: (context, index) {
                      final dayData = _historyData[index];
                      return _buildDayCard(dayData);
                    },
                  ),
                ),
    );
  }

  Widget _buildDayCard(dynamic dayData) {
    final String dateStr = dayData['date'] ?? '';
    final int totalCals = dayData['total_calories'] ?? 0;
    final double totalPro = (dayData['total_protein'] ?? 0).toDouble();
    final List meals = dayData['meals'] ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("$totalCals kcal", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                    Text("${totalPro.toStringAsFixed(1)}g Protein", style: const TextStyle(fontSize: 12, color: Colors.blue)),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            ...meals.map((meal) => _buildMealItem(meal)),
          ],
        ),
      ),
    );
  }

  Widget _buildMealItem(dynamic meal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal['title'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildMacro("Cal", "${meal['calories']} kcal", Colors.orange),
                    const SizedBox(width: 8),
                    _buildMacro("P", "${meal['protein']}g", Colors.blue),
                  ],
                )
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
            onPressed: () => _deleteMeal(meal['id']),
          ),
        ],
      ),
    );
  }

  Widget _buildMacro(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
