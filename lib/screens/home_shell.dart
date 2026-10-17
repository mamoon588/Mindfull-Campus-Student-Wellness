import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/voice_service.dart';
import '../theme.dart';
import '../utils.dart';
import 'breathing_page.dart';
import 'crisis_page.dart';
import 'focus_timer_page.dart';
import 'habit_tracker_page.dart';
import 'insights_page.dart';
import 'journal_page.dart';
import 'mood_page.dart';
import 'overview_page.dart';
import 'resources_page.dart';
import 'sleep_page.dart';

enum Section {
  overview('Overview', '🏠'),
  mood('Mood Tracker', '📊'),
  breathing('Breathing', '🌬️'),
  sleep('Sleep Tracker', '😴'),
  journal('Journal', '📝'),
  focus('Focus Timer', '⏱️'),
  habits('Habit Tracker', '🌱'),
  insights('Insights', '📈'),
  resources('Resources', '📚'),
  crisis('Crisis Support', '🆘');

  const Section(this.title, this.icon);
  final String title;
  final String icon;
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 0;

  void go(Section s) {
    if (s.index < 8) { // 👈 ALLOW FIRST 8 MODULES IN BOTTOM NAV
      setState(() => _index = s.index);
    } else {
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => _pageFor(s),
      ));
    }
  }

  Widget _pageFor(Section s) {
    switch (s) {
      case Section.resources:
        return const ResourcesPage();
      case Section.focus:
        return const FocusTimerPage();
      case Section.habits:
        return const HabitTrackerPage();
      case Section.insights:
        return const InsightsPage();
      case Section.crisis:
        return const CrisisPage();
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _confirmLogout() async {
    final app = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppColors.danger),
            SizedBox(width: 10),
            Text('Ready to leave?'),
          ],
        ),
        content: const Text('Your data is safely saved on this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log Out')),
        ],
      ),
    );
    if (ok == true) {
      VoiceService.instance.stop();
      await app.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final now = DateTime.now();
    final firstName = app.userName.split(' ').first;

    final String avatar = app.userGender.toLowerCase() == 'male'
        ? '👨‍🎓'
        : app.userGender.toLowerCase() == 'female'
        ? '👩‍🎓'
        : '🧑‍🎓';

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _index = 0);
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${greetingFor(now.hour)}, $firstName',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              Text(longDate(now),
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          ),
          actions: [
            Tooltip(
              message: 'Mood check-in streak: ${app.moodStreak} days',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.warnSoft, borderRadius: BorderRadius.circular(14)),
                child: Text('🔥 ${app.moodStreak}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
            IconButton(
              tooltip: 'Crisis support',
              icon: const Text('🆘', style: TextStyle(fontSize: 20)),
              onPressed: () => go(Section.crisis),
            ),
          ],
        ),
        drawer: Drawer(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primarySoft,
                        child: Text(avatar, style: const TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(app.userName,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            Text(app.userEmail, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.muted),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    children: [
                      for (final s in Section.values)
                        ListTile(
                          leading: Text(s.icon, style: const TextStyle(fontSize: 20)),
                          title: Text(s.title,
                              style: TextStyle(
                                  color: s == Section.crisis ? AppColors.danger : null,
                                  fontWeight: FontWeight.w600)),
                          selected: s.index < 8 && s.index == _index,
                          selectedTileColor: AppColors.primarySoft,
                          onTap: () {
                            Navigator.pop(context); // close drawer
                            go(s);
                          },
                        ),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.danger),
                  title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmLogout();
                  },
                ),
              ],
            ),
          ),
        ),
        body: IndexedStack(
          index: _index,
          children: [
            OverviewPage(onNavigate: go),
            const MoodPage(),
            BreathingPage(active: _index == Section.breathing.index),
            const SleepPage(),
            const JournalPage(),
            const FocusTimerPage(),
            const HabitTrackerPage(),
            const InsightsPage(),
          ],
        ),
        // 👈 FIXED: Shows first 8 items now
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            for (final s in Section.values.take(8))
              NavigationDestination(
                icon: Text(s.icon, style: const TextStyle(fontSize: 20)),
                label: switch (s) {
                  Section.overview => 'Home',
                  Section.mood => 'Mood',
                  Section.breathing => 'Breathe',
                  Section.sleep => 'Sleep',
                  Section.journal => 'Journal',
                  Section.focus => 'Focus',
                  Section.habits => 'Habits',
                  _ => 'Insights',
                },
              ),
          ],
        ),
      ),
    );
  }
}