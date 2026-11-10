import 'dart:math';

class FunFactItem {
  final String title;
  final String text;
  final String emoji;

  const FunFactItem({
    required this.title,
    required this.text,
    required this.emoji,
  });
}

class CalorieFactsService {
  static final Random _random = Random();

  static FunFactItem getRandomFact(int totalCalories) {
    final facts = _getAvailableFacts(totalCalories);
    return facts[_random.nextInt(facts.length)];
  }

  static List<FunFactItem> _getAvailableFacts(int totalCalories) {
    if (totalCalories < 1000) {
      return [
        const FunFactItem(
          emoji: '🌱',
          title: 'Kezdeti lendület',
          text: 'Minden nagy utazás egyetlen falattal indul. Rögzíts bátran!',
        ),
      ];
    }

    // Számított értékek
    final int burgers = (totalCalories / 300).round();
    final int pancakes = (totalCalories / 90).round();
    final int pizzas = (totalCalories / 1200).round();
    final int walkKm = (totalCalories / 65).round();
    final int pushups = (totalCalories / 0.5).round();
    final int phoneYears = (totalCalories / 4380).round(); // ~12 kcal egy teljes telefon feltöltés

    final List<FunFactItem> list = [
      FunFactItem(
        emoji: '🍔',
        title: 'Sajtburesz index',
        text: 'Ez a bevitel nagyjából $burgers db klasszikus sajtburesz energiatartalma.',
      ),
      FunFactItem(
        emoji: '🥞',
        title: 'Palacsinta torony',
        text: 'Ennyi energiából kisüthetnél kb. $pancakes db házi lekváros palacsintát.',
      ),
      FunFactItem(
        emoji: '🚶‍♂️',
        title: 'Országjárás',
        text: 'Ezzel a kalóriamennyiséggel nagyjából $walkKm kilométert tudnál gyalogolni.',
      ),
      FunFactItem(
        emoji: '💪',
        title: 'Edzőtermi erő',
        text: 'Ez az energiamennyiség kb. $pushups szabályos fekvőtámasz elvégzéséhez lenne elég.',
      ),
    ];

    if (pizzas >= 2) {
      list.add(
        FunFactItem(
          emoji: '🍕',
          title: 'Pizzaparti',
          text: 'Eddig összesen kb. $pizzas egész családi méretű pizzányi kalóriát vittél be.',
        ),
      );
    }

    if (totalCalories >= 15000) {
      list.add(
        FunFactItem(
          emoji: '🐻',
          title: 'Mackó üzemmód',
          text: 'Ez a kalóriamennyiség egy kifejlett barnamedve teljes 2 napos téli tartaléka.',
        ),
      );
    }

    if (phoneYears >= 1) {
      list.add(
        FunFactItem(
          emoji: '⚡',
          title: 'Akkumulátor',
          text: 'Ennyi elektromos energiával egy okostelefont $phoneYears évig tölthetnél folyamatosan.',
        ),
      );
    }

    return list;
  }
}