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
          title: 'Első szikra',
          text: 'Minden nagy utazás és komoly build az első lépéssel kezdődik. Rögzíts bátran!',
        ),
      ];
    }

    // --- Matek & Átváltások ---
    final int burgers = (totalCalories / 300).round();
    final int pancakes = (totalCalories / 90).round();
    final int pizzas = (totalCalories / 1200).round();
    final int walkKm = (totalCalories / 65).round();
    final int pushups = (totalCalories / 0.5).round();
    final int dumbbellPresses = (totalCalories / 0.35).round(); // ~0.35 kcal / ismétlés súlyzóval
    final int phoneCharges = (totalCalories / 12).round(); // 1 teljes okostelefon töltés ~12 kcal (50 kJ)
    final int ps5GamingHours = (totalCalories / 180).round(); // PS5 ~210W terhelve -> ~180 kcal/óra
    final int colibriDays = (totalCalories / 10).round(); // Egy kolibri napi fogyasztása ~10 kcal
    final int minecraftTorches = (totalCalories / 50).round(); // Szén/fáklya analógia
    final int boilLiters = (totalCalories / 80).round(); // 1L 20°C víz forrásig ~80 kcal

    final List<FunFactItem> list = [
      // Kaja vonal
      FunFactItem(
        emoji: '🍔',
        title: 'Sajtburesz index',
        text: 'Ez a kalóriamennyiség nagyjából $burgers db klasszikus sajtburesz energiatartalma.',
      ),
      FunFactItem(
        emoji: '🥞',
        title: 'Palacsinta torony',
        text: 'Ennyi energiából kisüthetnél és megpakolhatnál kb. $pancakes db házi palacsintát.',
      ),

      // Edzés / Fizikai erő
      FunFactItem(
        emoji: '🚶‍♂️',
        title: 'Országjárás',
        text: 'Ezzel a kalóriamennyiséggel nagyjából $walkKm kilométert tudnál folyamatosan gyalogolni.',
      ),
      FunFactItem(
        emoji: '💪',
        title: 'Edzőtermi erő',
        text: 'Ez az energiamennyiség kb. $pushups szabályos fekvőtámasz lenyomásához lenne elegendő.',
      ),
      FunFactItem(
        emoji: '🏋️‍♂️',
        title: 'Vasgyúrás',
        text: 'Ez a tápérték nagyjából $dumbbellPresses szabályos súlyzós nyomáshoz biztosítana üzemanyagot.',
      ),

      // Geek / Gamer / Tech vonal
      FunFactItem(
        emoji: '⚡',
        title: 'Okostelefon töltés',
        text: 'Ennyi energiával nagyjából $phoneCharges alkalommal tölthetnél fel egy telefont 0-ról 100%-ra.',
      ),
      FunFactItem(
        emoji: '🎮',
        title: 'Gamer terhelés',
        text: 'Ez a bemenet egy csúcsra járatott játékkonzol $ps5GamingHours órányi teljes áramfogyasztásának felel meg.',
      ),
      FunFactItem(
        emoji: '☕',
        title: 'Hőerőmű',
        text: 'Ezzel a hőenergiával nagyjából $boilLiters liter jéghideg vizet forralhatnál fel teának vagy kávénak.',
      ),
      FunFactItem(
        emoji: '⛏️',
        title: 'Bányász üzemmód',
        text: 'Ennyi tiszta energiából nagyjából $minecraftTorches fáklyát tarthatnál égve a barlangrendszerekben.',
      ),

      // Állatos / Természet
      FunFactItem(
        emoji: '🐦',
        title: 'Kolibri légierő',
        text: 'Egy szélsebesen csapkodó kolibri ezzel a táplálékkal $colibriDays napig folyamatosan lebegne a levegőben.',
      ),
    ];

    // Magasabb szinteknél unlockolódó mérföldkövek
    if (pizzas >= 2) {
      list.add(
        FunFactItem(
          emoji: '🍕',
          title: 'Pizzaparti',
          text: 'Eddig összesen kb. $pizzas egész családi méretű pizzányi kalóriát vittél be a szervezetedbe.',
        ),
      );
    }

    if (totalCalories >= 15000) {
      list.add(
        FunFactItem(
          emoji: '🐻',
          title: 'Mackó üzemmód',
          text: 'Ez a kalóriamennyiség egy kifejlett barnamedve teljes 2 napos téli tartaléka a barlangban.',
        ),
      );
    }

    if (totalCalories >= 25000) {
      list.add(
        FunFactItem(
          emoji: '🐋',
          title: 'Kék bálna reggeli',
          text: 'Ez a táplálék egy növendék kék bálnának még csak egyetlen tisztességes torkos falat krill.',
        ),
      );
      list.add(
        FunFactItem(
          emoji: '🚀',
          title: 'Rakéta hajtómű',
          text: 'Ennyi energiával egy 1 tonnás autót simán felgyorsíthatnál 0-ról autópálya tempóra... többször is.',
        ),
      );
    }

    if (totalCalories >= 50000) {
      list.add(
        FunFactItem(
          emoji: '⚡🌩️',
          title: 'Természet ereje',
          text: 'Gratulálunk! Az eddig bevitt kalóriáid már egy kisebb villámcsapás teljes energiájával vetekszenek.',
        ),
      );
    }

    return list;
  }
}