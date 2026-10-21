import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/call.dart';
import '../widgets/common.dart';

class ScreeningResult {
  const ScreeningResult(this.headline, this.advice, {this.urgent = false});
  final String headline;
  final String advice;
  final bool urgent;
}

class ScreeningSpec {
  const ScreeningSpec({
    required this.title,
    required this.intro,
    required this.questions,
    required this.interpret,
  });
  final String title;
  final String intro;
  final List<String> questions;
  final ScreeningResult Function(List<int> answers) interpret;
}

const _options = ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'];

const _disclaimer =
    'This is a screening questionnaire, not a diagnosis. Only a qualified professional can diagnose a condition.';

final phq9Spec = ScreeningSpec(
  title: 'PHQ-9 Depression Screening',
  intro: 'Over the last 2 weeks, how often have you been bothered by the following?',
  questions: const [
    'Little interest or pleasure in doing things',
    'Feeling down, depressed, or hopeless',
    'Trouble falling or staying asleep, or sleeping too much',
    'Feeling tired or having little energy',
    'Poor appetite or overeating',
    'Feeling bad about yourself, or that you are a failure',
    'Trouble concentrating on things',
    'Moving or speaking very slowly, or being unusually restless',
    'Thoughts that you would be better off dead, or of hurting yourself',
  ],
  interpret: (a) {
    final s = a.fold<int>(0, (x, y) => x + y);
    final severity = s <= 4
        ? 'Minimal'
        : s <= 9
        ? 'Mild'
        : s <= 14
        ? 'Moderate'
        : s <= 19
        ? 'Moderately Severe'
        : 'Severe';
    var advice = s >= 15
        ? '🆘 Please reach out to a professional or call 1166.'
        : s >= 10
        ? '⚠️ Consider talking to a counselor.'
        : '✅ Keep taking care of yourself!';
    final selfHarm = a.last > 0;
    if (selfHarm) {
      advice += '\n\nYou indicated thoughts of hurting yourself. Please talk to someone you '
          'trust today, or call 1166. If you are in immediate danger, call 1122.';
    }
    return ScreeningResult('Score: $s/27 - $severity', advice, urgent: s >= 15 || selfHarm);
  },
);

final gad7Spec = ScreeningSpec(
  title: 'GAD-7 Anxiety Screening',
  intro: 'Over the last 2 weeks, how often have you been bothered by the following?',
  questions: const [
    'Feeling nervous, anxious, or on edge',
    'Not being able to stop or control worrying',
    'Worrying too much about different things',
    'Trouble relaxing',
    'Being so restless that it is hard to sit still',
    'Becoming easily annoyed or irritable',
    'Feeling afraid, as if something awful might happen',
  ],
  interpret: (a) {
    final s = a.fold<int>(0, (x, y) => x + y);
    final advice = s >= 15
        ? '🆘 Please seek professional support.'
        : s >= 10
        ? '⚠️ Consider coping strategies and talking to a counselor.'
        : s >= 5
        ? '⚠️ Mild - monitor how you feel.'
        : '✅ Minimal anxiety.';
    return ScreeningResult('Score: $s/21', advice, urgent: s >= 15);
  },
);

Future<void> showScreening(BuildContext context, ScreeningSpec spec) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    // 👈 FIXED: Dynamic background color instead of hardcoded white
    backgroundColor: Theme.of(context).cardColor,
    builder: (_) => _ScreeningSheet(spec: spec),
  );
}

class _ScreeningSheet extends StatefulWidget {
  const _ScreeningSheet({required this.spec});
  final ScreeningSpec spec;

  @override
  State<_ScreeningSheet> createState() => _ScreeningSheetState();
}

class _ScreeningSheetState extends State<_ScreeningSheet> {
  late final List<int?> _answers = List<int?>.filled(widget.spec.questions.length, null);
  ScreeningResult? _result;

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final answered = _answers.where((a) => a != null).length;
    final complete = answered == _answers.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text(spec.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(spec.intro, style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: answered / _answers.length,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 4),
        Text('$answered of ${_answers.length} answered',
            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 12),
        for (var i = 0; i < spec.questions.length; i++) ...[
          Text('${i + 1}. ${spec.questions[i]}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (var v = 0; v < _options.length; v++)
                ChoiceChip(
                  label: Text(_options[v], style: const TextStyle(fontSize: 12)),
                  selected: _answers[i] == v,
                  onSelected: (_) => setState(() {
                    _answers[i] = v;
                    _result = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        FilledButton(
          onPressed: complete
              ? () => setState(() => _result = spec.interpret(_answers.cast<int>()))
              : null,
          child: Text(complete ? '📊 Get Results' : 'Answer all questions to see results'),
        ),
        if (_result != null) ...[
          const SizedBox(height: 14),
          Callout(
            color: _result!.urgent ? AppColors.dangerSoft : AppColors.okSoft,
            accent: _result!.urgent ? AppColors.danger : AppColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_result!.headline,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 6),
                Text(_result!.advice, style: const TextStyle(height: 1.4)),
                if (_result!.urgent) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                    onPressed: () => callNumber(context, '1166'),
                    child: const Text('📞 Call 1166 now'),
                  ),
                ],
                const SizedBox(height: 8),
                const Text(_disclaimer,
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}