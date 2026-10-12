import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';
import '../utils.dart';

/// Single source of truth for the app. Everything is persisted on-device with
/// shared_preferences (the web app used localStorage). No backend.
class AppState extends ChangeNotifier {
  AppState._(this._p);
  final SharedPreferences _p;

  static Future<AppState> create() async {
    final s = AppState._(await SharedPreferences.getInstance());
    s._load();
    return s;
  }

  // ---- session ----
  bool isLoggedIn = false;
  String userName = 'Student';
  String userEmail = 'student@campus.edu';

  // ---- data ----
  List<MoodEntry> moods = []; // oldest -> newest
  List<SleepLog> sleepLogs = []; // newest -> oldest
  List<JournalEntry> journals = []; // newest -> oldest
  int breathCount = 0;
  int breathTotalSeconds = 0;
  int breathStreak = 0;
  String lastBreathDate = '';
  Map<String, String> safetyPlan = {};

  String get rememberedEmail => _p.getString('rememberedEmail') ?? '';

  void _load() {
    isLoggedIn = _p.getBool('isLoggedIn') ?? false;
    userName = _p.getString('userName') ?? 'Student';
    userEmail = _p.getString('userEmail') ?? 'student@campus.edu';
    moods = _readList('mindfulCampusMoods', MoodEntry.fromJson);
    sleepLogs = _readList('sleepLogs', SleepLog.fromJson);
    journals = _readList('journalEntries', JournalEntry.fromJson);
    breathCount = _p.getInt('breathCount') ?? 0;
    breathTotalSeconds = _p.getInt('breathTotalSeconds') ?? 0;
    breathStreak = _p.getInt('breathStreak') ?? 0;
    lastBreathDate = _p.getString('lastBreathDate') ?? '';
    try {
      final raw = _p.getString('safetyPlan');
      if (raw != null) {
        safetyPlan = Map<String, String>.from(jsonDecode(raw) as Map);
      }
    } catch (_) {}
  }

