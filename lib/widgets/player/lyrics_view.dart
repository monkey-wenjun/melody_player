import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import '../../models/song.dart';

/// 歌词行数据
class LyricLine {
  final Duration time;
  final String text;

  LyricLine({required this.time, required this.text});
}

/// 歌词显示组件
class LyricsView extends StatefulWidget {
  final Song song;

  const LyricsView({
    Key? key,
    required this.song,
  }) : super(key: key);

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  List<LyricLine> _lyrics = [];
  int _currentLineIndex = -1;
  final ScrollController _scrollController = ScrollController();
  bool _hasLyrics = false;

  @override
  void initState() {
    super.initState();
    _loadLyrics();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id) {
      _loadLyrics();
    }
  }

  /// 加载歌词文件
  Future<void> _loadLyrics() async {
    // 使用实际文件路径（处理 content:// URI 的情况）
    final filePath = widget.song.filePath;
    
    // 检查是否为支持的音频格式
    final lowerPath = filePath.toLowerCase();
    if (!lowerPath.endsWith('.mp3') && !lowerPath.endsWith('.flac') && 
        !lowerPath.endsWith('.m4a') && !lowerPath.endsWith('.aac') &&
        !lowerPath.endsWith('.wav') && !lowerPath.endsWith('.ogg') &&
        !lowerPath.endsWith('.opus')) {
      setState(() {
        _hasLyrics = false;
        _lyrics = [];
      });
      return;
    }

    // 构建歌词文件路径
    final lyricsPath = filePath.substring(0, filePath.lastIndexOf('.')) + '.lrc';
    
    try {
      final file = File(lyricsPath);
      if (await file.exists()) {
        final content = await file.readAsString();
        _parseLyrics(content);
      } else {
        // 尝试其他常见命名格式（使用歌曲标题）
        final dir = file.parent.path;
        // 清理文件名中的非法字符
        final sanitizedTitle = widget.song.title
            .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
            .trim();
        final alternativePath = '$dir/$sanitizedTitle.lrc';
        final altFile = File(alternativePath);
        
        if (await altFile.exists()) {
          final content = await altFile.readAsString();
          _parseLyrics(content);
        } else {
          setState(() {
            _hasLyrics = false;
            _lyrics = [];
          });
        }
      }
    } catch (e) {
      setState(() {
        _hasLyrics = false;
        _lyrics = [];
      });
    }
  }

  /// 解析 LRC 歌词格式
  void _parseLyrics(String content) {
    final lines = content.split('\n');
    final lyrics = <LyricLine>[];

    final timeRegex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');

    for (final line in lines) {
      final matches = timeRegex.allMatches(line);
      for (final match in matches) {
        final minutes = int.tryParse(match.group(1)!) ?? 0;
        final seconds = int.tryParse(match.group(2)!) ?? 0;
        final milliseconds = int.tryParse(match.group(3)!.padRight(3, '0')) ?? 0;
        final text = match.group(4)!.trim();

        if (text.isNotEmpty) {
          final time = Duration(
            minutes: minutes,
            seconds: seconds,
            milliseconds: milliseconds,
          );
          lyrics.add(LyricLine(time: time, text: text));
        }
      }
    }

    // 按时间排序
    lyrics.sort((a, b) => a.time.compareTo(b.time));

    setState(() {
      _lyrics = lyrics;
      _hasLyrics = lyrics.isNotEmpty;
    });
  }

  /// 更新当前歌词行
  void _updateCurrentLine(Duration position) {
    if (_lyrics.isEmpty) return;

    int newIndex = -1;
    for (int i = 0; i < _lyrics.length; i++) {
      if (_lyrics[i].time <= position) {
        newIndex = i;
      } else {
        break;
      }
    }

    if (newIndex != _currentLineIndex) {
      setState(() {
        _currentLineIndex = newIndex;
      });
      _scrollToCurrentLine();
    }
  }

  /// 滚动到当前歌词行
  void _scrollToCurrentLine() {
    if (_currentLineIndex < 0 || !_scrollController.hasClients) return;

    final itemHeight = 56.0; // 每行高度
    final viewportHeight = _scrollController.position.viewportDimension;
    final targetOffset = (_currentLineIndex * itemHeight) - (viewportHeight / 2) + (itemHeight / 2);

    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        // 更新当前歌词行
        _updateCurrentLine(player.position);

        if (!_hasLyrics) {
          return _buildNoLyricsView();
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.surface.withOpacity(0),
                Theme.of(context).colorScheme.surface.withOpacity(0.1),
              ],
            ),
          ),
          child: ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.1),
                  Colors.black,
                  Colors.black,
                  Colors.black.withOpacity(0.1),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.05, 0.15, 0.85, 0.95, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 200),
              itemCount: _lyrics.length,
              itemBuilder: (context, index) {
                final isCurrent = index == _currentLineIndex;
                final isPast = index < _currentLineIndex;

                return GestureDetector(
                  onTap: () {
                    // 点击歌词跳转到对应时间
                    player.seek(_lyrics[index].time);
                  },
                  child: Container(
                    height: 56,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        fontSize: isCurrent ? 20 : 16,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent
                            ? Theme.of(context).colorScheme.primary
                            : isPast
                                ? Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5)
                                : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                      child: Text(
                        _lyrics[index].text,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoLyricsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lyrics_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无歌词',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '将 .lrc 歌词文件放在音乐同目录下即可显示',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// 标签页指示器
class PageIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;

  const PageIndicator({
    Key? key,
    required this.count,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: currentIndex == index ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: currentIndex == index
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
