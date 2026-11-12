import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/calorie_entry.dart';
import '../models/user_model.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Color _getProgressColor(double ratio) {
    if (ratio <= 0.70) {
      return const Color(0xFFA78BFA);
    } else if (ratio <= 0.90) {
      return Color.lerp(const Color(0xFFA78BFA), const Color(0xFFF43F5E), (ratio - 0.70) / 0.20)!;
    } else {
      return const Color(0xFFEF4444);
    }
  }

  ({String label, Color color}) _getBmiStatus(double bmi) {
    if (bmi < 18.5) {
      return (label: 'Alacsony', color: const Color(0xFF38BDF8));
    } else if (bmi <= 24.9) {
      return (label: 'Jó', color: const Color(0xFF22C55E));
    } else if (bmi <= 29.9) {
      return (label: 'Túlsúly', color: const Color(0xFFF59E0B));
    } else {
      return (label: 'Elhízás', color: const Color(0xFFEF4444));
    }
  }

  void _showAddCalorieDialog(BuildContext context, Box<CalorieEntry> entryBox) {
    final calorieCtrl = TextEditingController();
    final foodNameCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kalória hozzáadása',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: foodNameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Étel megnevezése (opcionális)',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: calorieCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Kalória (pl. 150)',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                  suffixText: 'kcal',
                  suffixStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final int? val = int.tryParse(calorieCtrl.text.trim());
                    if (val == null || val <= 0) return;

                    final newEntry = CalorieEntry(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      calories: val,
                      foodName: foodNameCtrl.text.trim().isEmpty ? null : foodNameCtrl.text.trim(),
                      dateTime: DateTime.now(),
                    );

                    entryBox.add(newEntry);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA78BFA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Hozzáadás',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userBox = Hive.box<UserModel>('userBox');
    final entryBox = Hive.box<CalorieEntry>('calorieBox');
    final UserModel? user = userBox.get('currentUser');

    final int goalCalories = user?.calorieGoal ?? 2000;
    final bmiInfo = _getBmiStatus(user?.bmi ?? 21.7);

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: ValueListenableBuilder(
        valueListenable: entryBox.listenable(),
        builder: (context, Box<CalorieEntry> box, _) {
          final todayEntries = box.values.where((e) => e.dateKey == _todayKey).toList();
          final int consumedCalories = todayEntries.fold(0, (sum, e) => sum + e.calories);

          final double rawRatio = goalCalories > 0 ? (consumedCalories / goalCalories) : 0.0;
          final double targetPercent = rawRatio.clamp(0.0, 1.0);
          final double targetAlertFactor = ((rawRatio - 0.70) / 0.30).clamp(0.0, 1.0);

          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: targetAlertFactor),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutCubic,
            builder: (context, animatedAlertFactor, _) {
              final Color activeColor = _getProgressColor(rawRatio);

              return Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Háttér
                  Positioned.fill(
                    child: _PearlAtmosphereBackground(alertFactor: animatedAlertFactor),
                  ),

                  // 2. Fő tartalom és rögzített lebegő Navbar
                  SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double screenW = constraints.maxWidth;
                        final double screenH = constraints.maxHeight;

                        final double cardWidth = (screenW * 0.72).clamp(260.0, 360.0);
                        final double titlePillWidth = (screenW * 0.57).clamp(200.0, 280.0);
                        final double navBarWidth = (screenW - 48.0).clamp(280.0, 420.0);

                        return Stack(
                          children: [
                            // Görgethető tartalom (alul 100px helyet hagy a navbarnak!)
                            Positioned.fill(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.only(top: 16, bottom: 100),
                                child: _selectedNavIndex == 0
                                    ? ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: screenW,
                                          minHeight: screenH - 116,
                                        ),
                                        child: IntrinsicHeight(
                                          child: _buildHomeDashboard(
                                            cardWidth: cardWidth,
                                            titlePillWidth: titlePillWidth,
                                            user: user,
                                            consumedCalories: consumedCalories,
                                            goalCalories: goalCalories,
                                            targetPercent: targetPercent,
                                            activeColor: activeColor,
                                            bmiInfo: bmiInfo,
                                            entryBox: entryBox,
                                          ),
                                        ),
                                      )
                                    : SizedBox(
                                        width: screenW,
                                        child: _selectedNavIndex == 2
                                            ? SettingsScreen(
                                                cardWidth: cardWidth,
                                                titlePillWidth: titlePillWidth,
                                              )
                                            : StatsScreen(
                                                cardWidth: cardWidth,
                                                titlePillWidth: titlePillWidth,
                                              ),
                                      ),
                              ),
                            ),

                            // Rögzített lebegő navigációs sáv (mindig a kijelző alján marad!)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 16,
                              child: Center(
                                child: _FigmaGlassContainer(
                                  width: navBarWidth,
                                  height: 64,
                                  borderRadius: 32,
                                  fillOpacity: 0.102,
                                  blurSigma: 12,
                                  shadowBlur: 24,
                                  shadowOffset: const Offset(0, 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 28),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildNavItem(
                                        index: 0,
                                        label: 'Kezdőlap',
                                        iconType: _NavIconType.home,
                                      ),
                                      _buildNavItem(
                                        index: 1,
                                        label: 'Stats',
                                        iconType: _NavIconType.stats,
                                      ),
                                      _buildNavItem(
                                        index: 2,
                                        label: 'Beállítások',
                                        iconType: _NavIconType.settings,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHomeDashboard({
    required double cardWidth,
    required double titlePillWidth,
    required UserModel? user,
    required int consumedCalories,
    required int goalCalories,
    required double targetPercent,
    required Color activeColor,
    required ({String label, Color color}) bmiInfo,
    required Box<CalorieEntry> entryBox,
  }) {
    final int remainingCalories = goalCalories - consumedCalories;

    return Column(
      children: [
        const Spacer(flex: 1),
        _FigmaGlassContainer(
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
              'Kezdőlap',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
        const Spacer(flex: 2),
        SizedBox(
          width: cardWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  'Üdvözöllek,',
                  style: GoogleFonts.happyMonkey(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(left: 36),
                  child: Text(
                    '${user?.username.toUpperCase() ?? "USERNAME"}!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _FigmaGlassContainer(
          width: cardWidth,
          height: 228,
          borderRadius: 28,
          fillOpacity: 0.071,
          blurSigma: 12,
          child: Stack(
            children: [
              Center(
                child: SizedBox(
                  width: 180,
                  height: 180,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: targetPercent),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedPercent, _) {
                      return CustomPaint(
                        painter: _CalorieRingPainter(
                          percent: animatedPercent,
                          progressColor: activeColor,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                consumedCalories.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 44,
                                  fontWeight: FontWeight.w600,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '/ $goalCalories',
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Bal alsó "Fennmaradt: XY kcal" kijelző
              Positioned(
                left: 15,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Fennmaradt',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${remainingCalories < 0 ? 0 : remainingCalories} kcal',
                      style: TextStyle(
                        color: remainingCalories < 0 ? const Color(0xFFEF4444) : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Jobb alsó "+" gomb
              Positioned(
                right: 22,
                bottom: 22,
                child: GestureDetector(
                  onTap: () => _showAddCalorieDialog(context, entryBox),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.45),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.22),
                                Colors.white.withValues(alpha: 0.02),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1.0,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(flex: 2),
        _FigmaGlassContainer(
          width: cardWidth,
          height: 97,
          borderRadius: 28,
          fillOpacity: 0.071,
          blurSigma: 12,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildSegmentItem(
                  iconType: _SegmentIconType.ruler,
                  label: '${user?.height ?? 173}cm',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSegmentItem(
                  iconType: _SegmentIconType.dumbbell,
                  label: '${user?.weight.toStringAsFixed(0) ?? 65}kg',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSegmentItem(
                  iconType: (user?.isMale ?? true)
                      ? _SegmentIconType.male
                      : _SegmentIconType.female,
                  label: (user?.isMale ?? true) ? 'Férfi' : 'Nő',
                ),
              ),
            ],
          ),
        ),
        const Spacer(flex: 2),
        _FigmaGlassContainer(
          width: cardWidth,
          height: 69,
          borderRadius: 28,
          fillOpacity: 0.071,
          blurSigma: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'BMI szinted: ${user?.bmi.toStringAsFixed(1) ?? "21.7"}',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: bmiInfo.color.withValues(alpha: 0.102),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: bmiInfo.color.withValues(alpha: 0.2),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  bmiInfo.label,
                  style: TextStyle(
                    color: bmiInfo.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }

  Widget _buildSegmentItem({
    required _SegmentIconType iconType,
    required String label,
  }) {
    return Container(
      height: 73,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.051),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.078),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.0,
              ),
            ),
            child: Center(
              child: CustomPaint(
                size: const Size(16, 16),
                painter: _SegmentIconPainter(iconType),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required _NavIconType iconType,
  }) {
    final bool isSelected = _selectedNavIndex == index;
    final Color color = isSelected ? Colors.white : const Color(0xFF94A3B8);

    return GestureDetector(
      onTap: () => setState(() => _selectedNavIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 44,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomPaint(
              size: const Size(24, 24),
              painter: _NavIconPainter(iconType: iconType, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PearlAtmosphereBackground extends StatelessWidget {
  final double alertFactor;

  const _PearlAtmosphereBackground({required this.alertFactor});

  @override
  Widget build(BuildContext context) {
    final topLinear = Color.lerp(const Color(0xFF1B2340), const Color(0xFF28111E), alertFactor)!;
    final midLinear = Color.lerp(const Color(0xFF0F172A), const Color(0xFF190914), alertFactor)!;
    final botLinear = Color.lerp(const Color(0xFF050816), const Color(0xFF0A0409), alertFactor)!;

    final blueUndertone = Color.lerp(const Color(0xFF5B6BFF), const Color(0xFFE11D48), alertFactor)!;
    final lavenderBloom = Color.lerp(const Color(0xFFA78BFA), const Color(0xFFF43F5E), alertFactor)!;
    final lavenderHaze = Color.lerp(const Color(0xFF8B5CF6), const Color(0xFFFF2E56), alertFactor)!;

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.5, 1.0],
              colors: [topLinear, midLinear, botLinear],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.24, -0.28),
              radius: 0.85,
              stops: const [0.0, 0.38, 0.72, 1.0],
              colors: [
                Colors.white.withValues(alpha: 0.58),
                Colors.white.withValues(alpha: 0.40 * 0.58),
                Colors.white.withValues(alpha: 0.102 * 0.58),
                Colors.white.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.94, 0.96),
              radius: 0.95,
              stops: const [0.0, 0.38, 0.72, 1.0],
              colors: [
                blueUndertone.withValues(alpha: 0.82),
                blueUndertone.withValues(alpha: 0.502 * 0.82),
                blueUndertone.withValues(alpha: 0.102 * 0.82),
                blueUndertone.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.88, 0.72),
              radius: 0.95,
              stops: const [0.0, 0.38, 0.72, 1.0],
              colors: [
                lavenderBloom,
                lavenderBloom.withValues(alpha: 0.502),
                lavenderBloom.withValues(alpha: 0.102),
                lavenderBloom.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.96, -0.22),
              radius: 0.85,
              stops: const [0.0, 0.38, 0.72, 1.0],
              colors: [
                const Color(0xFF94A3B8),
                const Color(0xFF94A3B8).withValues(alpha: 0.40),
                const Color(0xFF94A3B8).withValues(alpha: 0.102),
                const Color(0xFF94A3B8).withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.84, -0.84),
              radius: 0.90,
              stops: const [0.0, 0.38, 0.72, 1.0],
              colors: [
                lavenderHaze,
                lavenderHaze.withValues(alpha: 0.40),
                lavenderHaze.withValues(alpha: 0.102),
                lavenderHaze.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FigmaGlassContainer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final double fillOpacity;
  final double blurSigma;
  final double shadowBlur;
  final Offset shadowOffset;
  final double shadowOpacity;
  final EdgeInsetsGeometry? padding;
  final Widget child;

  const _FigmaGlassContainer({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.fillOpacity,
    required this.blurSigma,
    this.shadowBlur = 32,
    this.shadowOffset = const Offset(0, 16),
    this.shadowOpacity = 0.25,
    this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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

class _CalorieRingPainter extends CustomPainter {
  final double percent;
  final Color progressColor;

  _CalorieRingPainter({
    required this.percent,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 16.2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - strokeWidth) / 2;

    final Paint trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.078)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    if (percent > 0) {
      final Paint fillPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * percent,
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CalorieRingPainter oldDelegate) {
    return oldDelegate.percent != percent || oldDelegate.progressColor != progressColor;
  }
}

enum _SegmentIconType { ruler, dumbbell, male, female }

class _SegmentIconPainter extends CustomPainter {
  final _SegmentIconType type;

  _SegmentIconPainter(this.type);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (type) {
      case _SegmentIconType.ruler:
        canvas.save();
        canvas.translate(size.width / 2, size.height / 2);
        canvas.rotate(math.pi / 4);
        final RRect rrect = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-7, -3.2, 14, 6.4),
          const Radius.circular(1.5),
        );
        canvas.drawRRect(rrect, paint);
        canvas.drawLine(const Offset(-3.5, -3.2), const Offset(-3.5, -0.8), paint);
        canvas.drawLine(const Offset(0, -3.2), const Offset(0, -0.8), paint);
        canvas.drawLine(const Offset(3.5, -3.2), const Offset(3.5, -0.8), paint);
        canvas.restore();
        break;

      case _SegmentIconType.dumbbell:
        canvas.save();
        canvas.translate(size.width / 2, size.height / 2);
        canvas.rotate(-math.pi / 4);
        canvas.drawLine(const Offset(-3, 0), const Offset(3, 0), paint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(-6, -4, 3, 8), const Radius.circular(1)),
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(3, -4, 3, 8), const Radius.circular(1)),
          paint,
        );
        canvas.drawLine(const Offset(-7.5, 0), const Offset(-6, 0), paint);
        canvas.drawLine(const Offset(6, 0), const Offset(7.5, 0), paint);
        canvas.restore();
        break;

      case _SegmentIconType.male:
        canvas.drawCircle(const Offset(6.5, 9.5), 4.0, paint);
        canvas.drawLine(const Offset(9.3, 6.7), const Offset(13.5, 2.5), paint);
        canvas.drawLine(const Offset(10.0, 2.5), const Offset(13.5, 2.5), paint);
        canvas.drawLine(const Offset(13.5, 2.5), const Offset(13.5, 6.0), paint);
        break;

      case _SegmentIconType.female:
        canvas.drawCircle(const Offset(8, 6), 4.0, paint);
        canvas.drawLine(const Offset(8, 10), const Offset(8, 15), paint);
        canvas.drawLine(const Offset(5.5, 12.5), const Offset(10.5, 12.5), paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentIconPainter oldDelegate) => oldDelegate.type != type;
}

enum _NavIconType { home, stats, settings }

class _NavIconPainter extends CustomPainter {
  final _NavIconType iconType;
  final Color color;

  _NavIconPainter({required this.iconType, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (iconType) {
      case _NavIconType.home:
        final Path path = Path()
          ..moveTo(3, 9.5)
          ..lineTo(12, 2.5)
          ..lineTo(21, 9.5)
          ..lineTo(21, 19)
          ..arcToPoint(const Offset(19, 21), radius: const Radius.circular(2))
          ..lineTo(5, 21)
          ..arcToPoint(const Offset(3, 19), radius: const Radius.circular(2))
          ..close();
        canvas.drawPath(path, paint);

        final Path door = Path()
          ..moveTo(9, 21)
          ..lineTo(9, 13)
          ..lineTo(15, 13)
          ..lineTo(15, 21);
        canvas.drawPath(door, paint);
        break;

      case _NavIconType.stats:
        canvas.drawLine(const Offset(6, 20), const Offset(6, 14), paint);
        canvas.drawLine(const Offset(12, 20), const Offset(12, 4), paint);
        canvas.drawLine(const Offset(18, 20), const Offset(18, 10), paint);
        break;

      case _NavIconType.settings:
        final Offset center = Offset(size.width / 2, size.height / 2);
        canvas.drawCircle(center, 3.0, paint);
        const int teeth = 8;
        for (int i = 0; i < teeth; i++) {
          final double angle = (i * 2 * math.pi) / teeth;
          final Offset p1 = Offset(
            center.dx + 6.2 * math.cos(angle),
            center.dy + 6.2 * math.sin(angle),
          );
          final Offset p2 = Offset(
            center.dx + 8.8 * math.cos(angle),
            center.dy + 8.8 * math.sin(angle),
          );
          canvas.drawLine(p1, p2, paint);
        }
        canvas.drawCircle(center, 6.5, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _NavIconPainter oldDelegate) {
    return oldDelegate.iconType != iconType || oldDelegate.color != color;
  }
}