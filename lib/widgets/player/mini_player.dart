import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/playlist_provider.dart';
import '../common/album_art.dart';
import 'player_controls.dart';

class MiniPlayer extends StatelessWidget {
  final VoidCallback onTap;

  const MiniPlayer({Key? key, required this.onTap}) : super(key: key);

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

        return GestureDetector(
          onTap: onTap,
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
                  AlbumArt(id: song.id, size: 44, borderRadius: 6),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
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
                    ),
                  ),
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
