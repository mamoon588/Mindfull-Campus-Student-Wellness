import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'meditation_card.dart';
import 'screening_sheet.dart';

class ResourcesPage extends StatelessWidget {
  const ResourcesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📚 Wellness Resources')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Tools and exercises for your mental wellness',
              style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 14),
          const MeditationCard(),
          const SizedBox(height: 14),
          _ToolCard(
            emoji: '📋',
            badge: 'Clinical Tool',
            title: 'PHQ-9 Depression Screening',
            description: '9-question screening questionnaire used by doctors worldwide.',
            child: FilledButton(
              onPressed: () => showScreening(context, phq9Spec),
              child: const Text('📝 Start Assessment'),
            ),
          ),
          _ToolCard(
            emoji: '😰',
            badge: 'Clinical Tool',
            title: 'GAD-7 Anxiety Screening',
            description: '7-question screening for generalized anxiety.',
            child: FilledButton(
              onPressed: () => showScreening(context, gad7Spec),
              child: const Text('📝 Take Assessment'),
            ),
          ),
          const _ToolCard(
            emoji: '🧘',
            badge: 'Instant Relief',
            title: '5-4-3-2-1 Grounding',
            description: 'Calm anxious moments in minutes by using your 5 senses.',
            child: _Grounding(),
          ),
          const _ToolCard(
            emoji: '🧠',
            badge: 'CBT Tool',
            title: 'Thought Challenging',
            description: 'Challenge negative thoughts with evidence-based CBT questions.',
            child: _ThoughtChallenge(),
          ),
          const _ToolCard(
            emoji: '😴',
            badge: 'Sleep Science',
            title: 'Sleep Hygiene Check',
            description: 'Rate your sleep habits for a quick score.',
            child: _SleepHygiene(),
          ),
          const _ToolCard(
            emoji: '🆘',
            badge: 'Safety Tool',
            title: 'Personal Safety Plan',
            description: 'Write down coping strategies and who to contact in a crisis.',
            child: _SafetyPlan(),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.emoji,
    required this.badge,
    required this.title,
    required this.description,
    required this.child,
  });
  final String emoji, badge, title, description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          leading: Text(emoji, style: const TextStyle(fontSize: 28)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('$badge  ·  $description', style: const TextStyle(fontSize: 12)),
          ),
          children: [child],
        ),
      ),
    );
  }
}

class _Grounding extends StatelessWidget {
  const _Grounding();

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('👀', 'SEE', 5),
      ('✋', 'TOUCH', 4),
      ('👂', 'HEAR', 3),
      ('👃', 'SMELL', 2),
      ('👅', 'TASTE', 1),
    ];
    return Column(
      children: [
        for (final (icon, sense, n) in steps)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Callout(
              color: AppColors.okSoft,
              accent: AppColors.primary,
              child: Row(children: [
                Text(icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: '$sense: ', style: const TextStyle(fontWeight: FontWeight.w800)),
                    TextSpan(
                        text:
                            'Find $n thing${n > 1 ? 's' : ''} you can ${sense.toLowerCase()}.'),
                  ])),
                ),
              ]),
            ),
          ),
        const Text('Take your time. Breathe slowly between each step.',
            style: TextStyle(color: AppColors.muted, fontSize: 12)),
      ],
    );
  }
}

class _ThoughtChallenge extends StatefulWidget {
  const _ThoughtChallenge();

  @override
  State<_ThoughtChallenge> createState() => _ThoughtChallengeState();
}

