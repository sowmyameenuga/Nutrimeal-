class ProfileModel {
  final int? userId;
  final String? name;
  final int? age;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final String? goal;
  final String? allergy;

  ProfileModel({
    this.userId,
    this.name,
    this.age,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.goal,
    this.allergy,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      userId: json['user_id'],
      name: json['name'],
      age: json['age'] != null ? int.tryParse(json['age'].toString()) : null,
      gender: json['gender'],
      heightCm: json['height_cm'] != null
          ? double.tryParse(json['height_cm'].toString())
          : null,
      weightKg: json['weight_kg'] != null
          ? double.tryParse(json['weight_kg'].toString())
          : null,
      goal: json['goal'],
      allergy: json['allergy'],
    );
  }
}
