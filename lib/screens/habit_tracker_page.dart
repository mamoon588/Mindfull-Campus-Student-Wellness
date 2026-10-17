import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';

class HabitTrackerPage extends StatelessWidget {
  const HabitTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final today = todayKey();
    final done = app.habitsDoneToday;
    final total = app.habits.length;
    return Scaffold(
      appBar: AppBar(title: const Text('🌱 Habit Tracker')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const SectionHeader('Daily Habits', 'Small wins every day add up'),
            AppCard(
              color: AppColors.primarySoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Today', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      Text('$done / $total',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: total == 0 ? 0 : done / total),
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, child) => LinearProgressIndicator(
                        value: v,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFCFE7DA),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    total == 0
                        ? 'Add your first habit to begin tracking.'
                        : done == total
                        ? '🎉 All habits done for today!'
                        : 'Keep going – you have got this!',
                    style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (app.habits.isEmpty)
              const AppCard(
                child: Column(
                  children: [
                    Text('🌱', style: TextStyle(fontSize: 40)),
                    SizedBox(height: 10),
                    Text('No habits yet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text('Tap the + button below to add a daily habit.',
                        style: TextStyle(color: AppColors.muted), textAlign: TextAlign.center),
                  ],
                ),
              )
            else
              for (final h in app.habits) _HabitCard(habit: h, todayKey: today),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => _showHabitEditor(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Habit'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showHabitEditor(BuildContext context, {Habit? existing}) async {
    final result = await showModalBottomSheet<_HabitDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).cardColor,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _HabitEditorSheet(existing: existing),
      ),
    );
    if (result == null) return;
    if (!context.mounted) return;
    final app = context.read<AppState>();
    if (existing == null) {
      app.addHabit(emoji: result.emoji, name: result.name, description: result.description);
      showToast(context, '✅ Habit added', kind: ToastKind.success);
    } else {
      app.updateHabit(
        existing,
        Habit(
          id: existing.id,
          emoji: result.emoji,
          name: result.name,
          description: result.description,
          createdAt: existing.createdAt,
          completedDates: existing.completedDates,
        ),
      );
      showToast(context, '✏️ Habit updated', kind: ToastKind.success);
    }
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({required this.habit, required this.todayKey});
  final Habit habit;
  final String todayKey;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final done = habit.isDoneOn(todayKey);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(habit.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 22),
          decoration: BoxDecoration(
            color: AppColors.dangerSoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete, color: AppColors.danger),
        ),
        confirmDismiss: (direction) async {
          if (app.hapticsEnabled) HapticFeedback.mediumImpact();
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete habit?'),
              content: Text('"${habit.name}" and its history will be removed from this device.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
          return ok ?? false;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: done ? AppColors.primarySoft : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: done ? AppColors.primary : Theme.of(context).dividerColor,
              width: done ? 1.6 : 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                if (app.hapticsEnabled) HapticFeedback.lightImpact();
                app.toggleHabitToday(habit);
                if (!done) {
                  showToast(context, '✅ ${habit.name} done!', kind: ToastKind.success);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Text(habit.emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
                              color: done ? AppColors.primaryDark : Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            habit.description.isEmpty
                                ? 'Tap to mark done for today'
                                : habit.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.muted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '🔥 ${habit.currentStreak(todayKey)}-day streak',
                            style: const TextStyle(fontSize: 11, color: AppColors.primaryDark, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Edit habit',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {
                          showModalBottomSheet<_HabitDraft>(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            showDragHandle: true,
                            backgroundColor: Theme.of(context).cardColor,
                            builder: (context) => Padding(
                              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                              child: _HabitEditorSheet(existing: habit),
                            ),
                          ).then((draft) {
                            if (draft == null) return;
                            if (!context.mounted) return;
                            app.updateHabit(
                              habit,
                              Habit(
                                id: habit.id,
                                emoji: draft.emoji,
                                name: draft.name,
                                description: draft.description,
                                createdAt: habit.createdAt,
                                completedDates: habit.completedDates,
                              ),
                            );
                            showToast(context, '✏️ Habit updated', kind: ToastKind.success);
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.edit_outlined, color: AppColors.muted, size: 20),
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                      child: done
                          ? const Icon(Icons.check_circle, key: ValueKey('done'), color: AppColors.primary, size: 34)
                          : Icon(Icons.radio_button_unchecked,
                          key: const ValueKey('todo'), color: Theme.of(context).dividerColor, size: 34),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HabitDraft {
  const _HabitDraft(this.emoji, this.name, this.description);
  final String emoji;
  final String name;
  final String description;
}

class _HabitEditorSheet extends StatefulWidget {
  const _HabitEditorSheet({this.existing});
  final Habit? existing;

  @override
  State<_HabitEditorSheet> createState() => _HabitEditorSheetState();
}

class _HabitEditorSheetState extends State<_HabitEditorSheet> {
  static const _emojiChoices = <String>[
    '💧', '🚶', '📵', '🧠', '📖', '🧘', '🏃', '🥗',
    '💊', '☀️', '🌙', '🙏', '🎧', '✍️', '🌱', '💪',
  ];

  late final TextEditingController _name;
  late final TextEditingController _desc;
  late String _emoji;
  String? _nameError;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _desc = TextEditingController(text: widget.existing?.description ?? '');
    _emoji = widget.existing?.emoji ?? '🌱';
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Please give your habit a name.');
      return;
    }
    if (name.length > 40) {
      setState(() => _nameError = 'Keep the name under 40 characters.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_HabitDraft(_emoji, name, _desc.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'Add a habit' : 'Edit habit',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            const Text('Pick an icon', style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _emojiChoices.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final e = _emojiChoices[i];
                  final selected = e == _emoji;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primarySoft : AppColors.bg,
                      border: Border.all(
                          color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _emoji = e),
                      child: Center(child: Text(e, style: const TextStyle(fontSize: 24))),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Habit name',
                hintText: 'e.g. Drink Water',
                errorText: _nameError,
              ),
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) return 'Please give your habit a name.';
                if (s.length > 40) return 'Keep the name under 40 characters.';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Why does this habit matter to you?',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: Text(widget.existing == null ? 'Add Habit' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}