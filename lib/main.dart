import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/recipe_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/recommendation_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/saved_meals_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/privacy_screen.dart';
import 'screens/meal_history_screen.dart';
import 'screens/forgot_password_screen.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriMeal',
      debugShowCheckedModeBanner: false,

      initialRoute: '/',

      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/recipe': (context) => const RecipeScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/progress': (context) => const ProgressScreen(),
        '/recommendation': (context) => const RecommendationScreen(),
        '/insights': (context) => const InsightsScreen(),
        '/saved_meals': (context) => const SavedMealsScreen(),
        '/meal_history': (context) => const MealHistoryScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/privacy': (context) => const PrivacyScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
      },
    );
  }
}