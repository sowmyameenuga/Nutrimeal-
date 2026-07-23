import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController name = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool _isLoading = false;

  Future<void> signupUser() async {
    if (name.text.isEmpty || email.text.isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final response = await AuthService.signup(
      name: name.text.trim(),
      email: email.text.trim(),
      password: password.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response['statusCode'] == 201) {
      Navigator.pushReplacementNamed(context, '/profile');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['error'] ?? "Signup failed"),
        ),
      );
    }
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Signup"),
        backgroundColor: Colors.green,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;

          final formFields = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Create Account",
                style: TextStyle(
                  fontSize: isWide ? 32 : 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (isWide) ...[
                const SizedBox(height: 8),
                const Text(
                  "Sign up to start tracking your daily nutrition.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 36),
              TextField(
                controller: name,
                decoration: InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: email,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
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
                    await signupUser();
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
                          "Sign Up",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Back to Login", style: TextStyle(fontSize: 15)),
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
                            "Start your journey today.",
                            style: TextStyle(fontSize: 18, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Right Panel: Form
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
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: email,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password"),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    await signupUser();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("Sign Up"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Back to Login"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}