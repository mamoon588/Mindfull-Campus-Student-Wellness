import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class FocusTimerPage extends StatefulWidget {
  const FocusTimerPage({super.key});

  @override
  State<FocusTimerPage> createState() => _FocusTimerPageState();
}

class _FocusTimerPageState extends State<FocusTimerPage> with TickerProviderStateMixin {
  int _selectedMinutes = 25;
  int _remainingSeconds = 25 * 60;
  bool _running = false;
  Timer? _ticker;

  final TextEditingController _hoursController = TextEditingController(text: '0');
  final TextEditingController _minutesController = TextEditingController(text: '25');

  late final AnimationController _celebrate;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _celebrate = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _celebrate.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  int get _totalSeconds => _selectedMinutes * 60;

  void _applyCustomTime() {
    if (_running) return;
    final h = int.tryParse(_hoursController.text) ?? 0;
    final m = int.tryParse(_minutesController.text) ?? 0;
    final totalMins = (h * 60) + m;

    if (totalMins <= 0 || totalMins > 180) {
      showToast(context, '⚠️ Enter a valid time between 1 and 180 mins', kind: ToastKind.error);
      return;
    }

    setState(() {
      _selectedMinutes = totalMins;
      _remainingSeconds = totalMins * 60;
    });
    FocusScope.of(context).unfocus();
    showToast(context, '⏱️ Timer set to ${h}h ${m}m', kind: ToastKind.success);
  }

  void _start() {
    if (_running) return;
    if (_remainingSeconds <= 0) {
      _remainingSeconds = _totalSeconds;
    }
    setState(() => _running = true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _finish(completed: true);
        }
      });
    });
  }

  void _pause() {
    _ticker?.cancel();
    _ticker = null;
    setState(() => _running = false);
  }

  void _reset() {
    _ticker?.cancel();
    _ticker = null;
    setState(() {
      _running = false;
      _remainingSeconds = _totalSeconds;
    });
  }

  Future<void> _finish({required bool completed}) async {
    _ticker?.cancel();
    _ticker = null;
    _running = false;

    final app = context.read<AppState>();

    if (app.hapticsEnabled) {
      await HapticFeedback.heavyImpact();
    }

    if (app.focusSoundEnabled) {
      try {
        final soundFile = app.focusSoundType == 0 ? 'chime.mp3'
            : app.focusSoundType == 1 ? 'soft_chime.mp3'
            : 'nature.mp3';
        await _audioPlayer.play(AssetSource('audio/$soundFile'));
      } catch (e) {
        await SystemSound.play(SystemSoundType.click);
      }
    }

    _celebrate.forward(from: 0);

    final elapsedMinutes = (_totalSeconds - _remainingSeconds);
    final actualMinutes = completed
        ? _selectedMinutes
        : (elapsedMinutes.toDouble() / 60).round().clamp(0, _selectedMinutes);

    if (!mounted) return;
    app.recordFocusSession(
      plannedMinutes: _selectedMinutes,
      actualMinutes: actualMinutes,
      completed: completed,
    );
    showToast(
      context,
      '🎉 Focus session complete! Take a 5-minute break.',
      kind: ToastKind.success,
    );

    setState(() {
      _remainingSeconds = _totalSeconds;
    });
  }

  void _stopEarly() {
    if (!_running) return;
    _finish(completed: false);
  }

  String get _timeText {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final progress = _totalSeconds == 0 ? 0.0 : 1 - (_remainingSeconds / _totalSeconds);
    return Scaffold(
      appBar: AppBar(title: const Text('⏱️ Focus Timer')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const SectionHeader('Study Focus Timer', 'Pomodoro-style deep work blocks'),
            AdaptiveGrid(
              children: [
                _MiniStat('⏱️', '${app.totalFocusMinutes}', 'Focus Minutes', 'All-time'),
                _MiniStat('✅', '${app.completedFocusSessions}', 'Completed', 'Sessions'),
                _MiniStat('🔥', '${app.focusStreak}', 'Day Streak', 'Keep going'),
              ],
            ),
            const SizedBox(height: 18),
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _running ? AppColors.primarySoft : AppColors.bg,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: _running ? 0.18 : 0.05),
                      blurRadius: _running ? 28 : 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: _CountdownRing(
                  progress: progress,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _timeText,
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w800,
                          color: _running ? AppColors.primaryDark : AppColors.text,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: _running ? 1 : 0,
                        child: const Text(
                          'Deep focus',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _running ? 'Stay with it 🌱' : 'Ready when you are',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hoursController,
                    keyboardType: TextInputType.number,
                    enabled: !_running,
                    decoration: const InputDecoration(
                      labelText: 'Hours',
                      prefixIcon: Icon(Icons.access_time, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _minutesController,
                    keyboardType: TextInputType.number,
                    enabled: !_running,
                    decoration: const InputDecoration(
                      labelText: 'Minutes',
                      prefixIcon: Icon(Icons.timer, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: _running ? null : _applyCustomTime,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primaryDark),
                    child: const Text('Set'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _running ? null : _reset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _running ? _pause : _start,
                    icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                    label: Text(_running ? 'Pause' : 'Start'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  ),
                ),
              ],
            ),
            if (_running) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _stopEarly,
                child: const Text('End session early', style: TextStyle(color: AppColors.danger)),
              ),
            ],
            const SizedBox(height: 20),
            const AppCard(
              color: AppColors.okSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🧠 How it works',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  SizedBox(height: 8),
                  Text(
                    'Pick a duration, hit Start, and put your phone face-down. '
                        'When the timer ends you will get a gentle nudge to take a '
                        '5-minute break. Your focus minutes are saved automatically '
                        'and feed the Insights charts.',
                    style: TextStyle(height: 1.45, color: AppColors.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.icon, this.value, this.label, this.sub);
  final String icon;
  final String value;
  final String label;
  final String sub;

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

class _CountdownRing extends StatelessWidget {
  const _CountdownRing({required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, p, child) {
        return CustomPaint(
          painter: _RingPainter(p),
          child: SizedBox(width: 230, height: 230, child: Center(child: child)),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 12;

    final track = Paint()
      ..color = const Color(0xFFE3EAE5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final sweep = 2 * 3.14159265 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159265 / 2,
      sweep,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}