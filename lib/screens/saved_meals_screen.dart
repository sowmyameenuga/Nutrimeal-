import 'package:flutter/material.dart';
import '../services/meal_service.dart';

class SavedMealsScreen extends StatefulWidget {
  const SavedMealsScreen({super.key});

  @override
  State<SavedMealsScreen> createState() => _SavedMealsScreenState();
}

class _SavedMealsScreenState extends State<SavedMealsScreen> {
  bool _isLoading = true;
  Map<String, List<dynamic>> _savedMeals = {
    'breakfast': [],
    'lunch': [],
    'dinner': [],
    'snack': []
  };

  @override
  void initState() {
    super.initState();
    _loadSavedMeals();
  }

  Future<void> _loadSavedMeals() async {
    setState(() => _isLoading = true);
    
    final response = await MealService.getTodayMeals();
    
    if (mounted) {
      if (response['statusCode'] == 200) {
        setState(() {
          _savedMeals = {
            'breakfast': response['breakfast'] as List? ?? [],
            'lunch': response['lunch'] as List? ?? [],
            'dinner': response['dinner'] as List? ?? [],
            'snack': response['snack'] as List? ?? [],
          };
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load saved meals")),
        );
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
        title: const Text("My Saved Meals", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadSavedMeals,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMealCategory("Breakfast", _savedMeals['breakfast']!, Colors.orange, Icons.breakfast_dining),
                const SizedBox(height: 20),
                _buildMealCategory("Lunch", _savedMeals['lunch']!, Colors.green, Icons.lunch_dining),
                const SizedBox(height: 20),
                _buildMealCategory("Dinner", _savedMeals['dinner']!, Colors.indigo, Icons.dinner_dining),
                const SizedBox(height: 20),
                _buildMealCategory("Snack", _savedMeals['snack']!, Colors.pink, Icons.cookie),
              ],
            ),
          ),
    );
  }

  Widget _buildMealCategory(String title, List<dynamic> meals, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text("${meals.length} saved", style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 12),
        if (meals.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
              child: Text("No meals saved yet.", style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ...meals.map((meal) => _buildSavedMealCard(meal, color)),
      ],
    );
  }

  Future<void> _confirmDelete(dynamic meal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Saved Meal"),
        content: Text("Are you sure you want to remove '${meal['title']}' from today's plan?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      final response = await MealService.deleteMeal(meal['id']);
      if (mounted) {
        if (response['statusCode'] == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Meal deleted successfully"), backgroundColor: Colors.green),
          );
          _loadSavedMeals();
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['error'] ?? "Failed to delete meal")),
          );
        }
      }
    }
  }

  Widget _buildSavedMealCard(dynamic meal, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    meal['title'] ?? "Unknown Meal",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                  onPressed: () => _confirmDelete(meal),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildMacroPill("Cal", "${meal['calories'] ?? 0} kcal", Colors.orange),
                const SizedBox(width: 8),
                _buildMacroPill("P", "${meal['protein']?.toStringAsFixed(0) ?? 0}g", Colors.blue),
                const SizedBox(width: 8),
                _buildMacroPill("C", "${meal['carbs']?.toStringAsFixed(0) ?? 0}g", Colors.amber),
                const SizedBox(width: 8),
                _buildMacroPill("F", "${meal['fat']?.toStringAsFixed(0) ?? 0}g", Colors.red),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }


  Widget _buildMacroPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
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
