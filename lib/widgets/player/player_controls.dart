import 'package:flutter/material.dart';

class PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? iconColor;

  const PlayPauseButton({
    Key? key,
    required this.isPlaying,
    required this.onPressed,
    this.size = 64,
    this.iconSize = 32,
    this.backgroundColor,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: backgroundColor ?? theme.colorScheme.primary,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          child: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
            color: iconColor ?? Colors.white,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}

class IconButtonCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;
  final Color? color;

  const IconButtonCircle({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.size = 48,
    this.iconSize = 24,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (color ?? theme.colorScheme.primary).withOpacity(0.1),
          ),
          child: Icon(
            icon,
            color: color ?? theme.colorScheme.primary,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}

class PlayerControlBar extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const PlayerControlBar({
    Key? key,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.skip_previous, size: 36, color: theme.iconTheme.color),
          onPressed: onPrevious,
        ),
        const SizedBox(width: 24),
        PlayPauseButton(
          isPlaying: isPlaying,
          onPressed: onPlayPause,
          size: 72,
          iconSize: 36,
        ),
        const SizedBox(width: 24),
        IconButton(
          icon: Icon(Icons.skip_next, size: 36, color: theme.iconTheme.color),
          onPressed: onNext,
        ),
      ],
    );
  }
}

class PlaybackModeButton extends StatelessWidget {
  final PlaybackMode mode;
  final VoidCallback onTap;

  const PlaybackModeButton({
    Key? key,
    required this.mode,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    IconData icon;
    String tooltip;
    
    switch (mode) {
      case PlaybackMode.sequential:
        icon = Icons.repeat;
        tooltip = '顺序播放';
        break;
      case PlaybackMode.shuffle:
        icon = Icons.shuffle;
        tooltip = '随机播放';
        break;
      case PlaybackMode.repeatOne:
        icon = Icons.repeat_one;
        tooltip = '单曲循环';
        break;
      case PlaybackMode.repeatAll:
        icon = Icons.repeat;
        tooltip = '列表循环';
        break;
    }

    return IconButton(
      icon: Icon(icon, color: theme.colorScheme.primary),
      tooltip: tooltip,
      onPressed: onTap,
    );
  }
}

enum PlaybackMode { sequential, shuffle, repeatOne, repeatAll }
