enum GoalType {
  weightLoss,    // Fogyás (-400 kcal)
  maintenance,   // Súlytartás (0 kcal)
  muscleGain,    // Tömegnövelés / izomépítés (+300 kcal)
}

class CalorieCalculator {
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

  static int calculateGoalCalories({
    required bool isMale,
    required double weightKg,
    required int heightCm,
    required int age,
    required GoalType goal,
  }) {
    final bmr = calculateBMR(
      isMale: isMale,
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
    );

    // Alap fenntartó energiaszükséglet enyhe mozgással (~1.2 szorzó)
    final maintenance = (bmr * 1.2).round();

    switch (goal) {
      case GoalType.weightLoss:
        // Biztonságos deficit, de ne menjen a nyers BMR alá
        final deficit = maintenance - 400;
        return deficit < bmr.round() ? bmr.round() : deficit;
      case GoalType.maintenance:
        return maintenance;
      case GoalType.muscleGain:
        return maintenance + 300;
    }
  }
}