import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/calorie_entry.dart';
import '../models/user_model.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatelessWidget {
  final double cardWidth;
  final double titlePillWidth;

  const SettingsScreen({
    super.key,
    required this.cardWidth,
    required this.titlePillWidth,
  });

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _resetTodayCalories(BuildContext context) async {
    final entryBox = Hive.box<CalorieEntry>('calorieBox');
    final keysToDelete = entryBox.keys.where((k) {
      final entry = entryBox.get(k);
      return entry != null && entry.dateKey == _todayKey;
    }).toList();

    await entryBox.deleteAll(keysToDelete);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mai kalóriák sikeresen nullázva!'),
        backgroundColor: Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _resetAllData(BuildContext context) async {
    final userBox = Hive.box<UserModel>('userBox');
    final calorieBox = Hive.box<CalorieEntry>('calorieBox');

    await userBox.clear();
    await calorieBox.clear();

    if (!context.mounted) return;
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
          width: titlePillWidth,
          height: 64,
          borderRadius: 999,
          fillOpacity: 0.078,
          blurSigma: 10,
          shadowBlur: 20,
          shadowOffset: const Offset(0, 8),
          shadowOpacity: 0.15,
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
        const SizedBox(height: 36),

        // Műveletek kártya
        _buildGlassContainer(
          width: cardWidth,
          height: 200,
          borderRadius: 28,
          fillOpacity: 0.071,
          blurSigma: 12,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                label: 'Mai nap nullázása',
                sublabel: 'Csak a mai kalóriák törlése',
                icon: Icons.refresh_rounded,
                color: const Color(0xFFA78BFA),
                onTap: () => _resetTodayCalories(context),
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                label: 'Profil törlése',
                sublabel: 'Kezdő beállítások újrakezdése',
                icon: Icons.delete_forever_rounded,
                color: const Color(0xFFEF4444),
                onTap: () => _resetAllData(context),
              ),
            ],
          ),
        ),
        const Spacer(),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
    required double height,
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
      height: height,
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