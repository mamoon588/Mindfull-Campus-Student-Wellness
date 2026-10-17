// Removed: import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Mood
// ---------------------------------------------------------------------------

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
  MoodOption('struggling', '😢', 'Struggling', 0.20, "🫂 You're not alone. If you need someone to talk to, call 1166."),
];

MoodOption? moodByKey(String key) {
  for (final m in moodOptions) {
    if (m.key == key) return m;
  }
  return null;
}

class MoodEntry {
  MoodEntry({
    required this.date,
    required this.mood,
    required this.label,
    this.note = '',
  });

  final String date; // yyyy-MM-dd
  final String mood; // MoodOption.key
  final String label;
  final String note;

  double get score {
    final opt = moodByKey(mood);
    return opt?.barHeight ?? 0.5;
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'mood': mood,
    'label': label,
    'note': note,
  };

  factory MoodEntry.fromJson(Map<String, dynamic> j) => MoodEntry(
    date: j['date'] as String,
    mood: j['mood'] as String,
    label: (j['label'] as String?) ?? '',
    note: (j['note'] as String?) ?? '',
  );
}

// ---------------------------------------------------------------------------
// Sleep
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Journal
// ---------------------------------------------------------------------------

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
  JournalEntry({
    required this.date,
    required this.title,
    required this.content,
    required this.tag,
  });

  final String date;
  final String title;
  final String content;
  final String tag;

  Map<String, dynamic> toJson() => {
    'date': date,
    'title': title,
    'content': content,
    'tag': tag,
  };

  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
    date: j['date'] as String,
    title: j['title'] as String,
    content: j['content'] as String,
    tag: (j['tag'] as String?) ?? 'reflection',
  );
}

// ---------------------------------------------------------------------------
// Habit
// ---------------------------------------------------------------------------

class Habit {
  Habit({
    required this.id,
    required this.emoji,
    required this.name,
    required this.description,
    required this.createdAt,
    List<String>? completedDates,
  }) : completedDates = completedDates ?? <String>[];

  final String id;
  final String emoji;
  final String name;
  final String description;
  final String createdAt;
  final List<String> completedDates;

  bool isDoneOn(String dateKey) => completedDates.contains(dateKey);

  Habit toggleForDate(String dateKey) {
    final next = List<String>.from(completedDates);
    if (next.contains(dateKey)) {
      next.remove(dateKey);
    } else {
      next.add(dateKey);
      next.sort();
    }
    return Habit(
      id: id,
      emoji: emoji,
      name: name,
      description: description,
      createdAt: createdAt,
      completedDates: next,
    );
  }

  int currentStreak(String todayKey) {
    if (completedDates.isEmpty) return 0;
    final set = completedDates.toSet();
    final today = DateTime.now();
    if (!set.contains(todayKey)) {
      final y = today.subtract(const Duration(days: 1));
      if (!set.contains('${y.year.toString().padLeft(4, '0')}-${y.month.toString().padLeft(2, '0')}-${y.day.toString().padLeft(2, '0')}')) {
        return 0;
      }
    }
    var streak = 0;
    for (var i = 0; i < 365; i++) {
      final d = today.subtract(Duration(days: i));
      final k = '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      if (set.contains(k)) {
        streak++;
      } else if (i == 0) {
        continue;
      } else {
        break;
      }
    }
    return streak;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'emoji': emoji,
    'name': name,
    'description': description,
    'createdAt': createdAt,
    'completedDates': completedDates,
  };

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
    id: j['id'] as String,
    emoji: (j['emoji'] as String?) ?? '🌱',
    name: j['name'] as String,
    description: (j['description'] as String?) ?? '',
    createdAt: (j['createdAt'] as String?) ?? DateTime.now().toIso8601String(),
    completedDates: (j['completedDates'] as List?)?.map((e) => e as String).toList() ?? <String>[],
  );
}

// ---------------------------------------------------------------------------
// FocusSession
// ---------------------------------------------------------------------------

class FocusSession {
  FocusSession({
    required this.id,
    required this.date,
    required this.plannedMinutes,
    required this.actualMinutes,
    required this.completed,
    required this.startedAt,
  });

  final String id;
  final String date;
  final int plannedMinutes;
  final int actualMinutes;
  final bool completed;
  final String startedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'plannedMinutes': plannedMinutes,
    'actualMinutes': actualMinutes,
    'completed': completed,
    'startedAt': startedAt,
  };

  factory FocusSession.fromJson(Map<String, dynamic> j) => FocusSession(
    id: j['id'] as String,
    date: j['date'] as String,
    plannedMinutes: (j['plannedMinutes'] as num?)?.toInt() ?? 0,
    actualMinutes: (j['actualMinutes'] as num?)?.toInt() ?? 0,
    completed: (j['completed'] as bool?) ?? false,
    startedAt: (j['startedAt'] as String?) ?? DateTime.now().toIso8601String(),
  );
}