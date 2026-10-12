import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/call.dart';
import '../widgets/common.dart';

class MoodPage extends StatefulWidget {
  const MoodPage({super.key});

  @override
  State<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends State<MoodPage> {
  String? _selected;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _select(String key) {
    HapticFeedback.selectionClick();
    setState(() => _selected = key);
  }

  void _save() {
    if (_selected == null) {
      showToast(context, '⚠️ Pick how you feel first', kind: ToastKind.error);
      return;
    }
    final app = context.read<AppState>();
    final updating = app.latestMood?.date == todayKey();
    app.saveMood(_selected!, _note.text.trim());
    showToast(context, updating ? '✅ Today\'s mood updated' : '✅ Mood saved',
        kind: ToastKind.success);
    setState(() {
      _selected = null;
      _note.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final selected = _selected == null ? null : moodByKey(_selected!);
    final history = app.moods.reversed.take(10).toList();
    final today = app.latestMood?.date == todayKey() ? app.latestMood : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const SectionHeader('📊 Mood Tracker', "Track how you're feeling"),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('How are you feeling?',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              if (today != null) ...[
                const SizedBox(height: 4),
                Text('Today you logged "${today.label}". Saving again will update it.',
                    style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final m in moodOptions)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: _selected == m.key,
                        label: '${m.label} mood',
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: () => _select(m.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selected == m.key ? AppColors.primarySoft : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selected == m.key ? AppColors.primary : AppColors.border,
                                width: _selected == m.key ? 2 : 1,
                              ),
                            ),
                            child: Column(children: [
                              Text(m.emoji, style: const TextStyle(fontSize: 26)),
                              const SizedBox(height: 4),
                              Text(m.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: _selected == m.key
                                          ? FontWeight.w800
                                          : FontWeight.w600)),
                            ]),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (selected != null) ...[
                const SizedBox(height: 12),
                Callout(
                  color: selected.key == 'struggling' ? AppColors.dangerSoft : AppColors.okSoft,
                  child: Text('${selected.emoji}  ${selected.message}'),
                ),
              ],
              if (_selected == 'struggling') ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                  onPressed: () => callNumber(context, '1166'),
                  child: const Text('📞 Call the 1166 helpline now'),
                ),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: _note,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: "What's contributing to how you feel?",
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _save, child: const Text('💾 Save Mood')),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📅 Mood History',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 8),
              if (history.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                      child: Text('Nothing here yet. Your check-ins will appear in this list.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted))),
                )
              else
                for (final m in history)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Text(moodByKey(m.mood)?.emoji ?? '😐',
                        style: const TextStyle(fontSize: 26)),
                    title: Text(m.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(m.note.isEmpty ? m.date : '${m.date}  ·  ${m.note}',
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
