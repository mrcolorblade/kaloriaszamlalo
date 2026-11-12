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
  final Set<String> _expandedMonths = {};
  bool _initializedExpandedMonth = false;

  static const List<String> _hungarianMonths = [
    'Január',
    'Február',
    'Március',
    'Április',
    'Május',
    'Június',
    'Július',
    'Augusztus',
    'Szeptember',
    'Október',
    'November',
    'December',
  ];

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

  String _formatMonthHeader(String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length == 2) {
      final int? monthIdx = int.tryParse(parts[1]);
      if (monthIdx != null && monthIdx >= 1 && monthIdx <= 12) {
        return '${parts[0]}. ${_hungarianMonths[monthIdx - 1]}';
      }
    }
    return monthKey;
  }

  int _calculateDailyTdee(UserModel? user, double multiplier) {
    final bool isMale = user?.isMale ?? true;
    final int age = user?.age ?? 21;
    final int height = user?.height ?? 175;
    final double weight = user?.weight ?? 72.0;

    final double bmr = isMale
        ? (10 * weight) + (6.25 * height) - (5 * age) + 5
        : (10 * weight) + (6.25 * height) - (5 * age) - 161;

    return (bmr * multiplier).round();
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
    final List<CalorieEntry> currentEntries = List<CalorieEntry>.from(entries);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final int currentTotal =
                currentEntries.fold(0, (sum, e) => sum + e.calories);
            final bool isExceeded = currentTotal > goalCalories;
            final Color statusColor =
                isExceeded ? const Color(0xFFEF4444) : const Color(0xFF22C55E);

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
                          '$currentTotal / $goalCalories kcal',
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Rögzített ételek',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Húzd balra a törléshez',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (currentEntries.isEmpty)
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
                        itemCount: currentEntries.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = currentEntries[index];
                          final timeStr =
                              '${item.dateTime.hour.toString().padLeft(2, '0')}:${item.dateTime.minute.toString().padLeft(2, '0')}';

                          return Dismissible(
                            key: ValueKey(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                                ),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: Color(0xFFEF4444),
                                size: 22,
                              ),
                            ),
                            onDismissed: (_) async {
                              await item.delete();
                              setModalState(() {
                                currentEntries.removeAt(index);
                              });
                              if (currentEntries.isEmpty && ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                            },
                            child: Container(
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final entryBox = Hive.box<CalorieEntry>('calorieBox');
    final userBox = Hive.box<UserModel>('userBox');
    final settingsBox = Hive.box('settingsBox');

    final UserModel? user = userBox.get('currentUser');
    final int goalCalories = user?.calorieGoal ?? 2000;
    final double activityMultiplier =
        (settingsBox.get('activityMultiplier', defaultValue: 1.2) as num).toDouble();
    final int dailyTdee = _calculateDailyTdee(user, activityMultiplier);

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
            // 1. Összes bevitt kalória
            final int allTimeCalories = box.values.fold(0, (sum, e) => sum + e.calories);

            if (_currentFact == null || _lastTotalCalories != allTimeCalories) {
              _currentFact = CalorieFactsService.getRandomFact(allTimeCalories);
              _lastTotalCalories = allTimeCalories;
            }

            // 2. Napok csoportosítása
            final Map<String, List<CalorieEntry>> groupedByDay = {};
            for (final entry in box.values) {
              groupedByDay.putIfAbsent(entry.dateKey, () => []).add(entry);
            }

            // 3. Tömegfenntartó vs. Bevitt kalkuláció (legalább 600 kcal-os napok szűrése)
            final List<MapEntry<String, int>> dayTotals = groupedByDay.entries
                .map((e) => MapEntry(e.key, e.value.fold(0, (s, item) => s + item.calories)))
                .toList();

            final validDays = dayTotals.where((d) => d.value >= 600).toList();
            final effectiveDays =
                validDays.isNotEmpty ? validDays : dayTotals.where((d) => d.value > 0).toList();

            final int trackedDaysCount = effectiveDays.length;
            final int effectiveConsumedTotal =
                effectiveDays.fold(0, (sum, d) => sum + d.value);
            final int maintenanceTotal = trackedDaysCount * dailyTdee;
            final int netDifference = effectiveConsumedTotal - maintenanceTotal;
            final double weightDiffKg = netDifference / 7700.0;

            // 4. Hónapok csoportosítása (YYYY-MM)
            final Map<String, List<String>> daysByMonth = {};
            final sortedDayKeys = groupedByDay.keys.toList()..sort((a, b) => b.compareTo(a));

            for (final dayKey in sortedDayKeys) {
              final monthKey = dayKey.length >= 7 ? dayKey.substring(0, 7) : dayKey;
              daysByMonth.putIfAbsent(monthKey, () => []).add(dayKey);
            }

            final sortedMonthKeys = daysByMonth.keys.toList()..sort((a, b) => b.compareTo(a));

            // Az első (legfrissebb) hónap automatikus lenyitása első betöltéskor
            if (!_initializedExpandedMonth && sortedMonthKeys.isNotEmpty) {
              _expandedMonths.add(sortedMonthKeys.first);
              _initializedExpandedMonth = true;
            }

            return Column(
              children: [
                // A) ÖSSZESÍTŐ + FUN FACT KÁRTYA
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

                // B) TÖMEGFENNTARTÓ MÉRLEG (DEFICIT / TÖBBLET) KÁRTYA
                if (trackedDaysCount > 0) ...[
                  const SizedBox(height: 14),
                  _buildMaintenanceComparisonCard(
                    trackedDaysCount: trackedDaysCount,
                    dailyTdee: dailyTdee,
                    consumedTotal: effectiveConsumedTotal,
                    maintenanceTotal: maintenanceTotal,
                    netDifference: netDifference,
                    weightDiffKg: weightDiffKg,
                  ),
                ],

                const SizedBox(height: 20),

                // C) HÓNAPOKRA BONTOTT LENYITHATÓ LISTA
                if (sortedMonthKeys.isEmpty)
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
                        for (int m = 0; m < sortedMonthKeys.length; m++) ...[
                          if (m > 0) const SizedBox(height: 14),
                          _buildMonthAccordionSection(
                            monthKey: sortedMonthKeys[m],
                            dayKeys: daysByMonth[sortedMonthKeys[m]]!,
                            groupedByDay: groupedByDay,
                            goalCalories: goalCalories,
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

  Widget _buildMaintenanceComparisonCard({
    required int trackedDaysCount,
    required int dailyTdee,
    required int consumedTotal,
    required int maintenanceTotal,
    required int netDifference,
    required double weightDiffKg,
  }) {
    final bool isDeficit = netDifference <= 0;
    final Color statusColor = isDeficit ? const Color(0xFF22C55E) : const Color(0xFFF59E0B);
    final String signPrefix = netDifference > 0 ? '+' : '';
    final String kgPrefix = weightDiffKg > 0 ? '+' : '';

    return _buildGlassContainer(
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
                'Tömegfenntartó mérleg',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$trackedDaysCount nap ($dailyTdee/nap)',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bevitt összesen',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$consumedTotal kcal',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 28,
                color: Colors.white.withValues(alpha: 0.12),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Szinten tartó keret',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$maintenanceTotal kcal',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isDeficit ? 'Összesítve:' : 'Összesítve:',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$signPrefix$netDifference kcal (~$kgPrefix${weightDiffKg.toStringAsFixed(2)} kg)',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthAccordionSection({
    required String monthKey,
    required List<String> dayKeys,
    required Map<String, List<CalorieEntry>> groupedByDay,
    required int goalCalories,
  }) {
    final bool isExpanded = _expandedMonths.contains(monthKey);

    int monthTotalCalories = 0;
    for (final dk in dayKeys) {
      monthTotalCalories += groupedByDay[dk]!.fold(0, (s, e) => s + e.calories);
    }
    final int monthAvg = dayKeys.isNotEmpty ? (monthTotalCalories / dayKeys.length).round() : 0;

    return Column(
      children: [
        // Hónap fejléc gomb
        GestureDetector(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedMonths.remove(monthKey);
              } else {
                _expandedMonths.add(monthKey);
              }
            });
          },
          child: _buildGlassContainer(
            width: widget.cardWidth,
            borderRadius: 20,
            fillOpacity: isExpanded ? 0.10 : 0.065,
            blurSigma: 12,
            shadowBlur: 16,
            shadowOffset: const Offset(0, 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatMonthHeader(monthKey),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${dayKeys.length} nap • Átlag: $monthAvg kcal/nap',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 220),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Lenyíló napi csempék
        if (isExpanded) ...[
          const SizedBox(height: 10),
          for (int i = 0; i < dayKeys.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Builder(
              builder: (context) {
                final dateKey = dayKeys[i];
                final dayEntries = groupedByDay[dateKey]!;
                final int totalCal = dayEntries.fold(0, (sum, e) => sum + e.calories);
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: baseColor.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 6),
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
                  fontSize: 15.5,
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
                  fontSize: 16.5,
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