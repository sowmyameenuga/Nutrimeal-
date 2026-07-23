import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Small delay for splash branding
    await Future.delayed(const Duration(milliseconds: 1500));
// 
    if (!mounted) return;

    final loggedIn = await AuthService.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
    // If not logged in, stay on splash — user taps "Get Started"
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;

          final ctaContent = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isWide) ...[
                const Icon(
                  Icons.restaurant_menu,
                  size: 120,
                  color: Colors.green,
                ),
                const SizedBox(height: 20),
              ],
              Text(
                isWide ? "Welcome to NutriMeal" : "AI Nutrition App",
                style: TextStyle(
                  fontSize: isWide ? 36 : 28,
                  fontWeight: FontWeight.bold,
                  color: isWide ? Colors.black87 : Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Your smart food & health companion",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: isWide ? 300 : double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Let's Get Started",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
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
                            "AI-powered nutrition tracking",
                            style: TextStyle(fontSize: 18, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Right Panel: CTA
                Expanded(
                  flex: 5,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: ctaContent,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // Mobile layout — unchanged
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ctaContent,
            ),
          );
        },
      ),
    );
  }
}