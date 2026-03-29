import 'dart:async';
import 'package:just_audio/just_audio.dart';

enum AudioPlayState {
  idle,
  loading,
  playing,
  paused,
  stopped,
  error,
}

class AudioTrack {
  final String url;
  final String title;
  final String? artist;
  final String? album;
  final String? coverUrl;
  final Duration? duration;

  AudioTrack({
    required this.url,
    required this.title,
    this.artist,
    this.album,
    this.coverUrl,
    this.duration,
  });
}

class AudioPlayService {
  static final AudioPlayService _instance = AudioPlayService._internal();
  factory AudioPlayService() => _instance;
  AudioPlayService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);

  AudioPlayState _state = AudioPlayState.idle;
  List<AudioTrack> _tracks = [];
  int _currentIndex = 0;
  Timer? _sleepTimer;
  bool _isInitialized = false;

  AudioPlayState get state => _state;
  List<AudioTrack> get tracks => List.unmodifiable(_tracks);
  int get currentIndex => _currentIndex;
  AudioTrack? get currentTrack => _tracks.isNotEmpty ? _tracks[_currentIndex] : null;
  bool get isPlaying => _state == AudioPlayState.playing;
  bool get hasSleepTimer => _sleepTimer != null;

  Future<void> init() async {
    if (_isInitialized) return;

    await _audioPlayer.setAudioSource(_playlist);

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _state = AudioPlayState.idle;
      }
    });

    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && index != _currentIndex) {
        _currentIndex = index;
      }
    });

    _isInitialized = true;
  }

  Future<void> setPlaylist(List<AudioTrack> tracks, {int initialIndex = 0}) async {
    _tracks = tracks;
    _currentIndex = initialIndex.clamp(0, tracks.length - 1);

    _playlist.clear();
    for (final track in tracks) {
      _playlist.add(AudioSource.uri(
        Uri.parse(track.url),
        tag: track,
      ));
    }

    if (tracks.isNotEmpty) {
      await _audioPlayer.seek(Duration.zero, index: _currentIndex);
    }
  }

  Future<void> addTrack(AudioTrack track) async {
    _tracks.add(track);
    _playlist.add(AudioSource.uri(
      Uri.parse(track.url),
      tag: track,
    ));
  }

  Future<void> removeTrack(int index) async {
    if (index < 0 || index >= _tracks.length) return;

    _tracks.removeAt(index);
    await _playlist.removeAt(index);

    if (_currentIndex >= _tracks.length) {
      _currentIndex = _tracks.length - 1;
    }
  }

  Future<void> play() async {
    if (_tracks.isEmpty) return;

    _state = AudioPlayState.playing;
    await _audioPlayer.play();
  }

  Future<void> pause() async {
    _state = AudioPlayState.paused;
    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    _state = AudioPlayState.stopped;
    await _audioPlayer.stop();
    _cancelSleepTimer();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> seekToTrack(int index) async {
    if (index < 0 || index >= _tracks.length) return;

    _currentIndex = index;
    await _audioPlayer.seek(Duration.zero, index: index);
  }

  Future<void> playNext() async {
    if (_currentIndex < _tracks.length - 1) {
      await _audioPlayer.seekToNext();
    }
  }

  Future<void> playPrevious() async {
    if (_currentIndex > 0) {
      await _audioPlayer.seekToPrevious();
    }
  }

  Future<void> setSpeed(double speed) async {
    await _audioPlayer.setSpeed(speed.clamp(0.5, 2.0));
  }

  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<double> getSpeed() async {
    return _audioPlayer.speed;
  }

  Future<double> getVolume() async {
    return _audioPlayer.volume;
  }

  Future<Duration?> getDuration() async {
    return _audioPlayer.duration;
  }

  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  Stream<int?> get currentIndexStream => _audioPlayer.currentIndexStream;

  void setSleepTimer(Duration duration) {
    _cancelSleepTimer();

    if (duration.inSeconds > 0) {
      _sleepTimer = Timer(duration, () {
        stop();
      });
    }
  }

  void _cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
  }

  Future<void> dispose() async {
    _cancelSleepTimer();
    await _audioPlayer.dispose();
  }
}
