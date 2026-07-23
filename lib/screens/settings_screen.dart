import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,

      appBar: AppBar(
        title: const Text("Settings ⚙️"),
        backgroundColor: Colors.green,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [

          const SizedBox(height: 10),

          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.green,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),

          const SizedBox(height: 10),

          const Center(
            child: Text(
              "User Settings",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 20),

          settingsTile(Icons.person, "Edit Profile", () {
            Navigator.pushNamed(context, '/profile');
          }),

          settingsTile(Icons.lock, "Privacy & Security", () {
            Navigator.pushNamed(context, '/privacy');
          }),

          settingsTile(Icons.help, "Help & Support", () {
            showDialog(
              context: context,
              builder: (_) => const AlertDialog(
                title: Text("Help"),
                content: Text("Contact support: support@aiapp.com"),
              ),
            );
          }),

          settingsTile(Icons.info_outline, "About the App", () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.restaurant_menu, color: Colors.green),
                    SizedBox(width: 8),
                    Text("NutriMeal"),
                  ],
                ),
                content: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Version 1.0.0\n"),
                    Text("NutriMeal is your smart food & health companion. "
                        "Track your daily nutrition, get personalized meal recommendations, "
                        "monitor your progress, and achieve your health goals.\n"),
                    Text("Built with ❤️ using Flutter & AI."),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(_),
                    child: const Text("Close"),
                  ),
                ],
              ),
            );
          }),

          settingsTile(Icons.logout, "Logout", () async {
            await AuthService.logout();
            if (!context.mounted) return;
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
                  (route) => false,
            );
          }),
        ],
      ),
    );
  }

  Widget settingsTile(IconData icon, String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),

      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),

        onTap: onTap,
      ),
    );
  }
}