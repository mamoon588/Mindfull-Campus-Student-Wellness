import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../services/voice_service.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'breathing_page.dart';
import 'crisis_page.dart';
import 'journal_page.dart';
import 'mood_page.dart';
import 'overview_page.dart';
import 'resources_page.dart';
import 'sleep_page.dart';

/// The dashboard sections. The first five live in the bottom navigation bar;
/// resources and crisis open as full pages (also reachable from the drawer).
enum Section {
  overview('Overview', '🏠'),
  mood('Mood Tracker', '📊'),
  breathing('Breathing', '🌬️'),
  sleep('Sleep Tracker', '😴'),
  journal('Journal', '📝'),
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
    if (s.index < 5) {
      setState(() => _index = s.index);
    } else if (s == Section.resources) {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ResourcesPage()));
    } else {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CrisisPage()));
    }
  }

  Future<void> _confirmLogout() async {
    final app = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🚪 Ready to leave?'),
        content: const Text('Your data is saved on this device.'),
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
            Text(longDate(now), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
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
        child: SafeArea(
          child: Column(
            children: [
              ListTile(
                leading: const CircleAvatar(
                    backgroundColor: AppColors.primarySoft, child: Text('👩‍🎓')),
                title: Text(app.userName, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(app.userEmail, overflow: TextOverflow.ellipsis),
              ),
              const Divider(),
              for (final s in Section.values)
                ListTile(
                  leading: Text(s.icon, style: const TextStyle(fontSize: 20)),
                  title: Text(s.title,
                      style: TextStyle(
                          color: s == Section.crisis ? AppColors.danger : null,
                          fontWeight: FontWeight.w600)),
                  selected: s.index < 5 && s.index == _index,
                  selectedTileColor: AppColors.primarySoft,
                  onTap: () {
                    Navigator.pop(context); // close drawer
                    go(s);
                  },
                ),
              const Spacer(),
              const Divider(),
              ListTile(
                leading: const Text('🚪', style: TextStyle(fontSize: 20)),
                title: const Text('Log Out'),
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
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final s in Section.values.take(5))
            NavigationDestination(
              icon: Text(s.icon, style: const TextStyle(fontSize: 20)),
              label: switch (s) {
                Section.overview => 'Home',
                Section.mood => 'Mood',
                Section.breathing => 'Breathe',
                Section.sleep => 'Sleep',
                _ => 'Journal',
              },
            ),
        ],
      ),
    ),
    );
  }
}
