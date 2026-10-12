import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-speech used for the breathing and meditation voice guides
/// (replaces the web app's speechSynthesis).
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
      await tts.setLanguage('en-US');
      await tts.setSpeechRate(0.45);
      await tts.setVolume(0.8);
      _tts = tts;
      _ready = true;
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
