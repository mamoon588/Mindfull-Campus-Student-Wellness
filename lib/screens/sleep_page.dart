import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';

const _qualityOptions = <int, String>{
  5: '😊 Excellent - Woke up refreshed',
  4: '🙂 Good - Slept well',
  3: '😐 Fair - Some disturbances',
  2: '😔 Poor - Restless night',
  1: '😢 Very Poor - Barely slept',
};

const _dreamOptions = <String, String>{
  'none': 'None remembered',
  'pleasant': '😊 Pleasant dreams',
  'neutral': '😐 Neutral dreams',
  'unpleasant': '😟 Unpleasant dreams',
};

class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  TimeOfDay _bed = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _wake = const TimeOfDay(hour: 7, minute: 0);
  int _quality = 4;
  String _dreams = 'none';
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pick(bool bed) async {
    final t = await showTimePicker(context: context, initialTime: bed ? _bed : _wake);
    if (t == null) return;
    setState(() {
      if (bed) {
        _bed = t;
      } else {
        _wake = t;
      }
    });
  }

  void _save() {
    final bt = hhmm(_bed), wt = hhmm(_wake);
    final hours = sleepHours(bt, wt);
    final updating = context.read<AppState>().sleepOn(todayKey()) != null;
    context.read<AppState>().saveSleep(
          bedtime: bt,
          waketime: wt,
          quality: _quality,
          dreams: _dreams,
          notes: _notes.text.trim(),
        );
    showToast(
        context,
        updating
            ? '😴 Updated today\'s sleep log: ${formatHours(hours)} hours'
            : '😴 Sleep saved: ${formatHours(hours)} hours',
        kind: ToastKind.success);
    _notes.clear();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final logs = app.sleepLogs;
    final recent = logs.take(7).toList();
    final hours = sleepHours(hhmm(_bed), hhmm(_wake));
    final hoursColor = hours >= 7 ? const Color(0xFF22A15A) : (hours >= 6 ? AppColors.warn : AppColors.danger);

    String avgHours = '-- hrs', avgBed = '--', avgQuality = '--/5';
    if (recent.isNotEmpty) {
      final ah = recent.fold<double>(0, (s, l) => s + l.hours) / recent.length;
      final aq = recent.fold<int>(0, (s, l) => s + l.quality) / recent.length;
      final bedMin = recent
              .map((l) => bedtimeMinutesNormalized(l.bedtime))
              .reduce((a, b) => a + b) /
          recent.length;
      avgHours = '${formatHours((ah * 10).round() / 10)} hrs';
      avgQuality = '${(aq * 10).round() / 10}/5';
      avgBed = clock12(bedMin.round());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const SectionHeader('😴 Sleep Tracker',
            'Track your sleep patterns and improve your rest quality'),
        AdaptiveGrid(
          children: [
            _SleepStat('⏱️', avgHours, 'Avg. Duration'),
            _SleepStat('🌙', avgBed, 'Avg. Bedtime'),
            _SleepStat('⭐', avgQuality, 'Avg. Quality'),
            _SleepStat('🔥', '${app.sleepStreak}', 'Tracking Streak'),
          ],
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("🌙 Log Last Night's Sleep",
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text(app.sleepOn(todayKey()) == null ? 'No entry today' : 'Logged today',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                ],
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _TimeField('🛏️ Bedtime', _bed, () => _pick(true))),
                const SizedBox(width: 10),
                Expanded(child: _TimeField('⏰ Wake time', _wake, () => _pick(false))),
              ]),
              const SizedBox(height: 12),
              Center(
                child: Text('🕐 ${formatHours(hours)} hours of sleep',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16, color: hoursColor)),
              ),
              const SizedBox(height: 12),
              LabeledDropdown<int>(
                label: '⭐ Sleep quality',
                value: _quality,
                items: _qualityOptions,
                onChanged: (v) => setState(() => _quality = v),
              ),
              const SizedBox(height: 12),
              LabeledDropdown<String>(
                label: '💭 Dreams',
                value: _dreams,
                items: _dreamOptions,
                onChanged: (v) => setState(() => _dreams = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notes,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: '📝 Notes (optional)',
                  hintText: 'What affected your sleep? (caffeine, stress, late studying...)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _save, child: const Text('💾 Save Sleep Log')),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _WeeklySleepChart(app: app),
        const SizedBox(height: 14),
        _SleepTips(logs: logs),
      ],
    );
  }
}

class _SleepStat extends StatelessWidget {
  const _SleepStat(this.icon, this.value, this.label);
  final String icon, value, label;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 26)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField(this.label, this.time, this.onTap);
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(time.format(context),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _WeeklySleepChart extends StatelessWidget {
  const _WeeklySleepChart({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = [for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i))];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('📊 Your Sleep This Week',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Text('🎯 7-9 h', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final d in days)
                  Expanded(child: _bar(d, d == days.last)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(DateTime d, bool isToday) {
    final log = app.sleepOn(dateKey(d));
    final h = log?.hours;
    final double frac = h == null ? 0.04 : (h / 10).clamp(0.04, 1.0).toDouble();
    final color = h == null
        ? const Color(0xFFE3EAE5)
        : (h >= 7 ? AppColors.primary : (h >= 6 ? AppColors.warn : AppColors.danger));
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(h == null ? '--' : '${formatHours(h)}h', style: const TextStyle(fontSize: 11)),
        const SizedBox(height: 2),
        Container(
          height: 90 * frac,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        ),
        const SizedBox(height: 4),
        Text(isToday ? 'Today' : shortWeekday(d),
            style: TextStyle(
                fontSize: 11,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                color: isToday ? AppColors.primaryDark : AppColors.muted)),
      ],
    );
  }
}

class _SleepTips extends StatelessWidget {
  const _SleepTips({required this.logs});
  final List<SleepLog> logs;

  @override
  Widget build(BuildContext context) {
    final recent = logs.take(7).toList();
    bool? consistent;
    bool? enough;
    if (recent.length >= 3) {
      final mins = recent.map((l) => bedtimeMinutesNormalized(l.bedtime)).toList();
      final range = mins.reduce((a, b) => a > b ? a : b) - mins.reduce((a, b) => a < b ? a : b);
      consistent = range <= 60;
      enough = recent.fold<double>(0, (s, l) => s + l.hours) / recent.length >= 7;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡 Personalized Sleep Tips',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const Text('Based on your recent sleep logs',
              style: TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 10),
          _tip('⏰', 'Consistent Schedule',
              'Go to bed and wake up at the same time every day, even on weekends. This helps regulate your body clock.',
              consistent),
          _tip('📱', 'Screen-Free Wind-Down',
              'Avoid screens 30-60 minutes before bed. Light from devices can make it harder to fall asleep.',
              null),
          _tip('⏱️', '7-9 Hour Target',
              'Aim for 7-9 hours of sleep. Regularly sleeping less can affect memory, mood, and academic performance.',
              enough),
        ],
      ),
    );
  }

  Widget _tip(String icon, String title, String body, bool? ok) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Callout(
        color: const Color(0xFFF6FAF7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$icon  $title', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(body, style: const TextStyle(height: 1.35, fontSize: 13)),
            const SizedBox(height: 6),
            Text(
              ok == null
                  ? (title.startsWith('Screen') ? 'Tip' : 'Log at least 3 nights to see your status')
                  : (ok ? '✅ On track' : '⚠️ Needs attention'),
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ok == null
                      ? AppColors.muted
                      : (ok ? AppColors.primaryDark : const Color(0xFF854D0E))),
            ),
          ],
        ),
      ),
    );
  }
}
