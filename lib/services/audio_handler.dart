import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../utils/logger.dart';
import '../utils/vinyl_artwork.dart';
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
  
  // 自定义当前索引流，因为 just_audio 的 currentIndexStream 不适用于我们手动管理的播放列表
  final _currentIndexController = StreamController<int>.broadcast();

  MyAudioHandler() {
    _init();
  }

  void _init() {
    // 监听播放状态变化
    _player.playbackEventStream.listen((event) {
      _updatePlaybackState();
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
    
    // 初始化空的播放状态，确保通知栏控件立即可用
    _updatePlaybackState();
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
        MediaAction.skipToPrevious,
        MediaAction.skipToNext,
      },
      androidCompactActionIndices: const [0, 1, 2], // 显示上一首、播放/暂停、下一首
      processingState: _mapProcessingState(_player.processingState),
      playing: isPlaying,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _currentIndex,
      repeatMode: _mapRepeatMode(_loopMode),
      shuffleMode: _shuffleMode ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
    ));
  }

  /// 映射循环模式
  AudioServiceRepeatMode _mapRepeatMode(LoopMode mode) {
    switch (mode) {
      case LoopMode.off:
        return AudioServiceRepeatMode.none;
      case LoopMode.one:
        return AudioServiceRepeatMode.one;
      case LoopMode.all:
        return AudioServiceRepeatMode.all;
    }
  }

  /// 更新当前媒体项
  Future<void> _updateMediaItem() async {
    if (_songs.isEmpty || _currentIndex >= _songs.length) return;
    
    final song = _songs[_currentIndex];
    
    // 构建专辑封面 URI
    Uri? artUri;
    if (song.albumId != null && song.albumId!.isNotEmpty) {
      // 先尝试系统媒体库封面
      artUri = Uri.parse('content://media/external/audio/albumart/${song.albumId}');
      print('[AudioHandler] Using system artwork for: ${song.title}, uri: $artUri');
    } else {
      // 无封面时使用黑胶唱片图标
      print('[AudioHandler] No albumId for: ${song.title}, using vinyl icon...');
      final vinylPath = await VinylArtwork.getVinylPath();
      if (vinylPath != null) {
        artUri = Uri.file(vinylPath);
        print('[AudioHandler] Using vinyl icon: $vinylPath');
      } else {
        print('[AudioHandler] Failed to get vinyl icon');
      }
    }
    
    final mediaItem = MediaItem(
      id: song.uri,  // 使用 URI 作为唯一标识
      title: song.title,
      album: song.album.isEmpty ? '未知专辑' : song.album,
      artist: song.artist.isEmpty ? '未知艺术家' : song.artist,
      duration: Duration(milliseconds: song.duration),
      artUri: artUri,
      displayTitle: song.title,
      displaySubtitle: song.artist.isEmpty ? '未知艺术家' : song.artist,
      displayDescription: song.album.isEmpty ? '未知专辑' : song.album,
    );
    
    this.mediaItem.add(mediaItem);
    
    print('[AudioHandler] MediaItem updated: ${song.title}, artUri: $artUri');
  }

  /// 设置播放列表
  Future<void> setPlaylist(List<Song> songs, {int initialIndex = 0}) async {
    _songs = List.from(songs);
    _currentIndex = initialIndex.clamp(0, _songs.length - 1);
    
    // 构建队列
    final queueItems = <MediaItem>[];
    for (final song in _songs) {
      Uri? artUri;
      if (song.albumId != null && song.albumId!.isNotEmpty) {
        artUri = Uri.parse('content://media/external/audio/albumart/${song.albumId}');
      } else {
        // 无封面时使用黑胶唱片图标
        final vinylPath = await VinylArtwork.getVinylPath();
        if (vinylPath != null) {
          artUri = Uri.file(vinylPath);
        }
      }
      
      queueItems.add(MediaItem(
        id: song.uri,
        title: song.title,
        album: song.album.isEmpty ? '未知专辑' : song.album,
        artist: song.artist.isEmpty ? '未知艺术家' : song.artist,
        duration: Duration(milliseconds: song.duration),
        artUri: artUri,
        displayTitle: song.title,
        displaySubtitle: song.artist.isEmpty ? '未知艺术家' : song.artist,
      ));
    }
    
    // 更新队列
    queue.add(queueItems);
    
    logInfo('AudioHandler', 'Playlist set: ${_songs.length} songs, index: $_currentIndex');

    _currentIndexController.add(_currentIndex);
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
      // 先更新媒体项，确保通知栏能显示歌曲信息
      await _updateMediaItem();
      
      final uri = song.uri.startsWith('content://') 
          ? Uri.parse(song.uri) 
          : Uri.file(song.uri);

      await _player.setAudioSource(AudioSource.uri(uri));
      await _player.play();
      
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
    if (_songs.isEmpty) return;
    
    if (_shuffleMode) {
      _currentIndex = DateTime.now().millisecond % _songs.length;
    } else {
      final nextIndex = _currentIndex + 1;
      if (nextIndex >= _songs.length) {
        if (_loopMode == LoopMode.all) {
          _currentIndex = 0;
        } else {
          // 非循环模式下已到最后一首，不执行操作
          return;
        }
      } else {
        _currentIndex = nextIndex;
      }
    }
    _currentIndexController.add(_currentIndex);
    await _playCurrentSong();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_songs.isEmpty) return;
    
    // 如果当前播放超过3秒且不是第一首，先跳到开头
    // 但如果是第一首或循环模式，则切换到上一首/最后一首
    if (_player.position > const Duration(seconds: 3) && _currentIndex > 0) {
      await _player.seek(Duration.zero);
      return;
    }
    
    if (_shuffleMode) {
      _currentIndex = DateTime.now().millisecond % _songs.length;
    } else {
      final prevIndex = _currentIndex - 1;
      if (prevIndex < 0) {
        if (_loopMode == LoopMode.all) {
          _currentIndex = _songs.length - 1;
        } else {
          // 非循环模式下已在第一首，跳到开头
          await _player.seek(Duration.zero);
          return;
        }
      } else {
        _currentIndex = prevIndex;
      }
    }
    _currentIndexController.add(_currentIndex);
    await _playCurrentSong();
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
  Stream<int?> get currentIndexStream => _currentIndexController.stream;
  
  void dispose() {
    _currentIndexController.close();
  }
}
