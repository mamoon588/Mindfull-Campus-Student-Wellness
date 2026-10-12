# Mindful Campus (Flutter)

Flutter port of the Mindful Campus web app (landing page, login/register, and the
7-section wellness dashboard). Targets Android and iOS.

## Run it

```bash
cd project
flutter create --org com.mindfulcampus --platforms android,ios .   # generates android/ and ios/ (keeps lib/ and pubspec.yaml)
flutter pub get
flutter run
```

### One-time platform tweaks

**Android** – `android/app/src/main/AndroidManifest.xml`, inside `<manifest>` (above `<application>`):

```xml
<queries>
  <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="tel"/></intent>
  <intent><action android:name="android.intent.action.TTS_SERVICE"/></intent>
</queries>
```

(The `tel` query lets the Crisis
screen open the dialer; the TTS query is for the voice guide on Android 11+.)

**iOS** – `ios/Runner/Info.plist`:

```xml
<key>LSApplicationQueriesSchemes</key>
<array><string>tel</string></array>
```

## What maps to what

| Web app | Flutter |
|---|---|
| `landingpage.html/js/css` | `lib/screens/landing_screen.dart`, `auth_sheet.dart` |
| `dashboard.html` sidebar sections | `home_shell.dart` (bottom nav + drawer) and one page per section |
| Overview / Mood / Breathing / Sleep / Journal | `overview_page`, `mood_page`, `breathing_page`, `sleep_page`, `journal_page` |
| Resources (meditation, PHQ-9, GAD-7, grounding, CBT, sleep hygiene, safety plan) | `resources_page`, `meditation_card`, `screening_sheet` |
| Crisis Support | `crisis_page` (tap to call) |
| `localStorage` | `shared_preferences` via `services/app_state.dart` |
| `speechSynthesis` | `flutter_tts` via `services/voice_service.dart` |

## Notes

- Login/registration is local only, exactly like the web app: any valid-looking email and
  password is accepted. For real accounts, add Firebase Auth.
- Frontend only: all data stays on the device (no Firebase, no server).
- Tests: `flutter test` (sleep-hours math, date helpers).
