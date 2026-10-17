import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../services/voice_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

enum PhaseKind { inhale, hold, exhale }

class BreathPhase {
  const BreathPhase(this.kind, this.instruction, this.label, this.voice, this.seconds);
  final PhaseKind kind;
  final String instruction;
  final String label;
  final String voice;
  final int seconds;
}

class BreathTechnique {
  const BreathTechnique(this.icon, this.name, this.tagline, this.phases, this.rounds);
  final String icon;
  final String name;
  final String tagline;
  final List<BreathPhase> phases;
  final int rounds;

  int get totalSeconds => phases.fold(0, (s, p) => s + p.seconds) * rounds;
}

const breathTechniques = <BreathTechnique>[
  BreathTechnique('📦', 'Box Breathing', '4-4-4-4 | Focus & Calm', [
    BreathPhase(PhaseKind.inhale, 'Breathe In...', 'Inhale', 'Breathe in', 4),
    BreathPhase(PhaseKind.hold, 'Hold...', 'Hold', 'Hold', 4),
    BreathPhase(PhaseKind.exhale, 'Breathe Out...', 'Exhale', 'Breathe out', 4),
    BreathPhase(PhaseKind.hold, 'Hold...', 'Hold', 'Hold', 4),
  ], 3),
  BreathTechnique('😌', '4-7-8 Relaxation', 'Sleep & Anxiety', [
    BreathPhase(PhaseKind.inhale, 'Breathe In...', 'Inhale', 'Breathe in', 4),
    BreathPhase(PhaseKind.hold, 'Hold...', 'Hold', 'Hold', 7),
    BreathPhase(PhaseKind.exhale, 'Release...', 'Exhale', 'Release', 8),
  ], 2),
  BreathTechnique('⚡', 'Energizing Breath', 'Quick Energy Boost', [
    BreathPhase(PhaseKind.inhale, 'Quick Inhale!', 'Inhale', 'In', 2),
    BreathPhase(PhaseKind.exhale, 'Force Out!', 'Exhale', 'Out', 2),
  ], 5),
  BreathTechnique('🌊', 'Calming Waves', 'Gentle Relaxation', [
    BreathPhase(PhaseKind.inhale, 'Gentle Inhale...', 'Inhale', 'Breathe in', 5),
    BreathPhase(PhaseKind.exhale, 'Slow Release...', 'Exhale', 'Breathe out', 5),
  ], 4),
];

class BreathingPage extends StatefulWidget {
  const BreathingPage({super.key, required this.active});
  final bool active;

  @override
  State<BreathingPage> createState() => _BreathingPageState();
}

class _BreathingPageState extends State<BreathingPage> {
  static const double _maxSize = 220;
  static const double _minScale = 0.6;

  int _tech = 0;
  bool _running = false;
  bool _paused = false;
  bool _done = false;
  int _phase = 0;
  int _round = 0;
  int _left = 0;
  double _scale = _minScale;
  Timer? _timer;

  BreathTechnique get _t => breathTechniques[_tech];
  BreathPhase get _p => _t.phases[_phase];

  @override
  void didUpdateWidget(covariant BreathingPage old) {
    super.didUpdateWidget(old);
    if (old.active && !widget.active) _reset();
  }

  @override
  void dispose() {
    _timer?.cancel();
    VoiceService.instance.stop();
    super.dispose();
  }

  void _selectTechnique(int i) {
    _reset();
    setState(() => _tech = i);
    VoiceService.instance.say(breathTechniques[i].name);
  }

  void _start() {
    if (_running && !_paused) return;
    if (_paused) {
      setState(() => _paused = false);
      _startTimer();
      return;
    }
    setState(() {
      _round = 0;
      _done = false;
      _running = true;
    });
    _beginPhase(0);
  }

