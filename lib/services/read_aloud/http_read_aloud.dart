import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';

enum HttpTtsState {
  idle,
  loading,
  playing,
  paused,
  stopped,
  error,
}

enum HttpTtsPreset {
  custom,
  cloneTts,
}

class HttpTtsConfig {
  final String url;
  final String? voiceId;
  final double? speechRate;
  final double? pitch;
  final Map&lt;String, String&gt;? headers;
  final String? method;
  final String? bodyTemplate;
  final HttpTtsPreset preset;

  HttpTtsConfig({
    required this.url,
    this.voiceId,
    this.speechRate,
    this.pitch,
    this.headers,
    this.method = 'GET',
    this.bodyTemplate,
    this.preset = HttpTtsPreset.custom,
  });

  static HttpTtsConfig cloneTts({
    String voice = '',
    double speechRate = 1.0,
  }) {
    return HttpTtsConfig(
      url: 'http://127.0.0.1:8080/api/tts?text={text}&amp;voice={voice}',
      voiceId: voice,
      speechRate: speechRate,
      method: 'GET',
      preset: HttpTtsPreset.cloneTts,
    );
  }
}

class HttpReadAloud {
  static final HttpReadAloud _instance = HttpReadAloud._internal();
  factory HttpReadAloud() => _instance;
  HttpReadAloud._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final Dio _dio = Dio();
  HttpTtsState _state = HttpTtsState.idle;
  HttpTtsConfig? _config;
  String? _currentText;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  HttpTtsState get state => _state;
  HttpTtsConfig? get config => _config;
  String? get currentText => _currentText;

  Future<void> init() async {
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _state = HttpTtsState.idle;
      }
    });
  }

  void setConfig(HttpTtsConfig config) {
    _config = config;
  }

  Future<void> speak(String text) async {
    if (_config == null) {
      throw StateError('HTTP TTS config not set');
    }

    _currentText = text;
    _state = HttpTtsState.loading;

    try {
      final audioUrl = await _synthesizeAudio(text);
      await _audioPlayer.setUrl(audioUrl);
      await _audioPlayer.play();
      _state = HttpTtsState.playing;
    } catch (e) {
      _state = HttpTtsState.error;
      rethrow;
    }
  }

  Future<String> _synthesizeAudio(String text) async {
    final config = _config!;

    String requestUrl = config.url;
    requestUrl = requestUrl.replaceAll('{text}', Uri.encodeComponent(text));

    if (config.voiceId != null) {
      requestUrl = requestUrl.replaceAll('{voice}', config.voiceId!);
    }

    if (config.speechRate != null) {
      requestUrl = requestUrl.replaceAll('{rate}', config.speechRate.toString());
    }

    if (config.pitch != null) {
      requestUrl = requestUrl.replaceAll('{pitch}', config.pitch.toString());
    }

    final options = Options(
      method: config.method,
      headers: config.headers,
      responseType: ResponseType.bytes,
    );

    final response = await _dio.request<List<int>>(
      requestUrl,
      data: config.bodyTemplate?.replaceAll('{text}', text),
      options: options,
    );

    final tempDir = await Directory.systemTemp.createTemp();
    final audioFile = File('${tempDir.path}/tts_audio.mp3');
    await audioFile.writeAsBytes(response.data!);

    return audioFile.uri.toString();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _state = HttpTtsState.stopped;
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
    _state = HttpTtsState.paused;
  }

  Future<void> resume() async {
    await _audioPlayer.play();
    _state = HttpTtsState.playing;
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<Duration?> getDuration() async {
    return await _audioPlayer.duration;
  }

  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  Future<void> dispose() async {
    await _playerStateSubscription?.cancel();
    await _audioPlayer.dispose();
  }
}
