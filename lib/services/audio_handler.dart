import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../utils/logger.dart';

/// 自定义 AudioHandler 用于后台播放和媒体控制
class MyAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  
  // 播放列表
  List<Song> _songs = [];
  int _currentIndex = 0;
  
  // 循环模式
  LoopMode _loopMode = LoopMode.off;
  bool _shuffleMode = false;

  MyAudioHandler() {
    _init();
  }

  void _init() {
    // 监听播放状态变化
    _player.playbackEventStream.listen((event) {
      _updatePlaybackState();
    });

    // 监听当前歌曲变化
    _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _songs.length) {
        _currentIndex = index;
        _updateMediaItem();
      }
    });

    // 监听处理完成
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (_loopMode == LoopMode.one) {
          _player.seek(Duration.zero);
          _player.play();
        } else if (hasNext || _loopMode == LoopMode.all) {
          skipToNext();
        }
      }
      _updatePlaybackState();
    });
  }

  /// 更新播放状态（控制通知栏按钮）
  void _updatePlaybackState() {
    final isPlaying = _player.playing;
    final hasPrevious = _currentIndex > 0 || _loopMode == LoopMode.all;
    final hasNext = _currentIndex < _songs.length - 1 || _loopMode == LoopMode.all;

    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        isPlaying ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2], // 显示上一首、播放/暂停、下一首
      processingState: _mapProcessingState(_player.processingState),
      playing: isPlaying,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _currentIndex,
    ));
  }

  /// 更新当前媒体项
  void _updateMediaItem() {
    if (_songs.isEmpty || _currentIndex >= _songs.length) return;
    
    final song = _songs[_currentIndex];
    final mediaItem = MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: Duration(milliseconds: song.duration),
      artUri: song.albumId != null 
          ? Uri.parse('content://media/external/audio/albumart/${song.albumId}')
          : null,
    );
    
    this.mediaItem.add(mediaItem);
  }

  /// 设置播放列表
  Future<void> setPlaylist(List<Song> songs, {int initialIndex = 0}) async {
    _songs = List.from(songs);
    _currentIndex = initialIndex.clamp(0, _songs.length - 1);
    
    // 更新队列
    queue.add(_songs.map((song) => MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: Duration(milliseconds: song.duration),
      artUri: song.albumId != null 
          ? Uri.parse('content://media/external/audio/albumart/${song.albumId}')
          : null,
    )).toList());

    await _playCurrentSong();
  }

  /// 播放当前索引的歌曲
  Future<void> _playCurrentSong() async {
    if (_songs.isEmpty || _currentIndex < 0 || _currentIndex >= _songs.length) {
      return;
    }

    final song = _songs[_currentIndex];
    logInfo('AudioHandler', 'Playing: ${song.title}');

    try {
      final uri = song.uri.startsWith('content://') 
          ? Uri.parse(song.uri) 
          : Uri.file(song.uri);

      await _player.setAudioSource(AudioSource.uri(uri));
      await _player.play();
      
      _updateMediaItem();
      _updatePlaybackState();
    } catch (e) {
      logInfo('AudioHandler', 'Error playing: $e');
    }
  }

  @override
  Future<void> play() async {
    await _player.play();
    _updatePlaybackState();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _updatePlaybackState();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _updatePlaybackState();
  }

  @override
  Future<void> skipToNext() async {
    if (_shuffleMode) {
      _currentIndex = DateTime.now().millisecond % _songs.length;
    } else {
      _currentIndex++;
      if (_currentIndex >= _songs.length) {
        if (_loopMode == LoopMode.all) {
          _currentIndex = 0;
        } else {
          _currentIndex = _songs.length - 1;
          return;
        }
      }
    }
    await _playCurrentSong();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
    } else {
      _currentIndex--;
      if (_currentIndex < 0) {
        if (_loopMode == LoopMode.all) {
          _currentIndex = _songs.length - 1;
        } else {
          _currentIndex = 0;
          return;
        }
      }
      await _playCurrentSong();
    }
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _updatePlaybackState();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        _loopMode = LoopMode.off;
        break;
      case AudioServiceRepeatMode.one:
        _loopMode = LoopMode.one;
        break;
      case AudioServiceRepeatMode.all:
        _loopMode = LoopMode.all;
        break;
      case AudioServiceRepeatMode.group:
        break;
    }
    await _player.setLoopMode(_loopMode);
    _updatePlaybackState();
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    _shuffleMode = shuffleMode == AudioServiceShuffleMode.all;
    await _player.setShuffleModeEnabled(_shuffleMode);
    _updatePlaybackState();
  }

  /// 切换循环模式
  Future<void> cycleRepeatMode() async {
    final modes = [
      AudioServiceRepeatMode.none,
      AudioServiceRepeatMode.one,
      AudioServiceRepeatMode.all,
    ];
    final currentIndex = modes.indexOf(playbackState.value.repeatMode);
    final nextMode = modes[(currentIndex + 1) % modes.length];
    await setRepeatMode(nextMode);
  }

  /// 切换随机模式
  Future<void> toggleShuffleMode() async {
    await setShuffleMode(
      _shuffleMode ? AudioServiceShuffleMode.none : AudioServiceShuffleMode.all
    );
  }

  /// 获取当前播放状态
  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  // 公开播放器属性
  AudioPlayer get player => _player;
  List<Song> get songs => _songs;
  int get currentIndex => _currentIndex;
  Song? get currentSong => _songs.isNotEmpty && _currentIndex >= 0 && _currentIndex < _songs.length
      ? _songs[_currentIndex]
      : null;
  bool get hasNext => _currentIndex < _songs.length - 1;
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;
}
