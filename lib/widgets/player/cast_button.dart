import 'package:flutter/material.dart';
import '../../services/cast_service.dart';

/// Google Cast 投屏按钮（简化版）
class CastButton extends StatelessWidget {
  const CastButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.cast_connected),
      onPressed: () => _showCastDialog(context),
    );
  }

  void _showCastDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Google Cast'),
        content: const Text('投屏功能即将推出，敬请期待！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
