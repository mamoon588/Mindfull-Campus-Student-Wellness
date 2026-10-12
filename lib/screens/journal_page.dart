import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

const _prompts = [
  'What went well today?',
  'What is worrying me right now?',
  'One thing I am grateful for is…',
  'What would I tell a friend in my position?',
];

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  String? _tag;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  void _usePrompt(String p) {
    if (_title.text.trim().isEmpty) _title.text = p;
    setState(() {});
  }

  void _save() {
    final t = _title.text.trim();
    final c = _content.text.trim();
    if (t.isEmpty || c.isEmpty) {
      showToast(context, '⚠️ Add a title and a few words first', kind: ToastKind.error);
      return;
    }
    context.read<AppState>().saveJournal(t, c, _tag);
    showToast(context, '✅ Entry saved', kind: ToastKind.success);
    setState(() {
      _title.clear();
      _content.clear();
      _tag = null;
    });
  }

  void _delete(JournalEntry e) {
    final app = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final index = app.deleteJournal(e);
    if (index < 0) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: const Text('Entry deleted'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),
      action: SnackBarAction(label: 'Undo', onPressed: () => app.restoreJournal(index, e)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final entries = app.journals.take(20).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const SectionHeader('📝 Your Journal', 'A private place for your thoughts'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('New Entry',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 4),
              const Text('Not sure where to start? Tap an idea.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 0,
                children: [
                  for (final p in _prompts)
                    ActionChip(label: Text(p, style: const TextStyle(fontSize: 12)), onPressed: () => _usePrompt(p)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _title,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _content,
                minLines: 5,
                maxLines: 10,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Your thoughts',
                  hintText: "What's on your mind?",
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              const Text('How does this feel? (optional)',
                  style: TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final t in journalTags)
                    ChoiceChip(
                      label: Text(t.label),
                      selected: _tag == t.key,
                      onSelected: (v) => setState(() => _tag = v ? t.key : null),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _save, child: const Text('💾 Save Entry')),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📖 Recent Entries',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 8),
              if (entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                      child: Text('Nothing here yet. Your entries will appear in this list.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted))),
                )
              else
                for (final e in entries)
                  ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    title: Text(e.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${e.date}  ·  ${journalTagLabel(e.tag)}',
                        style: const TextStyle(fontSize: 12)),
                    children: [
                      Text(e.content, style: const TextStyle(height: 1.4)),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _delete(e),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Delete'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
