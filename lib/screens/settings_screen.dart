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

          settingsTile(Icons.notifications, "Notifications", () {
            Navigator.pushNamed(context, '/notifications');
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