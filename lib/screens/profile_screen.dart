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
  // For feet/inches mode
  final TextEditingController heightFeetController = TextEditingController();
  final TextEditingController heightInchesController = TextEditingController();

  String selectedGender = "Male";
  String selectedGoal = "Weight Loss";
  String selectedAllergy = "None";
  String selectedDiet = "Veg";

  // Unit selection
  String _heightUnit = "cm"; // "cm" or "ft"
  String _weightUnit = "kg"; // "kg" or "lb"

  // Validation error messages
  String? _heightError;
  String? _weightError;

  bool _isLoading = false;
  bool _isSaving = false;

  // Conversion constants
  static const double _cmPerFoot = 30.48;
  static const double _cmPerInch = 2.54;
  static const double _lbPerKg = 2.20462;

  // Validation limits (in base units)
  static const double _minHeightCm = 50;
  static const double _maxHeightCm = 250;
  static const double _minWeightKg = 20;
  static const double _maxWeightKg = 300;

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
          final double cm = (response['height_cm'] as num).toDouble();
          if (_heightUnit == "cm") {
            heightController.text = cm.toStringAsFixed(1);
          } else {
            _setCmToFeetInches(cm);
          }
        }
        if (response['weight_kg'] != null) {
          final double kg = (response['weight_kg'] as num).toDouble();
          if (_weightUnit == "kg") {
            weightController.text = kg.toStringAsFixed(1);
          } else {
            weightController.text = (kg * _lbPerKg).toStringAsFixed(1);
          }
        }

        selectedGender = response['gender'] ?? selectedGender;
        selectedGoal = response['goal'] ?? selectedGoal;
        selectedAllergy = response['allergy'] ?? selectedAllergy;
        selectedDiet = response['diet'] ?? selectedDiet;
      });
    }
  }

  void _setCmToFeetInches(double cm) {
    final totalInches = cm / _cmPerInch;
    final feet = totalInches ~/ 12;
    final inches = (totalInches % 12).round();
    heightFeetController.text = feet.toString();
    heightInchesController.text = inches.toString();
  }

  /// Convert the current height input to cm regardless of unit
  double? _getHeightInCm() {
    if (_heightUnit == "cm") {
      return double.tryParse(heightController.text.trim());
    } else {
      final feet = int.tryParse(heightFeetController.text.trim()) ?? 0;
      final inches = int.tryParse(heightInchesController.text.trim()) ?? 0;
      if (feet == 0 && inches == 0) return null;
      return (feet * _cmPerFoot) + (inches * _cmPerInch);
    }
  }

  /// Convert the current weight input to kg regardless of unit
  double? _getWeightInKg() {
    final val = double.tryParse(weightController.text.trim());
    if (val == null) return null;
    if (_weightUnit == "lb") {
      return val / _lbPerKg;
    }
    return val;
  }

  /// Validate height and return error string or null
  String? _validateHeight() {
    final cm = _getHeightInCm();
    if (cm == null) return "Please enter your height";
    if (cm < _minHeightCm || cm > _maxHeightCm) {
      if (_heightUnit == "cm") {
        return "Height must be between ${_minHeightCm.toInt()}–${_maxHeightCm.toInt()} cm";
      } else {
        return "Height must be between 1'8\" – 8'2\"";
      }
    }
    return null;
  }

  /// Validate weight and return error string or null
  String? _validateWeight() {
    final kg = _getWeightInKg();
    if (kg == null) return "Please enter your weight";
    if (kg < _minWeightKg || kg > _maxWeightKg) {
      if (_weightUnit == "kg") {
        return "Weight must be between ${_minWeightKg.toInt()}–${_maxWeightKg.toInt()} kg";
      } else {
        return "Weight must be between ${(_minWeightKg * _lbPerKg).toInt()}–${(_maxWeightKg * _lbPerKg).toInt()} lb";
      }
    }
    return null;
  }

  void _onHeightUnitChanged(String newUnit) {
    if (newUnit == _heightUnit) return;

    if (_heightUnit == "cm" && newUnit == "ft") {
      // Convert current cm value to ft/in
      final cm = double.tryParse(heightController.text.trim());
      if (cm != null) {
        _setCmToFeetInches(cm);
      } else {
        heightFeetController.clear();
        heightInchesController.clear();
      }
    } else if (_heightUnit == "ft" && newUnit == "cm") {
      // Convert current ft/in to cm
      final cm = _getHeightInCm();
      if (cm != null) {
        heightController.text = cm.toStringAsFixed(1);
      } else {
        heightController.clear();
      }
    }

    setState(() {
      _heightUnit = newUnit;
      _heightError = null;
    });
  }

  void _onWeightUnitChanged(String newUnit) {
    if (newUnit == _weightUnit) return;

    final currentVal = double.tryParse(weightController.text.trim());
    if (currentVal != null) {
      if (_weightUnit == "kg" && newUnit == "lb") {
        weightController.text = (currentVal * _lbPerKg).toStringAsFixed(1);
      } else if (_weightUnit == "lb" && newUnit == "kg") {
        weightController.text = (currentVal / _lbPerKg).toStringAsFixed(1);
      }
    }

    setState(() {
      _weightUnit = newUnit;
      _weightError = null;
    });
  }

  Future<void> saveProfile() async {
    // Validate
    final heightErr = _validateHeight();
    final weightErr = _validateWeight();
    setState(() {
      _heightError = heightErr;
      _weightError = weightErr;
    });

    if (heightErr != null || weightErr != null) return;

    setState(() => _isSaving = true);

    final heightCm = _getHeightInCm()!;
    final weightKg = _getWeightInKg()!;

    final response = await ProfileService.saveProfile(
      name: nameController.text,
      age: ageController.text,
      gender: selectedGender,
      heightCm: heightCm.toStringAsFixed(1),
      weightKg: weightKg.toStringAsFixed(1),
      goal: selectedGoal,
      allergy: selectedAllergy,
      diet: selectedDiet,
      country: "Global",
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
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

            // HEIGHT with unit selector
            _buildHeightField(),
            const SizedBox(height: 20),

            // WEIGHT with unit selector
            _buildWeightField(),
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

            // ⭐ DIET DROPDOWN
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
        ),
      ),
    );
  }

  /// Height field with unit toggle (cm or ft/in)
  Widget _buildHeightField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.height, color: Colors.grey),
            const SizedBox(width: 8),
            const Text("Height", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            // Unit toggle
            ToggleButtons(
              isSelected: [_heightUnit == "cm", _heightUnit == "ft"],
              onPressed: (index) {
                _onHeightUnitChanged(index == 0 ? "cm" : "ft");
              },
              borderRadius: BorderRadius.circular(10),
              selectedColor: Colors.white,
              fillColor: Colors.green,
              color: Colors.green,
              constraints: const BoxConstraints(minWidth: 50, minHeight: 36),
              children: const [
                Text("cm"),
                Text("ft/in"),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_heightUnit == "cm")
          TextField(
            controller: heightController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "Height in cm (e.g. 170)",
              prefixIcon: const Icon(Icons.straighten),
              suffixText: "cm",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              filled: true,
              fillColor: Colors.white,
              errorText: _heightError,
            ),
            onChanged: (_) => setState(() => _heightError = null),
          )
        else
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: heightFeetController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Feet",
                    suffixText: "ft",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (_) => setState(() => _heightError = null),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: heightInchesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Inches",
                    suffixText: "in",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (_) => setState(() => _heightError = null),
                ),
              ),
            ],
          ),
        if (_heightError != null && _heightUnit == "ft")
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(_heightError!, style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
          ),
      ],
    );
  }

  /// Weight field with unit toggle (kg or lb)
  Widget _buildWeightField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.monitor_weight, color: Colors.grey),
            const SizedBox(width: 8),
            const Text("Weight", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            // Unit toggle
            ToggleButtons(
              isSelected: [_weightUnit == "kg", _weightUnit == "lb"],
              onPressed: (index) {
                _onWeightUnitChanged(index == 0 ? "kg" : "lb");
              },
              borderRadius: BorderRadius.circular(10),
              selectedColor: Colors.white,
              fillColor: Colors.green,
              color: Colors.green,
              constraints: const BoxConstraints(minWidth: 50, minHeight: 36),
              children: const [
                Text("kg"),
                Text("lb"),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: weightController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: _weightUnit == "kg" ? "Weight in kg (e.g. 65)" : "Weight in lb (e.g. 143)",
            prefixIcon: const Icon(Icons.fitness_center),
            suffixText: _weightUnit,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            filled: true,
            fillColor: Colors.white,
            errorText: _weightError,
          ),
          onChanged: (_) => setState(() => _weightError = null),
        ),
      ],
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