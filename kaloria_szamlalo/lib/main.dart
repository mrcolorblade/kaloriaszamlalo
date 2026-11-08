import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/user_model.dart';
import 'screens/onboarding_screen.dart';
import 'models/calorie_entry.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  // Flutter binding biztosítása az aszinkron Hive inithez
  WidgetsFlutterBinding.ensureInitialized();

  // Hive inicializálása a telefon/böngésző lokális tárolóján
  await Hive.initFlutter();

  // A generált UserModel adapter regisztrációja
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(CalorieEntryAdapter());

  // Megnyitjuk a felhasználói adatokat tároló dobozt
  final userBox = await Hive.openBox<UserModel>('userBox');
  await Hive.openBox<CalorieEntry>('calorieBox');

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
      home: hasProfile ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}