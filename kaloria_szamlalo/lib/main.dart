import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/user_model.dart';
import 'screens/onboarding_screen.dart';

Future<void> main() async {
  // Flutter binding biztosítása az aszinkron Hive inithez
  WidgetsFlutterBinding.ensureInitialized();

  // Hive inicializálása a telefon/böngésző lokális tárolóján
  await Hive.initFlutter();

  // A generált UserModel adapter regisztrációja
  Hive.registerAdapter(UserModelAdapter());

  // Megnyitjuk a felhasználói adatokat tároló dobozt
  final userBox = await Hive.openBox<UserModel>('userBox');

  // Megnézzük, van-e már elmentve 'currentUser'
  final bool hasProfile = userBox.containsKey('currentUser');

  runApp(KaloriaApp(hasProfile: hasProfile));
}

class KaloriaApp extends StatelessWidget {
  final bool hasProfile;

  const KaloriaApp({super.key, required this.hasProfile});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kalóriaszámláló',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0B1E),
        fontFamily: 'SF Pro Display', // iOS natív érzet, ha nincs egyedi betű beállítva fallbackol
      ),
      // Ha van profil, mehet a főoldal, ha nincs, az onboarding
      home: hasProfile ? const PlaceholderHomeScreen() : const OnboardingScreen(),
    );
  }
}

// Ideiglenes helyőrző, amíg a következő lépésben meg nem írjuk a végleges HomeScreen-t
class PlaceholderHomeScreen extends StatelessWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<UserModel>('userBox');
    final user = box.get('currentUser');

    return Scaffold(
      backgroundColor: const Color(0xFF0F0B1E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Üdvözöllek, ${user?.username ?? "Felhasználó"}!',
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Cél: ${user?.calorieGoal} kcal | BMI: ${user?.bmi.toStringAsFixed(1)} (${user?.bmiCategory})',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                // Teszteléshez: profil törlése, hogy újra lásd az onboarding képernyőt
                await box.clear();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Profil törlése (Teszt reset)', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}