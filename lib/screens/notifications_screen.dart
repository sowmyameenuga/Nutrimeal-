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
  bool _soundAndVibrate = true;
  bool _progressAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text("App Notifications"),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "In-App & Push Notifications",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 15),
          _buildSwitch(
            "Meal Reminders",
            "Get notified on screen when it's time for your planned breakfast, lunch, or dinner.",
            _mealReminders,
            (val) => setState(() => _mealReminders = val),
          ),
          _buildSwitch(
            "Water Hydration Alerts",
            "Hourly screen alerts to drink water and log your target glasses.",
            _waterReminders,
            (val) => setState(() => _waterReminders = val),
          ),
          _buildSwitch(
            "Daily Health Quotes",
            "Receive an inspiring wellness notification every morning inside the app.",
            _dailyQuotes,
            (val) => setState(() => _dailyQuotes = val),
          ),
          _buildSwitch(
            "Progress & Achievement Alerts",
            "Receive alerts inside the app when you hit your daily macro or hydration targets.",
            _progressAlerts,
            (val) => setState(() => _progressAlerts = val),
          ),
          const SizedBox(height: 25),
          const Text(
            "Alert Styles",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 15),
          _buildSwitch(
            "Sound & Haptic Vibration",
            "Play alert sound and vibrate on receiving in-app notification banners.",
            _soundAndVibrate,
            (val) => setState(() => _soundAndVibrate = val),
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
