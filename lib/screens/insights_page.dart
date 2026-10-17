import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('📈 Insights Dashboard')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const SectionHeader('Your Progress', 'Live charts powered by your own data'),

            // TOP ROW: Donut Charts
            Row(
              children: [
                Expanded(child: _HabitsDonutCard(app: app)),
                const SizedBox(width: 12),
                Expanded(child: _MoodDonutCard(app: app)),
              ],
            ),
            const SizedBox(height: 16),

            // SNAPSHOT STATS
            AdaptiveGrid(
              children: [
                _SnapshotCard('⏱️', '${app.totalFocusMinutes}', 'Focus minutes', 'All time'),
                _SnapshotCard('✅', '${app.completedFocusSessions}', 'Focus sessions', 'Completed'),
                _SnapshotCard('🔥', '${app.focusStreak}', 'Focus streak', 'Days'),
                _SnapshotCard('📝', '${app.journals.length}', 'Journal entries', 'Total'),
              ],
            ),
            const SizedBox(height: 16),

            // MOOD & SLEEP LINE CHART
            _MoodSleepCorrelationCard(
              moods: app.moods,
              sleepLogs: app.sleepLogs,
              days: 14,
            ),
            const SizedBox(height: 16),

            // WEEKLY FOCUS BAR CHART
            _WeeklyFocusCard(focusSessions: app.focusSessions),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. HABITS DONUT CHART (Animates from 0 to %)
// ---------------------------------------------------------------------------
class _HabitsDonutCard extends StatelessWidget {
  const _HabitsDonutCard({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final total = app.habits.length;
    final done = app.habitsDoneToday;
    final percent = total == 0 ? 0.0 : (done / total) * 100;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Habits Today', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // The animated Donut
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: percent / 100),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 35,
                        startDegreeOffset: -90,
                        sections: [
                          PieChartSectionData(
                            color: AppColors.primary,
                            value: value * 100,
                            radius: 12,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            color: const Color(0xFFE3EAE5),
                            value: (1 - value) * 100,
                            radius: 10,
                            showTitle: false,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // The animated Percentage Text
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: percent),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Text(
                      '${value.toInt()}%',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('$done of $total done',
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. MOOD DONUT CHART (Animates from 0 to %)
// ---------------------------------------------------------------------------
class _MoodDonutCard extends StatelessWidget {
  const _MoodDonutCard({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    // Get last 7 days of moods
    final recentMoods = app.moods.take(7).toList();
    final greatCount = recentMoods.where((m) => m.mood == 'great' || m.mood == 'good').length;
    final total = recentMoods.isEmpty ? 1 : recentMoods.length;
    final percent = (greatCount / total) * 100;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Positive Moods', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: percent / 100),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 35,
                        startDegreeOffset: -90,
                        sections: [
                          PieChartSectionData(
                            color: const Color(0xFFF59E0B), // Orange for positive
                            value: value * 100,
                            radius: 12,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            color: const Color(0xFFE3EAE5),
                            value: (1 - value) * 100,
                            radius: 10,
                            showTitle: false,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: percent),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Text(
                      '${value.toInt()}%',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('$greatCount of $total good days',
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. MOOD ↔ SLEEP LINE CHART (Smooth area gradient)
// ---------------------------------------------------------------------------
class _MoodSleepCorrelationCard extends StatelessWidget {
  const _MoodSleepCorrelationCard({
    required this.moods,
    required this.sleepLogs,
    required this.days,
  });

  final List<MoodEntry> moods;
  final List<SleepLog> sleepLogs;
  final int days;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateKeys = [
      for (var i = days - 1; i >= 0; i--)
        dateKey(today.subtract(Duration(days: i)))
    ];

    final sleepSpots = <FlSpot>[];
    final moodSpots = <FlSpot>[];
    double maxSleep = 0;

    for (var i = 0; i < dateKeys.length; i++) {
      final k = dateKeys[i];
      final sleep = sleepLogs.firstWhere(
            (l) => l.date == k,
        orElse: () => SleepLog(date: k, bedtime: '', waketime: '', hours: 0, quality: 0, dreams: ''),
      );
      if (sleep.hours > 0) {
        sleepSpots.add(FlSpot(i.toDouble(), sleep.hours));
        if (sleep.hours > maxSleep) maxSleep = sleep.hours;
      }
      final mood = moods.firstWhere(
            (m) => m.date == k,
        orElse: () => MoodEntry(date: k, mood: 'okay', label: 'Okay'),
      );
      if (moods.any((m) => m.date == k)) {
        moodSpots.add(FlSpot(i.toDouble(), mood.score * 12));
      }
    }

    final maxY = (maxSleep < 8 ? 12.0 : (maxSleep + 2).ceilToDouble()).clamp(8.0, 14.0);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('😴 Sleep vs. 😊 Mood', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('See how your sleep hours track your mood score.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 14),
          const Row(
            children: [
              _LegendDot(color: AppColors.primary, label: 'Sleep hours'),
              SizedBox(width: 16),
              _LegendDot(color: Color(0xFFF59E0B), label: 'Mood score'),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: dateKeys.length * 38.0,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 2,
                        getDrawingHorizontalLine: (v) => const FlLine(color: Color(0xFFE3EAE5), strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 2,
                            reservedSize: 28,
                            getTitlesWidget: (v, meta) => Text(v.toInt().toString(), style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 28,
                            getTitlesWidget: (v, meta) {
                              final i = v.round();
                              if (i < 0 || i >= dateKeys.length) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(shortWeekday(parseDateKey(dateKeys[i])), style: const TextStyle(fontSize: 9, color: AppColors.muted)),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [for (final s in sleepSpots) FlSpot(s.x, s.y * t)],
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        LineChartBarData(
                          spots: [for (final s in moodSpots) FlSpot(s.x, s.y * t)],
                          isCurved: true,
                          color: const Color(0xFFF59E0B),
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          dashArray: [6, 4],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. WEEKLY FOCUS BAR CHART (Animates from 0 to value)
// ---------------------------------------------------------------------------
class _WeeklyFocusCard extends StatelessWidget {
  const _WeeklyFocusCard({required this.focusSessions});
  final List<FocusSession> focusSessions;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = [for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i))];
    final keys = [for (final d in days) dateKey(d)];
    final minutes = [for (final k in keys) focusSessions.where((s) => s.date == k).fold<int>(0, (a, s) => a + s.actualMinutes)];
    final maxVal = minutes.fold<int>(0, (a, b) => a > b ? a : b).clamp(30, 1000).toDouble();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('⏱️ Focus Minutes', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Text('This week', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 180,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) => BarChart(
                BarChartData(
                  maxY: maxVal,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 30,
                    getDrawingHorizontalLine: (v) => const FlLine(color: Color(0xFFE3EAE5), strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 30,
                        getTitlesWidget: (v, meta) => Text('${v.toInt()}', style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        getTitlesWidget: (v, meta) {
                          final i = v.round();
                          if (i < 0 || i >= days.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(shortWeekday(days[i]), style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    for (var i = 0; i < minutes.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: minutes[i] == 0 ? 0.4 : minutes[i] * t,
                            color: AppColors.primary,
                            width: 16,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ],
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

// ---------------------------------------------------------------------------
// Shared Widgets
// ---------------------------------------------------------------------------
class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard(this.icon, this.value, this.label, this.sub);
  final String icon, value, label, sub;
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
    ],
  );
}