class _ThoughtChallengeState extends State<_ThoughtChallenge> {
  final _c = TextEditingController();
  String? _thought;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const questions = [
      '🤔 What evidence supports this thought?',
      '🔍 What evidence contradicts it?',
      '👥 What would I tell a friend?',
      '⏰ Will this matter in 1 year?',
      '🌈 What is a more balanced thought?',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _c,
          decoration: const InputDecoration(hintText: 'What negative thought bothers you?'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () {
            final t = _c.text.trim();
            if (t.isEmpty) {
              showToast(context, '⚠️ Enter a negative thought first', kind: ToastKind.error);
              return;
            }
            setState(() => _thought = t);
          },
          child: const Text('🔍 Challenge This'),
        ),
        if (_thought != null) ...[
          const SizedBox(height: 10),
          Callout(
            color: AppColors.warnSoft,
            accent: AppColors.warn,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(TextSpan(children: [
                  const TextSpan(
                      text: 'Challenging: ', style: TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(text: '"$_thought"'),
                ])),
                const SizedBox(height: 8),
                for (final q in questions)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(q, style: const TextStyle(fontSize: 14))),
                const SizedBox(height: 6),
                const Text(
                    '💡 Answer these honestly. You may find the thought is not entirely true.',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SleepHygiene extends StatefulWidget {
  const _SleepHygiene();

  @override
  State<_SleepHygiene> createState() => _SleepHygieneState();
}

class _SleepHygieneState extends State<_SleepHygiene> {
  static const _habits = [
    'I go to bed at consistent times',
    'I avoid screens 30 min before bed',
    'My room is cool and dark',
    'I avoid caffeine after 2 PM',
    'I exercise regularly',
    'I avoid heavy meals before bed',
    'I have a relaxing bedtime routine',
  ];
  final List<bool> _checked = List<bool>.filled(_habits.length, false);
  int? _score;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _habits.length; i++)
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(_habits[i], style: const TextStyle(fontSize: 14)),
            value: _checked[i],
            onChanged: (v) => setState(() {
              _checked[i] = v ?? false;
              _score = null;
            }),
          ),
        const SizedBox(height: 6),
        FilledButton(
          onPressed: () => setState(() => _score = _checked.where((c) => c).length),
          child: const Text('📊 Check Score'),
        ),
        if (_score != null) ...[
          const SizedBox(height: 10),
          Callout(
            color: _score! >= 5
                ? AppColors.okSoft
                : (_score! >= 3 ? AppColors.warnSoft : AppColors.dangerSoft),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Score: $_score/7',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text(_score! >= 5
                    ? '✅ Great sleep habits!'
                    : (_score! >= 3 ? '⚠️ Room for improvement.' : '❌ Poor sleep hygiene.')),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SafetyPlan extends StatefulWidget {
  const _SafetyPlan();

  @override
  State<_SafetyPlan> createState() => _SafetyPlanState();
}

class _SafetyPlanState extends State<_SafetyPlan> {
  late final TextEditingController _person;
  late final TextEditingController _place;

  @override
  void initState() {
    super.initState();
    final plan = context.read<AppState>().safetyPlan;
    _person = TextEditingController(text: plan['person'] ?? '');
    _place = TextEditingController(text: plan['place'] ?? '');
  }

  @override
  void dispose() {
    _person.dispose();
    _place.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Callout(
          color: AppColors.dangerSoft,
          accent: AppColors.danger,
          child: const Text.rich(TextSpan(children: [
            TextSpan(
                text: '🆘 My Safety Plan\n',
                style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.danger)),
            TextSpan(
                text: '1. Practice deep breathing for 5 minutes\n'
                    '2. Use 5-4-3-2-1 grounding\n'
                    '3. Call a trusted person (below)\n'
                    '4. Go to a safe place (below)\n'
                    '5. Call 1166 (Mental Health Helpline)\n'
                    'If I am in immediate danger: call 1122.',
                style: TextStyle(height: 1.6)),
          ])),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _person,
          decoration: const InputDecoration(labelText: 'Trusted person (name and number)'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _place,
          decoration: const InputDecoration(labelText: 'Safe place I can go to'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () {
            context
                .read<AppState>()
                .saveSafetyPlan({'person': _person.text.trim(), 'place': _place.text.trim()});
            showToast(context, '🆘 Safety plan saved on this device', kind: ToastKind.success);
          },
          child: const Text('💾 Save My Plan'),
        ),
        const SizedBox(height: 6),
        const Text('You matter. You are not alone. 💙',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
