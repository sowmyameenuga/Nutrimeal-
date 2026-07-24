import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String? _nameError;
  String? _ageError;
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

  // ─── Validation Methods ────────────────────────────────────────────

  String? _validateName() {
    final name = nameController.text.trim();
    if (name.isEmpty) return "Please enter your name";
    if (name.length < 2) return "Name must be at least 2 characters";
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
      return "Name can only contain letters and spaces";
    }
    return null;
  }

  String? _validateAge() {
    final text = ageController.text.trim();
    if (text.isEmpty) return "Please enter your age";
    final age = int.tryParse(text);
    if (age == null) return "Age must be a number";
    if (age < 1 || age > 100) return "Age must be between 1 and 100";
    return null;
  }

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

  /// Returns true if the form is currently valid (for enabling/disabling Save button)
  bool get _isFormValid {
    return nameController.text.trim().isNotEmpty &&
        ageController.text.trim().isNotEmpty &&
        (_heightUnit == "cm"
            ? heightController.text.trim().isNotEmpty
            : (heightFeetController.text.trim().isNotEmpty || heightInchesController.text.trim().isNotEmpty)) &&
        weightController.text.trim().isNotEmpty;
  }

  // ─── Unit Conversion ───────────────────────────────────────────────

  void _onHeightUnitChanged(String newUnit) {
    if (newUnit == _heightUnit) return;

    if (_heightUnit == "cm" && newUnit == "ft") {
      final cm = double.tryParse(heightController.text.trim());
      if (cm != null) {
        _setCmToFeetInches(cm);
      } else {
        heightFeetController.clear();
        heightInchesController.clear();
      }
    } else if (_heightUnit == "ft" && newUnit == "cm") {
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

  // ─── Save ──────────────────────────────────────────────────────────

  Future<void> saveProfile() async {
    // Run all validations
    final nameErr = _validateName();
    final ageErr = _validateAge();
    final heightErr = _validateHeight();
    final weightErr = _validateWeight();
    setState(() {
      _nameError = nameErr;
      _ageError = ageErr;
      _heightError = heightErr;
      _weightError = weightErr;
    });

    if (nameErr != null || ageErr != null || heightErr != null || weightErr != null) return;

    setState(() => _isSaving = true);

    final heightCm = _getHeightInCm()!;
    final weightKg = _getWeightInKg()!;

    final response = await ProfileService.saveProfile(
      name: nameController.text.trim(),
      age: ageController.text.trim(),
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

            // NAME — letters and spaces only
            TextField(
              controller: nameController,
              keyboardType: TextInputType.name,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                LengthLimitingTextInputFormatter(50),
              ],
              decoration: InputDecoration(
                hintText: "Full Name",
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: Colors.white,
                errorText: _nameError,
              ),
              onChanged: (_) => setState(() => _nameError = null),
            ),
            const SizedBox(height: 20),

            // AGE — numbers only, 1-100
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
                _MaxValueInputFormatter(100),
              ],
              decoration: InputDecoration(
                hintText: "Age (1–100)",
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: Colors.white,
                errorText: _ageError,
              ),
              onChanged: (_) => setState(() => _ageError = null),
            ),
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
                // Disable button if form is incomplete
                onPressed: (_isSaving || !_isFormValid) ? null : saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  disabledBackgroundColor: Colors.grey.shade400,
                ),
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              LengthLimitingTextInputFormatter(5), // e.g. 250.0
              _SingleDecimalFormatter(),
            ],
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
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(1), // max 8 feet
                    _MaxValueInputFormatter(8),
                  ],
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
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2), // max 11 inches
                    _MaxValueInputFormatter(11),
                  ],
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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            LengthLimitingTextInputFormatter(6), // e.g. 300.0 or 661.4
            _SingleDecimalFormatter(),
          ],
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

// ─── Custom Input Formatters ─────────────────────────────────────────

/// Prevents entering a value greater than [maxValue].
class _MaxValueInputFormatter extends TextInputFormatter {
  final int maxValue;

  _MaxValueInputFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final intVal = int.tryParse(newValue.text);
    if (intVal == null || intVal > maxValue) {
      return oldValue;
    }
    return newValue;
  }
}

/// Allows only one decimal point in the input.
class _SingleDecimalFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    // Reject if there are multiple decimal points
    if ('.'.allMatches(text).length > 1) {
      return oldValue;
    }
    // Reject if it starts with a dot (require leading digit)
    if (text.startsWith('.')) {
      return oldValue;
    }
    return newValue;
  }
}