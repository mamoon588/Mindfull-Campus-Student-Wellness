import 'dart:async';

import 'package:flutter/material.dart';

import '../services/voice_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

class _Phase {
  _Phase(this.name, this.start, this.length, this.cues);
  final String name;
  final int start; // seconds from session start
  final int length;
  final List<(int, String)> cues; // (absolute second, text)
}

// (phase name, length in seconds for a 5-minute session, [(offset, prompt)])
const List<(String, int, List<(int, String)>)> _fullScript = [
  ('Settling In', 30, [
    (0, 'Find a comfortable position. Close your eyes gently.'),
    (10, 'Let your hands rest comfortably in your lap.'),
    (20, 'Take a deep breath in... and slowly release.'),
  ]),
  ('Body Relaxation', 45, [
    (0, 'Bring your attention to your feet. Feel them relax.'),
    (10, 'Move up to your legs. Release any tension.'),
    (20, 'Relax your stomach and chest. Let them soften.'),
    (30, 'Soften your shoulders. Let them drop away from your ears.'),
    (40, 'Relax your jaw, your face, the space between your eyebrows.'),
  ]),
  ('Breath Awareness', 60, [
    (0, 'Now bring your awareness to your natural breath.'),
    (10, 'Notice the cool air entering your nose.'),
    (20, 'Feel the warm air leaving your body.'),
    (30, "Don't change your breath. Just observe it."),
    (40, 'Your breath is your anchor to this present moment.'),
    (50, 'If thoughts come, acknowledge them and return to your breath.'),
  ]),
  ('Deep Breathing', 60, [
    (0, 'Now breathe in deeply for 4 counts. 1... 2... 3... 4...'),
    (10, 'Hold gently. 1... 2... 3... 4...'),
    (20, 'Release slowly. 1... 2... 3... 4... 5... 6...'),
    (30, 'Again. Breathe in peace. 1... 2... 3... 4...'),
    (40, 'Hold the calm. 1... 2... 3... 4...'),
    (50, 'Let go of stress. Release... 1... 2... 3... 4... 5... 6...'),
  ]),
  ('Visualization', 45, [
    (0, 'Imagine a warm, golden light above your head.'),
    (10, 'This light slowly flows down through your body.'),
    (20, 'It fills you with warmth, peace, and calm.'),
    (30, 'This light dissolves any tension or worry.'),
    (40, 'You are safe, and you are at peace.'),
  ]),
  ('Stillness', 30, [
    (0, 'Rest in this peaceful stillness.'),
    (15, 'Simply be. Nothing to do. Nowhere to go.'),
  ]),
  ('Returning', 30, [
    (0, 'Begin to bring your awareness back to the room.'),
    (5, 'Wiggle your fingers and toes gently.'),
    (10, 'Notice the surface beneath you.'),
    (15, 'Notice any sounds around you.'),
    (20, "When you're ready, slowly open your eyes."),
    (25, 'Take this calm, peaceful feeling with you into your day.'),
  ]),
];

const List<(String, int, List<(int, String)>)> _shortScript = [
  ('Settle', 20, [(0, 'Close your eyes and breathe.')]),
  ('Breathe', 90, [
    (0, 'Breathe in calm... and release tension.'),
    (45, 'Stay with your breath.'),
  ]),
  ('Return', 70, [
    (0, 'Slowly return. Wiggle your fingers.'),
    (30, 'Open your eyes when ready.'),
  ]),
];

List<_Phase> _buildScript(int minutes) {
  final base = minutes == 3 ? _shortScript : _fullScript;
  final factor = minutes == 3 ? 1 : minutes ~/ 5; // 5 -> 1, 10 -> 2, 15 -> 3
  final phases = <_Phase>[];
  var start = 0;
  for (final (name, len, prompts) in base) {
    final length = len * factor;
    phases.add(_Phase(
      name,
      start,
      length,
      [for (final (at, text) in prompts) (start + at * factor, text)],
    ));
    start += length;
  }
  return phases;
}

class MeditationCard extends StatefulWidget {
  const MeditationCard({super.key});

  @override
  State<MeditationCard> createState() => _MeditationCardState();
}

class _MeditationCardState extends State<MeditationCard> {
  static const _durations = [3, 5, 10, 15];

  int _minutes = 5;
  int _elapsed = 0;
  bool _running = false;
  bool _done = false;
  Timer? _timer;
  late List<_Phase> _script = _buildScript(_minutes);

  int get _total => _minutes * 60;

  @override
  void dispose() {
    _timer?.cancel();
    VoiceService.instance.stop();
    super.dispose();
  }

  void _setMinutes(int m) {
    _reset();
    setState(() {
      _minutes = m;
      _script = _buildScript(m);
    });
  }

  void _fire(int second) {
    for (final p in _script) {
      for (final (at, text) in p.cues) {
        if (at == second) {
          VoiceService.instance.say(text);
          return;
        }
      }
    }
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      VoiceService.instance.stop();
      setState(() => _running = false);
      return;
    }
    if (_done) _reset();
    setState(() => _running = true);
    if (_elapsed == 0) _fire(0);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed++);
      if (_elapsed >= _total) {
        _complete();
      } else {
        _fire(_elapsed);
      }
    });
  }

  void _complete() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _done = true;
    });
    VoiceService.instance.say(
        'Beautiful. Take a moment to notice how calm and centered you feel. You can return to this peaceful state anytime.');
    showToast(context, '🧘 Meditation complete! You did wonderfully.', kind: ToastKind.success);
  }

  void _reset() {
    _timer?.cancel();
    VoiceService.instance.stop();
    if (!mounted) return;
    setState(() {
      _running = false;
      _done = false;
      _elapsed = 0;
    });
  }

  String get _stateLabel {
    if (_done) return 'Complete! 🎉';
    if (_elapsed == 0 && !_running) return 'Ready';
    if (!_running) return 'Paused';
    var name = _script.first.name;
    for (final p in _script) {
      if (_elapsed >= p.start) name = p.name;
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (_total - _elapsed).clamp(0, _total);
    final mm = remaining ~/ 60;
    final ss = (remaining % 60).toString().padLeft(2, '0');

    return AppCard(
      color: AppColors.primarySoft,
      child: Column(
        children: [
          const Text('🧘 Voice-Guided Meditation',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 4),
          const Text(
            'Choose your duration and let a calm voice guide you through a peaceful session.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final d in _durations)
                ChoiceChip(
                  label: Text('$d min'),
                  selected: _minutes == d,
                  onSelected: (_) => _setMinutes(d),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 170,
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 170,
                  height: 170,
                  child: CircularProgressIndicator(
                    value: _total == 0 ? 0 : _elapsed / _total,
                    strokeWidth: 8,
                    color: AppColors.primary,
                    backgroundColor: Colors.white,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$mm:$ss',
                        style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
                    Text(_stateLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.muted)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _toggle,
                  child: Text(_running
                      ? '⏸ Pause'
                      : (_done ? '▶ Start Again' : (_elapsed > 0 ? '▶ Resume' : '▶ Start'))),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                  child: OutlinedButton(onPressed: _reset, child: const Text('🔄 Reset'))),
            ],
          ),
        ],
      ),
    );
  }
}
