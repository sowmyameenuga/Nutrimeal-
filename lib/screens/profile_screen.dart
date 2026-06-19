import 'package:flutter/material.dart';
import '../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  String selectedGender = "Male";
  String selectedGoal = "Weight Loss";
  String selectedAllergy = "None";
  String selectedDiet = "Veg";

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    final response = await ProfileService.getProfile();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response['statusCode'] == 200) {
      setState(() {
        nameController.text = response['name'] ?? '';

        if (response['age'] != null) {
          ageController.text = response['age'].toString();
        }
        if (response['height_cm'] != null) {
          heightController.text = response['height_cm'].toString();
        }
        if (response['weight_kg'] != null) {
          weightController.text = response['weight_kg'].toString();
        }

        selectedGender = response['gender'] ?? selectedGender;
        selectedGoal = response['goal'] ?? selectedGoal;
        selectedAllergy = response['allergy'] ?? selectedAllergy;

        // ⭐ DIET LOAD
        selectedDiet = response['diet'] ?? selectedDiet;
      });
    }
  }

  Future<void> saveProfile() async {
    setState(() => _isSaving = true);

    final response = await ProfileService.saveProfile(
      name: nameController.text,
      age: ageController.text,
      gender: selectedGender,
      heightCm: heightController.text,
      weightKg: weightController.text,
      goal: selectedGoal,
      allergy: selectedAllergy,
      diet: selectedDiet,
      country: "Global", // Send default since UI was removed
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (response['statusCode'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile saved successfully!")),
      );
      Navigator.pushNamed(context, '/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['error'] ?? "Failed to save profile"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.green.shade50,
        appBar: AppBar(
          title: const Text("Profile"),
          backgroundColor: Colors.green,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.green,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),

            const SizedBox(height: 25),

            textField(controller: nameController, hint: "Full Name", icon: Icons.person),
            const SizedBox(height: 20),

            textField(controller: ageController, hint: "Age", icon: Icons.calendar_today),
            const SizedBox(height: 20),

            dropdownBox(
              value: selectedGender,
              icon: Icons.people,
              items: ["Male", "Female", "Other"],
              onChanged: (value) => setState(() => selectedGender = value!),
            ),

            const SizedBox(height: 20),

            textField(controller: heightController, hint: "Height (cm)", icon: Icons.height),
            const SizedBox(height: 20),

            textField(controller: weightController, hint: "Weight (kg)", icon: Icons.monitor_weight),
            const SizedBox(height: 20),

            const Text("Fitness Goal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            dropdownBox(
              value: selectedGoal,
              icon: Icons.flag,
              items: [
                "Weight Loss",
                "Weight Gain",
                "Fat Loss",
                "Muscle Gain",
                "Maintain Weight",
              ],
              onChanged: (value) => setState(() => selectedGoal = value!),
            ),

            const SizedBox(height: 20),

            const Text("Allergies", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            dropdownBox(
              value: selectedAllergy,
              icon: Icons.no_food,
              items: ["None", "Nuts", "Dairy", "Gluten", "Seafood", "Eggs"],
              onChanged: (value) => setState(() => selectedAllergy = value!),
            ),

            const SizedBox(height: 20),

            // ⭐ NEW DIET DROPDOWN
            const Text("Diet Preference (Veg / Non-Veg / Vegan)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            dropdownBox(
              value: selectedDiet,
              icon: Icons.restaurant,
              items: ["Veg", "Non-Veg", "Vegan"],
              onChanged: (value) => setState(() => selectedDiet = value!),
            ),


            const SizedBox(height: 35),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSaving ? null : saveProfile,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Save Profile",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget dropdownBox({
    required String value,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}