  void _beginPhase(int i) {
    final p = _t.phases[i];
    setState(() {
      _phase = i;
      _left = p.seconds;
      if (p.kind == PhaseKind.inhale) _scale = 1.0;
      if (p.kind == PhaseKind.exhale) _scale = _minScale;
    });
    HapticFeedback.lightImpact();
    VoiceService.instance.say(p.voice);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_left > 1) {
        setState(() => _left--);
      } else {
        _advance();
      }
    });
  }

  void _advance() {
    _timer?.cancel();
    final next = _phase + 1;
    if (next >= _t.phases.length) {
      _round++;
      if (_round >= _t.rounds) {
        _complete();
      } else {
        _beginPhase(0);
      }
    } else {
      _beginPhase(next);
    }
  }

  void _complete() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _paused = false;
      _done = true;
      _left = 0;
    });
    HapticFeedback.mediumImpact();
    VoiceService.instance.say('Well done');
    context.read<AppState>().recordBreathSession(
        technique: _t.name, rounds: _t.rounds, seconds: _t.totalSeconds);
    showToast(context, '🎉 ${_t.name} complete!', kind: ToastKind.success);
  }

  void _pause() {
    if (!_running || _paused) return;
    _timer?.cancel();
    VoiceService.instance.stop();
    setState(() => _paused = true);
  }

  void _reset() {
    _timer?.cancel();
    VoiceService.instance.stop();
    if (!mounted) return;
    setState(() {
      _running = false;
      _paused = false;
      _done = false;
      _phase = 0;
      _round = 0;
      _left = 0;
      _scale = _minScale;
    });
  }

  void _skip() {
    if (_running && !_paused) _advance();
  }

  Color _phaseColor() {
    if (!_running) return AppColors.primary;
    switch (_p.kind) {
      case PhaseKind.inhale:
        return const Color(0xFF4FB783);
      case PhaseKind.hold:
        return const Color(0xFF6C8EBF);
      case PhaseKind.exhale:
        return const Color(0xFF8E7CC3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final t = _t;
    final circleSize = _maxSize * _scale;
    final double progress = (_running && !_done)
        ? ((_p.seconds - _left + 1) / _p.seconds).clamp(0.0, 1.0).toDouble()
        : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const SectionHeader('🌬️ Breathing Exercises', 'Choose a technique'),
        AdaptiveGrid(
          children: [
            for (var i = 0; i < breathTechniques.length; i++)
              AppCard(
                onTap: () => _selectTechnique(i),
                color: i == _tech ? AppColors.primarySoft : Colors.white,
                padding: const EdgeInsets.all(10),
                child: Row(children: [
                  Text(breathTechniques[i].icon, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(breathTechniques[i].name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        Text(breathTechniques[i].tagline,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                      ],
                    ),
                  ),
                ]),
              ),
          ],
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(t.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                  Text(
                      'Round ${_done ? t.rounds : (_running ? _round + 1 : 0)}/${t.rounds}',
                      style: const TextStyle(color: AppColors.muted)),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => (_running && !_paused) ? _pause() : _start(),
                child: SizedBox(
                  width: _maxSize + 20,
                  height: _maxSize + 20,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: _maxSize + 12,
                        height: _maxSize + 12,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(end: progress),
                          duration: const Duration(milliseconds: 900),
                          builder: (context, v, child) => CircularProgressIndicator(
                            value: v,
                            strokeWidth: 6,
                            color: _phaseColor(),
                            backgroundColor: const Color(0xFFE3EAE5),
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: Duration(
                            milliseconds: _running && !_paused && _p.kind != PhaseKind.hold
                                ? _p.seconds * 1000
                                : 400),
                        curve: Curves.easeInOut,
                        width: circleSize,
                        height: circleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _phaseColor().withAlpha(46),
                          border: Border.all(color: _phaseColor(), width: 3),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _done
                                  ? '✓'
                                  : (_running ? '$_left' : '${t.phases.first.seconds}'),
                              style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800),
                            ),
                            const Text('sec', style: TextStyle(color: AppColors.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _done
                    ? 'Well done 🎉'
                    : (_running
                    ? (_paused ? 'Paused - tap the circle to resume' : _p.instruction)
                    : 'Tap the circle to begin'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < t.phases.length; i++)
                    Chip(
                      label: Text('${t.phases[i].label} ${t.phases[i].seconds}s'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor:
                      (_running && i == _phase) ? AppColors.primarySoft : Colors.white,
                      side: BorderSide(
                          color: (_running && i == _phase)
                              ? AppColors.primary
                              : AppColors.border),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _start,
                      child: Text(_paused ? '▶️ Resume' : (_running ? '▶️ Running' : '▶️ Start')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                      child: OutlinedButton(onPressed: _pause, child: const Text('⏸️ Pause'))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: OutlinedButton(onPressed: _reset, child: const Text('🔄 Reset'))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: OutlinedButton(onPressed: _skip, child: const Text('⏭️ Skip'))),
                ],
              ),
              const Divider(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Stat('${app.breathCount}', 'Sessions'),
                  _Stat('${app.breathMinutes}', 'Minutes'),
                  _Stat('${app.breathStreak}', 'Day streak'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value, label;

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value,
        style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
    Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
  ]);
}