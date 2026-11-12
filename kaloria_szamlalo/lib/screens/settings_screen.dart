import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/calorie_entry.dart';
import '../models/user_model.dart';
import 'onboarding_screen.dart';

class ActivityOption {
  final double multiplier;
  final String label;
  final String subtitle;

  const ActivityOption({
    required this.multiplier,
    required this.label,
    required this.subtitle,
  });
}

const List<ActivityOption> kActivityOptions = [
  ActivityOption(
    multiplier: 1.2,
    label: 'Átlagos (1.2×)',
    subtitle: 'Ülő életmód, kevés mozgás',
  ),
  ActivityOption(
    multiplier: 1.375,
    label: 'Enyhe (1.375×)',
    subtitle: 'Heti 1–3 könnyű edzés',
  ),
  ActivityOption(
    multiplier: 1.55,
    label: 'Mérsékelt (1.55×)',
    subtitle: 'Heti 3–5 edzés',
  ),
  ActivityOption(
    multiplier: 1.725,
    label: 'Aktív (1.725×)',
    subtitle: 'Heti 6–7 intenzív edzés',
  ),
];

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
  late TextEditingController _usernameCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _goalCtrl;
  late bool _isMale;
  late double _activityMultiplier;

  @override
  void initState() {
    super.initState();
    final userBox = Hive.box<UserModel>('userBox');
    final settingsBox = Hive.box('settingsBox');
    final user = userBox.get('currentUser');

    _usernameCtrl = TextEditingController(text: user?.username ?? '');
    _ageCtrl = TextEditingController(text: (user?.age ?? 21).toString());
    _heightCtrl = TextEditingController(text: (user?.height ?? 175).toString());
    _weightCtrl = TextEditingController(text: (user?.weight ?? 72.0).toStringAsFixed(1));
    _goalCtrl = TextEditingController(text: (user?.calorieGoal ?? 2000).toString());
    _isMale = user?.isMale ?? true;
    _activityMultiplier =
        (settingsBox.get('activityMultiplier', defaultValue: 1.2) as num).toDouble();
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

  int _calculatePreviewTdee() {
    final int age = int.tryParse(_ageCtrl.text.trim()) ?? 21;
    final int height = int.tryParse(_heightCtrl.text.trim()) ?? 175;
    final double weight = double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.')) ?? 72.0;

    final double bmr = _isMale
        ? (10 * weight) + (6.25 * height) - (5 * age) + 5
        : (10 * weight) + (6.25 * height) - (5 * age) - 161;

    return (bmr * _activityMultiplier).round();
  }

  Future<void> _saveSettings() async {
    final String username = _usernameCtrl.text.trim();
    final int? age = int.tryParse(_ageCtrl.text.trim());
    final int? height = int.tryParse(_heightCtrl.text.trim());
    final double? weight = double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.'));
    final int? goal = int.tryParse(_goalCtrl.text.trim());

    if (username.length < 2 ||
        age == null || age < 10 || age > 120 ||
        height == null || height < 100 || height > 250 ||
        weight == null || weight < 30 || weight > 350 ||
        goal == null || goal < 800 || goal > 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kérlek valós adatokat adj meg minden mezőben!'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final userBox = Hive.box<UserModel>('userBox');
    final settingsBox = Hive.box('settingsBox');

    final updatedUser = UserModel(
      username: username,
      isMale: _isMale,
      age: age,
      height: height,
      weight: weight,
      calorieGoal: goal,
    );

    await userBox.put('currentUser', updatedUser);
    await settingsBox.put('activityMultiplier', _activityMultiplier);

    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Beállítások sikeresen mentve!'),
        backgroundColor: Color(0xFF22C55E),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _resetToday() async {
    final bool? confirmed = await _showConfirmDialog(
      title: 'Mai nap nullázása',
      message: 'Biztosan törlöd az összes mai kalóriabejegyzést?',
      confirmText: 'Nullázás',
      confirmColor: const Color(0xFFA78BFA),
    );

    if (confirmed != true) return;

    final entryBox = Hive.box<CalorieEntry>('calorieBox');
    final now = DateTime.now();
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final keysToDelete = entryBox.keys.where((k) {
      final item = entryBox.get(k);
      return item?.dateKey == todayKey;
    }).toList();

    await entryBox.deleteAll(keysToDelete);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mai bejegyzések törölve.'),
        backgroundColor: Color(0xFF0F172A),
      ),
    );
  }

  Future<void> _deleteProfile() async {
    final bool? confirmed = await _showConfirmDialog(
      title: 'Profil törlése',
      message: 'Minden profiladat és statisztika törlődik. Biztosan folytatod?',
      confirmText: 'Törlés',
      confirmColor: const Color(0xFFEF4444),
    );

    if (confirmed != true) return;

    final userBox = Hive.box<UserModel>('userBox');
    final entryBox = Hive.box<CalorieEntry>('calorieBox');
    final settingsBox = Hive.box('settingsBox');

    await entryBox.clear();
    await settingsBox.clear();
    await userBox.delete('currentUser');

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (route) => false,
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Mégse', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(confirmText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int previewTdee = _calculatePreviewTdee();

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
        const SizedBox(height: 20),

        // 1. Profil adatok kártya
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA78BFA).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
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
              const Text(
                'Felhasználónév',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              _buildInputField(
                controller: _usernameCtrl,
                prefixIcon: Icons.badge_outlined,
              ),
              const SizedBox(height: 14),

              // Nem választó
              const Text(
                'Nem',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildGenderButton(
                      label: 'Férfi',
                      icon: Icons.male_rounded,
                      isSelected: _isMale,
                      onTap: () => setState(() => _isMale = true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildGenderButton(
                      label: 'Nő',
                      icon: Icons.female_rounded,
                      isSelected: !_isMale,
                      onTap: () => setState(() => _isMale = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Életkor & Magasság
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Életkor',
                          style: TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),
                        _buildInputField(
                          controller: _ageCtrl,
                          suffix: 'év',
                          isNumber: true,
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Magasság',
                          style: TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),
                        _buildInputField(
                          controller: _heightCtrl,
                          suffix: 'cm',
                          isNumber: true,
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Súly & Cél kalória
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Súly',
                          style: TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),
                        _buildInputField(
                          controller: _weightCtrl,
                          suffix: 'kg',
                          isNumber: true,
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cél kalória',
                          style: TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),
                        _buildInputField(
                          controller: _goalCtrl,
                          suffix: 'kcal',
                          isNumber: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // AKTIVITÁSI SZINT VÁLASZTÓ (2x2 Row elrendezés)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Aktivitási szint',
                    style: TextStyle(
                        color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Szinten tartó: ~$previewTdee kcal',
                    style: const TextStyle(
                      color: Color(0xFFA78BFA),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildActivityOptionCard(kActivityOptions[0])),
                      const SizedBox(width: 8),
                      Expanded(child: _buildActivityOptionCard(kActivityOptions[1])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildActivityOptionCard(kActivityOptions[2])),
                      const SizedBox(width: 8),
                      Expanded(child: _buildActivityOptionCard(kActivityOptions[3])),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Mentés gomb
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                  label: const Text(
                    'Mentés',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA78BFA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 2. Adatkezelés kártya
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
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              _buildActionTile(
                icon: Icons.refresh_rounded,
                title: 'Mai nap nullázása',
                subtitle: 'Csak a mai bejegyzések törlése',
                accentColor: const Color(0xFFA78BFA),
                onTap: _resetToday,
              ),
              const SizedBox(height: 10),
              _buildActionTile(
                icon: Icons.delete_outline_rounded,
                title: 'Profil törlése',
                subtitle: 'Kezdő beállítások újrakezdése',
                accentColor: const Color(0xFFEF4444),
                onTap: _deleteProfile,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildActivityOptionCard(ActivityOption option) {
    final bool isSelected = (_activityMultiplier - option.multiplier).abs() < 0.001;

    return GestureDetector(
      onTap: () => setState(() => _activityMultiplier = option.multiplier),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFA78BFA).withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFA78BFA)
                : Colors.white.withValues(alpha: 0.14),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              option.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.75)
                    : const Color(0xFF94A3B8),
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    IconData? prefixIcon,
    String? suffix,
    bool isNumber = false,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          if (prefixIcon != null) ...[
            Icon(prefixIcon, color: const Color(0xFF94A3B8), size: 18),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: isNumber
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (suffix != null)
            Text(
              suffix,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGenderButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFA78BFA).withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFA78BFA) : Colors.white.withValues(alpha: 0.14),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : const Color(0xFF94A3B8), size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: accentColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: accentColor.withValues(alpha: 0.7), size: 20),
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