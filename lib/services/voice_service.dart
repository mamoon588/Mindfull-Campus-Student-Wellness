import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  VoiceService._();
  static final VoiceService instance = VoiceService._();

  FlutterTts? _tts;
  bool _ready = false;
  bool enabled = true;

  bool get available => _ready;

  Future<void> init() async {
    try {
      final tts = FlutterTts();

      // 1. FORCE a higher pitch. Even if the phone only has a male voice,
      // a pitch of 1.4 will make it sound much more feminine.
      await tts.setPitch(1.4);
      await tts.setSpeechRate(0.45);
      await tts.setVolume(0.9);

      // 2. Set Language
      await tts.setLanguage("en-US");

      // 3. Try to find a female voice from the system
      final voices = await tts.getVoices;
      bool foundFemale = false;

      if (voices != null) {
        final femaleKeywords = [
          'female', 'samantha', 'zira', 'karen', 'tessa', 'victoria',
          'moira', 'fiona', 'ava', 'susan', 'zoe', 'allison', 'catherine',
          'serena', 'veena', 'sfg', 'en-us-x-sfg', 'google us english',
          'aria', 'jenny', 'michelle', 'emma'
        ];

        for (var v in voices) {
          final name = v['name'].toString().toLowerCase();
          final locale = v['locale'].toString().toLowerCase().replaceAll('_', '-');

          if (locale.startsWith('en')) {
            for (var keyword in femaleKeywords) {
              if (name.contains(keyword)) {
                await tts.setVoice({
                  "name": v['name'].toString(),
                  "locale": v['locale'].toString()
                });
                foundFemale = true;
                debugPrint('✅ Found female voice: ${v['name']}');
                break;
              }
            }
          }
          if (foundFemale) break;
        }
      }

      _tts = tts;
      _ready = true;

      if (!foundFemale) {
        debugPrint('⚠️ No female voice found. Using high-pitch fallback (1.4).');
      }

    } catch (e) {
      debugPrint('TTS unavailable: $e');
      _ready = false;
    }
  }

  Future<void> say(String text) async {
    if (!enabled || !_ready) return;
    try {
      await _tts!.speak(text);
    } catch (_) {}
  }

  Future<void> stop() async {
    if (!_ready) return;
    try {
      await _tts!.stop();
    } catch (_) {}
  }
}