import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {

  @HiveField(0)
  final String username;

  @HiveField(1)
  final bool isMale;

  @HiveField(2)
  final int age;

  @HiveField(3)
  final int height;

  @HiveField(4)
  final double weight;

  @HiveField(5)
  final int calorieGoal;

  UserModel({
    required this.username,
    required this.isMale,
    required this.age,
    required this.height,
    required this.weight,
    required this.calorieGoal,
  });

  //BMI számítás
  double get bmi {
    final heightInMeters = height / 100.0;
    return weight / (heightInMeters * heightInMeters);
  }


  //Szöveg return
  String? get bmiCategory {
    final val = bmi;
    if (val < 18.5) return "Alacsony 🥹";
    if (val <= 24.9) return "Normál 😊";
    if (val <= 29.9) return "Túlsúlyos ☹️";
    return "Elhízott 💀";
  }

}