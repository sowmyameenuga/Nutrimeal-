import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _mealReminders = true;
  bool _waterReminders = true;
  bool _dailyQuotes = false;
  bool _marketingEmails = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Push Notifications",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildSwitch(
            "Meal Reminders",
            "Get notified when it's time for your planned meals.",
            _mealReminders,
            (val) => setState(() => _mealReminders = val),
          ),
          _buildSwitch(
            "Water Hydration",
            "Reminders to drink water throughout the day.",
            _waterReminders,
            (val) => setState(() => _waterReminders = val),
          ),
          _buildSwitch(
            "Daily Health Quotes",
            "Receive an inspiring health quote every morning.",
            _dailyQuotes,
            (val) => setState(() => _dailyQuotes = val),
          ),
          const SizedBox(height: 30),
          const Text(
            "Email Preferences",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildSwitch(
            "Marketing & Offers",
            "Receive emails about new features and offers.",
            _marketingEmails,
            (val) => setState(() => _marketingEmails = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        activeColor: Colors.green,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
