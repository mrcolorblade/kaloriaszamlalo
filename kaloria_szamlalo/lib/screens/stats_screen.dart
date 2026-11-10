import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/calorie_entry.dart';
import '../models/user_model.dart';
import '../services/calorie_facts_service.dart';

class StatsScreen extends StatefulWidget {
  final double cardWidth;
  final double titlePillWidth;

  const StatsScreen({
    super.key,
    required this.cardWidth,
    required this.titlePillWidth,
  });

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  FunFactItem? _currentFact;
  int _lastTotalCalories = -1;

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String get _yesterdayKey {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return '${y.year}-${y.month.toString().padLeft(2, '0')}-${y.day.toString().padLeft(2, '0')}';
  }

  String _formatDateLabel(String dateKey) {
    if (dateKey == _todayKey) return 'Ma';
    if (dateKey == _yesterdayKey) return 'Tegnap';
    final parts = dateKey.split('-');
    if (parts.length == 3) {
      return '${parts[0]}. ${parts[1]}. ${parts[2]}.';
    }
    return dateKey;
  }

  void _refreshFact(int totalCalories) {
    setState(() {
      _currentFact = CalorieFactsService.getRandomFact(totalCalories);
      _lastTotalCalories = totalCalories;
    });
  }

  void _showDayDetails(
    BuildContext context, {
    required String dateKey,
    required List<CalorieEntry> entries,
    required int totalCalories,
    required int goalCalories,
  }) {
    final bool isExceeded = totalCalories > goalCalories;
    final Color statusColor = isExceeded ? const Color(0xFFEF4444) : const Color(0xFF22C55E);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDateLabel(dateKey),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        dateKey,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      isExceeded ? 'Cél túllépve' : 'Célon belül',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Napi bevitel:',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$totalCalories / $goalCalories kcal',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Rögzített ételek',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              if (entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Nincsenek rögzített tételek erre a napra.',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = entries[index];
                      final timeStr =
                          '${item.dateTime.hour.toString().padLeft(2, '0')}:${item.dateTime.minute.toString().padLeft(2, '0')}';

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFA78BFA).withValues(alpha: 0.15),
                              ),
                              child: const Icon(
                                Icons.restaurant_rounded,
                                color: Color(0xFFA78BFA),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.foodName ?? 'Kalória bejegyzés',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    timeStr,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '+${item.calories} kcal',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
    final entryBox = Hive.box<CalorieEntry>('calorieBox');
    final userBox = Hive.box<UserModel>('userBox');
    final UserModel? user = userBox.get('currentUser');
    final int goalCalories = user?.calorieGoal ?? 2000;

    return Column(
      children: [
        const SizedBox(height: 16),

        // Felső "Statisztika" pirula
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
              'Statisztika',
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

        ValueListenableBuilder(
          valueListenable: entryBox.listenable(),
          builder: (context, Box<CalorieEntry> box, _) {
            // Összes bevitt kalória számítása a kezdetektől
            final int allTimeCalories = box.values.fold(0, (sum, e) => sum + e.calories);

            // Ha változott az összesített kalória vagy még nincs kiválasztott tény, inicializáljuk
            if (_currentFact == null || _lastTotalCalories != allTimeCalories) {
              _currentFact = CalorieFactsService.getRandomFact(allTimeCalories);
              _lastTotalCalories = allTimeCalories;
            }

            // Napok csoportosítása
            final Map<String, List<CalorieEntry>> grouped = {};
            for (final entry in box.values) {
              grouped.putIfAbsent(entry.dateKey, () => []).add(entry);
            }

            final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

            return Column(
              children: [
                // 1. ÖSSZESÍTŐ + FUN FACT KÁRTYA (Koppintható újrasorsoláshoz!)
                GestureDetector(
                  onTap: () => _refreshFact(allTimeCalories),
                  child: _buildGlassContainer(
                    width: widget.cardWidth,
                    borderRadius: 24,
                    fillOpacity: 0.08,
                    blurSigma: 12,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Összes bevitt kalória',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  _currentFact?.emoji ?? '✨',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.touch_app_rounded,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.35),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$allTimeCalories kcal',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA78BFA).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFA78BFA).withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentFact?.title ?? 'Tudtad?',
                                style: const TextStyle(
                                  color: Color(0xFFA78BFA),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _currentFact?.text ?? '',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. NAPI BONTÁS KÁRTYÁK
                if (sortedKeys.isEmpty)
                  _buildGlassContainer(
                    width: widget.cardWidth,
                    borderRadius: 28,
                    fillOpacity: 0.071,
                    blurSigma: 12,
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,
                          size: 40,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Még nincsenek rögzített napjaid',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: widget.cardWidth,
                    child: Column(
                      children: [
                        for (int i = 0; i < sortedKeys.length; i++) ...[
                          if (i > 0) const SizedBox(height: 12),
                          Builder(
                            builder: (context) {
                              final dateKey = sortedKeys[i];
                              final dayEntries = grouped[dateKey]!;
                              final int totalCal =
                                  dayEntries.fold(0, (sum, e) => sum + e.calories);
                              final bool isExceeded = totalCal > goalCalories;

                              final Color baseColor =
                                  isExceeded ? const Color(0xFFEF4444) : const Color(0xFF22C55E);

                              return GestureDetector(
                                onTap: () => _showDayDetails(
                                  context,
                                  dateKey: dateKey,
                                  entries: dayEntries,
                                  totalCalories: totalCal,
                                  goalCalories: goalCalories,
                                ),
                                child: _buildDayTile(
                                  dateLabel: _formatDateLabel(dateKey),
                                  subDate: dateKey,
                                  totalCalories: totalCal,
                                  goalCalories: goalCalories,
                                  baseColor: baseColor,
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDayTile({
    required String dateLabel,
    required String subDate,
    required int totalCalories,
    required int goalCalories,
    required Color baseColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: baseColor.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subDate,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '$totalCalories',
                style: TextStyle(
                  color: baseColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                ' / $goalCalories',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ],
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