  List<T> _readList<T>(String key, T Function(Map<String, dynamic>) f) {
    final raw = _p.getString(key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => f(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  void _writeList(String key, List<Map<String, dynamic>> l) {
    _p.setString(key, jsonEncode(l));
  }

  // =====================================================================
  // Auth (local session only - same behaviour as the web app)
  // =====================================================================
  Future<void> login({required String email, required bool remember}) async {
    userEmail = email;
    userName = prettyNameFromEmail(email);
    isLoggedIn = true;
    await _p.setBool('isLoggedIn', true);
    await _p.setString('userName', userName);
    await _p.setString('userEmail', userEmail);
    await _p.setString('loginTime', DateTime.now().toIso8601String());
    if (remember) {
      await _p.setString('rememberedEmail', email);
    } else {
      await _p.remove('rememberedEmail');
    }
    notifyListeners();
  }

  Future<void> register({required String fullName, required String email}) async {
    userEmail = email;
    userName = fullName;
    isLoggedIn = true;
    await _p.setBool('isLoggedIn', true);
    await _p.setString('userName', userName);
    await _p.setString('userEmail', userEmail);
    await _p.setString('registrationDate', DateTime.now().toIso8601String());
    await _p.setString('loginTime', DateTime.now().toIso8601String());
    notifyListeners();
  }

  Future<void> logout() async {
    isLoggedIn = false;
    await _p.setBool('isLoggedIn', false);
    notifyListeners();
  }

  void saveContactMessage(String name, String email, String message) {
    List<dynamic> all = [];
    try {
      all = jsonDecode(_p.getString('contactMessages') ?? '[]') as List;
    } catch (_) {}
    all.add({'name': name, 'email': email, 'message': message, 'date': DateTime.now().toIso8601String()});
    _p.setString('contactMessages', jsonEncode(all));
  }

  // =====================================================================
  // Mood
  // =====================================================================
  MoodEntry? get latestMood => moods.isEmpty ? null : moods.last;

  void saveMood(String moodKey, String note) {
    final opt = moodByKey(moodKey);
    if (opt == null) return;
    final today = todayKey();
    moods.removeWhere((m) => m.date == today);
    moods.add(MoodEntry(date: today, mood: moodKey, label: opt.label, note: note));
    if (moods.length > 90) moods = moods.sublist(moods.length - 90);
    _writeList('mindfulCampusMoods', moods.map((m) => m.toJson()).toList());
    notifyListeners();
  }

  int get moodStreak => _streak(moods.reversed.map((m) => m.date).toList());

  /// Consecutive days ending today or yesterday. [datesNewestFirst] must be
  /// unique, newest first.
  int _streak(List<String> datesNewestFirst) {
    if (datesNewestFirst.isEmpty) return 0;
    final now = DateTime.now();
    final first = parseDateKey(datesNewestFirst.first);
    if (daysBetween(first, now) > 1) return 0;
    var count = 1;
    for (var i = 1; i < datesNewestFirst.length; i++) {
      final newer = parseDateKey(datesNewestFirst[i - 1]);
      final older = parseDateKey(datesNewestFirst[i]);
      if (daysBetween(older, newer) == 1) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  // =====================================================================
  // Sleep
  // =====================================================================
  void saveSleep({
    required String bedtime,
    required String waketime,
    required int quality,
    required String dreams,
    required String notes,
  }) {
    final hours = sleepHours(bedtime, waketime);
    final today = todayKey();
    final log = SleepLog(
      date: today, bedtime: bedtime, waketime: waketime,
      hours: hours, quality: quality, dreams: dreams, notes: notes,
    );
    final i = sleepLogs.indexWhere((l) => l.date == today);
    if (i >= 0) {
      sleepLogs[i] = log;
    } else {
      sleepLogs.insert(0, log);
    }
    if (sleepLogs.length > 90) sleepLogs = sleepLogs.sublist(0, 90);
    _writeList('sleepLogs', sleepLogs.map((l) => l.toJson()).toList());
    notifyListeners();
  }

  SleepLog? get lastSleep => sleepLogs.isEmpty ? null : sleepLogs.first;
  SleepLog? sleepOn(String date) {
    for (final l in sleepLogs) {
      if (l.date == date) return l;
    }
    return null;
  }

  int get sleepStreak => _streak(sleepLogs.map((l) => l.date).toList());

  // =====================================================================
  // Journal
  // =====================================================================
  void saveJournal(String title, String content, String? tag) {
    final today = todayKey();
    final t = tag ?? 'reflection';
    journals.insert(0, JournalEntry(date: today, title: title, content: content, tag: t));
    if (journals.length > 100) journals = journals.sublist(0, 100);
    _writeList('journalEntries', journals.map((j) => j.toJson()).toList());
    notifyListeners();
  }

  int deleteJournal(JournalEntry e) {
    final i = journals.indexOf(e);
    if (i < 0) return -1;
    journals.removeAt(i);
    _writeList('journalEntries', journals.map((j) => j.toJson()).toList());
    notifyListeners();
    return i;
  }

  void restoreJournal(int index, JournalEntry e) {
    final at = index > journals.length ? journals.length : index;
    journals.insert(at, e);
    _writeList('journalEntries', journals.map((j) => j.toJson()).toList());
    notifyListeners();
  }

  // =====================================================================
  // Breathing
  // =====================================================================
  void recordBreathSession({required String technique, required int rounds, required int seconds}) {
    final today = todayKey();
    breathCount++;
    breathTotalSeconds += seconds;
    if (lastBreathDate != today) {
      final y = dateKey(DateTime.now().subtract(const Duration(days: 1)));
      breathStreak = lastBreathDate == y ? breathStreak + 1 : 1;
      lastBreathDate = today;
    }
    _p.setInt('breathCount', breathCount);
    _p.setInt('breathTotalSeconds', breathTotalSeconds);
    _p.setInt('breathStreak', breathStreak);
    _p.setString('lastBreathDate', lastBreathDate);
    notifyListeners();
  }

  int get breathMinutes => (breathTotalSeconds / 60).round();

  // =====================================================================
  // Safety plan
  // =====================================================================
  void saveSafetyPlan(Map<String, String> plan) {
    safetyPlan = plan;
    _p.setString('safetyPlan', jsonEncode(plan));
    notifyListeners();
  }
}
