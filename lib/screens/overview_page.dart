import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'home_shell.dart';

const _tips = [
  '💧 Stay hydrated! Drinking water throughout the day helps maintain energy and focus.',
  '🚶 Take a short walk between study sessions to refresh your mind and body.',
  '🧘 Practice 5 minutes of deep breathing before bed for better sleep quality.',
  '📵 Try a digital detox for 30 minutes before sleeping to improve rest.',
  "🙏 Write down 3 things you're grateful for today - it can help shift your focus toward the positive.",
  '🤝 Reach out to a friend or family member - social connection supports mental health.',
  '🎵 Listen to calming music while studying to reduce stress and improve focus.',
  '☀️ Get 10-15 minutes of morning sunlight to help regulate your sleep-wake cycle.',
];

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key, required this.onNavigate});
  final void Function(Section) onNavigate;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final mood = app.latestMood;
    final moodOpt = mood == null ? null : moodByKey(mood.mood);
    final sleep = app.lastSleep;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const SectionHeader('🏠 Your Wellness Overview',
            "Here's a snapshot of your mental wellness journey"),
        if (app.latestMood?.date != todayKey()) ...[
          AppCard(
            color: AppColors.primarySoft,
            onTap: () => onNavigate(Section.mood),
            child: const Row(children: [
              Text('🙂', style: TextStyle(fontSize: 28)),
              SizedBox(width: 12),
              Expanded(
                child: Text("How are you feeling today? Tap to log your mood. It takes about ten seconds.",
                    style: TextStyle(fontWeight: FontWeight.w600, height: 1.35)),
              ),
              Icon(Icons.chevron_right, color: AppColors.primaryDark),
            ]),
          ),
          const SizedBox(height: 12),
        ],
        AdaptiveGrid(
          children: [
            // 👈 FIXED: Replaced '—' with clear, professional wording
            _StatCard(
                moodOpt?.emoji ?? '📝',
                moodOpt?.label ?? 'Log Mood',
                'Current Mood',
                mood == null ? 'Tap to check in' : (mood.date == todayKey() ? 'Logged today' : mood.date)),
            _StatCard('🔥', '${app.moodStreak}', 'Day Streak', 'Keep going!'),
            _StatCard('🌬️', '${app.breathCount}', 'Breathing Sessions', 'Total'),
            _StatCard('⏱️', '${app.totalFocusMinutes}', 'Focus Minutes', 'All-time'),
            _StatCard('🌱', '${app.habitsDoneToday}/${app.habits.length}', 'Habits Today', 'Tap to log'),
            _StatCard('📝', '${app.journals.length}', 'Journal Entries', 'Total'),
          ],
        ),
        const SizedBox(height: 14),
        _WeeklyMoodChart(moods: app.moods),
        const SizedBox(height: 14),
        AppCard(
          onTap: () => onNavigate(Section.insights),
          child: Row(
            children: [
              const Text('📈', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('See your Insights',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      app.totalFocusMinutes == 0
                          ? 'Start a focus session to fill your charts'
                          : '${app.totalFocusMinutes} focus minutes • ${app.completedFocusSessions} sessions so far',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.primaryDark),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          onTap: () => onNavigate(Section.sleep),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('😴 Sleep Summary',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Mini(sleep == null ? '-- hrs' : '${formatHours(sleep.hours)} hrs', 'Last Night'),
                  _Mini(sleep == null ? '--/5' : '${sleep.quality}/5', 'Quality'),
                  _Mini('${app.sleepStreak}', 'Day Streak'),
                ],
              ),
              const SizedBox(height: 10),
              _sleepMessage(sleep),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text('⚡ Quick Actions',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 10),
        AdaptiveGrid(
          children: [
            _Action('📊', 'Check Mood', 'Log how you feel', () => onNavigate(Section.mood)),
            _Action('⏱️', 'Focus Timer', 'Pomodoro 25 min', () => onNavigate(Section.focus)),
            _Action('🌱', 'Habits', 'Daily check-ins', () => onNavigate(Section.habits)),
            _Action('📈', 'Insights', 'Charts & trends', () => onNavigate(Section.insights)),
            _Action('🌬️', 'Breathe', 'Guided exercise', () => onNavigate(Section.breathing)),
            _Action('😴', 'Log Sleep', 'Track rest', () => onNavigate(Section.sleep)),
            _Action('📝', 'Journal', 'Write thoughts', () => onNavigate(Section.journal)),
            _Action('📚', 'Resources', 'Tools & exercises', () => onNavigate(Section.resources)),
            _Action('🆘', 'Get Help', 'Crisis support', () => onNavigate(Section.crisis)),
          ],
        ),
        const SizedBox(height: 18),
        AppCard(
          color: AppColors.okSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💡 Wellness Tip of the Day',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 6),
              Text(_tips[DateTime.now().day % _tips.length],
                  style: const TextStyle(height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sleepMessage(SleepLog? s) {
    if (s == null) {
      return const Text('No sleep data yet. Start tracking!',
          style: TextStyle(color: AppColors.muted));
    }
    final h = s.hours;
    final (text, color) = h >= 7
        ? ('✅ Great sleep last night!', AppColors.primaryDark)
        : h >= 6
        ? ('⚠️ Slightly below target', const Color(0xFF854D0E))
        : ('❌ Sleep deprived - try to rest more', AppColors.danger);
    return Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600));
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.icon, this.value, this.label, this.sub);
  final String icon, value, label, sub;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini(this.value, this.label);
  final String value, label;

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
    Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
  ]);
}

class _Action extends StatelessWidget {
  const _Action(this.icon, this.label, this.desc, this.onTap);
  final String icon, label, desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(desc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _WeeklyMoodChart extends StatelessWidget {
  const _WeeklyMoodChart({required this.moods});
  final List<MoodEntry> moods;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = [for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i))];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📈 Weekly Mood Overview',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final d in days) Expanded(child: _bar(d, d == days.last)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 10,
            children: [
              Text('😊 Great', style: TextStyle(fontSize: 11, color: AppColors.muted)),
              Text('🙂 Good', style: TextStyle(fontSize: 11, color: AppColors.muted)),
              Text('😐 Okay', style: TextStyle(fontSize: 11, color: AppColors.muted)),
              Text('😔 Low', style: TextStyle(fontSize: 11, color: AppColors.muted)),
              Text('😢 Struggling', style: TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bar(DateTime d, bool isToday) {
    final key = dateKey(d);
    MoodEntry? entry;
    for (final m in moods) {
      if (m.date == key) entry = m;
    }
    final opt = entry == null ? null : moodByKey(entry.mood);
    final h = opt == null ? 0.08 : opt.barHeight;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(opt?.emoji ?? '', style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 2),
        Container(
          height: 90 * h,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: opt == null
                ? const Color(0xFFE3EAE5)
                : (isToday ? AppColors.primary : const Color(0xFF8FD3AE)),
            borderRadius: BorderRadius.circular(6),
          ),
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