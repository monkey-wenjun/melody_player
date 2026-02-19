import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/playlist_provider.dart';
import '../common/album_art.dart';
import 'player_controls.dart';

class MiniPlayer extends StatefulWidget {
  final VoidCallback onTap;

  const MiniPlayer({Key? key, required this.onTap}) : super(key: key);

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  bool _showLyrics = false;
  List<String> _lyricsLines = [];
  int _currentLyricIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadLyrics();
  }

  @override
  void didUpdateWidget(MiniPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentSong = context.read<PlayerProvider>().currentSong;
    if (currentSong != null) {
      _loadLyrics();
    }
  }

  Future<void> _loadLyrics() async {
    final song = context.read<PlayerProvider>().currentSong;
    if (song == null) return;

    final uri = song.uri;
    if (!uri.endsWith('.mp3') && !uri.endsWith('.flac') && 
        !uri.endsWith('.m4a') && !uri.endsWith('.aac')) {
      setState(() {
        _lyricsLines = [];
      });
      return;
    }

    final lyricsPath = uri.substring(0, uri.lastIndexOf('.')) + '.lrc';
    
    try {
      final file = File(lyricsPath);
      if (await file.exists()) {
        final content = await file.readAsString();
        _parseLyrics(content);
      } else {
        setState(() {
          _lyricsLines = [];
        });
      }
    } catch (e) {
      setState(() {
        _lyricsLines = [];
      });
    }
  }

  void _parseLyrics(String content) {
    final lines = content.split('\n');
    final lyrics = <String>[];

    // 简单的 LRC 解析，提取歌词文本
    final timeRegex = RegExp(r'\[\d{2}:\d{2}\.\d{2,3}\](.*)');
    
    for (final line in lines) {
      final match = timeRegex.firstMatch(line);
      if (match != null) {
        final text = match.group(1)?.trim() ?? '';
        if (text.isNotEmpty && !text.startsWith('[')) {
          lyrics.add(text);
        }
      }
    }

    if (mounted) {
      setState(() {
        _lyricsLines = lyrics;
      });
    }
  }

  void _updateCurrentLyric(Duration position) {
    if (_lyricsLines.isEmpty) return;
    
    // 简化处理：根据播放进度估算歌词行
    final totalDuration = context.read<PlayerProvider>().duration.inMilliseconds;
    if (totalDuration <= 0) return;
    
    final progress = position.inMilliseconds / totalDuration;
    final newIndex = (progress * _lyricsLines.length).floor().clamp(0, _lyricsLines.length - 1);
    
    if (newIndex != _currentLyricIndex) {
      setState(() {
        _currentLyricIndex = newIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        if (player.currentSong == null) {
          return const SizedBox.shrink();
        }

        final song = player.currentSong!;
        
        // 更新当前歌词
        if (_showLyrics) {
          _updateCurrentLyric(player.position);
        }

        return GestureDetector(
          onTap: widget.onTap,
          onHorizontalDragEnd: (details) {
            // 左右滑动切换显示模式
            if (details.primaryVelocity != null && details.primaryVelocity!.abs() > 100) {
              setState(() {
                _showLyrics = !_showLyrics;
              });
            }
          },
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A4A) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  // 专辑封面或歌词指示器
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showLyrics = !_showLyrics;
                      });
                    },
                    child: _showLyrics && _lyricsLines.isNotEmpty
                        ? _buildLyricsIndicator(theme)
                        : AlbumArt(id: song.id, size: 44, borderRadius: 6),
                  ),
                  const SizedBox(width: 12),
                  // 歌曲信息或滚动歌词
                  Expanded(
                    child: _showLyrics && _lyricsLines.isNotEmpty
                        ? _buildScrollingLyrics(theme)
                        : _buildSongInfo(song, theme),
                  ),
                  // 播放控制
                  IconButton(
                    icon: const Icon(Icons.skip_previous, size: 24),
                    onPressed: player.previous,
                  ),
                  PlayPauseButton(
                    isPlaying: player.isPlaying,
                    onPressed: player.togglePlay,
                    size: 40,
                    iconSize: 24,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, size: 24),
                    onPressed: player.next,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 歌曲信息
  Widget _buildSongInfo(var song, ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          song.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  /// 滚动歌词显示
  Widget _buildScrollingLyrics(ThemeData theme) {
    if (_lyricsLines.isEmpty) {
      return _buildNoLyrics(theme);
    }

    return ClipRect(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Column(
          key: ValueKey<int>(_currentLyricIndex),
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 当前歌词
            Text(
              _lyricsLines[_currentLyricIndex],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            // 下一句歌词（如果有）
            if (_currentLyricIndex < _lyricsLines.length - 1)
              Text(
                _lyricsLines[_currentLyricIndex + 1],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 歌词指示器
  Widget _buildLyricsIndicator(ThemeData theme) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        Icons.lyrics,
        color: theme.colorScheme.primary,
        size: 24,
      ),
    );
  }

  /// 无歌词提示
  Widget _buildNoLyrics(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '暂无歌词',
          style: TextStyle(
            fontSize: 14,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '左滑切换回歌曲信息',
          style: TextStyle(
            fontSize: 11,
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}

class MiniPlayerProgressBar extends StatelessWidget {
  const MiniPlayerProgressBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        if (player.currentSong == null) {
          return const SizedBox.shrink();
        }

        return LinearProgressIndicator(
          value: player.progress.clamp(0.0, 1.0),
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          minHeight: 2,
        );
      },
    );
  }
}
