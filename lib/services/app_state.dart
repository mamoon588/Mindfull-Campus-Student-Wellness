import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models.dart';
import '../utils.dart';

class AppState extends ChangeNotifier {
  AppState._(this._p);
  final SharedPreferences _p;

  static Future<AppState> create() async {
    final s = AppState._(await SharedPreferences.getInstance());
    s._load();
    return s;
  }

  bool isLoggedIn = false;
  String userName = 'Student';
  String userEmail = 'student@campus.edu';
  String userPhone = '';
  String userGender = '';
  String userUniversity = '';

  // Theme & Accessibility Settings
  bool isDarkMode = false;
  int themeColorValue = 0xFF2D9D5F;
  bool hapticsEnabled = true;
  double textScale = 1.0;

  // Notifications & Sounds
  bool reminderEnabled = false;
  String reminderTime = '20:00';
  bool focusSoundEnabled = true;
  int focusSoundType = 0;

  // Emergency Contact
  String trustedPersonName = '';
  String trustedPersonPhone = '';

  List<MoodEntry> moods = [];
  List<SleepLog> sleepLogs = [];
  List<JournalEntry> journals = [];
  int breathCount = 0;
  int breathTotalSeconds = 0;
  int breathStreak = 0;
  String lastBreathDate = '';

  List<Habit> habits = [];
  List<FocusSession> focusSessions = [];
  bool _seededHabits = false;
  Map<String, String> safetyPlan = {};

  String get rememberedEmail => _p.getString('rememberedEmail') ?? '';

