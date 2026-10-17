import 'package:flutter/material.dart';

const _weekdaysLong = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
];
const _weekdaysShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
  'September', 'October', 'November', 'December'
];

/// yyyy-MM-dd in the device's local time zone.
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String todayKey() => dateKey(DateTime.now());

DateTime parseDateKey(String k) {
  final p = k.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

/// Whole calendar days from [a] to [b] (positive when b is later).
int daysBetween(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day)
        .difference(DateTime.utc(a.year, a.month, a.day))
        .inDays;

String longDate(DateTime d) =>
    '${_weekdaysLong[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}, ${d.year}';

String shortWeekday(DateTime d) => _weekdaysShort[d.weekday - 1];

String greetingFor(int hour) =>
    hour < 12 ? 'Good Morning' : (hour < 17 ? 'Good Afternoon' : 'Good Evening');

/// "john_doe99@uni.edu" -> "John Doe".
String prettyNameFromEmail(String email) {
  final local = email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z]'), ' ');
  final words = local.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  final name = words
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
  return name.isEmpty ? 'Student' : name;
}

int _toMinutes(String hhmm) {
  final p = hhmm.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

/// Hours slept between a bedtime and a wake time ("HH:mm"), crossing midnight
/// when needed, rounded to one decimal.
double sleepHours(String bedtime, String waketime) {
  final b = _toMinutes(bedtime);
  var w = _toMinutes(waketime);
  if (w <= b) w += 24 * 60;
  return ((w - b) / 60 * 10).round() / 10;
}

/// Minutes-after-noon style value so 23:30 and 00:30 average sensibly.
int bedtimeMinutesNormalized(String bedtime) {
  final m = _toMinutes(bedtime);
  return m < 12 * 60 ? m + 24 * 60 : m;
}

String clock12(int minutesOfDay) {
  final m = minutesOfDay % (24 * 60);
  final h24 = m ~/ 60;
  final mm = (m % 60).toString().padLeft(2, '0');
  final suffix = h24 >= 12 ? 'PM' : 'AM';
  final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
  return '$h12:$mm $suffix';
}

String hhmm(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String formatHours(double h) =>
    h == h.roundToDouble() ? h.toStringAsFixed(0) : h.toStringAsFixed(1);

/// Rules for a new password: 8+ characters with at least one letter and one number.
/// Strong password: 8+ chars with upper, lower, digit and a special character.
class PasswordRules {
  static bool hasLength(String p) => p.length >= 8;
  static bool hasUpper(String p) => RegExp(r'[A-Z]').hasMatch(p);
  static bool hasLower(String p) => RegExp(r'[a-z]').hasMatch(p);
  static bool hasLetter(String p) => hasUpper(p) || hasLower(p); // kept for older code
  static bool hasNumber(String p) => RegExp(r'\d').hasMatch(p);
  static bool hasSpecial(String p) => RegExp(r'[^A-Za-z0-9\s]').hasMatch(p);
  static bool ok(String p) =>
      hasLength(p) && hasUpper(p) && hasLower(p) && hasNumber(p) && hasSpecial(p);
}
bool looksLikeEmail(String e) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);

/// Pakistani mobile number: 11 digits starting with 03 (spaces and dashes ignored).
bool looksLikePkMobile(String p) =>
    RegExp(r'^03\d{9}$').hasMatch(p.replaceAll(RegExp(r'[\s-]'), ''));

/// A name: at least 2 characters, letters plus spaces, dots, apostrophes and hyphens.
bool looksLikeName(String n) =>
    n.trim().length >= 2 && RegExp(r"^[A-Za-z][A-Za-z\s.'-]*$").hasMatch(n.trim());