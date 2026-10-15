# Mindful Campus

A student mental wellness companion built with Flutter. It is a mobile port of the Mindful Campus web app, with a landing page, local sign-up and login, and a 7-section wellness dashboard. All data stays on the device.

## Features

- **Landing and authentication:** a slide-based intro with login and register in a bottom sheet. Email and password rules are checked on the form (valid email, 8+ characters with a letter and a number).
- **Overview:** a daily greeting, streaks, quick stats, quick actions and a weekly mood chart.
- **Mood tracker:** a five-level daily check-in with an optional note and a mood streak.
- **Breathing:** guided breathing techniques with an animated circle, voice guidance and haptic feedback. Sessions, minutes and streaks are tracked.
- **Sleep tracker:** bedtime and wake time with automatic hours calculation (including past midnight), quality and dream notes, a weekly chart and personalised sleep tips.
- **Journal:** entries with mood tags, plus undo after deleting.
- **Resources:** guided meditation, PHQ-9 and GAD-7 self-screenings, a grounding exercise, a CBT thought challenge, sleep hygiene tips and a personal safety plan.
- **Crisis support:** tap-to-call helplines (Pakistan) from a dedicated screen and from the top bar.

## Tech stack

| Area | Package |
|---|---|
| UI | Flutter (Material 3) |
| State management | `provider` |
| Local storage | `shared_preferences` |
| Voice guide | `flutter_tts` |
| Phone dialer | `url_launcher` |
| Linting | `flutter_lints` |

## Getting started

### Requirements

- Flutter 3.24 or newer (Dart 3.5 or newer)
- Android Studio or VS Code with the Flutter plugin
- An Android or iOS device or emulator, or Chrome for web

### Run the app

```bash
git clone <repo-url>
cd <project-folder>      # the folder that contains pubspec.yaml
flutter pub get
flutter run              # or: flutter run -d chrome
```

If the `android/`, `ios/` or `web/` folders are missing, generate them once:

```bash
flutter create --org com.mindfulcampus --platforms android,ios,web .
```

### One-time platform setup

**Android:** in `android/app/src/main/AndroidManifest.xml`, inside `<manifest>` and above `<application>`:

```xml
<queries>
  <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="tel"/></intent>
  <intent><action android:name="android.intent.action.TTS_SERVICE"/></intent>
</queries>
```

The `tel` query lets the Crisis screen open the dialer. The TTS query enables the voice guide on Android 11 and newer.

**iOS:** in `ios/Runner/Info.plist`:

```xml
<key>LSApplicationQueriesSchemes</key>
<array><string>tel</string></array>
```

> On web, the call buttons cannot open a dialer and haptics do nothing. Test those on a phone or emulator.

## Project structure

```
lib/
├── main.dart                  App entry point, provider setup, logged-in/out routing
├── models.dart                Mood, sleep and journal models
├── theme.dart                 Colors and Material 3 theme
├── utils.dart                 Date, sleep-hours and validation helpers
├── screens/
│   ├── landing_screen.dart    Intro slides
│   ├── auth_sheet.dart        Login and register sheet
│   ├── home_shell.dart        Bottom navigation and drawer
│   ├── overview_page.dart
│   ├── mood_page.dart
│   ├── breathing_page.dart
│   ├── sleep_page.dart
│   ├── journal_page.dart
│   ├── resources_page.dart
│   ├── meditation_card.dart
│   ├── screening_sheet.dart   PHQ-9 and GAD-7
│   └── crisis_page.dart
├── services/
│   ├── app_state.dart         App state, persisted with shared_preferences
│   └── voice_service.dart     Text-to-speech wrapper
└── widgets/
    ├── common.dart            Shared UI (cards, headers, toasts)
    └── call.dart              Opens the phone dialer
test/
└── logic_test.dart            Unit tests for helpers
```

## How it works

`AppState` (a `ChangeNotifier`) is the single source of truth. It loads saved data at startup and writes changes back to `shared_preferences`, so moods, sleep logs, journal entries, breathing stats and the safety plan survive app restarts. Screens read it through `provider`.

## Testing

```bash
flutter test
```

Current tests cover sleep-hours maths, date helpers, name formatting and password rules.

## Current limitations

- Login and registration are local only: any valid-looking email and password is accepted and nothing is verified.
- Data is stored on the device only, with no cloud sync or backup.
- Crisis contacts are hardcoded for Pakistan and should be verified before any public release.

## Planned improvements

- Real authentication (for example Firebase Auth)
- Per-user data so accounts on one device do not share entries
- Cloud sync and data export
- Reminders and notifications
- Widget and UI tests

## Disclaimer

Mindful Campus is a self-care companion, not a medical tool or a substitute for professional care. If you or someone you know is in danger, contact local emergency services immediately.

## Contributing

1. Create a branch: `git checkout -b feature/your-change`
2. Commit your changes with a clear message
3. Push the branch and open a pull request