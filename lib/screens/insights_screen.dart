import 'package:flutter/material.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  static const List<Map<String, String>> _quotes = [
    {
      "text": "The food you eat can be either the safest and most powerful form of medicine or the slowest form of poison.",
      "author": "Ann Wigmore"
    },
    {
      "text": "Let food be thy medicine and medicine be thy food.",
      "author": "Hippocrates"
    },
    {
      "text": "To ensure good health: eat lightly, breathe deeply, live moderately, cultivate cheerfulness, and maintain an interest in life.",
      "author": "William Londen"
    },
    {
      "text": "Take care of your body. It's the only place you have to live.",
      "author": "Jim Rohn"
    },
    {
      "text": "Water is the driving force of all nature.",
      "author": "Leonardo da Vinci"
    },
    {
      "text": "He who has health has hope, and he who has hope has everything.",
      "author": "Arabian Proverb"
    },
    {
      "text": "A healthy outside starts from the inside.",
      "author": "Robert Urich"
    }
  ];

  static const List<Map<String, dynamic>> _tipsPool = [
    {"icon": Icons.local_dining, "color": Colors.orange, "title": "Eat more fiber", "desc": "Add chia seeds or flaxseeds to your morning smoothies to boost your fiber intake."},
    {"icon": Icons.nightlight_round, "color": Colors.indigo, "title": "Don't eat too late", "desc": "Try to finish your dinner at least 2-3 hours before going to bed to improve sleep quality."},
    {"icon": Icons.fitness_center, "color": Colors.teal, "title": "Protein pacing", "desc": "Spread your protein intake evenly across meals rather than consuming it all at dinner."},
    {"icon": Icons.water_drop, "color": Colors.blue, "title": "Hydrate before meals", "desc": "Drinking a glass of water 30 minutes before a meal can aid digestion."},
    {"icon": Icons.monitor_weight, "color": Colors.purple, "title": "Mindful eating", "desc": "Eat slowly and without distractions (like TV or phone) to recognize when you're full."},
    {"icon": Icons.restaurant, "color": Colors.green, "title": "Eat the rainbow", "desc": "Try to include at least 3 different colors of vegetables in your daily meals."},
    {"icon": Icons.directions_walk, "color": Colors.red, "title": "Post-meal walk", "desc": "A 10-minute walk after eating can significantly help balance your blood sugar levels."},
    {"icon": Icons.emoji_nature, "color": Colors.amber, "title": "Healthy snacking", "desc": "Keep nuts, seeds, or fruits visible on your counter instead of processed snacks."},
    {"icon": Icons.bedtime, "color": Colors.deepPurple, "title": "Prioritize sleep", "desc": "Poor sleep can disrupt your appetite hormones. Aim for 7-8 hours per night."},
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    
    final currentQuote = _quotes[dayOfYear % _quotes.length];
    
    final tipsCount = _tipsPool.length;
    final tip1 = _tipsPool[dayOfYear % tipsCount];
    final tip2 = _tipsPool[(dayOfYear + 1) % tipsCount];
    final tip3 = _tipsPool[(dayOfYear + 2) % tipsCount];
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Insights", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Health Quote
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.deepPurple, Colors.purpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.deepPurple.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote, color: Colors.white70, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    "\"${currentQuote['text']}\"",
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "— ${currentQuote['author']}",
                    style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),


            // Nutrition Tips
            const Text("Quick Tips", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildTipCard(tip1['icon'], tip1['color'], tip1['title'], tip1['desc']),
            _buildTipCard(tip2['icon'], tip2['color'], tip2['title'], tip2['desc']),
            _buildTipCard(tip3['icon'], tip3['color'], tip3['title'], tip3['desc']),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(IconData icon, Color color, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