  void _load() {
    isLoggedIn = _p.getBool('isLoggedIn') ?? false;
    userName = _p.getString('userName') ?? 'Student';
    userEmail = _p.getString('userEmail') ?? 'student@campus.edu';
    userPhone = _p.getString('userPhone') ?? '';
    userGender = _p.getString('userGender') ?? '';
    userUniversity = _p.getString('userUniversity') ?? '';

    isDarkMode = _p.getBool('isDarkMode') ?? false;
    themeColorValue = _p.getInt('themeColor') ?? 0xFF2D9D5F;
    hapticsEnabled = _p.getBool('hapticsEnabled') ?? true;
    textScale = _p.getDouble('textScale') ?? 1.0;
    reminderEnabled = _p.getBool('reminderEnabled') ?? false;
    reminderTime = _p.getString('reminderTime') ?? '20:00';
    focusSoundEnabled = _p.getBool('focusSoundEnabled') ?? true;
    focusSoundType = _p.getInt('focusSoundType') ?? 0;
    trustedPersonName = _p.getString('trustedPersonName') ?? '';
    trustedPersonPhone = _p.getString('trustedPersonPhone') ?? '';

    moods = _readList('mindfulCampusMoods', MoodEntry.fromJson);
    sleepLogs = _readList('sleepLogs', SleepLog.fromJson);
    journals = _readList('journalEntries', JournalEntry.fromJson);
    breathCount = _p.getInt('breathCount') ?? 0;
    breathTotalSeconds = _p.getInt('breathTotalSeconds') ?? 0;
    breathStreak = _p.getInt('breathStreak') ?? 0;
    lastBreathDate = _p.getString('lastBreathDate') ?? '';
    habits = _readList('habits', Habit.fromJson);
    focusSessions = _readList('focusSessions', FocusSession.fromJson);
    _seededHabits = _p.getBool('_seededHabits') ?? false;

    try {
      final raw = _p.getString('safetyPlan');
      if (raw != null) {
        safetyPlan = Map<String, String>.from(jsonDecode(raw) as Map);
      }
    } catch (_) {}

    if (!_seededHabits && habits.isEmpty) {
      final now = DateTime.now().toIso8601String();
      habits = [
        Habit(id: 'seed_water', emoji: '💧', name: 'Drink Water', description: 'Stay hydrated through the day', createdAt: now),
        Habit(id: 'seed_walk', emoji: '🚶', name: 'Short Walk', description: 'A 10-minute walk boosts mood', createdAt: now),
        Habit(id: 'seed_screens', emoji: '📵', name: 'No Screens Before Bed', description: 'Wind down without scrolling', createdAt: now),
      ];
      _writeList('habits', habits.map((h) => h.toJson()).toList());
      _p.setBool('_seededHabits', true);
    }
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

  // ================= Settings & Preferences =================
  void toggleDarkMode(bool value) { isDarkMode = value; _p.setBool('isDarkMode', value); notifyListeners(); }
  void setThemeColor(int colorValue) { themeColorValue = colorValue; _p.setInt('themeColor', colorValue); notifyListeners(); }
  void setHaptics(bool value) { hapticsEnabled = value; _p.setBool('hapticsEnabled', value); notifyListeners(); }
  void setTextScale(double value) { textScale = value; _p.setDouble('textScale', value); notifyListeners(); }
  void setReminder(bool enabled, String time) { reminderEnabled = enabled; reminderTime = time; _p.setBool('reminderEnabled', enabled); _p.setString('reminderTime', time); notifyListeners(); }
  void setFocusSound(bool enabled, int type) { focusSoundEnabled = enabled; focusSoundType = type; _p.setBool('focusSoundEnabled', enabled); _p.setInt('focusSoundType', type); notifyListeners(); }

  Future<void> updateProfile({required String name, required String email}) async {
    userName = name; userEmail = email;
    await _p.setString('userName', name); await _p.setString('userEmail', email);
    notifyListeners();
  }

  Future<void> updateTrustedContact(String name, String phone) async {
    trustedPersonName = name; trustedPersonPhone = phone;
    await _p.setString('trustedPersonName', name); await _p.setString('trustedPersonPhone', phone);
    notifyListeners();
  }

  // ================= Data Management =================

  Future<void> exportDataAsCSV() async {
    List<List<dynamic>> rows = [];
    rows.add(['Date', 'Type', 'Details', 'Value/Notes']);

    for (var m in moods) { rows.add([m.date, 'Mood', m.label, m.note]); }
    for (var s in sleepLogs) { rows.add([s.date, 'Sleep', '${s.hours} hours', 'Quality: ${s.quality}/5. ${s.notes}']); }
    for (var f in focusSessions) { rows.add([f.date, 'Focus Session', '${f.plannedMinutes} mins planned', '${f.actualMinutes} mins focused']); }
    for (var h in habits) { rows.add(['-', 'Habit', h.name, 'Streak: ${h.currentStreak(todayKey())}']); }

    String csvData = const ListToCsvConverter().convert(rows);
    final bytes = utf8.encode(csvData);
    final file = XFile.fromData(bytes, mimeType: 'text/csv', name: 'mindful_campus_export.csv');
    await Share.shareXFiles([file], text: 'My Mindful Campus CSV Data');
  }

  Future<void> exportDataAsPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // 👈 FIXED: Added const to pw.TextStyle
            pw.Header(level: 0, child: pw.Text('Mindful Campus Data Export', style: const pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
            pw.Paragraph(text: 'User: $userName ($userEmail)'),
            pw.Paragraph(text: 'Date: ${DateTime.now().toString()}'),
            pw.SizedBox(height: 20),

            pw.Header(level: 1, text: 'Mood Logs'),
            ...moods.map((m) => pw.Bullet(text: '${m.date}: ${m.label} - ${m.note}')),
            pw.SizedBox(height: 10),

            pw.Header(level: 1, text: 'Sleep Logs'),
            ...sleepLogs.map((s) => pw.Bullet(text: '${s.date}: ${s.hours} hours, Quality: ${s.quality}/5')),
            pw.SizedBox(height: 10),

            pw.Header(level: 1, text: 'Focus Sessions'),
            ...focusSessions.map((f) => pw.Bullet(text: '${f.date}: ${f.actualMinutes} mins focused')),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final file = XFile.fromData(bytes, mimeType: 'application/pdf', name: 'mindful_campus_export.pdf');
    await Share.shareXFiles([file], text: 'My Mindful Campus PDF Data');
  }

  Future<void> exportDataAsMP3() async {
    final tts = FlutterTts();
    final textToSpeak = 'Here is your Mindful Campus summary. You have logged ${moods.length} moods, ${sleepLogs.length} sleep sessions, and ${focusSessions.length} focus sessions. You have completed $habitsDoneToday habits today. Keep up the good work!';

    try {
      await tts.setLanguage("en-US");
      await tts.awaitSpeakCompletion(true);

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/mindful_campus_summary.mp3';

      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      var result = await tts.synthesizeToFile(textToSpeak, filePath, true);

      if (result == 1 && await file.exists() && await file.length() > 0) {
        final xFile = XFile(filePath, mimeType: 'audio/mpeg');
        await Share.shareXFiles([xFile], text: 'My Mindful Campus Audio Summary');
      } else {
        throw Exception('TTS synthesis failed or produced an empty file');
      }
    } catch (e) {
      debugPrint('MP3 Export Error: $e');
      final bytes = utf8.encode('Audio export is not supported on Web or your device lacks a TTS engine. Here is your script:\n\n$textToSpeak');
      final file = XFile.fromData(bytes, mimeType: 'text/plain', name: 'audio_script.txt');
      await Share.shareXFiles([file], text: 'Audio Export requires a mobile phone with Text-to-Speech installed.');
    }
  }

  Future<void> clearAllData() async {
    await _p.clear();
    isLoggedIn = false;
    moods.clear(); sleepLogs.clear(); journals.clear(); focusSessions.clear(); habits.clear();
    notifyListeners();
  }

  Future<void> login({required String email, required bool remember}) async {
    userEmail = email; userName = prettyNameFromEmail(email); isLoggedIn = true;
    await _p.setBool('isLoggedIn', true); await _p.setString('userName', userName); await _p.setString('userEmail', userEmail);
    if (remember) { await _p.setString('rememberedEmail', email); } else { await _p.remove('rememberedEmail'); }
    notifyListeners();
  }

  Future<void> register({required String fullName, required String email, required String phone, required String gender, String university = ''}) async {
    userEmail = email; userName = fullName; userPhone = phone; userGender = gender; userUniversity = university; isLoggedIn = true;
    await _p.setBool('isLoggedIn', true); await _p.setString('userName', userName); await _p.setString('userEmail', userEmail);
    await _p.setString('userPhone', phone); await _p.setString('userGender', gender); await _p.setString('userUniversity', university);
    notifyListeners();
  }

  Future<void> logout() async { isLoggedIn = false; await _p.setBool('isLoggedIn', false); notifyListeners(); }

  MoodEntry? get latestMood => moods.isEmpty ? null : moods.last;

  void saveMood(String moodKey, String note) {
    final opt = moodByKey(moodKey); if (opt == null) return;
    final today = todayKey();
    moods.removeWhere((m) => m.date == today);
    moods.add(MoodEntry(date: today, mood: moodKey, label: opt.label, note: note));
    if (moods.length > 90) moods = moods.sublist(moods.length - 90);
    _writeList('mindfulCampusMoods', moods.map((m) => m.toJson()).toList());
    notifyListeners();
  }

  int get moodStreak => _streak(moods.reversed.map((m) => m.date).toList());

  int _streak(List<String> datesNewestFirst) {
    if (datesNewestFirst.isEmpty) return 0;
    final now = DateTime.now(); final first = parseDateKey(datesNewestFirst.first);
    if (daysBetween(first, now) > 1) return 0;
    var count = 1;
    for (var i = 1; i < datesNewestFirst.length; i++) {
      final newer = parseDateKey(datesNewestFirst[i - 1]); final older = parseDateKey(datesNewestFirst[i]);
      if (daysBetween(older, newer) == 1) { count++; } else { break; }
    }
    return count;
  }

  void saveSleep({required String bedtime, required String waketime, required int quality, required String dreams, required String notes}) {
    final hours = sleepHours(bedtime, waketime); final today = todayKey();
    final log = SleepLog(date: today, bedtime: bedtime, waketime: waketime, hours: hours, quality: quality, dreams: dreams, notes: notes);
    final i = sleepLogs.indexWhere((l) => l.date == today);
    if (i >= 0) { sleepLogs[i] = log; } else { sleepLogs.insert(0, log); }
    if (sleepLogs.length > 90) sleepLogs = sleepLogs.sublist(0, 90);
    _writeList('sleepLogs', sleepLogs.map((l) => l.toJson()).toList());
    notifyListeners();
  }

  SleepLog? get lastSleep => sleepLogs.isEmpty ? null : sleepLogs.first;
  SleepLog? sleepOn(String date) { for (final l in sleepLogs) { if (l.date == date) return l; } return null; }
  int get sleepStreak => _streak(sleepLogs.map((l) => l.date).toList());

  void saveJournal(String title, String content, String? tag) {
    final today = todayKey(); final t = tag ?? 'reflection';
    journals.insert(0, JournalEntry(date: today, title: title, content: content, tag: t));
    if (journals.length > 100) journals = journals.sublist(0, 100);
    _writeList('journalEntries', journals.map((j) => j.toJson()).toList());
    notifyListeners();
  }

  int deleteJournal(JournalEntry e) {
    final i = journals.indexOf(e); if (i < 0) return -1;
    journals.removeAt(i); _writeList('journalEntries', journals.map((j) => j.toJson()).toList());
    notifyListeners(); return i;
  }

  void restoreJournal(int index, JournalEntry e) {
    final at = index > journals.length ? journals.length : index;
    journals.insert(at, e); _writeList('journalEntries', journals.map((j) => j.toJson()).toList());
    notifyListeners();
  }

  void recordBreathSession({required String technique, required int rounds, required int seconds}) {
    final today = todayKey(); breathCount++; breathTotalSeconds += seconds;
    if (lastBreathDate != today) {
      final y = dateKey(DateTime.now().subtract(const Duration(days: 1)));
      breathStreak = lastBreathDate == y ? breathStreak + 1 : 1;
      lastBreathDate = today;
    }
    _p.setInt('breathCount', breathCount); _p.setInt('breathTotalSeconds', breathTotalSeconds);
    _p.setInt('breathStreak', breathStreak); _p.setString('lastBreathDate', lastBreathDate);
    notifyListeners();
  }

  int get breathMinutes => (breathTotalSeconds / 60).round();

  Habit addHabit({required String emoji, required String name, required String description}) {
    final h = Habit(id: 'habit_${DateTime.now().millisecondsSinceEpoch}', emoji: emoji.isEmpty ? '🌱' : emoji, name: name, description: description, createdAt: DateTime.now().toIso8601String());
    habits.add(h); _writeList('habits', habits.map((e) => e.toJson()).toList()); notifyListeners(); return h;
  }

  void updateHabit(Habit old, Habit updated) {
    final i = habits.indexOf(old); if (i < 0) return;
    habits[i] = updated; _writeList('habits', habits.map((e) => e.toJson()).toList()); notifyListeners();
  }

  void deleteHabit(Habit h) { habits.removeWhere((e) => e.id == h.id); _writeList('habits', habits.map((e) => e.toJson()).toList()); notifyListeners(); }
  void toggleHabitToday(Habit h) { final i = habits.indexWhere((e) => e.id == h.id); if (i < 0) return; habits[i] = h.toggleForDate(todayKey()); _writeList('habits', habits.map((e) => e.toJson()).toList()); notifyListeners(); }

  int get habitsDoneToday { if (habits.isEmpty) return 0; final today = todayKey(); return habits.where((h) => h.isDoneOn(today)).length; }

  FocusSession recordFocusSession({required int plannedMinutes, required int actualMinutes, required bool completed}) {
    final s = FocusSession(id: 'focus_${DateTime.now().millisecondsSinceEpoch}', date: todayKey(), plannedMinutes: plannedMinutes, actualMinutes: actualMinutes, completed: completed, startedAt: DateTime.now().toIso8601String());
    focusSessions.add(s); if (focusSessions.length > 365) focusSessions = focusSessions.sublist(focusSessions.length - 365);
    _writeList('focusSessions', focusSessions.map((e) => e.toJson()).toList()); notifyListeners(); return s;
  }

  int get totalFocusMinutes => focusSessions.fold<int>(0, (a, s) => a + s.actualMinutes);
  int focusMinutesOn(String dateKey) => focusSessions.where((s) => s.date == dateKey).fold<int>(0, (a, s) => a + s.actualMinutes);
  int get completedFocusSessions => focusSessions.where((s) => s.completed).length;

  int get focusStreak {
    final days = <String>{}; for (final s in focusSessions) { if (s.actualMinutes > 0) days.add(s.date); }
    return _streak(days.toList()..sort((a, b) => b.compareTo(a)));
  }

  void saveSafetyPlan(Map<String, String> plan) { safetyPlan = plan; _p.setString('safetyPlan', jsonEncode(plan)); notifyListeners(); }
}