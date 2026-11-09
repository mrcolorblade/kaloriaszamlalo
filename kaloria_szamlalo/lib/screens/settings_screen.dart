import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/calorie_entry.dart';
import '../models/user_model.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  final double cardWidth;
  final double titlePillWidth;

  const SettingsScreen({
    super.key,
    required this.cardWidth,
    required this.titlePillWidth,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _goalCtrl;
  late bool _isMale;

  UserModel? _currentUser;

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    final userBox = Hive.box<UserModel>('userBox');
    _currentUser = userBox.get('currentUser');

    _usernameCtrl = TextEditingController(text: _currentUser?.username ?? '');
    _isMale = _currentUser?.isMale ?? true;
    _ageCtrl = TextEditingController(text: _currentUser != null ? _currentUser!.age.toString() : '20');
    _heightCtrl = TextEditingController(text: _currentUser != null ? _currentUser!.height.toString() : '175');
    _weightCtrl = TextEditingController(
      text: _currentUser != null ? _currentUser!.weight.toStringAsFixed(1) : '70.0',
    );
    _goalCtrl = TextEditingController(
      text: _currentUser != null ? _currentUser!.calorieGoal.toString() : '2000',
    );
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final userBox = Hive.box<UserModel>('userBox');

    final String updatedUsername = _usernameCtrl.text.trim().isEmpty
        ? (_currentUser?.username ?? 'USER')
        : _usernameCtrl.text.trim();
    final int updatedAge = int.tryParse(_ageCtrl.text.trim()) ?? _currentUser?.age ?? 20;
    final int updatedHeight = int.tryParse(_heightCtrl.text.trim()) ?? _currentUser?.height ?? 175;
    final double updatedWeight = double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.')) ??
        _currentUser?.weight ??
        70.0;
    final int updatedGoal = int.tryParse(_goalCtrl.text.trim()) ?? _currentUser?.calorieGoal ?? 2000;

    final updatedUser = UserModel(
      username: updatedUsername,
      isMale: _isMale,
      age: updatedAge,
      height: updatedHeight,
      weight: updatedWeight,
      calorieGoal: updatedGoal,
    );

    await userBox.put('currentUser', updatedUser);
    setState(() => _currentUser = updatedUser);

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil adatok elmentve!'),
        backgroundColor: Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 1500),
      ),
    );
  }

  Future<void> _resetTodayCalories() async {
    final entryBox = Hive.box<CalorieEntry>('calorieBox');
    final keysToDelete = entryBox.keys.where((k) {
      final entry = entryBox.get(k);
      return entry != null && entry.dateKey == _todayKey;
    }).toList();

    await entryBox.deleteAll(keysToDelete);

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mai kalóriák sikeresen nullázva!'),
        backgroundColor: Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _resetAllData() async {
    final userBox = Hive.box<UserModel>('userBox');
    final calorieBox = Hive.box<CalorieEntry>('calorieBox');

    await userBox.clear();
    await calorieBox.clear();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),

        // Felső "Beállítások" pirula
        _buildGlassContainer(
          width: widget.titlePillWidth,
          borderRadius: 999,
          fillOpacity: 0.078,
          blurSigma: 10,
          shadowBlur: 20,
          shadowOffset: const Offset(0, 8),
          shadowOpacity: 0.15,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: const Center(
            child: Text(
              'Beállítások',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 1. PROFIL ADATOK SZERKESZTÉSE
        _buildGlassContainer(
          width: widget.cardWidth,
          borderRadius: 28,
          fillOpacity: 0.071,
          blurSigma: 12,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA78BFA).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: Color(0xFFA78BFA),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Profil adatok',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Felhasználónév
              _buildInputField(
                label: 'Felhasználónév',
                controller: _usernameCtrl,
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 12),

              // Nem váltó
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nem',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGenderChoice(
                          label: 'Férfi',
                          icon: Icons.male_rounded,
                          selected: _isMale,
                          onTap: () => setState(() => _isMale = true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildGenderChoice(
                          label: 'Nő',
                          icon: Icons.female_rounded,
                          selected: !_isMale,
                          onTap: () => setState(() => _isMale = false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Életkor & Magasság
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      label: 'Életkor',
                      controller: _ageCtrl,
                      suffixText: 'év',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField(
                      label: 'Magasság',
                      controller: _heightCtrl,
                      suffixText: 'cm',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Súly & Cél kalória
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      label: 'Súly',
                      controller: _weightCtrl,
                      suffixText: 'kg',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField(
                      label: 'Cél kalória',
                      controller: _goalCtrl,
                      suffixText: 'kcal',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Mentés gomb
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                  label: const Text(
                    'Mentés',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA78BFA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. ADATKEZELÉS / RESET
        _buildGlassContainer(
          width: widget.cardWidth,
          borderRadius: 28,
          fillOpacity: 0.071,
          blurSigma: 12,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adatkezelés',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              _buildActionButton(
                label: 'Mai nap nullázása',
                sublabel: 'Csak a mai bejegyzések törlése',
                icon: Icons.refresh_rounded,
                color: const Color(0xFFA78BFA),
                onTap: _resetTodayCalories,
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                label: 'Profil törlése',
                sublabel: 'Kezdő beállítások újrakezdése',
                icon: Icons.delete_forever_rounded,
                color: const Color(0xFFEF4444),
                onTap: _resetAllData,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? suffixText,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            suffixText: suffixText,
            suffixStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            prefixIcon: icon != null
                ? Icon(icon, color: const Color(0xFF94A3B8), size: 18)
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFA78BFA), width: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderChoice({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    const Color activeColor = Color(0xFFA78BFA);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? activeColor : Colors.white.withValues(alpha: 0.15),
            width: selected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required String sublabel,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassContainer({
    required double width,
    required double borderRadius,
    required double fillOpacity,
    required double blurSigma,
    double shadowBlur = 32,
    Offset shadowOffset = const Offset(0, 16),
    double shadowOpacity = 0.25,
    EdgeInsetsGeometry? padding,
    required Widget child,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: shadowOpacity),
            blurRadius: shadowBlur,
            offset: shadowOffset,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: fillOpacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}