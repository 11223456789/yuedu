import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tts_read_aloud.dart';

final readAloudServiceProvider = Provider<ReadAloudService>((ref) {
  return ReadAloudService();
});

enum ReadAloudState {
  idle,
  playing,
  paused,
  error,
}

class ReadAloudService {
  final TtsReadAloud _tts = TtsReadAloud();
  ReadAloudState _state = ReadAloudState.idle;
  String _currentText = '';
  int _currentPosition = 0;
  final List<String> _paragraphs = [];
  int _currentParagraphIndex = 0;

  // 状态监听
  final _stateController = StreamController<ReadAloudState>.broadcast();
  final _progressController = StreamController<int>.broadcast();

  Stream<ReadAloudState> get stateStream => _stateController.stream;
  Stream<int> get progressStream => _progressController.stream;

  ReadAloudState get state => _state;
  String get currentText => _currentText;
  int get currentPosition => _currentPosition;
  bool get isPlaying => _state == ReadAloudState.playing;
  bool get isPaused => _state == ReadAloudState.paused;

  /// 初始化
  Future<void> init() async {
    await _tts.init();
  }

  /// 开始朗读
  Future<void> start(String text) async {
    if (text.isEmpty) return;

    _currentText = text;
    _paragraphs.clear();
    _paragraphs.addAll(_splitIntoParagraphs(text));
    _currentParagraphIndex = 0;
    _currentPosition = 0;

    await _speakCurrentParagraph();
  }

  /// 暂停朗读
  Future<void> pause() async {
    await _tts.pause();
    _state = ReadAloudState.paused;
    _stateController.add(_state);
  }

  /// 继续朗读
  Future<void> resume() async {
    if (_paragraphs.isEmpty) return;
    await _speakCurrentParagraph();
  }

  /// 停止朗读
  Future<void> stop() async {
    await _tts.stop();
    _state = ReadAloudState.idle;
    _currentParagraphIndex = 0;
    _currentPosition = 0;
    _stateController.add(_state);
    _progressController.add(0);
  }

  /// 下一段
  Future<void> next() async {
    if (_currentParagraphIndex < _paragraphs.length - 1) {
      _currentParagraphIndex++;
      await _speakCurrentParagraph();
    }
  }

  /// 上一段
  Future<void> previous() async {
    if (_currentParagraphIndex > 0) {
      _currentParagraphIndex--;
      await _speakCurrentParagraph();
    }
  }

  /// 朗读当前段落
  Future<void> _speakCurrentParagraph() async {
    if (_currentParagraphIndex >= _paragraphs.length) {
      await stop();
      return;
    }

    final paragraph = _paragraphs[_currentParagraphIndex];
    _currentPosition = _getParagraphStartPosition(_currentParagraphIndex);

    _state = ReadAloudState.playing;
    _stateController.add(_state);
    _progressController.add(_currentPosition);

    await _tts.speak(paragraph);

    // 监听朗读完成，自动播放下一段
    _tts.state == TtsState.stopped;
    if (_state == ReadAloudState.playing) {
      await next();
    }
  }

  /// 将文本分割成段落
  List<String> _splitIntoParagraphs(String text) {
    // 按换行符和句号分割
    final paragraphs = text
        .split(RegExp(r'[\n。！？]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // 如果段落太长，进一步分割
    final result = <String>[];
    for (final paragraph in paragraphs) {
      if (paragraph.length > 100) {
        // 按逗号分割长段落
        final sentences = paragraph.split('，');
        final buffer = StringBuffer();
        for (final sentence in sentences) {
          if (buffer.length + sentence.length > 80) {
            if (buffer.isNotEmpty) {
              result.add(buffer.toString());
              buffer.clear();
            }
          }
          buffer.write(sentence);
          buffer.write('，');
        }
        if (buffer.isNotEmpty) {
          result.add(buffer.toString().replaceAll(RegExp(r'，$'), ''));
        }
      } else {
        result.add(paragraph);
      }
    }

    return result;
  }

  /// 获取段落起始位置
  int _getParagraphStartPosition(int paragraphIndex) {
    int position = 0;
    for (int i = 0; i < paragraphIndex && i < _paragraphs.length; i++) {
      position += _paragraphs[i].length + 1; // +1 for separator
    }
    return position;
  }

  /// 设置语速
  Future<void> setSpeechRate(double rate) async {
    await _tts.setSpeechRate(rate);
  }

  /// 设置音调
  Future<void> setSpeechPitch(double pitch) async {
    await _tts.setSpeechPitch(pitch);
  }

  /// 设置音量
  Future<void> setSpeechVolume(double volume) async {
    await _tts.setSpeechVolume(volume);
  }

  /// 获取语速
  double get speechRate => _tts.speechRate;

  /// 获取音调
  double get speechPitch => _tts.speechPitch;

  /// 获取音量
  double get speechVolume => _tts.speechVolume;

  /// 获取可用语言
  Future<List<String>> getLanguages() async {
    return await _tts.getLanguages();
  }

  /// 设置语言
  Future<void> setLanguage(String language) async {
    await _tts.setLanguage(language);
  }

  /// 释放资源
  void dispose() {
    _tts.dispose();
    _stateController.close();
    _progressController.close();
  }
}
