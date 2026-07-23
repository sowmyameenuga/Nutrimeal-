import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _resetToken;
  bool _tokenObtained = false;

  Future<void> _requestReset() async {
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final response = await AuthService.forgotPassword(
      email: emailController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response['statusCode'] == 200 && response['reset_token'] != null) {
      setState(() {
        _resetToken = response['reset_token'];
        _tokenObtained = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email verified! Enter your new password.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['error'] ?? "Failed to verify email")),
      );
    }
  }

  Future<void> _resetPassword() async {
    if (newPasswordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a new password")),
      );
      return;
    }

    if (newPasswordController.text.trim().length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 4 characters")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final response = await AuthService.resetPassword(
      resetToken: _resetToken!,
      newPassword: newPasswordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response['statusCode'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset successfully! Please login.")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['error'] ?? "Failed to reset password")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text("Forgot Password"),
        backgroundColor: Colors.green,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;

          final formContent = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isWide) ...[
                const Center(
                  child: Icon(Icons.lock_reset, size: 80, color: Colors.green),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                _tokenObtained ? "Set New Password" : "Forgot Password",
                style: TextStyle(
                  fontSize: isWide ? 32 : 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _tokenObtained
                    ? "Enter your new password below."
                    : "Enter your email and we'll help you reset your password.",
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 30),

              if (!_tokenObtained) ...[
                // Step 1: Email input
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: "Email",
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _requestReset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Verify Email",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                ),
              ] else ...[
                // Step 2: New password input
                TextField(
                  controller: newPasswordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: "New Password",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Reset Password",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                ),
              ],

              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Back to Login", style: TextStyle(fontSize: 15)),
                ),
              ),
            ],
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade700, Colors.green.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_reset, size: 140, color: Colors.white),
                          SizedBox(height: 24),
                          Text(
                            "NutriMeal",
                            style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Reset your password securely",
                            style: TextStyle(fontSize: 18, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: formContent,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: formContent,
          );
        },
      ),
    );
  }
}
