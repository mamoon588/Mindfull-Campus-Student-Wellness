class MoodOption {
  const MoodOption(this.key, this.emoji, this.label, this.barHeight, this.message);
  final String key;
  final String emoji;
  final String label;
  final double barHeight; // 0..1, used by the weekly chart
  final String message;
}

const moodOptions = <MoodOption>[
  MoodOption('great', '😊', 'Great', 0.90, '🌟 Amazing! Keep doing what works for you.'),
  MoodOption('good', '🙂', 'Good', 0.70, '🌈 Glad to hear it!'),
  MoodOption('okay', '😐', 'Okay', 0.50, '🍃 Neutral days happen. Be kind to yourself.'),
  MoodOption('low', '😔', 'Low', 0.35, '💙 Be gentle with yourself today.'),
  MoodOption('struggling', '😢', 'Struggling', 0.20,
      "🫂 You're not alone. If you need someone to talk to, call 1166."),
];

MoodOption? moodByKey(String key) {
  for (final m in moodOptions) {
    if (m.key == key) return m;
  }
  return null;
}

class MoodEntry {
  MoodEntry({required this.date, required this.mood, required this.label, this.note = ''});
  final String date; // yyyy-MM-dd
  final String mood; // MoodOption.key
  final String label;
  final String note;

  Map<String, dynamic> toJson() =>
      {'date': date, 'mood': mood, 'label': label, 'note': note};

  factory MoodEntry.fromJson(Map<String, dynamic> j) => MoodEntry(
        date: j['date'] as String,
        mood: j['mood'] as String,
        label: (j['label'] as String?) ?? '',
        note: (j['note'] as String?) ?? '',
      );
}

class SleepLog {
  SleepLog({
    required this.date,
    required this.bedtime,
    required this.waketime,
    required this.hours,
    required this.quality,
    required this.dreams,
    this.notes = '',
  });
  final String date;
  final String bedtime; // HH:mm
  final String waketime; // HH:mm
  final double hours;
  final int quality; // 1..5
  final String dreams;
  final String notes;

  Map<String, dynamic> toJson() => {
        'date': date,
        'bedtime': bedtime,
        'waketime': waketime,
        'hours': hours,
        'quality': quality,
        'dreams': dreams,
        'notes': notes,
      };

  factory SleepLog.fromJson(Map<String, dynamic> j) => SleepLog(
        date: j['date'] as String,
        bedtime: j['bedtime'] as String,
        waketime: j['waketime'] as String,
        hours: (j['hours'] as num).toDouble(),
        quality: (j['quality'] as num).toInt(),
        dreams: (j['dreams'] as String?) ?? 'none',
        notes: (j['notes'] as String?) ?? '',
      );
}

class JournalTag {
  const JournalTag(this.key, this.label);
  final String key;
  final String label;
}

const journalTags = <JournalTag>[
  JournalTag('happy', '😊 Happy'),
  JournalTag('grateful', '🙏 Grateful'),
  JournalTag('anxious', '😰 Anxious'),
  JournalTag('tired', '😴 Tired'),
  JournalTag('motivated', '💪 Motivated'),
];

String journalTagLabel(String key) {
  for (final t in journalTags) {
    if (t.key == key) return t.label;
  }
  return '📝 Reflection';
}

class JournalEntry {
  JournalEntry({required this.date, required this.title, required this.content, required this.tag});
  final String date;
  final String title;
  final String content;
  final String tag;

  Map<String, dynamic> toJson() =>
      {'date': date, 'title': title, 'content': content, 'tag': tag};

  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
        date: j['date'] as String,
        title: j['title'] as String,
        content: j['content'] as String,
        tag: (j['tag'] as String?) ?? 'reflection',
      );
}
