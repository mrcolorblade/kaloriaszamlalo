import 'package:hive/hive.dart';

part 'calorie_entry.g.dart';

@HiveType(typeId: 1)
class CalorieEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int calories;

  @HiveField(2)
  final String? foodName;

  @HiveField(3)
  final DateTime dateTime;

  CalorieEntry({
    required this.id,
    required this.calories,
    this.foodName,
    required this.dateTime,
  });

  String get dateKey {
    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
  }
}