import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../services/audio_player_service.dart';
import 'playlist_provider.dart';

class PlayerProvider extends ChangeNotifier {
  final AudioPlayerService _audioService = AudioPlayerService();
  PlaylistProvider? _playlistProvider;

  // 播放器状态
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  String? _errorMessage;
  
  // 播放列表状态
  List<Song> _playlist = [];
  Song? _currentSong;
  int _currentIndex = 0;
  PlaybackMode _playbackMode = PlaybackMode.sequential;

  // Getters
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  String? get errorMessage => _errorMessage;
  List<Song> get playlist => _playlist;
  Song? get currentSong => _currentSong;
  int get currentIndex => _currentIndex;
  PlaybackMode get playbackMode => _playbackMode;
  
  double get progress {
    if (_duration.inMilliseconds == 0) return 0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  String get positionText => _formatDuration(_position);
  String get durationText => _formatDuration(_duration);

  // 流订阅
  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _indexSub;

  PlayerProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      await _audioService.init();
    } catch (e) {
      print('PlayerProvider init error: $e');
    }
    
    // 监听播放状态
    _playerStateSub = _audioService.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isLoading = state.processingState == ProcessingState.loading ||
                   state.processingState == ProcessingState.buffering;
      notifyListeners();
    });

    // 监听位置
    _positionSub = _audioService.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });

    // 监听时长
    _durationSub = _audioService.durationStream.listen((duration) {
      if (duration != null && duration.inMilliseconds > 0) {
        _duration = duration;
        notifyListeners();
      }
    });

    // 监听索引变化
    _indexSub = _audioService.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _playlist.length) {
        _currentIndex = index;
        _currentSong = _playlist[index];
        _errorMessage = null;
        notifyListeners();
      }
    });

    // 监听歌曲变化回调
    _audioService.onSongChanged = (song) {
      _currentSong = song;
      if (song != null) {
        _addToRecent(song);
      }
      notifyListeners();
    };

    // 监听播放模式
    _audioService.onModeChanged = (mode) {
      _playbackMode = mode;
      notifyListeners();
    };
    
    // 监听错误
    _audioService.onError = (message) {
      _errorMessage = message;
      notifyListeners();
    };
  }

  void setPlaylistProvider(PlaylistProvider provider) {
    _playlistProvider = provider;
  }

  void _addToRecent(Song song) {
    _playlistProvider?.addToRecent(song);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // 播放控制
  Future<void> play() async {
    await _audioService.play();
  }

  Future<void> pause() async {
    await _audioService.pause();
  }

  Future<void> togglePlay() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> next() async {
    _errorMessage = null;
    await _audioService.next();
  }

  Future<void> previous() async {
    _errorMessage = null;
    await _audioService.previous();
  }

  Future<void> seek(Duration position) async {
    await _audioService.seek(position);
  }

  Future<void> seekToProgress(double progress) async {
    final position = Duration(
      milliseconds: (_duration.inMilliseconds * progress).round(),
    );
    await seek(position);
  }

  // 播放列表管理
  Future<void> setPlaylist(List<Song> songs, {int initialIndex = 0, bool autoPlay = true}) async {
    _playlist = List.from(songs);
    _currentIndex = initialIndex;
    if (initialIndex >= 0 && initialIndex < songs.length) {
      _currentSong = songs[initialIndex];
    }
    _errorMessage = null;
    await _audioService.setPlaylist(songs, initialIndex: initialIndex);
    if (autoPlay) {
      await play();
    }
    notifyListeners();
  }

  Future<void> playSong(Song song, {List<Song>? queue}) async {
    _errorMessage = null;
    
    try {
      if (queue != null && queue.isNotEmpty) {
        // 找到歌曲在队列中的索引
        final index = queue.indexWhere((s) => s.id == song.id || s.uri == song.uri);
        final targetIndex = index >= 0 ? index : 0;
        final targetSong = index >= 0 ? queue[index] : song;
        
        print('PlayerProvider.playSong: target=${targetSong.title}, index=$targetIndex, queueSize=${queue.length}');
        
        // 直接调用 setPlaylist，它会处理状态更新和播放
        await setPlaylist(queue, initialIndex: targetIndex, autoPlay: true);
      } else {
        // 单首歌曲播放
        print('PlayerProvider.playSong: single song=${song.title}');
        if (_playlist.isEmpty) {
          await setPlaylist([song], initialIndex: 0, autoPlay: true);
        } else {
          await _audioService.playSong(song);
        }
      }
    } catch (e) {
      _errorMessage = '播放失败: $e';
      print('PlayerProvider.playSong error: $e');
    }
    notifyListeners();
  }

  Future<void> addToQueue(Song song) async {
    _playlist.add(song);
    await _audioService.setPlaylist(_playlist, initialIndex: _currentIndex);
    notifyListeners();
  }

  Future<void> playAtIndex(int index) async {
    if (index >= 0 && index < _playlist.length) {
      _currentIndex = index;
      _currentSong = _playlist[index];
      _errorMessage = null;
      
      try {
        await _audioService.playAtIndex(index);
      } catch (e) {
        _errorMessage = '播放失败: $e';
      }
      notifyListeners();
    }
  }

  // 播放模式
  void cyclePlaybackMode() {
    _audioService.cyclePlaybackMode();
  }

  void setPlaybackMode(PlaybackMode mode) {
    _audioService.setPlaybackMode(mode);
  }

  IconData getPlaybackModeIcon() {
    switch (_playbackMode) {
      case PlaybackMode.sequential:
        return Icons.repeat;
      case PlaybackMode.shuffle:
        return Icons.shuffle;
      case PlaybackMode.repeatOne:
        return Icons.repeat_one;
      case PlaybackMode.repeatAll:
        return Icons.repeat;
    }
  }

  String getPlaybackModeText() {
    switch (_playbackMode) {
      case PlaybackMode.sequential:
        return '顺序播放';
      case PlaybackMode.shuffle:
        return '随机播放';
      case PlaybackMode.repeatOne:
        return '单曲循环';
      case PlaybackMode.repeatAll:
        return '列表循环';
    }
  }

  // 音量控制
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _audioService.setVolume(_volume);
    notifyListeners();
  }

  // 工具方法
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _indexSub?.cancel();
    super.dispose();
  }
}
