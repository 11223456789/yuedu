import 'package:flutter_tts/flutter_tts.dart';

enum TtsState {
  playing,
  stopped,
  paused,
  continued,
}

class TtsReadAloud {
  static final TtsReadAloud _instance = TtsReadAloud._internal();
  factory TtsReadAloud() => _instance;
  TtsReadAloud._internal();

  final FlutterTts _flutterTts = FlutterTts();
  TtsState _ttsState = TtsState.stopped;
  double _speechRate = 0.5;
  double _speechPitch = 1.0;
  double _speechVolume = 1.0;
  String? _currentLanguage = 'zh-CN';

  TtsState get state => _ttsState;
  double get speechRate => _speechRate;
  double get speechPitch => _speechPitch;
  double get speechVolume => _speechVolume;
  String? get currentLanguage => _currentLanguage;

  Future<void> init() async {
    await _flutterTts.setStartHandler(() {
      _ttsState = TtsState.playing;
    });

    await _flutterTts.setCompletionHandler(() {
      _ttsState = TtsState.stopped;
    });

    await _flutterTts.setCancelHandler(() {
      _ttsState = TtsState.stopped;
    });

    await _flutterTts.setPauseHandler(() {
      _ttsState = TtsState.paused;
    });

    await _flutterTts.setContinueHandler(() {
      _ttsState = TtsState.continued;
    });

    await _flutterTts.setErrorHandler((msg) {
      _ttsState = TtsState.stopped;
    });

    await _setDefaults();
  }

  Future<void> _setDefaults() async {
    await _flutterTts.setLanguage(_currentLanguage!);
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setPitch(_speechPitch);
    await _flutterTts.setVolume(_speechVolume);
  }

  Future<List<String>> getLanguages() async {
    final languages = await _flutterTts.getLanguages;
    return List<String>.from(languages ?? []);
  }

  Future<void> setLanguage(String language) async {
    _currentLanguage = language;
    await _flutterTts.setLanguage(language);
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.1, 3.0);
    await _flutterTts.setSpeechRate(_speechRate);
  }

  Future<void> setSpeechPitch(double pitch) async {
    _speechPitch = pitch.clamp(0.5, 2.0);
    await _flutterTts.setPitch(_speechPitch);
  }

  Future<void> setSpeechVolume(double volume) async {
    _speechVolume = volume.clamp(0.0, 1.0);
    await _flutterTts.setVolume(_speechVolume);
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  Future<void> pause() async {
    await _flutterTts.pause();
  }

  Future<bool> isLanguageAvailable(String language) async {
    final available = await _flutterTts.isLanguageAvailable(language);
    return available ?? false;
  }

  Future<dynamic> getVoices() async {
    return await _flutterTts.getVoices;
  }

  Future<void> setVoice(Map<String, String> voice) async {
    await _flutterTts.setVoice(voice);
  }

  Future<void> dispose() async {
    await _flutterTts.stop();
  }
}
