import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _shareData = false;
  bool _publicProfile = false;

  void _showChangePasswordDialog() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text("Change Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldCtrl,
                obscureText: obscureOld,
                decoration: InputDecoration(
                  labelText: "Current Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setDialogState(() => obscureOld = !obscureOld),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newCtrl,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: "New Password",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (oldCtrl.text.isEmpty || newCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please fill both fields")),
                        );
                        return;
                      }
                      if (newCtrl.text.length < 4) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("New password must be at least 4 characters")),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      final response = await AuthService.changePassword(
                        oldPassword: oldCtrl.text,
                        newPassword: newCtrl.text,
                      );

                      if (!mounted) return;
                      setDialogState(() => isLoading = false);

                      Navigator.pop(ctx);

                      if (response['statusCode'] == 200) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("✅ Password changed successfully!"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(response['error'] ?? "Failed to change password"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text("Update", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text("Delete Account"),
              ],
            ),
            content: const Text(
              "This action is permanent and cannot be undone.\n\n"
              "All your data including your profile, meal plans, progress logs, "
              "and saved meals will be permanently deleted.\n\n"
              "Are you sure you want to continue?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                        setDialogState(() => isDeleting = true);

                        final response = await AuthService.deleteAccount();

                        if (!mounted) return;
                        setDialogState(() => isDeleting = false);

                        Navigator.pop(ctx);

                        if (response['statusCode'] == 200) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Account deleted successfully."),
                              backgroundColor: Colors.green,
                            ),
                          );
                          // Navigate to splash/login and clear all routes
                          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(response['error'] ?? "Failed to delete account"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text("Delete Permanently", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text("Privacy & Security"),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Account Security",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildActionTile(
            Icons.lock_reset,
            "Change Password",
            "Update your account password",
            onTap: _showChangePasswordDialog,
          ),
          
          const SizedBox(height: 30),
          const Text(
            "Data Privacy",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildSwitch(
            "Public Profile",
            "Allow others to see your progress.",
            _publicProfile,
            (val) => setState(() => _publicProfile = val),
          ),
          _buildSwitch(
            "Share Analytics Data",
            "Share anonymous usage data to improve the app.",
            _shareData,
            (val) => setState(() => _shareData = val),
          ),

          const SizedBox(height: 30),
          const Text(
            "Account Management",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text("Delete Account", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: _showDeleteAccountDialog,
            ),
          )
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

  Widget _buildActionTile(IconData icon, String title, String subtitle, {required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }
}
