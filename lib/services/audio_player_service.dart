import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../utils/logger.dart';
import 'audio_handler.dart';

// 全局 AudioHandler 实例，由 main.dart 初始化
late MyAudioHandler _globalAudioHandler;

void setGlobalAudioHandler(MyAudioHandler handler) {
  _globalAudioHandler = handler;
}

enum PlaybackMode {
  sequential,
  shuffle,
  repeatOne,
  repeatAll,
}

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  MyAudioHandler get _handler => _globalAudioHandler;
  AudioPlayer get _player => _globalAudioHandler.player;
  
  // 状态流 - 直接使用 handler 的流
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<int?> get currentIndexStream => _handler.currentIndexStream;

  // 当前状态
  PlayerState get playerState => _player.playerState;
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  bool get hasNext {
    final songs = _handler.songs;
    final index = _handler.currentIndex;
    return index < songs.length - 1;
  }
  bool get hasPrevious => _handler.currentIndex > 0;

  // 播放列表
  List<Song> get songs => _handler.songs;
  int get currentIndex => _handler.currentIndex;
  Song? get currentSong => _handler.currentSong;

  // 监听回调
  void Function(Song? song)? onSongChanged;
  void Function(PlaybackMode mode)? onModeChanged;
  void Function(String message)? onError;

  Future<void> init() async {
    logInfo('AudioService', 'init started');
    
    // 监听播放状态变化
    _player.playerStateStream.listen((state) {
      logInfo('AudioService', 'State: ${state.processingState}, playing: ${state.playing}');
      if (state.processingState == ProcessingState.completed) {
        onSongChanged?.call(currentSong);
      }
    }, onError: (e) {
      logInfo('AudioService', 'Player state error: $e');
    });
    
    // 监听歌曲变化
    _handler.currentIndexStream.listen((index) {
      if (index != null) {
        onSongChanged?.call(currentSong);
      }
    });
    
    logInfo('AudioService', 'init completed');
  }

  /// 设置播放列表并播放
  Future<void> setPlaylist(List<Song> songs, {int initialIndex = 0}) async {
    logInfo('AudioService', 'setPlaylist called: ${songs.length} songs, index: $initialIndex');
    await _handler.setPlaylist(songs, initialIndex: initialIndex);
  }

  /// 播放指定歌曲
  Future<void> playSong(Song song) async {
    logInfo('AudioService', 'playSong: ${song.title}');
    final index = songs.indexWhere((s) => s.id == song.id || s.uri == song.uri);
    if (index >= 0) {
      await playAtIndex(index);
    } else {
      // 不在列表中，添加到列表末尾
      final newSongs = List<Song>.from(songs)..add(song);
      await setPlaylist(newSongs, initialIndex: newSongs.length - 1);
    }
  }

  Future<void> play() async {
    logInfo('AudioService', 'play() called');
    await _handler.play();
  }

  Future<void> pause() async {
    logInfo('AudioService', 'pause() called');
    await _handler.pause();
  }

  Future<void> playAtIndex(int index) async {
    logInfo('AudioService', 'playAtIndex: $index');
    // 通过设置播放列表到指定索引
    if (index >= 0 && index < songs.length) {
      await setPlaylist(songs, initialIndex: index);
    }
  }

  Future<void> next() async {
    logInfo('AudioService', 'next() called');
    await _handler.skipToNext();
  }

  Future<void> previous() async {
    logInfo('AudioService', 'previous() called');
    await _handler.skipToPrevious();
  }

  Future<void> seek(Duration position) async {
    logInfo('AudioService', 'seek: $position');
    await _handler.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  void setPlaybackMode(PlaybackMode mode) {
    logInfo('AudioService', 'setPlaybackMode: $mode');
    switch (mode) {
      case PlaybackMode.sequential:
        _handler.setRepeatMode(AudioServiceRepeatMode.none);
        _handler.setShuffleMode(AudioServiceShuffleMode.none);
        break;
      case PlaybackMode.shuffle:
        _handler.setRepeatMode(AudioServiceRepeatMode.none);
        _handler.setShuffleMode(AudioServiceShuffleMode.all);
        break;
      case PlaybackMode.repeatOne:
        _handler.setRepeatMode(AudioServiceRepeatMode.one);
        _handler.setShuffleMode(AudioServiceShuffleMode.none);
        break;
      case PlaybackMode.repeatAll:
        _handler.setRepeatMode(AudioServiceRepeatMode.all);
        _handler.setShuffleMode(AudioServiceShuffleMode.none);
        break;
    }
    onModeChanged?.call(mode);
  }

  void cyclePlaybackMode() {
    final modes = PlaybackMode.values;
    // 获取当前模式
    final currentMode = _getCurrentPlaybackMode();
    final nextIndex = (modes.indexOf(currentMode) + 1) % modes.length;
    setPlaybackMode(modes[nextIndex]);
  }

  PlaybackMode _getCurrentPlaybackMode() {
    final repeatMode = _handler.playbackState.value.repeatMode;
    final shuffleMode = _handler.playbackState.value.shuffleMode;
    
    if (shuffleMode == AudioServiceShuffleMode.all) {
      return PlaybackMode.shuffle;
    }
    switch (repeatMode) {
      case AudioServiceRepeatMode.one:
        return PlaybackMode.repeatOne;
      case AudioServiceRepeatMode.all:
        return PlaybackMode.repeatAll;
      default:
        return PlaybackMode.sequential;
    }
  }

  PlaybackMode get playbackMode => _getCurrentPlaybackMode();

  Future<void> clearTranscodeCache() async {}
  Future<String> getCacheSize() async => '0 B';

  Future<void> dispose() async {
    logInfo('AudioService', 'dispose() called');
    await _player.dispose();
  }
}
