import 'package:flutter/material.dart';

class RecipeScreen extends StatelessWidget {
  const RecipeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recipe"),
        backgroundColor: Colors.green,
      ),

      body: const Center(
        child: Text(
          "Recipe Page Coming Soon 🍲",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}