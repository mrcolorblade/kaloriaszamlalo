class CalorieCalculator {

  //BMR
  static double calculateBMR({
    required bool isMale,
    required double weightKg,
    required int heightCm,
    required int age,
  }) {
    if (isMale) {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }
  }

  //Ajanlott napoi kaloria bevitel
  static int calculateMaintenanceCalories({
    required bool isMale,
    required double weightKg,
    required int heightCm,
    required int age,
  }) {
    final bmr = calculateBMR(isMale: isMale, weightKg: weightKg, heightCm: heightCm, age: age);

    final totalDailyEnergyExpenditure = bmr * 1.2;
    return totalDailyEnergyExpenditure.round();
  }

}