import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/user_model.dart';
import '../services/calorie_calculator.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_scaffold.dart';
import '../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _calorieController = TextEditingController();

  bool _isMale = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _calorieController.dispose();
    super.dispose();
  }

  void _calculateAutoCalories() {
    final int? age = int.tryParse(_ageController.text);
    final int? height = int.tryParse(_heightController.text);
    final double? weight = double.tryParse(_weightController.text.replaceAll(',', '.'));

    if (age == null || height == null || weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kérlek add meg a nemet, kort, magasságot és súlyt az automatikus számításhoz!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final calculated = CalorieCalculator.calculateMaintenanceCalories(
      isMale: _isMale,
      weightKg: weight,
      heightCm: height,
      age: age,
    );

    setState(() {
      _calorieController.text = calculated.toString();
    });
  }

  Future<void> _saveProfile() async {
    final String username = _usernameController.text.trim();
    final int? age = int.tryParse(_ageController.text);
    final int? height = int.tryParse(_heightController.text);
    final double? weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    final int? calorieGoal = int.tryParse(_calorieController.text);

    if (username.isEmpty || age == null || height == null || weight == null || calorieGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kérlek tölts ki minden mezőt!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

final user = UserModel(
      username: username,
      isMale: _isMale,
      age: age,
      height: height,
      weight: weight, // Biztosítjuk, hogy double legyen
      calorieGoal: calorieGoal,
    );

    final box = Hive.box<UserModel>('userBox');
    await box.put('currentUser', user);

    if (!mounted) return;

    // Átirányítás a HomeScreen-re, amint elkészül
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil sikeresen mentve!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PlaceholderHomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          children: [
            // Felső pirula címke: "Profil beállítása"
            GlassCard(
              borderRadius: 30,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: const Text(
                'Profil beállítása',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Főcím és leírás
            const Text(
              'Kezdjük veled!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add meg az adataidat a személyre szabott napi\nkalóriacélhoz.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),

            // Fő üvegkártya a form mezőkkel
            GlassCard(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Username'),
                  const SizedBox(height: 6),
                  _buildInputField(
                    controller: _usernameController,
                    hintText: 'alex_fit',
                  ),
                  const SizedBox(height: 18),

                  // Nem és Életkor egy sorban
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Nem'),
                            const SizedBox(height: 6),
                            _buildGenderSelector(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Életkor'),
                            const SizedBox(height: 6),
                            _buildInputField(
                              controller: _ageController,
                              hintText: '25',
                              suffix: 'év',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Magasság és Testsúly egy sorban
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Magasság'),
                            const SizedBox(height: 6),
                            _buildInputField(
                              controller: _heightController,
                              hintText: '173',
                              suffix: 'cm',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Testsúly'),
                            const SizedBox(height: 6),
                            _buildInputField(
                              controller: _weightController,
                              hintText: '65',
                              suffix: 'kg',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Maximális kalóriaérték sor automata gombbal
                  _buildLabel('Maximális kalóriaérték'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildInputField(
                          controller: _calorieController,
                          hintText: '2000',
                          suffix: 'kcal',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: GestureDetector(
                          onTap: _calculateAutoCalories,
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B42D6).withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Automatikus',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Állítsd be kézzel, vagy kérj automatikus értéket.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Mentés és kezdés gomb
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B64FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Mentés és kezdés',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Az adataidat később is módosíthatod.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.7),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    String? suffix,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (suffix != null)
            Text(
              suffix,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isMale = false),
              child: Container(
                decoration: BoxDecoration(
                  color: !_isMale ? const Color(0xFF6B42D6).withValues(alpha: 0.6) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_isMale) ...const [
                      Icon(Icons.check, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                    ],
                    Text(
                      'Nő',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: !_isMale ? 1.0 : 0.5),
                        fontSize: 13,
                        fontWeight: !_isMale ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isMale = true),
              child: Container(
                decoration: BoxDecoration(
                  color: _isMale ? const Color(0xFF6B42D6).withValues(alpha: 0.6) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isMale) ...const [
                      Icon(Icons.check, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                    ],
                    Text(
                      'Férfi',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: _isMale ? 1.0 : 0.5),
                        fontSize: 13,
                        fontWeight: _isMale ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}