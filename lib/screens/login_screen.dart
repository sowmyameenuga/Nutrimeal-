import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> loginUser() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final response = await AuthService.login(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response['statusCode'] == 200) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['error'] ?? "Login failed"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text("Login"),
        backgroundColor: Colors.green,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;

          final formFields = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isWide) ...[
                const Center(
                  child: Icon(Icons.lock, size: 100, color: Colors.green),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                "Welcome Back",
                style: TextStyle(
                  fontSize: isWide ? 32 : 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (isWide) ...[
                const SizedBox(height: 8),
                const Text(
                  "Sign in to continue tracking your meals.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 30),
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
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Password",
                  prefixIcon: const Icon(Icons.lock),
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
                  onPressed: _isLoading ? null : () async {
                    await loginUser();
                  },
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
                          "Login",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  child: const Text("Create new account", style: TextStyle(fontSize: 15)),
                ),
              ),
            ],
          );

          if (isWide) {
            return Row(
              children: [
                // Left Panel: Green Gradient Branding
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
                          Icon(Icons.restaurant_menu, size: 140, color: Colors.white),
                          SizedBox(height: 24),
                          Text(
                            "NutriMeal",
                            style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Your smart food & health companion",
                            style: TextStyle(fontSize: 18, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Right Panel: Login Form
                Expanded(
                  flex: 5,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: formFields,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // Mobile layout — unchanged
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [formFields],
            ),
          );
        },
      ),
    );
  }
}